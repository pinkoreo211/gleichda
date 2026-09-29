-- Telling the other side what just happened.
--
-- No new machinery. The outbox, the sender, the webhook and the wording
-- have been carrying "new request" for days; each notification below is one
-- more call to enqueue_notification() inside the function that already
-- performs the step. Recreated only because their bodies change.
--
-- Five, in the order they occur in a job:
--
--   1. accepted           → customer
--   2. appointment agreed → the other one of the two
--   3. on the way         → customer
--   4. completed          → customer
--   5. confirmed          → provider
--
-- `in_progress` deliberately sends nothing. The customer already knows the
-- provider arrived, and a phone buzzing while someone works in your flat
-- tells you nothing you cannot see.
--
-- Every enqueue sits in its own block that swallows its errors. A step
-- that happened must stay happened even if nobody could be told about it:
-- a job that silently rolled back would be far worse than a missing push.

-- 1. The provider answers ----------------------------------------------------

create or replace function public.respond_to_request(
  target_contact_id uuid,
  new_status public.request_contact_status
)
returns public.request_contact_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  updated_status public.request_contact_status;
  customer_user_id uuid;
  provider_name text;
  service_name text;
begin
  if new_status not in ('accepted', 'declined') then
    raise exception 'Status % is not an answer', new_status
      using errcode = '22023';
  end if;

  update public.request_contacts c
     set status = new_status
   where c.id = target_contact_id
     and c.status = 'sent'
     and exists (
       select 1 from public.providers p
       where p.id = c.provider_id and p.user_id = (select auth.uid())
     )
  returning c.status into updated_status;

  if updated_status is not null then
    -- Only a yes is worth a notification. A customer who was turned down
    -- finds out in the app; a push saying "no" on a lock screen would be
    -- the coldest way to hear it.
    if updated_status = 'accepted' then
      begin
        select
          r.customer_id,
          coalesce(nullif(p.display_name, ''), nullif(p.business_name, ''),
                   nullif(p.first_name, '')),
          s.name
        into customer_user_id, provider_name, service_name
        from public.request_contacts c
        join public.service_requests r on r.id = c.request_id
        join public.providers p on p.id = c.provider_id
        left join public.services s on s.id = r.service_id
        where c.id = target_contact_id;

        perform public.enqueue_notification(
          customer_user_id,
          'request_accepted',
          target_contact_id,
          jsonb_build_object(
            'other_name', provider_name,
            'service_name', service_name
          )
        );
      exception when others then
        null;
      end;
    end if;

    return updated_status;
  end if;

  if exists (
    select 1
    from public.request_contacts c
    join public.providers p on p.id = c.provider_id
    where c.id = target_contact_id
      and p.user_id = (select auth.uid())
  ) then
    raise exception 'Request was already answered' using errcode = '22023';
  end if;

  raise exception 'Request not found' using errcode = '42501';
end;
$$;

-- 2 to 5. The job moves along -----------------------------------------------

create or replace function public.advance_job_status(
  target_contact_id uuid,
  new_status public.request_contact_status,
  appointment_at timestamptz default null
)
returns public.request_contact_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_status public.request_contact_status;
  is_customer boolean;
  is_provider boolean;
  customer_user_id uuid;
  provider_user_id uuid;
  provider_name text;
  customer_name text;
  service_name text;
  recipient_id uuid;
  kind public.notification_kind;
