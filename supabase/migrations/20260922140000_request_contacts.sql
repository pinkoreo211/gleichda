-- Sending a request to a provider.
--
-- Until now a request was saved and then sat there: nobody was ever told
-- about it. This adds the missing half -- the customer picks a provider and
-- the request reaches them.
--
-- Security model, in one sentence: the client never names the facts that
-- matter. It passes a request id, and the server looks up the service, the
-- city and the ownership itself.
--
-- Three functions, each one a door with a fixed shape:
-- * find_providers_for_request -- who can do this request
-- * send_request_to_provider   -- hand the request over
-- * requests_for_me            -- what a provider has received
--
-- Deliberately NOT done: a row policy on service_requests for providers.
-- That table grants SELECT on every column, so any row a provider could
-- match would hand them customer_id and the AI columns with it. Row
-- policies cannot distinguish columns; a function's return type can.

-- 1. Requests know where the work is ---------------------------------------

alter table public.service_requests
  add column city text check (char_length(city) <= 120),
  add column postal_code text check (char_length(postal_code) <= 12);

comment on column public.service_requests.city is
  'Where the work is. Plain text, matched against providers.city for now; '
  'real distance arrives with maps.';

grant insert (city, postal_code) on public.service_requests to authenticated;
grant update (city, postal_code) on public.service_requests to authenticated;

-- 2. The contact between a request and a provider --------------------------

-- Only 'sent' is used at this stage. The other two are what a provider will
-- answer with once replying exists; they are named here so the column does
-- not have to change later.
create type public.request_contact_status as enum (
  'sent',
  'accepted',
  'declined'
);

create table public.request_contacts (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null
    references public.service_requests (id) on delete cascade,
  provider_id uuid not null
    references public.providers (id) on delete cascade,
  status public.request_contact_status not null default 'sent',
  created_at timestamptz not null default now(),

  -- One request reaches a provider once. Tapping twice changes nothing.
  unique (request_id, provider_id)
);

comment on table public.request_contacts is
  'One row per request handed to a provider. Written only by '
  'send_request_to_provider(), never directly by a client.';

create index request_contacts_provider_idx
  on public.request_contacts (provider_id, created_at desc);
create index request_contacts_request_idx
  on public.request_contacts (request_id);

alter table public.request_contacts enable row level security;

revoke all on public.request_contacts from anon, authenticated;

-- Readable, never writable: no insert, update or delete grant exists, so
-- the only way a row gets here is through the function below.
grant select on public.request_contacts to authenticated;

create policy "Customers see who they contacted"
  on public.request_contacts for select
  to authenticated
  using (
    exists (
      select 1 from public.service_requests r
      where r.id = request_id and r.customer_id = (select auth.uid())
    )
  );

-- No policy for providers on purpose: a provider reads what they received
-- through requests_for_me(), which returns the request's content too.

-- 3. Who can do this request -----------------------------------------------

create function public.find_providers_for_request(target_request_id uuid)
returns table (
  provider_id uuid,
  display_name text,
  description text,
  city text,
  verification_status public.provider_verification_status,
  lowest_price_cents integer,
  currency char(3),
  already_contacted boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  with request as (
    -- The ownership check is this line. A request that is not the caller's
    -- yields no row, so the rest of the query returns nothing.
    select r.id, r.service_id, r.city
    from public.service_requests r
    where r.id = target_request_id
      and r.customer_id = (select auth.uid())
  )
  select
    p.id,
    coalesce(nullif(p.display_name, ''), nullif(p.business_name, ''),
             nullif(p.first_name, '')),
    p.description,
    p.city,
    p.verification_status,
    cheapest.price_cents,
    cheapest.currency,
    exists (
      select 1 from public.request_contacts c
      where c.request_id = request.id and c.provider_id = p.id
    )
  from request
  join public.provider_services ps
    on ps.service_id = request.service_id and ps.is_active
  join public.providers p
    on p.id = ps.provider_id and p.onboarding_status = 'completed'
  left join lateral (
    select pp.price_cents, pp.currency
    from public.provider_service_prices pp
    where pp.provider_service_id = ps.id and pp.is_active
    order by pp.price_cents asc
    limit 1
  ) cheapest on true
  where
    -- A request without a city matches everywhere, exactly as before.
    request.city is null
    or trim(request.city) = ''
    or lower(trim(p.city)) = lower(trim(request.city))
  order by
    (p.verification_status = 'verified') desc,
    cheapest.price_cents asc nulls last;
$$;

comment on function public.find_providers_for_request is
  'Providers for one of the caller''s own requests. Same public fields as '
  'find_providers_for_service, plus whether this request already reached them.';

revoke execute on function public.find_providers_for_request(uuid)
  from public, anon;
grant execute on function public.find_providers_for_request(uuid)
  to authenticated;

-- 4. Handing the request over ----------------------------------------------

create function public.send_request_to_provider(
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
begin
  -- The request must be the caller's. Anything else is not a permission
  -- question the app may answer.
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

  -- And the provider must actually offer it. Checked here rather than in
  -- the app, so a tampered client cannot invent a match.
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

  -- Sending twice is not an error; the customer just sees it stays sent.
  insert into public.request_contacts (request_id, provider_id)
  values (target_request_id, target_provider_id)
  on conflict (request_id, provider_id) do update
    set request_id = excluded.request_id
  returning id into contact_id;

  return contact_id;
end;
$$;

comment on function public.send_request_to_provider is
  'Creates the contact after checking ownership and that the provider really '
  'offers the requested service. The only writer of request_contacts.';

revoke execute on function public.send_request_to_provider(uuid, uuid)
  from public, anon;
grant execute on function public.send_request_to_provider(uuid, uuid)
  to authenticated;

-- 5. What a provider has received ------------------------------------------

create function public.requests_for_me()
returns table (
  contact_id uuid,
  request_id uuid,
  status public.request_contact_status,
  sent_at timestamptz,
  description text,
  service_name text,
  service_name_en text,
  city text,
  postal_code text,
  timing public.request_timing,
  preferred_date date,
  customer_name text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    c.id,
    r.id,
    c.status,
    c.created_at,
    r.original_description,
    s.name,
    s.name_en,
    r.city,
    r.postal_code,
    r.timing,
    r.preferred_date,
    -- The name the customer chose to show. Not their email, and not their
    -- user id: a provider has no use for either.
    nullif(prof.display_name, '')
  from public.request_contacts c
  join public.providers p
    on p.id = c.provider_id and p.user_id = (select auth.uid())
  join public.service_requests r on r.id = c.request_id
  left join public.services s on s.id = r.service_id
  left join public.profiles prof on prof.id = r.customer_id
  order by c.created_at desc;
$$;

comment on function public.requests_for_me is
  'Requests handed to the caller''s own provider profile. The return type is '
  'the whole contract: customer_id and the AI columns are not in it.';

revoke execute on function public.requests_for_me() from public, anon;
grant execute on function public.requests_for_me() to authenticated;
