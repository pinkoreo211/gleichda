-- Provider profiles, the services they offer, and their documents.
--
-- Security model:
-- * A provider sees and edits only their own rows. Provider A can never read
--   or change Provider B's profile, services or documents.
-- * verification_status is NOT writable by any client. A provider cannot
--   mark themselves verified; only the team can, in the dashboard. The app
--   must therefore never show "verified" unless this column says so.
-- * The central catalog stays read-only for providers: they pick from
--   `services`, they cannot add to it or change it.

-- Types ---------------------------------------------------------------------

create type public.provider_kind as enum ('self_employed', 'company');

-- Where the provider is in the onboarding, so closing the app and coming
-- back later resumes at the right step instead of starting over.
create type public.provider_onboarding_status as enum (
  'started',
  'profile_incomplete',
  'services_selected',
  'verification_pending',
  'completed'
);

create type public.provider_verification_status as enum (
  'unverified',
  'pending',
  'verified',
  'rejected'
);

-- Which documents are needed depends on the category and service, and is
-- decided per service later. This only names the kinds that can exist.
create type public.provider_document_type as enum (
  'identity',
  'business_registration',
  'trade_license',
  'qualification',
  'insurance',
  'other'
);

create type public.provider_document_status as enum (
  'uploaded',
  'in_review',
  'accepted',
  'rejected'
);

-- Tables --------------------------------------------------------------------

create table public.providers (
  id uuid primary key default gen_random_uuid(),
  -- One provider profile per account. Defaults to the caller and is not
  -- grantable, so a profile cannot be created in someone else's name.
  user_id uuid not null unique default auth.uid()
    references auth.users (id) on delete cascade,

  first_name text check (char_length(first_name) <= 80),
  last_name text check (char_length(last_name) <= 80),
  -- What customers will see. Falls back to the first name in the app.
  display_name text check (char_length(display_name) <= 120),

  provider_kind public.provider_kind,
  business_name text check (char_length(business_name) <= 160),

  phone text check (char_length(phone) <= 40),
  profile_image_url text,
  description text check (char_length(description) <= 2000),

  -- Service area. Plain text for now; real coordinates arrive with maps.
  city text check (char_length(city) <= 120),
  postal_code text check (char_length(postal_code) <= 12),
  address text check (char_length(address) <= 200),
  service_radius_km integer check (service_radius_km between 1 and 200),

  onboarding_status public.provider_onboarding_status not null
    default 'started',

  -- Set by the team only. See the grants below: no client can write it.
  verification_status public.provider_verification_status not null
    default 'unverified',

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.providers.verification_status is
  'Team-controlled. Never granted to clients; the app must not infer it.';

-- The services a provider offers, chosen from the central catalog.
create table public.provider_services (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null
    references public.providers (id) on delete cascade,
  service_id uuid not null
    references public.services (id) on delete restrict,

  -- The provider's own price for this service, in whole cents. Null means
  -- "not set yet" -- the app then falls back to the catalog's example price
  -- or says the price is on request.
  price_cents integer check (price_cents >= 0),
  minimum_price_cents integer check (minimum_price_cents >= 0),
  provider_description text check (char_length(provider_description) <= 1000),

  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- A provider offers each service once.
  unique (provider_id, service_id)
);

create table public.provider_documents (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null
    references public.providers (id) on delete cascade,
  document_type public.provider_document_type not null,
  -- Path in storage. Null until file upload exists.
  file_path text,
  status public.provider_document_status not null default 'uploaded',
  note text check (char_length(note) <= 500),
  uploaded_at timestamptz not null default now(),
  -- Set by the team when a document has actually been looked at.
  reviewed_at timestamptz
);

comment on table public.provider_documents is
  'Prepared for verification. Which documents a service requires is decided '
  'per service later, not assumed to be the same for all.';

create index providers_verification_idx
  on public.providers (verification_status);
create index provider_services_provider_idx
  on public.provider_services (provider_id) where is_active;
create index provider_services_service_idx
  on public.provider_services (service_id) where is_active;
create index provider_documents_provider_idx
  on public.provider_documents (provider_id);

create trigger providers_set_updated_at
  before update on public.providers
  for each row execute function public.set_updated_at();
create trigger provider_services_set_updated_at
  before update on public.provider_services
  for each row execute function public.set_updated_at();

-- Access ----------------------------------------------------------------------

alter table public.providers enable row level security;
alter table public.provider_services enable row level security;
alter table public.provider_documents enable row level security;

revoke all on public.providers from anon, authenticated;
revoke all on public.provider_services from anon, authenticated;
revoke all on public.provider_documents from anon, authenticated;

grant select on public.providers to authenticated;
grant select on public.provider_services to authenticated;
grant select on public.provider_documents to authenticated;

-- Column-level grants: everything a provider fills in during onboarding,
-- and deliberately NOT verification_status, user_id or the timestamps.
grant insert (
  first_name, last_name, display_name,
  provider_kind, business_name,
  phone, profile_image_url, description,
  city, postal_code, address, service_radius_km,
  onboarding_status
) on public.providers to authenticated;

grant update (
  first_name, last_name, display_name,
  provider_kind, business_name,
  phone, profile_image_url, description,
  city, postal_code, address, service_radius_km,
  onboarding_status
) on public.providers to authenticated;

grant insert (provider_id, service_id, price_cents, minimum_price_cents,
              provider_description, is_active)
  on public.provider_services to authenticated;
grant update (price_cents, minimum_price_cents, provider_description,
              is_active)
  on public.provider_services to authenticated;
grant delete on public.provider_services to authenticated;

grant insert (provider_id, document_type, file_path, note)
  on public.provider_documents to authenticated;

create policy "Providers read their own profile"
  on public.providers for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Providers create their own profile"
  on public.providers for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Providers change their own profile"
  on public.providers for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- The subqueries below are themselves subject to the policies above, so a
-- row only matches when the provider row really belongs to the caller.
create policy "Providers read their own services"
  on public.provider_services for select
  to authenticated
  using (
    exists (
      select 1 from public.providers p
      where p.id = provider_id and p.user_id = (select auth.uid())
    )
  );

create policy "Providers add their own services"
  on public.provider_services for insert
  to authenticated
  with check (
    exists (
      select 1 from public.providers p
      where p.id = provider_id and p.user_id = (select auth.uid())
    )
  );

create policy "Providers change their own services"
  on public.provider_services for update
  to authenticated
  using (
    exists (
      select 1 from public.providers p
      where p.id = provider_id and p.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.providers p
      where p.id = provider_id and p.user_id = (select auth.uid())
    )
  );

create policy "Providers remove their own services"
  on public.provider_services for delete
  to authenticated
  using (
    exists (
      select 1 from public.providers p
      where p.id = provider_id and p.user_id = (select auth.uid())
    )
  );

create policy "Providers read their own documents"
  on public.provider_documents for select
  to authenticated
  using (
    exists (
      select 1 from public.providers p
      where p.id = provider_id and p.user_id = (select auth.uid())
    )
  );

create policy "Providers add their own documents"
  on public.provider_documents for insert
  to authenticated
  with check (
    exists (
      select 1 from public.providers p
      where p.id = provider_id and p.user_id = (select auth.uid())
    )
  );

-- No update or delete policy on documents: once handed in, only the team
-- touches them.
