-- The job's lifecycle, part 2 of 2: reading a job and moving it along.
--
-- `request_contacts` still has no update grant for clients, so the only way
-- a status changes is the function below. It decides three things the app
-- must not be trusted with:
--
--   * whether the caller belongs to this job at all;
--   * whether they are the customer or the provider, because the two may
--     do different things;
--   * whether the step being asked for follows the one before it.
--
-- That last point matters as much as the first two. "Done" must not be
-- reachable from "accepted" -- not because the app would offer it, but
-- because nothing outside the database can promise it will not.

-- 1. The jobs a person is part of --------------------------------------------

create function public.my_jobs()
returns table (
  contact_id uuid,
  request_id uuid,
  provider_id uuid,
  viewer_is_customer boolean,
  status public.request_contact_status,
  other_name text,
  service_name text,
  service_name_en text,
  description text,
  city text,
  postal_code text,
  scheduled_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  customer_confirmed_at timestamptz,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  with mine as (
    -- The whole boundary. Everything below joins onto rows that already
    -- passed it.
    select c.*, r.customer_id, (r.customer_id = (select auth.uid()))
             as viewer_is_customer
    from public.request_contacts c
    join public.service_requests r on r.id = c.request_id
    where (
        r.customer_id = (select auth.uid())
        or exists (
          select 1 from public.providers p
          where p.id = c.provider_id and p.user_id = (select auth.uid())
        )
      )
      -- A job starts when somebody says yes. Requests still waiting for an
      -- answer, and refused ones, are not jobs and stay off this list.
      and c.status not in ('sent', 'declined')
  )
  select
    m.id,
    m.request_id,
    m.provider_id,
    m.viewer_is_customer,
    m.status,
    case
      when m.viewer_is_customer then coalesce(
        nullif(p.display_name, ''),
        nullif(p.business_name, ''),
        nullif(p.first_name, '')
      )
      else nullif(prof.display_name, '')
    end,
    s.name,
    s.name_en,
    r.original_description,
    r.city,
    r.postal_code,
    m.scheduled_at,
    m.started_at,
    m.completed_at,
    m.customer_confirmed_at,
    m.updated_at
  from mine m
  join public.providers p on p.id = m.provider_id
  join public.service_requests r on r.id = m.request_id
  left join public.profiles prof on prof.id = m.customer_id
  left join public.services s on s.id = r.service_id
  -- What moved most recently is what somebody is waiting on.
  order by m.updated_at desc;
$$;

comment on function public.my_jobs is
  'The caller''s own jobs, from both sides. The return type is the whole '
  'contract: the other person''s name, never their email, phone or address.';

revoke execute on function public.my_jobs() from public, anon;
grant execute on function public.my_jobs() to authenticated;

-- 2. Moving a job one step -----------------------------------------------------

create function public.advance_job_status(
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
    -- Same answer either way: somebody else's job is not findable, and a
    -- job that does not exist is not distinguishable from one that is not
    -- theirs.
    raise exception 'Job not found' using errcode = '42501';
  end if;

  -- Which step may follow which, and who may take it. Anything not listed
  -- here cannot happen, so "accepted" can never jump to "completed".
  if new_status = 'scheduled' then
    -- Either of them may record the time they agreed on in the chat.
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
    -- The one point the provider must not be able to reach: a job counts
    -- as done when the person who paid for it says so.
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
    -- 'sent', 'accepted', 'declined' and 'cancelled' are not steps this
    -- function takes. Cancelling in particular is its own decision, with
    -- its own consequences, and is not built yet.
    raise exception 'Status % cannot be set here', new_status
      using errcode = '22023';
  end if;

  return new_status;
end;
$$;

comment on function public.advance_job_status is
  'The only writer of request_contacts.status after the answer. Enforces '
  'both who may take a step and which step may follow which.';

revoke execute on function public.advance_job_status(
  uuid, public.request_contact_status, timestamptz
) from public, anon;
grant execute on function public.advance_job_status(
  uuid, public.request_contact_status, timestamptz
) to authenticated;
