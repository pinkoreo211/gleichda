-- Booking a verified provider at a listed price.
--
-- Nothing new is invented here. A booking is still a `service_requests` row
-- and a `request_contacts` row -- the same two tables the whole status flow,
-- the chat and the reviews already hang off. What was missing is what the
-- customer chose: where the work is, which of the provider's price options
-- they picked, and when they would like it.
--
-- Three rules this file exists to hold:
--
--   * The price is never sent by the phone. The client names a price option
--     and the server reads the amount from that row. A tampered app can
--     pick a different option, which is a choice, not a discount.
--   * The price option has to belong to that provider's offering of that
--     service. Otherwise a customer could point at somebody else's cheap
--     option and book it.
--   * `requested_at` is a wish, not an appointment. Availability is not
--     modelled yet, so the booking says "the customer would like this" and
--     the existing `scheduled_at` still records what the two agreed.

-- Where the work is ---------------------------------------------------------

alter table public.service_requests
  add column address text check (char_length(address) <= 200),
  -- Prepared, not used: there is no geocoding yet, so every booking stores
  -- null here. Matching compares towns. Showing a distance computed from
  -- nothing would be worse than showing none.
  add column latitude numeric(9, 6) check (latitude between -90 and 90),
  add column longitude numeric(9, 6) check (longitude between -180 and 180);

comment on column public.service_requests.latitude is
  'Reserved for real distance matching. Null everywhere until geocoding '
  'exists; the app must not derive a distance from it before then.';

grant insert (address, latitude, longitude) on public.service_requests
  to authenticated;
grant update (address, latitude, longitude) on public.service_requests
  to authenticated;

-- What was booked -----------------------------------------------------------

alter table public.request_contacts
  -- Which of the provider's own options the customer picked. Kept as a
  -- reference so the team can see what was offered, and nulled rather than
  -- deleted if the provider later removes the option.
  add column provider_service_price_id uuid
    references public.provider_service_prices (id) on delete set null,
  -- Copied at booking time. A provider raising their price afterwards does
  -- not change what was agreed.
  add column price_cents integer check (price_cents >= 0),
  add column currency char(3),
  -- What the customer asked for. Not a confirmed appointment: that is
  -- `scheduled_at`, which both sides arrive at through the status flow.
  add column requested_at timestamptz;

comment on column public.request_contacts.price_cents is
  'The agreed price, copied from the chosen option by create_booking(). '
  'No client can write this column.';

comment on column public.request_contacts.requested_at is
  'The time the customer would like. A wish -- scheduled_at is the '
  'appointment.';

-- No grants added: `request_contacts` still has no insert or update grant
-- at all, so these columns are writable only by the functions below.

-- Which service does this sound like? ----------------------------------------

-- The catalog already carries `ai_keywords` per service, filled in with the
-- words people actually use. This matches against them.
--
-- It is deliberately dumb: no stemming, no ranking model, no invented
-- confidence. When it finds nothing the app asks the customer instead of
-- guessing, which is the honest failure. Real understanding replaces the
-- body of this function later -- the app calls the same name and keeps
-- working.
create function public.suggest_services_for_text(query text)
returns table (
  service_id uuid,
  slug text,
  name text,
  name_en text,
  short_description text,
  short_description_en text,
  service_type public.service_type,
  category_slug text,
  category_name text,
  score integer
)
language sql
stable
security definer
set search_path = ''
as $$
  with needle as (
    select lower(btrim(coalesce(query, ''))) as text
  ),
  scored as (
    select
      s.id,
      s.slug,
      s.name,
      s.name_en,
      s.short_description,
      s.short_description_en,
      s.service_type,
      c.slug as category_slug,
      c.name as category_name,
      -- A keyword found in what the customer wrote counts for more than
      -- the service name appearing, because the keywords were chosen for
      -- exactly this.
      (
        case when exists (
          select 1 from unnest(s.ai_keywords) as k
          where length(k) >= 3 and (select text from needle) like '%' || lower(k) || '%'
        ) then 3 else 0 end
        +
        case when (select text from needle) like '%' || lower(s.name) || '%'
          then 2 else 0 end
      ) as score
    from public.services s
    join public.service_categories c on c.id = s.category_id
    where s.is_active and c.is_active
  )
  select
    scored.id, scored.slug, scored.name, scored.name_en,
    scored.short_description, scored.short_description_en,
    scored.service_type, scored.category_slug, scored.category_name,
    scored.score
  from scored, needle
  where needle.text <> '' and scored.score > 0
  order by scored.score desc, scored.name
  limit 5;
