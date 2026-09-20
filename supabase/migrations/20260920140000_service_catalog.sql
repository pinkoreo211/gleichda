-- The service catalog: categories, services and their price options.
--
-- This is the backbone of the marketplace. Providers will pick the services
-- they offer from it, customers browse it, and the AI step maps free text
-- onto it. Adding a category or a service is an insert here -- never an app
-- release.
--
-- Security model:
-- * Everyone signed in may READ the active catalog.
-- * No client may write it: there are no insert/update/delete grants at all.
--   The catalog is maintained by the team in the dashboard, which bypasses
--   row level security. Admin tools never ship inside the mobile app.
--
-- Translations: `name` and the descriptions hold German, the launch market's
-- language; `*_en` holds English and falls back to German when empty. A
-- proper translation table is the right move once a third language arrives.

-- Types ---------------------------------------------------------------------

-- fixed_price: the customer can book a listed price directly (later).
-- quote:       the customer describes the job and receives offers.
create type public.service_type as enum ('fixed_price', 'quote');

-- Tables --------------------------------------------------------------------

create table public.service_categories (
  id uuid primary key default gen_random_uuid(),
  -- Stable key used by code and links; the display name may change freely.
  slug text not null unique check (slug ~ '^[a-z0-9-]+$'),
  name text not null check (char_length(name) between 1 and 80),
  name_en text check (char_length(name_en) <= 80),
  description text,
  description_en text,
  -- Icon key the app maps to a drawn icon, with a fallback for unknown keys,
  -- so a new category never ships a blank tile.
  icon text not null default 'other',
  image_url text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.service_categories is
  'Top level of the catalog. Order and visibility are data, not code.';

create table public.services (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null
    references public.service_categories (id) on delete restrict,
  slug text not null unique check (slug ~ '^[a-z0-9-]+$'),
  name text not null check (char_length(name) between 1 and 120),
  name_en text check (char_length(name_en) <= 120),
  short_description text check (char_length(short_description) <= 200),
  short_description_en text check (char_length(short_description_en) <= 200),
  description text,
  description_en text,
  service_type public.service_type not null default 'quote',
  -- Everyday words a customer might use. The AI step matches against these
  -- plus ai_description; they are not shown in the app.
  ai_keywords text[] not null default '{}',
  ai_description text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.services.ai_keywords is
  'Search and AI matching only. Never rendered.';

create table public.service_price_options (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null
    references public.services (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120),
  name_en text check (char_length(name_en) <= 120),
  description text,
  -- Money is always whole cents, never a decimal: 4999 = EUR 49,99.
  price_cents integer not null check (price_cents >= 0),
  currency char(3) not null default 'EUR',
  -- What the price refers to, e.g. 'pauschal' or 'pro Stunde'.
  unit text,
  duration_minutes integer check (duration_minutes > 0),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.service_price_options is
  'Example MVP prices, not final market prices.';

-- The three queries the app actually runs.
create index service_categories_active_order_idx
  on public.service_categories (sort_order, name) where is_active;
create index services_category_order_idx
  on public.services (category_id, sort_order, name) where is_active;
create index service_price_options_service_order_idx
  on public.service_price_options (service_id, sort_order) where is_active;

create trigger service_categories_set_updated_at
  before update on public.service_categories
  for each row execute function public.set_updated_at();
create trigger services_set_updated_at
  before update on public.services
  for each row execute function public.set_updated_at();
create trigger service_price_options_set_updated_at
  before update on public.service_price_options
  for each row execute function public.set_updated_at();

-- Access: read-only for every client ------------------------------------------

alter table public.service_categories enable row level security;
alter table public.services enable row level security;
alter table public.service_price_options enable row level security;

revoke all on public.service_categories from anon, authenticated;
revoke all on public.services from anon, authenticated;
revoke all on public.service_price_options from anon, authenticated;

-- Deliberately select only: no client can change the catalog.
grant select on public.service_categories to authenticated;
grant select on public.services to authenticated;
grant select on public.service_price_options to authenticated;

create policy "Anyone signed in can read active categories"
  on public.service_categories for select to authenticated using (is_active);

create policy "Anyone signed in can read active services"
  on public.services for select to authenticated using (is_active);

create policy "Anyone signed in can read active price options"
  on public.service_price_options for select to authenticated using (is_active);

-- Requests point at the catalog instead of a fixed list -----------------------

-- The old enum could only ever hold the eight values compiled into it, which
-- is exactly what the catalog replaces.
alter table public.service_requests
  add column category_id uuid
    references public.service_categories (id) on delete set null;

grant insert (category_id) on public.service_requests to authenticated;
grant update (category_id) on public.service_requests to authenticated;

-- Seed data ------------------------------------------------------------------
-- Realistic example data for Vienna. Prices are placeholders for the MVP.

insert into public.service_categories (slug, name, name_en, icon, sort_order)
values
  ('handyman',   'Handwerker',        'Handyman',           'handyman',   10),
  ('cleaning',   'Reinigung',         'Cleaning',           'cleaning',   20),
  ('moving',     'Umzug & Transport', 'Moving & transport', 'moving',     30),
  ('car',        'Auto',              'Car',                'car',        40),
  ('pets',       'Haustiere',         'Pets',               'pets',       50),
  ('beauty',     'Beauty',            'Beauty',             'beauty',     60),
  ('renovation', 'Renovierung',       'Renovation',         'renovation', 70),
  ('garden',     'Garten',            'Garden',             'garden',     80),
  ('other',      'Sonstiges',         'Other',              'other',      90);

-- Existing requests keep their category: the old enum values are the new
-- slugs, so they map one to one.
update public.service_requests r
set category_id = c.id
from public.service_categories c
where c.slug = r.category::text;

alter table public.service_requests drop column category;
drop type public.service_category;

insert into public.services (
  category_id, slug, name, name_en, short_description, short_description_en,
  service_type, ai_keywords, ai_description, sort_order
) values
  -- Handwerker
  ((select id from public.service_categories where slug = 'handyman'),
   'moebelmontage', 'Möbelmontage', 'Furniture assembly',
   'Kasten, Bett oder Regal fachgerecht aufbauen',
   'Wardrobes, beds and shelves assembled properly',
   'fixed_price',
   array['möbel','montage','aufbauen','zusammenbauen','kasten','schrank','bett','regal','ikea'],
   'Aufbau gelieferter Möbel in der Wohnung des Kunden.', 10),
  ((select id from public.service_categories where slug = 'handyman'),
   'lampenmontage', 'Lampenmontage', 'Light fitting',
   'Deckenlampen und Leuchten anschließen',
   'Ceiling lights and lamps connected',
   'fixed_price',
   array['lampe','leuchte','deckenlampe','luster','licht','anschließen','montieren'],
   'Montage und Anschluss von Lampen und Leuchten.', 20),
  ((select id from public.service_categories where slug = 'handyman'),
   'bilder-regale-montieren', 'Bilder & Regale montieren', 'Pictures & shelves',
   'Bilder, Spiegel und Regale sicher an die Wand',
   'Pictures, mirrors and shelves mounted securely',
   'fixed_price',
   array['bild','bilder','spiegel','regal','aufhängen','montieren','wand'],
   'Anbringen von Bildern, Spiegeln und Regalen an Wänden.', 30),
  ((select id from public.service_categories where slug = 'handyman'),
   'bohrarbeiten', 'Bohrarbeiten', 'Drilling',
   'Löcher bohren, auch in Beton und Fliesen',
   'Drilling, including concrete and tiles',
   'fixed_price',
   array['bohren','loch','löcher','dübel','beton','fliesen'],
   'Bohrarbeiten in Wänden, Beton oder Fliesen.', 40),
  ((select id from public.service_categories where slug = 'handyman'),
   'kleine-reparaturen', 'Kleine Reparaturen', 'Small repairs',
   'Tür klemmt, Griff locker, Silikon erneuern',
   'Sticking doors, loose handles, fresh sealant',
   'quote',
   array['reparatur','reparieren','kaputt','defekt','tür','griff','silikon','undicht','tropft'],
   'Kleine Reparaturen in der Wohnung, Umfang nach Besichtigung.', 50),

  -- Reinigung
  ((select id from public.service_categories where slug = 'cleaning'),
   'wohnungsreinigung', 'Wohnungsreinigung', 'Home cleaning',
   'Regelmäßige oder einmalige Reinigung der Wohnung',
   'One-off or recurring cleaning of your home',
   'fixed_price',
   array['putzen','reinigen','wohnung','haushalt','sauber','saubermachen','reinigung','putzfrau'],
   'Reinigung einer privaten Wohnung durch einen Dienstleister.', 10),
  ((select id from public.service_categories where slug = 'cleaning'),
   'tiefenreinigung', 'Tiefenreinigung', 'Deep cleaning',
   'Gründliche Reinigung inklusive Küche und Bad',
   'Thorough clean including kitchen and bathroom',
   'fixed_price',
   array['grundreinigung','tiefenreinigung','gründlich','intensiv','küche','bad','kalk'],
   'Intensive Grundreinigung einer Wohnung.', 20),
  ((select id from public.service_categories where slug = 'cleaning'),
   'fensterreinigung', 'Fensterreinigung', 'Window cleaning',
   'Fenster innen und außen, streifenfrei',
   'Windows inside and out, streak-free',
   'fixed_price',
   array['fenster','scheiben','glas','putzen','streifenfrei'],
   'Reinigung von Fenstern innen und außen.', 30),
  ((select id from public.service_categories where slug = 'cleaning'),
   'bueroreinigung', 'Büroreinigung', 'Office cleaning',
   'Regelmäßige Reinigung von Büroflächen',
   'Recurring cleaning of office space',
   'quote',
   array['büro','office','gewerbe','firma','geschäft','reinigung'],
   'Reinigung gewerblicher Büroflächen, meist wiederkehrend.', 40),
  ((select id from public.service_categories where slug = 'cleaning'),
   'umzugsreinigung', 'Umzugsreinigung', 'End of tenancy cleaning',
   'Übergabefertige Reinigung beim Auszug',
   'Handover-ready cleaning when you move out',
   'quote',
   array['auszug','übergabe','umzugsreinigung','endreinigung','ablöse','wohnungsübergabe'],
   'Endreinigung einer Wohnung zur Übergabe an den Vermieter.', 50),

  -- Umzug & Transport
  ((select id from public.service_categories where slug = 'moving'),
   'kleintransport', 'Kleintransport', 'Small transport',
   'Einzelne Stücke schnell von A nach B',
   'Single items moved quickly',
   'fixed_price',
   array['transport','liefern','abholen','fahren','kleintransport','übersiedeln'],
   'Transport einzelner Gegenstände innerhalb der Stadt.', 10),
  ((select id from public.service_categories where slug = 'moving'),
   'moebeltransport', 'Möbeltransport', 'Furniture transport',
   'Große Möbel sicher transportieren',
   'Large furniture transported safely',
   'quote',
   array['möbel','couch','sofa','kasten','transport','tragen','übersiedlung'],
   'Transport großer Möbelstücke, Umfang nach Anfrage.', 20),
  ((select id from public.service_categories where slug = 'moving'),
   'umzugshilfe', 'Umzugshilfe', 'Moving help',
   'Helfer für Ihren Umzug, stundenweise',
   'Helpers for your move, by the hour',
   'fixed_price',
   array['umzug','übersiedlung','helfer','tragen','packen','kartons'],
   'Helfer für einen Umzug, abgerechnet pro Stunde.', 30),
  ((select id from public.service_categories where slug = 'moving'),
   'moebel-tragen', 'Möbel tragen', 'Furniture carrying',
   'Tragen und Umstellen innerhalb des Hauses',
   'Carrying and rearranging inside the building',
   'fixed_price',
   array['tragen','heben','umstellen','schleppen','stock','treppe'],
   'Tragen und Umstellen von Möbeln innerhalb eines Gebäudes.', 40),

  -- Auto
  ((select id from public.service_categories where slug = 'car'),
   'mobile-autoreinigung', 'Mobile Autoreinigung', 'Mobile car cleaning',
   'Komplette Aufbereitung vor Ort',
   'Full valet at your address',
   'fixed_price',
   array['auto','wagen','putzen','waschen','reinigen','aufbereitung','pflege'],
   'Vollständige Innen- und Außenaufbereitung eines Fahrzeugs beim Kunden.', 10),
  ((select id from public.service_categories where slug = 'car'),
   'auto-innenreinigung', 'Innenreinigung', 'Interior cleaning',
   'Saugen, Polster und Armaturen',
   'Vacuuming, upholstery and dashboard',
   'fixed_price',
   array['auto','innen','saugen','polster','armaturen','innenraum'],
   'Reinigung des Fahrzeuginnenraums.', 20),
  ((select id from public.service_categories where slug = 'car'),
   'auto-aussenreinigung', 'Außenreinigung', 'Exterior cleaning',
   'Wäsche, Felgen und Scheiben',
   'Wash, wheels and windows',
   'fixed_price',
   array['auto','außen','waschen','lack','felgen','scheiben'],
   'Reinigung der Fahrzeugaußenseite.', 30),
  ((select id from public.service_categories where slug = 'car'),
   'auto-innen-aussenreinigung', 'Innen- & Außenreinigung', 'Interior & exterior',
   'Innen und außen in einem Termin',
   'Inside and out in one appointment',
   'fixed_price',
   array['auto','komplett','innen','außen','rundum'],
   'Kombinierte Innen- und Außenreinigung eines Fahrzeugs.', 40),

  -- Haustiere
  ((select id from public.service_categories where slug = 'pets'),
   'hundespaziergang', 'Hundespaziergang', 'Dog walking',
   'Eine Runde für Ihren Hund, wenn Sie keine Zeit haben',
   'A walk for your dog when you are short on time',
   'fixed_price',
   array['hund','gassi','spazieren','ausführen','runde'],
   'Ausführen eines Hundes durch einen Dienstleister.', 10),
  ((select id from public.service_categories where slug = 'pets'),
   'hundebetreuung', 'Hundebetreuung', 'Dog sitting',
   'Betreuung über den Tag',
   'Care during the day',
   'fixed_price',
   array['hund','betreuung','aufpassen','hundesitter','tagesbetreuung'],
   'Betreuung eines Hundes über mehrere Stunden.', 20),
  ((select id from public.service_categories where slug = 'pets'),
   'katzenbetreuung', 'Katzenbetreuung', 'Cat sitting',
   'Füttern und Nachschauen im Urlaub',
   'Feeding and checking in while you are away',
   'fixed_price',
   array['katze','füttern','urlaub','katzensitter','betreuung'],
   'Versorgung einer Katze zu Hause, meist während einer Abwesenheit.', 30),
  ((select id from public.service_categories where slug = 'pets'),
   'tiersitting', 'Tiersitting', 'Pet sitting',
   'Betreuung anderer Haustiere',
   'Care for other pets',
   'quote',
   array['tier','haustier','sitting','betreuung','kaninchen','vogel','nager'],
   'Betreuung von Haustieren abseits von Hund und Katze.', 40),

  -- Beauty
  ((select id from public.service_categories where slug = 'beauty'),
   'mobile-manikuere', 'Mobile Maniküre', 'Mobile manicure',
   'Nagelpflege bei Ihnen zu Hause',
   'Nail care at your home',
   'fixed_price',
   array['nägel','maniküre','hände','nagelpflege','lackieren'],
   'Maniküre beim Kunden zu Hause.', 10),
  ((select id from public.service_categories where slug = 'beauty'),
   'mobile-pedikuere', 'Mobile Pediküre', 'Mobile pedicure',
   'Fußpflege bei Ihnen zu Hause',
   'Foot care at your home',
   'fixed_price',
   array['füße','pediküre','fußpflege','zehennägel'],
   'Pediküre beim Kunden zu Hause.', 20),
  ((select id from public.service_categories where slug = 'beauty'),
   'mobile-make-up', 'Mobile Make-up', 'Mobile make-up',
   'Make-up für Anlässe und Feiern',
   'Make-up for events and celebrations',
   'fixed_price',
   array['make-up','schminken','hochzeit','feier','anlass','visagist'],
   'Make-up beim Kunden zu Hause, etwa für Feiern.', 30),
  ((select id from public.service_categories where slug = 'beauty'),
   'mobile-hairstyling', 'Mobile Hairstyling', 'Mobile hairstyling',
   'Schnitt und Styling zu Hause',
   'Cut and styling at home',
   'quote',
   array['haare','friseur','schneiden','styling','frisur','hochsteckfrisur'],
   'Haarschnitt oder Styling beim Kunden zu Hause.', 40),

  -- Renovierung
  ((select id from public.service_categories where slug = 'renovation'),
   'waende-streichen', 'Wände streichen', 'Wall painting',
   'Einzelne Wände frisch streichen',
   'Individual walls freshly painted',
   'quote',
   array['streichen','malen','wand','farbe','anstrich','maler'],
   'Streichen einzelner Wände, Umfang nach Besichtigung.', 10),
  ((select id from public.service_categories where slug = 'renovation'),
   'raeume-ausmalen', 'Räume ausmalen', 'Room painting',
   'Ganze Räume oder Wohnungen ausmalen',
   'Entire rooms or flats painted',
   'quote',
   array['ausmalen','streichen','zimmer','wohnung','maler','weißen'],
   'Ausmalen kompletter Räume oder Wohnungen.', 20),
  ((select id from public.service_categories where slug = 'renovation'),
   'boden-verlegen', 'Boden verlegen', 'Flooring',
   'Laminat, Vinyl oder Parkett verlegen',
   'Laminate, vinyl or parquet laid',
   'quote',
   array['boden','laminat','parkett','vinyl','verlegen','fußboden'],
   'Verlegen von Bodenbelägen.', 30),
  ((select id from public.service_categories where slug = 'renovation'),
   'fliesenarbeiten', 'Fliesenarbeiten', 'Tiling',
   'Fliesen legen und ausbessern',
   'Tiles laid and repaired',
   'quote',
   array['fliesen','kacheln','bad','küche','verfugen','legen'],
   'Verlegen und Ausbessern von Fliesen.', 40),
  ((select id from public.service_categories where slug = 'renovation'),
   'renovierungsarbeiten', 'Renovierungsarbeiten', 'Renovation work',
   'Größere Umbauten nach Besichtigung',
   'Larger conversions after a site visit',
   'quote',
   array['renovieren','sanieren','umbau','sanierung','komplett'],
   'Umfangreichere Renovierungen, Angebot nach Besichtigung.', 50),

  -- Garten
  ((select id from public.service_categories where slug = 'garden'),
   'rasen-maehen', 'Rasen mähen', 'Lawn mowing',
   'Rasen kürzen und Schnittgut entsorgen',
   'Lawn cut and clippings removed',
   'fixed_price',
   array['rasen','mähen','gras','wiese','garten','schneiden'],
   'Mähen einer Rasenfläche inklusive Entsorgung.', 10),
  ((select id from public.service_categories where slug = 'garden'),
   'heckenschnitt', 'Heckenschnitt', 'Hedge trimming',
   'Hecken in Form bringen',
   'Hedges brought back into shape',
   'quote',
   array['hecke','schneiden','stutzen','sträucher','garten'],
   'Schneiden von Hecken und Sträuchern.', 20),
  ((select id from public.service_categories where slug = 'garden'),
   'gartenpflege', 'Gartenpflege', 'Garden maintenance',
   'Regelmäßige Pflege Ihres Gartens',
   'Recurring care for your garden',
   'quote',
   array['garten','pflege','beet','bewässern','jäten','gärtner'],
   'Laufende Pflege eines Gartens.', 30),
  ((select id from public.service_categories where slug = 'garden'),
   'unkraut-entfernen', 'Unkraut entfernen', 'Weeding',
   'Beete und Wege von Unkraut befreien',
   'Beds and paths cleared of weeds',
   'fixed_price',
   array['unkraut','jäten','beet','wege','garten','entfernen'],
   'Entfernen von Unkraut auf Beeten und Wegen.', 40),

  -- Sonstiges
  ((select id from public.service_categories where slug = 'other'),
   'sonstige-dienstleistung', 'Sonstige Dienstleistung', 'Other service',
   'Etwas, das in keine Kategorie passt',
   'Something that fits no category',
   'quote',
   array['sonstiges','anderes','hilfe','unterstützung'],
   'Dienstleistung, die keiner bestehenden Kategorie zugeordnet ist.', 10),
  ((select id from public.service_categories where slug = 'other'),
   'individuelle-anfrage', 'Individuelle Anfrage', 'Custom request',
   'Beschreiben Sie einfach, was Sie brauchen',
   'Just describe what you need',
   'quote',
   array['individuell','speziell','sonderwunsch','beschreiben'],
   'Frei beschriebene Anfrage ohne festen Leistungsumfang.', 20);

insert into public.service_price_options (
  service_id, name, name_en, price_cents, unit, duration_minutes, sort_order
) values
  -- Wohnungsreinigung
  ((select id from public.services where slug = 'wohnungsreinigung'),
   'bis 50 m²', 'up to 50 m²', 5900, 'pauschal', 120, 10),
  ((select id from public.services where slug = 'wohnungsreinigung'),
   '51–80 m²', '51–80 m²', 8900, 'pauschal', 180, 20),
  ((select id from public.services where slug = 'wohnungsreinigung'),
   '81–120 m²', '81–120 m²', 11900, 'pauschal', 240, 30),
  ((select id from public.services where slug = 'wohnungsreinigung'),
   'über 120 m²', 'over 120 m²', 15900, 'pauschal', 300, 40),
  -- Tiefenreinigung
  ((select id from public.services where slug = 'tiefenreinigung'),
   'bis 50 m²', 'up to 50 m²', 12900, 'pauschal', 240, 10),
  ((select id from public.services where slug = 'tiefenreinigung'),
   '51–80 m²', '51–80 m²', 17900, 'pauschal', 330, 20),
  ((select id from public.services where slug = 'tiefenreinigung'),
   '81–120 m²', '81–120 m²', 23900, 'pauschal', 420, 30),
  -- Fensterreinigung
  ((select id from public.services where slug = 'fensterreinigung'),
   'bis 5 Fenster', 'up to 5 windows', 4900, 'pauschal', 60, 10),
  ((select id from public.services where slug = 'fensterreinigung'),
   '6–10 Fenster', '6–10 windows', 7900, 'pauschal', 120, 20),
  ((select id from public.services where slug = 'fensterreinigung'),
   '11–20 Fenster', '11–20 windows', 12900, 'pauschal', 180, 30),
  -- Möbelmontage
  ((select id from public.services where slug = 'moebelmontage'),
   'kleines Möbelstück', 'small item', 3900, 'pauschal', 45, 10),
  ((select id from public.services where slug = 'moebelmontage'),
   'mittleres Möbelstück', 'medium item', 6900, 'pauschal', 90, 20),
  ((select id from public.services where slug = 'moebelmontage'),
   'großes Möbelstück', 'large item', 11900, 'pauschal', 150, 30),
  -- Lampenmontage
  ((select id from public.services where slug = 'lampenmontage'),
   'eine Lampe', 'one light', 4900, 'pauschal', 45, 10),
  ((select id from public.services where slug = 'lampenmontage'),
   'bis zu drei Lampen', 'up to three lights', 9900, 'pauschal', 90, 20),
  -- Bilder & Regale
  ((select id from public.services where slug = 'bilder-regale-montieren'),
   'bis 3 Teile', 'up to 3 items', 3900, 'pauschal', 45, 10),
  ((select id from public.services where slug = 'bilder-regale-montieren'),
   '4–8 Teile', '4–8 items', 6900, 'pauschal', 90, 20),
  -- Bohrarbeiten
  ((select id from public.services where slug = 'bohrarbeiten'),
   'bis 5 Löcher', 'up to 5 holes', 3900, 'pauschal', 45, 10),
  ((select id from public.services where slug = 'bohrarbeiten'),
   '6–15 Löcher', '6–15 holes', 6900, 'pauschal', 90, 20),
  -- Mobile Autoreinigung
  ((select id from public.services where slug = 'mobile-autoreinigung'),
   'Kleinwagen', 'Small car', 6900, 'pauschal', 90, 10),
  ((select id from public.services where slug = 'mobile-autoreinigung'),
   'Mittelklasse', 'Mid-size', 8900, 'pauschal', 120, 20),
  ((select id from public.services where slug = 'mobile-autoreinigung'),
   'SUV', 'SUV', 10900, 'pauschal', 150, 30),
  -- Auto Innenreinigung
  ((select id from public.services where slug = 'auto-innenreinigung'),
   'Kleinwagen', 'Small car', 4900, 'pauschal', 60, 10),
  ((select id from public.services where slug = 'auto-innenreinigung'),
   'Mittelklasse', 'Mid-size', 5900, 'pauschal', 75, 20),
  ((select id from public.services where slug = 'auto-innenreinigung'),
   'SUV', 'SUV', 6900, 'pauschal', 90, 30),
  -- Auto Außenreinigung
  ((select id from public.services where slug = 'auto-aussenreinigung'),
   'Kleinwagen', 'Small car', 3900, 'pauschal', 45, 10),
  ((select id from public.services where slug = 'auto-aussenreinigung'),
   'Mittelklasse', 'Mid-size', 4500, 'pauschal', 60, 20),
  ((select id from public.services where slug = 'auto-aussenreinigung'),
   'SUV', 'SUV', 5500, 'pauschal', 75, 30),
  -- Auto Innen & Außen
  ((select id from public.services where slug = 'auto-innen-aussenreinigung'),
   'Kleinwagen', 'Small car', 7900, 'pauschal', 120, 10),
  ((select id from public.services where slug = 'auto-innen-aussenreinigung'),
   'Mittelklasse', 'Mid-size', 9900, 'pauschal', 150, 20),
  ((select id from public.services where slug = 'auto-innen-aussenreinigung'),
   'SUV', 'SUV', 11900, 'pauschal', 180, 30),
  -- Kleintransport
  ((select id from public.services where slug = 'kleintransport'),
   'bis 1 Stunde', 'up to 1 hour', 5900, 'pauschal', 60, 10),
  ((select id from public.services where slug = 'kleintransport'),
   'bis 2 Stunden', 'up to 2 hours', 9900, 'pauschal', 120, 20),
  -- Umzugshilfe / Möbel tragen
  ((select id from public.services where slug = 'umzugshilfe'),
   'pro Helfer', 'per helper', 3900, 'pro Stunde', 60, 10),
  ((select id from public.services where slug = 'moebel-tragen'),
   'pro Helfer', 'per helper', 3900, 'pro Stunde', 60, 10),
  -- Haustiere
  ((select id from public.services where slug = 'hundespaziergang'),
   '30 Minuten', '30 minutes', 1500, 'pro Termin', 30, 10),
  ((select id from public.services where slug = 'hundespaziergang'),
   '60 Minuten', '60 minutes', 2500, 'pro Termin', 60, 20),
  ((select id from public.services where slug = 'hundebetreuung'),
   'halber Tag', 'half day', 3900, 'pro Termin', 240, 10),
  ((select id from public.services where slug = 'hundebetreuung'),
   'ganzer Tag', 'full day', 6900, 'pro Termin', 480, 20),
  ((select id from public.services where slug = 'katzenbetreuung'),
   'ein Besuch', 'one visit', 1900, 'pro Besuch', 30, 10),
  -- Beauty
  ((select id from public.services where slug = 'mobile-manikuere'),
   'klassisch', 'classic', 3500, 'pauschal', 45, 10),
  ((select id from public.services where slug = 'mobile-manikuere'),
   'mit Lack', 'with polish', 4500, 'pauschal', 60, 20),
  ((select id from public.services where slug = 'mobile-pedikuere'),
   'klassisch', 'classic', 4500, 'pauschal', 60, 10),
  ((select id from public.services where slug = 'mobile-make-up'),
   'Tages-Make-up', 'Day make-up', 5900, 'pauschal', 60, 10),
  ((select id from public.services where slug = 'mobile-make-up'),
   'Abend-Make-up', 'Evening make-up', 7900, 'pauschal', 90, 20),
  -- Garten
  ((select id from public.services where slug = 'rasen-maehen'),
   'bis 100 m²', 'up to 100 m²', 4900, 'pauschal', 60, 10),
  ((select id from public.services where slug = 'rasen-maehen'),
   '101–300 m²', '101–300 m²', 7900, 'pauschal', 120, 20),
  ((select id from public.services where slug = 'rasen-maehen'),
   'über 300 m²', 'over 300 m²', 11900, 'pauschal', 180, 30),
  ((select id from public.services where slug = 'unkraut-entfernen'),
   'bis 50 m²', 'up to 50 m²', 4900, 'pauschal', 60, 10),
  ((select id from public.services where slug = 'unkraut-entfernen'),
   '51–150 m²', '51–150 m²', 8900, 'pauschal', 120, 20);
