-- Customer service requests.
--
-- Security model:
-- * Row level security: a customer only ever sees their own requests.
-- * The columns an AI step fills (detected service, price range, duration)
--   are NOT granted to clients. A phone therefore cannot write its own
--   price, even if the app were tampered with. Only a server-side function
--   with elevated rights will write them.
-- * customer_id defaults to auth.uid() and cannot be supplied by the client,
--   so a request can never be created in someone else's name.

-- Types ---------------------------------------------------------------------

-- The values match the Dart enum names exactly, so no translation layer is
-- needed between app and database.
create type public.service_category as enum (
  'handyman',
  'cleaning',
  'moving',
  'car',
  'pets',
  'beauty',
  'renovation',
  'other'
);

create type public.request_timing as enum (
  'asap',
  'today',
  'tomorrow',
  'onDate'
);

-- Table ---------------------------------------------------------------------

create table public.service_requests (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,

  -- What the customer typed, unchanged. Never narrowed down by the app.
  original_description text not null
    check (char_length(original_description) between 1 and 4000),

  -- Optional: the customer may pick one, or leave it to the AI.
  category public.service_category,

  timing public.request_timing not null default 'asap',

  -- Only meaningful when timing = 'onDate'.
  preferred_date date,

  location_label text check (char_length(location_label) <= 200),

  -- Written by the AI step later; always null until then, so the app never
  -- shows an invented price.
  detected_service text check (char_length(detected_service) <= 200),
  ai_confidence numeric(3, 2) check (ai_confidence between 0 and 1),
  estimated_price_min_cents integer check (estimated_price_min_cents >= 0),
  estimated_price_max_cents integer check (estimated_price_max_cents >= 0),
  estimated_duration_minutes integer check (estimated_duration_minutes > 0),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint service_requests_price_range_ordered check (
    estimated_price_min_cents is null
    or estimated_price_max_cents is null
    or estimated_price_max_cents >= estimated_price_min_cents
  )
);

comment on table public.service_requests is
  'One request per customer enquiry, in the customer''s own words.';

comment on column public.service_requests.original_description is
  'Exactly what the customer typed. Never overwritten by the AI step.';

-- Newest first, per customer: the query the app runs on every list.
create index service_requests_customer_created_idx
  on public.service_requests (customer_id, created_at desc);

-- Access: row level security + column-level grants ---------------------------

alter table public.service_requests enable row level security;

revoke all on public.service_requests from anon, authenticated;

grant select on public.service_requests to authenticated;

-- Only these columns may ever be written from a client. Everything else --
-- customer_id, the AI columns, the timestamps -- is out of reach.
grant insert (
  original_description,
  category,
  timing,
  preferred_date,
  location_label
) on public.service_requests to authenticated;

grant update (
  original_description,
  category,
  timing,
  preferred_date,
  location_label
) on public.service_requests to authenticated;

create policy "Customers can read their own requests"
  on public.service_requests for select
  to authenticated
  using ((select auth.uid()) = customer_id);

create policy "Customers can create their own requests"
  on public.service_requests for insert
  to authenticated
  with check ((select auth.uid()) = customer_id);

create policy "Customers can change their own requests"
  on public.service_requests for update
  to authenticated
  using ((select auth.uid()) = customer_id)
  with check ((select auth.uid()) = customer_id);

-- No delete policy on purpose: deleting is denied until the app offers it.

-- updated_at ------------------------------------------------------------------

-- Reuses the function created with the profiles migration.
create trigger service_requests_set_updated_at
  before update on public.service_requests
  for each row execute function public.set_updated_at();
