-- A provider answers a request: accepted or declined.
--
-- No new column. `request_contacts.status` was created with the contact
-- itself and already holds exactly these three states: 'sent' is the open
-- one, 'accepted' and 'declined' are the answers. Adding a second status
-- column would mean two sources of truth for one fact.
--
-- The rules, and where each one is enforced:
--
-- * Only the provider the request was sent to may answer it.
--   -> The update below matches provider_id against the caller's own
--      provider profile. No other provider's row can be reached, because
--      no other row satisfies that condition.
-- * An answered request cannot be answered again.
--   -> The update only matches rows that are still 'sent'. A second answer
--      matches nothing and is reported as such, rather than silently
--      overwriting the first one.
-- * The customer may see the status of their own request.
--   -> The existing select policy "Customers see who they contacted"
--      already covers it; nothing about it changes here.
--
-- request_contacts still has no update grant for clients. The function
-- below is security definer and is the only writer, so the checks above
-- cannot be skipped by talking to the table directly.

-- 1. Answering ---------------------------------------------------------------

create function public.respond_to_request(
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
begin
  -- 'sent' is the state a request arrives in, not an answer to it.
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
    return updated_status;
  end if;

  -- Nothing was updated. Tell the two cases apart, so the app can say
  -- "already answered" instead of a blank failure.
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

comment on function public.respond_to_request is
  'The only writer of request_contacts.status. Answers once, and only for '
  'the provider the request was actually sent to.';

revoke execute on function
  public.respond_to_request(uuid, public.request_contact_status)
  from public, anon;
grant execute on function
  public.respond_to_request(uuid, public.request_contact_status)
  to authenticated;

-- 2. The customer sees the answer --------------------------------------------

-- Until now the matching result only said whether a provider had been
-- contacted. A yes/no cannot express "they said no", so it becomes the
-- status itself: null when never contacted, otherwise what the provider
-- answered. Dropped and recreated because the return type changes.
drop function public.find_providers_for_request(uuid);

create function public.find_providers_for_request(target_request_id uuid)
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
    contact.status
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
  left join public.request_contacts contact
    on contact.request_id = request.id and contact.provider_id = p.id
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
  'Providers for one of the caller''s own requests, plus what each of them '
  'answered. Null status means this request never reached them.';

revoke execute on function public.find_providers_for_request(uuid)
  from public, anon;
grant execute on function public.find_providers_for_request(uuid)
  to authenticated;
