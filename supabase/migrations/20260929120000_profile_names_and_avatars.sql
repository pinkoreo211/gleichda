-- A name and a face for the person on the other side.
--
-- Until now a provider deciding whether to let someone into their home saw
-- the word "Kunde", and a customer choosing who to let into theirs saw a
-- name and nothing else. Both sides were talking to a placeholder.
--
-- One picture per account, in `profiles.avatar_url`. `providers` already
-- had `profile_image_url` from onboarding; it stays as something the team
-- could set, and wins where it is filled in, but the app writes the
-- account's own avatar. Two upload screens for one face would only mean
-- two faces that disagree.
--
-- Names stay split on purpose: `profiles.display_name` is the person, and
-- `providers.display_name` is the business. "Max Müller" and "Max
-- Montagen" are both true and belong in different places.

alter table public.profiles
  add column avatar_url text check (char_length(avatar_url) <= 500);

comment on column public.profiles.avatar_url is
  'Where this account''s picture lives in the avatars bucket. One per '
  'account; providers may override it with providers.profile_image_url.';

grant update (avatar_url) on public.profiles to authenticated;

-- Where the pictures live -----------------------------------------------------

-- Public on purpose, and this is the one place in the project where that
-- is true. A profile picture is shown to every customer browsing a
-- provider list; signing a URL for each of twenty faces would be a lot of
-- machinery for something people upload in order to be seen.
--
-- What that means in plain words: once uploaded, the picture is reachable
-- by anyone who has its address. The address contains a random name, so
-- it cannot be guessed or listed -- but it is not a secret either, and the
-- app says so where people choose their picture.
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Small, and images only. A profile picture that a phone has to download
-- on mobile data should not be a photograph at full resolution.
update storage.buckets
   set file_size_limit = 2097152,
       allowed_mime_types = array[
         'image/jpeg', 'image/png', 'image/heic', 'image/webp'
       ]
 where id = 'avatars';

-- Writing is still only your own folder, named after your account. Public
-- read does not mean public write.
create policy "People upload their own picture"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "People replace their own picture"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "People remove their own picture"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- Everywhere a person appears ---------------------------------------------------

-- The six functions below all gain the same thing: the picture that goes
-- with the name they already returned. Recreated rather than replaced
-- because the return type changes; nothing else about them moves.

-- 1. Jobs, seen from either side ------------------------------------------------

drop function public.my_jobs();