begin
  select
    c.status,
    r.customer_id = (select auth.uid()),
    exists (
      select 1 from public.providers p
      where p.id = c.provider_id and p.user_id = (select auth.uid())
    )
  into current_status, is_customer, is_provider
  from public.request_contacts c
  join public.service_requests r on r.id = c.request_id
  where c.id = target_contact_id;

  if not found or not (is_customer or is_provider) then
    raise exception 'Job not found' using errcode = '42501';
  end if;

  if new_status = 'scheduled' then
    if current_status not in ('accepted', 'scheduled') then
      raise exception 'A time can only be set on an accepted job'
        using errcode = '22023';
    end if;
    if appointment_at is null then
      raise exception 'An appointment needs a time' using errcode = '22023';
    end if;

    update public.request_contacts
       set status = 'scheduled', scheduled_at = appointment_at
     where id = target_contact_id;

  elsif new_status = 'on_the_way' then
    if not is_provider then
      raise exception 'Only the provider is on their way'
        using errcode = '42501';
    end if;
    if current_status <> 'scheduled' then
      raise exception 'Agree a time first' using errcode = '22023';
    end if;

    update public.request_contacts
       set status = 'on_the_way'
     where id = target_contact_id;

  elsif new_status = 'in_progress' then
    if not is_provider then
      raise exception 'Only the provider starts the work'
        using errcode = '42501';
    end if;
    if current_status <> 'on_the_way' then
      raise exception 'Say you are on your way first'
        using errcode = '22023';
    end if;

    update public.request_contacts
       set status = 'in_progress', started_at = now()
     where id = target_contact_id;

  elsif new_status = 'completed' then
    if not is_provider then
      raise exception 'Only the provider reports the work done'
        using errcode = '42501';
    end if;
    if current_status <> 'in_progress' then
      raise exception 'Start the work first' using errcode = '22023';
    end if;

    update public.request_contacts
       set status = 'completed', completed_at = now()
     where id = target_contact_id;

  elsif new_status = 'customer_confirmed' then
    if not is_customer then
      raise exception 'Only the customer confirms their own job'
        using errcode = '42501';
    end if;
    if current_status <> 'completed' then
      raise exception 'Nothing to confirm yet' using errcode = '22023';
    end if;

    update public.request_contacts
       set status = 'customer_confirmed', customer_confirmed_at = now()
     where id = target_contact_id;

  else
    raise exception 'Status % cannot be set here', new_status
      using errcode = '22023';
  end if;

  -- The step stands. Telling somebody about it is a separate, failable
  -- thing, so it gets its own block.
  begin
    select
      r.customer_id,
      p.user_id,
      coalesce(nullif(p.display_name, ''), nullif(p.business_name, ''),
               nullif(p.first_name, '')),
      nullif(prof.display_name, ''),
      s.name
    into customer_user_id, provider_user_id, provider_name, customer_name,
         service_name
    from public.request_contacts c
    join public.service_requests r on r.id = c.request_id
    join public.providers p on p.id = c.provider_id
    left join public.profiles prof on prof.id = r.customer_id
    left join public.services s on s.id = r.service_id
    where c.id = target_contact_id;

    -- Who hears about it, and as what.
    if new_status = 'scheduled' then
      -- Either of them may set the time, so the note goes to whichever
      -- one did not. enqueue_notification() drops a note addressed to the
      -- person who caused it, which makes this safe either way round.
      kind := 'appointment_agreed';
      recipient_id := case
        when is_customer then provider_user_id else customer_user_id
      end;
    elsif new_status = 'on_the_way' then
      kind := 'provider_on_the_way';
      recipient_id := customer_user_id;
    elsif new_status = 'completed' then
      kind := 'job_completed';
      recipient_id := customer_user_id;
    elsif new_status = 'customer_confirmed' then
      kind := 'job_confirmed';
      recipient_id := provider_user_id;
    else
      -- 'in_progress' on purpose: see the note at the top.
      kind := null;
    end if;

    if kind is not null then
      perform public.enqueue_notification(
        recipient_id,
        kind,
        target_contact_id,
        jsonb_build_object(
          -- The name of whoever is not being told, which is who every one
          -- of these texts is about.
          'other_name', case
            when recipient_id = customer_user_id then provider_name
            else customer_name
          end,
          'service_name', service_name
        )
      );
    end if;
  exception when others then
    null;
  end;

  return new_status;
end;
$$;
