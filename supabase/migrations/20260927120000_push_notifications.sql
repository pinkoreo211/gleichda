-- Telling someone something happened, when they are not looking at the app.
--
-- Two tables and one rule:
--
--   * `user_push_tokens` — which devices belong to which account. A client
--     may write only its own rows and can read nobody's, not even its own
--     by accident: there is no select policy at all, because nothing in the
--     app needs to read a token back.
--   * `notification_outbox` — what still has to be sent. No client can
--     read or write it. The functions that already do the real work put a
--     row here; a server-side sender picks it up.
--
-- The outbox is the whole point. A push that fails must never undo a
-- booking, so sending is not part of the booking: the booking writes a
-- note, commits, and is done. If the sender is down, the note waits.
--
-- What goes in a note is deliberately thin. A name and a service, never an
-- address, never a phone number, never what the customer wrote. A push
-- appears on a lock screen, which is the least private place a sentence
-- can land.

-- Devices -------------------------------------------------------------------

create table public.user_push_tokens (
  id uuid primary key default gen_random_uuid(),

  -- Defaults to the caller and is not grantable, so a token can never be
  -- filed under somebody else's account.
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,

  -- The device's address at the push service.
  token text not null check (char_length(token) between 1 and 4096),

  platform text check (platform in ('android', 'ios', 'web')),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- One row per device. A device that reinstalls gets a new token; the old
  -- one stops working and the sender clears it out.
  unique (token)
);

comment on table public.user_push_tokens is
  'Which devices to reach an account on. Write-only for clients: they '
  'register and delete their own, and can read none.';

create index user_push_tokens_user_idx on public.user_push_tokens (user_id);

create trigger user_push_tokens_set_updated_at
  before update on public.user_push_tokens
  for each row execute function public.set_updated_at();

alter table public.user_push_tokens enable row level security;

revoke all on public.user_push_tokens from anon, authenticated;

-- No select grant: the app never needs to read a token it just sent.
-- Reading is for the sender, which runs with the service role.
grant insert (token, platform) on public.user_push_tokens to authenticated;
grant update (token, platform) on public.user_push_tokens to authenticated;
grant delete on public.user_push_tokens to authenticated;

create policy "People register their own devices"
  on public.user_push_tokens for insert
  to authenticated
  with check (user_id = (select auth.uid()));

create policy "People update their own devices"
  on public.user_push_tokens for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "People remove their own devices"
  on public.user_push_tokens for delete
  to authenticated
  using (user_id = (select auth.uid()));

-- Registering a device ---------------------------------------------------------