$$;

comment on function public.suggest_services_for_text is
  'Keyword match against the catalog. Returns nothing rather than a weak '
  'guess; the app then asks the customer which service they mean.';

revoke execute on function public.suggest_services_for_text(text)
  from public, anon;
grant execute on function public.suggest_services_for_text(text)
  to authenticated;

-- Who can actually be booked -------------------------------------------------

-- Stricter than find_providers_for_request() on purpose. That list answers
-- "who could do this", and shows unverified providers too, marked as such.
-- This one answers "who can I book right now at a listed price", and for
-- that the team has to have seen the papers.
create function public.find_bookable_providers(
  target_service_id uuid,
  requested_city text default null
)
returns table (
  provider_id uuid,
  display_name text,
  description text,
  city text,
  verification_status public.provider_verification_status,
  lowest_price_cents integer,
  currency char(3),
  rating_average numeric,
  rating_count integer
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
    cheapest.currency,
    rated.average,
    coalesce(rated.total, 0)
  from public.provider_services ps
  join public.providers p
    on p.id = ps.provider_id
   and p.onboarding_status = 'completed'
   and p.verification_status = 'verified'
   -- Booking yourself is not a job.
   and p.user_id <> (select auth.uid())
  left join lateral (
    select pp.price_cents, pp.currency
    from public.provider_service_prices pp
    where pp.provider_service_id = ps.id and pp.is_active
    order by pp.price_cents asc
    limit 1
  ) cheapest on true
  left join lateral (
    select avg(v.rating)::numeric(2, 1) as average, count(*)::integer as total
    from public.reviews v
    where v.provider_id = p.id
  ) rated on true
  where ps.service_id = target_service_id
    and ps.is_active
    and (
      requested_city is null
      or btrim(requested_city) = ''
      or lower(btrim(p.city)) = lower(btrim(requested_city))
    )
    -- A provider with no price for this service cannot be booked at a
    -- price. They are still reachable through the older request flow.
    and cheapest.price_cents is not null
  order by cheapest.price_cents asc, p.display_name;
$$;

comment on function public.find_bookable_providers is
  'Verified providers with a listed price for one service. The return type '
  'is the whole contract: no phone number, no address, no documents.';

revoke execute on function public.find_bookable_providers(uuid, text)
  from public, anon;
grant execute on function public.find_bookable_providers(uuid, text)
  to authenticated;

-- One provider's offer for one service ---------------------------------------

create function public.provider_offer(
  target_provider_id uuid,
  target_service_id uuid
)
returns table (
  provider_id uuid,
  display_name text,
  description text,
  city text,
  profile_image_url text,
  verification_status public.provider_verification_status,
  rating_average numeric,
  rating_count integer,
  price_id uuid,
  price_name text,
  price_description text,
  price_cents integer,
  currency char(3),
  unit text,
  duration_minutes integer
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
    p.profile_image_url,
    p.verification_status,
    rated.average,
    coalesce(rated.total, 0),
    pp.id,
    pp.name,
    pp.description,
    pp.price_cents,
    pp.currency,
    pp.unit,
    pp.duration_minutes
  from public.provider_services ps
  join public.providers p
    on p.id = ps.provider_id
   and p.onboarding_status = 'completed'
   and p.verification_status = 'verified'
   and p.user_id <> (select auth.uid())
  join public.provider_service_prices pp
    on pp.provider_service_id = ps.id and pp.is_active
  left join lateral (
    select avg(v.rating)::numeric(2, 1) as average, count(*)::integer as total
    from public.reviews v
    where v.provider_id = p.id
  ) rated on true
  where ps.provider_id = target_provider_id
    and ps.service_id = target_service_id
    and ps.is_active
  order by pp.sort_order, pp.price_cents;
$$;

comment on function public.provider_offer is
  'One row per price option, repeating the provider''s public details. '
  'Phone, address and documents are not in the return type.';

revoke execute on function public.provider_offer(uuid, uuid)
  from public, anon;
grant execute on function public.provider_offer(uuid, uuid)
  to authenticated;

-- Making the booking ----------------------------------------------------------

-- Creates the request and hands it to the provider in one step, so an
-- abandoned flow leaves nothing behind.
create function public.create_booking(
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

  -- The price option decides everything: it names the offering, which names
  -- the provider and the service. Checking all three against each other
  -- here is what stops a customer pointing at a cheaper option belonging to
  -- somebody else.
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
    -- Only a provider the team has checked can be booked at a fixed price.
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

  return query select new_request_id, new_contact_id;
end;
$$;

comment on function public.create_booking is
  'The only way a booking is written. The amount comes from the chosen '
  'price row, never from the caller.';

revoke execute on function public.create_booking(
  text, uuid, uuid, uuid, timestamptz, text, text, text
) from public, anon;
grant execute on function public.create_booking(
  text, uuid, uuid, uuid, timestamptz, text, text, text
) to authenticated;

-- Both sides see what was booked ------------------------------------------------

-- Same rows as before, with the price and the wanted time added. Recreated
-- rather than altered because the return type changes.
drop function public.my_jobs();

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
  address text,
  price_cents integer,
  currency char(3),
  requested_at timestamptz,
  scheduled_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  customer_confirmed_at timestamptz,
  updated_at timestamptz,
  my_rating integer,
  my_comment text
)
language sql
stable
security definer
set search_path = ''
as $$
  with mine as (
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
    -- The street only reaches the two people on this job, and only once
    -- the provider accepted it -- which is what being in this list means.
    r.address,
    m.price_cents,
    m.currency,
    m.requested_at,
    m.scheduled_at,
    m.started_at,
    m.completed_at,
    m.customer_confirmed_at,
    m.updated_at,
    v.rating,
    v.comment
  from mine m
  join public.providers p on p.id = m.provider_id
  join public.service_requests r on r.id = m.request_id
  left join public.profiles prof on prof.id = m.customer_id
  left join public.services s on s.id = r.service_id
  left join public.reviews v on v.contact_id = m.id
  order by m.updated_at desc;
$$;

revoke execute on function public.my_jobs() from public, anon;
grant execute on function public.my_jobs() to authenticated;

-- And the provider sees the price and the wanted time before answering:
-- accepting a booking without knowing either would be answering blind.
drop function public.requests_for_me();

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
  customer_name text,
  price_cents integer,
  currency char(3),
  requested_at timestamptz
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
    nullif(prof.display_name, ''),
    c.price_cents,
    c.currency,
    c.requested_at
  from public.request_contacts c
  join public.providers p
    on p.id = c.provider_id and p.user_id = (select auth.uid())
  join public.service_requests r on r.id = c.request_id
  left join public.services s on s.id = r.service_id
  left join public.profiles prof on prof.id = r.customer_id
  order by c.created_at desc;
$$;

comment on function public.requests_for_me is
  'Requests handed to the caller''s own provider profile. The street '
  'address is deliberately not in the return type: it is in my_jobs(), '
  'which only lists jobs the provider already accepted.';

revoke execute on function public.requests_for_me() from public, anon;
grant execute on function public.requests_for_me() to authenticated;