create function public.my_jobs()
returns table (
  contact_id uuid,
  request_id uuid,
  provider_id uuid,
  viewer_is_customer boolean,
  status public.request_contact_status,
  other_name text,
  other_avatar_url text,
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
    -- The provider's own picture wins if the team set one; otherwise the
    -- one they uploaded themselves.
    case
      when m.viewer_is_customer then
        coalesce(nullif(p.profile_image_url, ''), nullif(pprof.avatar_url, ''))
      else nullif(prof.avatar_url, '')
    end,
    s.name,
    s.name_en,
    r.original_description,
    r.city,
    r.postal_code,
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
  left join public.profiles pprof on pprof.id = p.user_id
  left join public.services s on s.id = r.service_id
  left join public.reviews v on v.contact_id = m.id
  order by m.updated_at desc;
$$;

revoke execute on function public.my_jobs() from public, anon;
grant execute on function public.my_jobs() to authenticated;

-- 2. Requests waiting for a provider ---------------------------------------------

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
  customer_avatar_url text,
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
    nullif(prof.avatar_url, ''),
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
  'Requests handed to the caller''s own provider profile. Name and picture '
  'only -- the street address stays in my_jobs(), which lists jobs the '
  'provider already accepted.';

revoke execute on function public.requests_for_me() from public, anon;
grant execute on function public.requests_for_me() to authenticated;

-- 3. The chat list ---------------------------------------------------------------

drop function public.my_conversations();

create function public.my_conversations()
returns table (
  conversation_id uuid,
  request_id uuid,
  provider_id uuid,
  viewer_is_customer boolean,
  other_name text,
  other_image_url text,
  service_name text,
  service_name_en text,
  last_message text,
  last_message_at timestamptz,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  with mine as (
    select c.*, (c.customer_id = (select auth.uid())) as viewer_is_customer
    from public.conversations c
    where c.customer_id = (select auth.uid())
       or exists (
         select 1 from public.providers p
         where p.id = c.provider_id and p.user_id = (select auth.uid())
       )
  )
  select
    m.id,
    m.request_id,
    m.provider_id,
    m.viewer_is_customer,
    case
      when m.viewer_is_customer then coalesce(
        nullif(p.display_name, ''),
        nullif(p.business_name, ''),
        nullif(p.first_name, '')
      )
      else nullif(prof.display_name, '')
    end,
    -- Was only ever filled for the provider. The customer has a face too.
    case
      when m.viewer_is_customer then
        coalesce(nullif(p.profile_image_url, ''), nullif(pprof.avatar_url, ''))
      else nullif(prof.avatar_url, '')
    end,
    s.name,
    s.name_en,
    last_message.message,
    last_message.created_at,
    m.updated_at
  from mine m
  join public.providers p on p.id = m.provider_id
  left join public.profiles prof on prof.id = m.customer_id
  left join public.profiles pprof on pprof.id = p.user_id
  left join public.service_requests r on r.id = m.request_id
  left join public.services s on s.id = r.service_id
  left join lateral (
    select msg.message, msg.created_at
    from public.messages msg
    where msg.conversation_id = m.id
    order by msg.created_at desc
    limit 1
  ) last_message on true
  order by coalesce(last_message.created_at, m.updated_at) desc;
$$;

revoke execute on function public.my_conversations() from public, anon;
grant execute on function public.my_conversations() to authenticated;

-- 4. Providers for a saved request -------------------------------------------------

drop function public.find_providers_for_request(uuid);

create function public.find_providers_for_request(target_request_id uuid)
returns table (
  provider_id uuid,
  display_name text,
  avatar_url text,
  description text,
  city text,
  verification_status public.provider_verification_status,
  lowest_price_cents integer,
  currency char(3),
  contact_status public.request_contact_status,
  rating_average numeric,
  rating_count integer
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
    coalesce(nullif(p.profile_image_url, ''), nullif(prof.avatar_url, '')),
    p.description,
    p.city,
    p.verification_status,
    cheapest.price_cents,
    cheapest.currency,
    contact.status,
    rated.average,
    coalesce(rated.total, 0)
  from request
  join public.provider_services ps
    on ps.service_id = request.service_id and ps.is_active
  join public.providers p
    on p.id = ps.provider_id
   and p.onboarding_status = 'completed'
   and p.user_id <> (select auth.uid())
  left join public.profiles prof on prof.id = p.user_id
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

revoke execute on function public.find_providers_for_request(uuid)
  from public, anon;
grant execute on function public.find_providers_for_request(uuid)
  to authenticated;

-- 5. Providers for a service browsed from the catalog --------------------------------

drop function public.find_providers_for_service(uuid, text);

create function public.find_providers_for_service(
  requested_service_id uuid,
  requested_city text default null
)
returns table (
  provider_id uuid,
  display_name text,
  avatar_url text,
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
    coalesce(nullif(p.profile_image_url, ''), nullif(prof.avatar_url, '')),
    p.description,
    p.city,
    p.verification_status,
    cheapest.price_cents,
    cheapest.currency,
    rated.average,
    coalesce(rated.total, 0)
  from public.providers p
  join public.provider_services ps
    on ps.provider_id = p.id and ps.is_active
  left join public.profiles prof on prof.id = p.user_id
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
  where ps.service_id = requested_service_id
    and p.onboarding_status = 'completed'
    and p.user_id <> (select auth.uid())
    and (
      requested_city is null
      or lower(trim(p.city)) = lower(trim(requested_city))
    )
  order by
    (p.verification_status = 'verified') desc,
    cheapest.price_cents asc nulls last;
$$;

revoke execute on function public.find_providers_for_service(uuid, text)
  from public, anon;
grant execute on function public.find_providers_for_service(uuid, text)
  to authenticated;

-- 6. Providers who can be booked ------------------------------------------------------

drop function public.find_bookable_providers(uuid, text);

create function public.find_bookable_providers(
  target_service_id uuid,
  requested_city text default null
)
returns table (
  provider_id uuid,
  display_name text,
  avatar_url text,
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
    coalesce(nullif(p.profile_image_url, ''), nullif(prof.avatar_url, '')),
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
   and p.user_id <> (select auth.uid())
  left join public.profiles prof on prof.id = p.user_id
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
    and cheapest.price_cents is not null
  order by cheapest.price_cents asc, p.display_name;
$$;

revoke execute on function public.find_bookable_providers(uuid, text)
  from public, anon;
grant execute on function public.find_bookable_providers(uuid, text)
  to authenticated;

-- 7. One provider's offer ----------------------------------------------------------

drop function public.provider_offer(uuid, uuid);

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
    coalesce(nullif(p.profile_image_url, ''), nullif(prof.avatar_url, '')),
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
  left join public.profiles prof on prof.id = p.user_id
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

revoke execute on function public.provider_offer(uuid, uuid)
  from public, anon;
grant execute on function public.provider_offer(uuid, uuid)
  to authenticated;
