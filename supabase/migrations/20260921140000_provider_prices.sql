-- A provider's own prices for the services they offer.
--
-- The central catalog stays untouched: a provider prices *their* offering,
-- never the catalog entry or its example prices.
--
-- Security model:
-- * A price hangs off a row in `provider_services`, which already belongs to
--   exactly one provider. That structure alone makes it impossible to price
--   a service the provider has not selected, or to price it for someone
--   else -- there is no provider_id here to get wrong.
-- * Provider A can neither read nor write Provider B's prices.
-- * Customers do not read these yet. The public, matched view comes with
--   discovery, together with the read policies it needs.

-- `provider_services` briefly carried a single price and a minimum. Neither
-- was ever written, and keeping them beside this table would mean two
-- places claiming to hold "the price". One fixed price is simply one option
-- below.
alter table public.provider_services drop column price_cents;
alter table public.provider_services drop column minimum_price_cents;

create table public.provider_service_prices (
  id uuid primary key default gen_random_uuid(),

  -- The provider's offering this price belongs to. Deleting the offering
  -- takes its prices with it.
  provider_service_id uuid not null
    references public.provider_services (id) on delete cascade,

  -- What the customer reads, e.g. "bis 50 m²" or "kleines Möbelstück".
  name text not null check (char_length(name) between 1 and 120),
  description text check (char_length(description) <= 500),

  -- Whole cents, never a decimal: 4999 is EUR 49,99.
  price_cents integer not null check (price_cents >= 0),
  currency char(3) not null default 'EUR',

  -- What the price refers to, e.g. "pro Auftrag" or "pro Stunde".
  unit text check (char_length(unit) <= 60),
  duration_minutes integer check (duration_minutes > 0),

  -- Deactivating keeps the history without offering it any more.
  is_active boolean not null default true,
  sort_order integer not null default 0,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.provider_service_prices is
  'One provider''s price options for one service they offer.';

create index provider_service_prices_offering_idx
  on public.provider_service_prices (provider_service_id, sort_order)
  where is_active;

create trigger provider_service_prices_set_updated_at
  before update on public.provider_service_prices
  for each row execute function public.set_updated_at();

-- Access ----------------------------------------------------------------------

alter table public.provider_service_prices enable row level security;

revoke all on public.provider_service_prices from anon, authenticated;

grant select on public.provider_service_prices to authenticated;
grant insert (provider_service_id, name, description, price_cents, currency,
              unit, duration_minutes, is_active, sort_order)
  on public.provider_service_prices to authenticated;
grant update (name, description, price_cents, currency, unit,
              duration_minutes, is_active, sort_order)
  on public.provider_service_prices to authenticated;
grant delete on public.provider_service_prices to authenticated;

-- Ownership runs through provider_services to providers. Those tables' own
-- policies apply inside this subquery, so it can only ever match a row that
-- really belongs to the caller.
create policy "Providers read their own prices"
  on public.provider_service_prices for select
  to authenticated
  using (
    exists (
      select 1
      from public.provider_services ps
      join public.providers p on p.id = ps.provider_id
      where ps.id = provider_service_id and p.user_id = (select auth.uid())
    )
  );

create policy "Providers add prices to their own offerings"
  on public.provider_service_prices for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.provider_services ps
      join public.providers p on p.id = ps.provider_id
      where ps.id = provider_service_id and p.user_id = (select auth.uid())
    )
  );

create policy "Providers change their own prices"
  on public.provider_service_prices for update
  to authenticated
  using (
    exists (
      select 1
      from public.provider_services ps
      join public.providers p on p.id = ps.provider_id
      where ps.id = provider_service_id and p.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.provider_services ps
      join public.providers p on p.id = ps.provider_id
      where ps.id = provider_service_id and p.user_id = (select auth.uid())
    )
  );

create policy "Providers remove their own prices"
  on public.provider_service_prices for delete
  to authenticated
  using (
    exists (
      select 1
      from public.provider_services ps
      join public.providers p on p.id = ps.provider_id
      where ps.id = provider_service_id and p.user_id = (select auth.uid())
    )
  );
