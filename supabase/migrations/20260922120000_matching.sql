-- Connecting a customer request to the providers who can do it.
--
-- Two separate things:
--
-- 1. A request may now name a concrete service, not just a category. The
--    customer already picks one when browsing the catalog; until now that
--    choice was thrown away. The AI step will fill it in for free text.
--
-- 2. A read-only door onto providers for matching.
--
-- On that second point, deliberately NOT done as a new row policy:
-- `providers` grants SELECT on every column, limited only by the row policy
-- "your own row". Adding a policy that also matches other providers' rows
-- would expose every granted column with it -- phone number, address,
-- postal code, surname. Row policies cannot distinguish columns.
--
-- So the existing policies stay exactly as they are, and this function is
-- the only door. It returns display name, description, city, verification
-- status and the cheapest active price. Nothing else can come out of it,
-- because nothing else is in its return type.

-- 1. Requests can name a service ------------------------------------------

alter table public.service_requests
  add column service_id uuid
    references public.services (id) on delete set null;

comment on column public.service_requests.service_id is
  'The catalog service this request is about, once known. Null while only '
  'free text exists; the AI step fills it in later.';

grant insert (service_id) on public.service_requests to authenticated;
grant update (service_id) on public.service_requests to authenticated;

create index service_requests_service_idx
  on public.service_requests (service_id) where service_id is not null;

-- 2. The matching query ----------------------------------------------------

create function public.find_providers_for_service(
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
    -- Whatever name the provider gave, in the order a customer would
    -- recognise. Never the surname on its own.
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
    -- Only providers who actually finished setting themselves up.
    and p.onboarding_status = 'completed'
    -- City is a plain match for now; real distance arrives with maps.
    and (
      requested_city is null
      or lower(trim(p.city)) = lower(trim(requested_city))
    )
  order by
    -- Verified first, then cheapest. No score, no weighting: a number
    -- invented from fields that are still empty would only look clever.
    (p.verification_status = 'verified') desc,
    cheapest.price_cents asc nulls last;
$$;

comment on function public.find_providers_for_service is
  'Public provider data for matching. The return type is the whole contract: '
  'phone, address, postal code and documents are not in it and cannot leak.';

revoke execute on function public.find_providers_for_service(uuid, text)
  from public, anon;
grant execute on function public.find_providers_for_service(uuid, text)
  to authenticated;
