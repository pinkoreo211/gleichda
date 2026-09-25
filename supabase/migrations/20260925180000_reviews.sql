-- What a customer thought of a finished job.
--
-- Keyed to the job, not to a (job, customer) pair: `request_contacts` is
-- one row per request and provider, and a request has exactly one
-- customer. So one review per contact already says "each customer rates
-- each job once", with no second column that could disagree with the
-- first.
--
-- Two things are deliberately not public:
--
--   * Individual reviews. Reading them would say which customer hired
--     which provider, and the app has never shown that to strangers.
--     Everyone else sees the average and the count, through the matching
--     functions, which is what a person choosing a provider actually needs.
--   * Writing. `reviews` has no insert grant at all. The function below is
--     the only writer, and it checks that the caller is that job's
--     customer and that the job was actually confirmed -- a rating for
--     work nobody agreed was finished is not a rating.

create table public.reviews (
  id uuid primary key default gen_random_uuid(),

  -- The job. One review per job, which is the whole rule.
  contact_id uuid not null unique
    references public.request_contacts (id) on delete cascade,

  customer_id uuid not null references auth.users (id) on delete cascade,
  provider_id uuid not null
    references public.providers (id) on delete cascade,

  rating integer not null check (rating between 1 and 5),
  comment text check (char_length(comment) <= 2000),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.reviews is
  'One review per finished job. Written only by submit_review(), and only '
  'by the customer of that job.';

create index reviews_provider_idx on public.reviews (provider_id);
create index reviews_customer_idx on public.reviews (customer_id);

create trigger reviews_set_updated_at
  before update on public.reviews
  for each row execute function public.set_updated_at();

-- Access ---------------------------------------------------------------------

alter table public.reviews enable row level security;

revoke all on public.reviews from anon, authenticated;

-- Readable by the two people it concerns, and by nobody else. No insert,
-- update or delete grant exists: a review is written once, by the
-- function, and then it stands.
grant select on public.reviews to authenticated;

create policy "Customers read their own reviews"
  on public.reviews for select
  to authenticated
  using (customer_id = (select auth.uid()));

create policy "Providers read reviews about themselves"
  on public.reviews for select
  to authenticated
  using (
    exists (
      select 1 from public.providers p
      where p.id = provider_id and p.user_id = (select auth.uid())
    )
  );

-- Writing a review -------------------------------------------------------------

create function public.submit_review(
  target_contact_id uuid,
  new_rating integer,
  new_comment text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  job_customer_id uuid;
  job_provider_id uuid;
  job_status public.request_contact_status;
  review_id uuid;
begin
  if new_rating is null or new_rating < 1 or new_rating > 5 then
    raise exception 'A rating is one to five stars' using errcode = '22023';
  end if;

  select r.customer_id, c.provider_id, c.status
    into job_customer_id, job_provider_id, job_status
  from public.request_contacts c
  join public.service_requests r on r.id = c.request_id
  where c.id = target_contact_id;

  -- Somebody else's job is not findable, and a job that does not exist is
  -- not distinguishable from one that is not theirs.
  if not found or job_customer_id <> (select auth.uid()) then
    raise exception 'Job not found' using errcode = '42501';
  end if;

  -- Only a job both sides agreed was finished. Rating work that is still
  -- running, or that the customer never confirmed, would be a verdict
  -- nobody had the chance to earn.
  if job_status <> 'customer_confirmed' then
    raise exception 'Confirm the job first' using errcode = '22023';
  end if;

  insert into public.reviews (
    contact_id, customer_id, provider_id, rating, comment
  )
  values (
    target_contact_id,
    job_customer_id,
    job_provider_id,
    new_rating,
    nullif(btrim(coalesce(new_comment, '')), '')
  )
  on conflict (contact_id) do nothing
  returning id into review_id;

  if review_id is null then
    raise exception 'This job has already been reviewed'
      using errcode = '22023';
  end if;

  return review_id;
end;
$$;

comment on function public.submit_review is
  'The only writer of reviews. Checks that the caller is that job''s '
  'customer and that the job was confirmed, then writes it once.';

revoke execute on function public.submit_review(uuid, integer, text)
  from public, anon;
grant execute on function public.submit_review(uuid, integer, text)
  to authenticated;

-- Jobs now carry the customer's own verdict --------------------------------

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
    m.scheduled_at,
    m.started_at,
    m.completed_at,
    m.customer_confirmed_at,
    m.updated_at,
    -- Both sides see it: the customer wrote it, and the provider is the
    -- person it is about.
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

-- Matching shows the real average ---------------------------------------------

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
    p.description,
    p.city,
    p.verification_status,
    cheapest.price_cents,
    cheapest.currency,
    contact.status,
    -- Null when nobody has rated them. Never a default, and never a
    -- flattering one: an unrated provider is unrated, not five stars.
    rated.average,
    coalesce(rated.total, 0)
  from request
  join public.provider_services ps
    on ps.service_id = request.service_id and ps.is_active
  join public.providers p
    on p.id = ps.provider_id
   and p.onboarding_status = 'completed'
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

drop function public.find_providers_for_service(uuid, text);

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