-- A token can move between accounts: two people sharing a phone, or one
-- person signing out and someone else signing in. Whoever registered it
-- last is who the device belongs to, so the previous owner stops being
-- reachable there.
create function public.register_push_token(
  device_token text,
  device_platform text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  me uuid := (select auth.uid());
begin
  if me is null then
    raise exception 'Not signed in' using errcode = '42501';
  end if;
  if device_token is null or btrim(device_token) = '' then
    raise exception 'A device needs a token' using errcode = '22023';
  end if;

  insert into public.user_push_tokens (user_id, token, platform)
  values (me, btrim(device_token), device_platform)
  on conflict (token) do update
    set user_id = me,
        platform = coalesce(excluded.platform,
                            public.user_push_tokens.platform),
        updated_at = now();
end;
$$;

comment on function public.register_push_token is
  'Files a device under the signed-in account, taking it off any other.';

revoke execute on function public.register_push_token(text, text)
  from public, anon;
grant execute on function public.register_push_token(text, text)
  to authenticated;

-- Signing out should stop the pushes, so the app forgets the device.
create function public.forget_push_token(device_token text)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.user_push_tokens
  where token = btrim(device_token)
    and user_id = (select auth.uid());
$$;

comment on function public.forget_push_token is
  'Removes one of the caller''s own devices. Another account''s device is '
  'not matched, so nobody can unregister somebody else.';

revoke execute on function public.forget_push_token(text) from public, anon;
grant execute on function public.forget_push_token(text) to authenticated;

-- What still has to be sent -----------------------------------------------------

-- Every kind of notification the app will ever send, named now so the
-- column does not have to change when the next one is switched on. Only
-- 'booking_received' is written today; the rest are one line each, in the
-- function that already performs the step.
create type public.notification_kind as enum (
  'booking_received',     -- a request reached a provider
  'request_accepted',     -- the provider said yes
  'appointment_agreed',   -- a time was recorded
  'provider_on_the_way',
  'job_completed',        -- the provider says the work is done
  'job_confirmed',        -- the customer agrees it is
  'chat_message'
);

create table public.notification_outbox (
  id uuid primary key default gen_random_uuid(),

  recipient_id uuid not null references auth.users (id) on delete cascade,
  kind public.notification_kind not null,

  -- The job this is about. The app opens it when the notification is
  -- tapped, so a push lands on the thing it is about rather than on the
  -- home screen.
  contact_id uuid references public.request_contacts (id) on delete cascade,

  -- The few facts the text is built from: a name, a service. The wording
  -- itself lives in the sender, so it can be changed without a migration.
  -- Never an address and never what the customer wrote.
  payload jsonb not null default '{}'::jsonb,

  status text not null default 'pending'
    check (status in ('pending', 'sent', 'failed')),
  attempts integer not null default 0,
  last_error text,

  created_at timestamptz not null default now(),
  sent_at timestamptz
);

comment on table public.notification_outbox is
  'Notes for the sender. Written by the functions that do the real work, '
  'read only by the sender. No client can reach this table.';

create index notification_outbox_pending_idx
  on public.notification_outbox (created_at)
  where status = 'pending';

alter table public.notification_outbox enable row level security;

-- No grants at all. Not select, not insert: the app neither writes its own
-- notifications nor reads anybody's. The security definer functions below
-- write, and the sender reads with the service role.
revoke all on public.notification_outbox from anon, authenticated;

-- Writing a note ------------------------------------------------------------------

create function public.enqueue_notification(
  target_recipient_id uuid,
  notification_kind public.notification_kind,
  target_contact_id uuid default null,
  notification_payload jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  note_id uuid;
begin
  -- Nobody is told about their own doing. Without this, accepting your own
  -- request -- which cannot happen -- or any future self-directed step
  -- would buzz the phone of the person who just tapped the button.
  if target_recipient_id is null
     or target_recipient_id = (select auth.uid()) then
    return null;
  end if;

  insert into public.notification_outbox (
    recipient_id, kind, contact_id, payload
  )
  values (
    target_recipient_id,
    notification_kind,
    target_contact_id,
    coalesce(notification_payload, '{}'::jsonb)
  )
  returning id into note_id;

  return note_id;
end;
$$;

comment on function public.enqueue_notification is
  'The only writer of the outbox. Not callable by any client role: it is '
  'called from inside the functions that perform the step being announced.';

revoke execute on function public.enqueue_notification(
  uuid, public.notification_kind, uuid, jsonb
) from public, anon, authenticated;

-- What the sender needs to know ---------------------------------------------------

-- One row per note still to send, with the devices to send it to already
-- joined on. The sender never queries the tables itself, so what it can
-- see is exactly this.
create function public.pending_notifications(batch_size integer default 20)
returns table (
  id uuid,
  recipient_id uuid,
  kind public.notification_kind,
  contact_id uuid,
  payload jsonb,
  attempts integer,
  tokens text[]
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    n.id,
    n.recipient_id,
    n.kind,
    n.contact_id,
    n.payload,
    n.attempts,
    coalesce(
      array(
        select t.token from public.user_push_tokens t
        where t.user_id = n.recipient_id
      ),
      array[]::text[]
    )
  from public.notification_outbox n
  where n.status = 'pending'
    -- Three tries, then it stops. A note nobody can deliver is not worth
    -- retrying forever.
    and n.attempts < 3
  order by n.created_at
  limit greatest(1, least(coalesce(batch_size, 20), 100));
$$;

revoke execute on function public.pending_notifications(integer)
  from public, anon, authenticated;

create function public.mark_notification_sent(note_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.notification_outbox
     set status = 'sent', sent_at = now(), attempts = attempts + 1,
         last_error = null
   where id = note_id;
$$;

revoke execute on function public.mark_notification_sent(uuid)
  from public, anon, authenticated;

create function public.mark_notification_failed(note_id uuid, reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.notification_outbox
     set attempts = attempts + 1,
         last_error = left(coalesce(reason, ''), 500),
         -- Only the last try is a failure. Before that it stays pending
         -- and the sender will come back to it.
         status = case when attempts + 1 >= 3 then 'failed' else 'pending' end
   where id = note_id;
end;
$$;

revoke execute on function public.mark_notification_failed(uuid, text)
  from public, anon, authenticated;

-- A device the push service rejected is gone for good; keeping it means
-- trying it again every time.
create function public.drop_push_token(device_token text)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.user_push_tokens where token = device_token;
$$;

revoke execute on function public.drop_push_token(text)
  from public, anon, authenticated;

-- Telling a provider about a new request -------------------------------------------

-- Both ways a request reaches a provider now leave a note. Recreated
-- rather than replaced only where the body changes; the signatures and
-- everything else stay exactly as they were.

create or replace function public.send_request_to_provider(
  target_request_id uuid,
  target_provider_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  contact_id uuid;
  request_service_id uuid;
  provider_user_id uuid;
  customer_name text;
  service_name text;
begin
  select r.service_id into request_service_id
  from public.service_requests r
  where r.id = target_request_id
    and r.customer_id = (select auth.uid());

  if not found then
    raise exception 'Request not found' using errcode = '42501';
  end if;

  if request_service_id is null then
    raise exception 'Request has no service yet' using errcode = '22023';
  end if;

  if exists (
    select 1 from public.providers p
    where p.id = target_provider_id and p.user_id = (select auth.uid())
  ) then
    raise exception 'Cannot send a request to your own profile'
      using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.provider_services ps
    join public.providers p on p.id = ps.provider_id
    where ps.provider_id = target_provider_id
      and ps.service_id = request_service_id
      and ps.is_active
      and p.onboarding_status = 'completed'
  ) then
    raise exception 'Provider does not offer this service'
      using errcode = '42501';
  end if;

  insert into public.request_contacts (request_id, provider_id)
  values (target_request_id, target_provider_id)
  on conflict (request_id, provider_id) do update
    set request_id = excluded.request_id
  returning id into contact_id;

  -- The note. Anything that goes wrong from here must not undo the line
  -- above, so it is wrapped: a request that reached a provider stays
  -- reached even if nobody could be told about it.
  begin
    select p.user_id into provider_user_id
    from public.providers p where p.id = target_provider_id;

    select nullif(prof.display_name, '') into customer_name
    from public.profiles prof where prof.id = (select auth.uid());

    select s.name into service_name
    from public.service_requests r
    join public.services s on s.id = r.service_id
    where r.id = target_request_id;

    perform public.enqueue_notification(
      provider_user_id,
      'booking_received',
      contact_id,
      jsonb_build_object(
        'customer_name', customer_name,
        'service_name', service_name
      )
    );
  exception when others then
    -- Deliberately swallowed. A missing notification is a smaller problem
    -- than a request that did not arrive.
    null;
  end;

  return contact_id;
end;
$$;

create or replace function public.create_booking(
  description text,
  target_service_id uuid,
  target_provider_id uuid,
  price_option_id uuid,
  wanted_at timestamptz,
  booking_address text default null,
  booking_postal_code text default null,
  booking_city text default null
)
returns table (request_id uuid, contact_id uuid)
language plpgsql
security definer
set search_path = ''
as $$
declare
  me uuid := (select auth.uid());
  agreed_price integer;
  agreed_currency char(3);
  new_request_id uuid;
  new_contact_id uuid;
  provider_user_id uuid;
  customer_name text;
  service_name text;
begin
  if me is null then
    raise exception 'Not signed in' using errcode = '42501';
  end if;

  if description is null or btrim(description) = '' then
    raise exception 'A request needs a description' using errcode = '22023';
  end if;

  if wanted_at is null then
    raise exception 'A booking needs a time' using errcode = '22023';
  end if;

  select pp.price_cents, pp.currency
    into agreed_price, agreed_currency
  from public.provider_service_prices pp
  join public.provider_services ps on ps.id = pp.provider_service_id
  join public.providers p on p.id = ps.provider_id
  where pp.id = price_option_id
    and pp.is_active
    and ps.is_active
    and ps.provider_id = target_provider_id
    and ps.service_id = target_service_id
    and p.onboarding_status = 'completed'
    and p.verification_status = 'verified'
    and p.user_id <> me;

  if not found then
    raise exception 'That price is not on offer' using errcode = '42501';
  end if;

  insert into public.service_requests (
    customer_id, original_description, service_id,
    timing, preferred_date,
    address, postal_code, city
  )
  values (
    me,
    btrim(description),
    target_service_id,
    'onDate',
    (wanted_at at time zone 'UTC')::date,
    nullif(btrim(coalesce(booking_address, '')), ''),
    nullif(btrim(coalesce(booking_postal_code, '')), ''),
    nullif(btrim(coalesce(booking_city, '')), '')
  )
  returning id into new_request_id;

  insert into public.request_contacts (
    request_id, provider_id,
    provider_service_price_id, price_cents, currency, requested_at
  )
  values (
    new_request_id, target_provider_id,
    price_option_id, agreed_price, agreed_currency, wanted_at
  )
  returning id into new_contact_id;

  -- Same as above: the booking is made, and telling the provider is a
  -- separate, failable thing.
  begin
    select p.user_id into provider_user_id
    from public.providers p where p.id = target_provider_id;

    select nullif(prof.display_name, '') into customer_name
    from public.profiles prof where prof.id = me;

    select s.name into service_name
    from public.services s where s.id = target_service_id;

    perform public.enqueue_notification(
      provider_user_id,
      'booking_received',
      new_contact_id,
      jsonb_build_object(
        'customer_name', customer_name,
        'service_name', service_name
      )
    );
  exception when others then
    null;
  end;

  return query select new_request_id, new_contact_id;
end;
$$;
