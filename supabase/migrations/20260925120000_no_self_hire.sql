-- Nobody hires themselves.
--
-- An account can be a customer and a provider at once, which is right: the
-- same person may offer furniture assembly and need a cleaner. What was
-- missing is that nothing stopped them sending their own request to their
-- own provider profile -- and the app happily opened a chat between one
-- person and themselves.
--
-- Three functions are replaced, none of them dropped, and their return
-- types are unchanged, so nothing that reads them has to change:
--
-- * send_request_to_provider refuses the case outright. That is the rule.
-- * the two matching functions leave the caller's own provider profile out
--   of the results, so the button is never offered in the first place.
--
-- Existing rows are left exactly as they are. A conversation somebody
-- already has with themselves keeps working; this only stops new ones.

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

  -- Hiring yourself is not a job, it is a to-do.
  if exists (
    select 1 from public.providers p
    where p.id = target_provider_id and p.user_id = (select auth.uid())
  ) then
    raise exception 'Cannot send a request to your own profile'
      using errcode = '22023';
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

-- Matching: same as before, minus the caller's own profile ------------------

create or replace function public.find_providers_for_request(
  target_request_id uuid
)
returns table (
  provider_id uuid,
  display_name text,
  description text,
  city text,
  verification_status public.provider_verification_status,
  lowest_price_cents integer,
  currency char(3),
  contact_status public.request_contact_status
)
language sql
stable
security definer
set search_path = ''
as $$
  with request as (
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
    contact.status
  from request
  join public.provider_services ps
    on ps.service_id = request.service_id and ps.is_active
  join public.providers p
    on p.id = ps.provider_id
   and p.onboarding_status = 'completed'
   -- Not yourself.
   and p.user_id <> (select auth.uid())
  left join lateral (
    select pp.price_cents, pp.currency
    from public.provider_service_prices pp
    where pp.provider_service_id = ps.id and pp.is_active
    order by pp.price_cents asc
    limit 1
  ) cheapest on true
  left join public.request_contacts contact
    on contact.request_id = request.id and contact.provider_id = p.id
  where
    request.city is null
    or trim(request.city) = ''
    or lower(trim(p.city)) = lower(trim(request.city))
  order by
    (p.verification_status = 'verified') desc,
    cheapest.price_cents asc nulls last;
$$;

create or replace function public.find_providers_for_service(
  requested_service_id uuid,
  requested_city text default null
)
returns table (
  provider_id uuid,
  display_name text,
  description text,
  city text,
  verification_status public.provider_verification_status,
  lowest_price_cents integer,
  currency char(3)
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    p.id,
    coalesce(nullif(p.display_name, ''), nullif(p.business_name, ''),
             nullif(p.first_name, '')),
    p.description,
    p.city,
    p.verification_status,
    cheapest.price_cents,
    cheapest.currency
  from public.providers p
  join public.provider_services ps
    on ps.provider_id = p.id and ps.is_active
  left join lateral (
    select pp.price_cents, pp.currency
    from public.provider_service_prices pp
    where pp.provider_service_id = ps.id and pp.is_active
    order by pp.price_cents asc
    limit 1
  ) cheapest on true
  where ps.service_id = requested_service_id
    and p.onboarding_status = 'completed'
    -- Browsing the catalog, a provider does not need to be offered
    -- themselves either.
    and p.user_id <> (select auth.uid())
    and (
      requested_city is null
      or lower(trim(p.city)) = lower(trim(requested_city))
    )
  order by
    (p.verification_status = 'verified') desc,
    cheapest.price_cents asc nulls last;
$$;
