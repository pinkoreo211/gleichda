-- The job's lifecycle, part 1 of 2: the new values and columns.
--
-- Split in two on purpose. Postgres will not let a brand new enum value be
-- *used* in the same transaction that added it, and the functions in part 2
-- use these values. Running them as one script can therefore fail on a
-- detail that has nothing to do with the change itself.
--
-- No new table and no second status column: `request_contacts` already is
-- the job -- one row per (request, provider) that a provider answered --
-- and its `status` already carries the answer. The lifecycle is the same
-- story continuing, so it continues in the same column.
--
-- 'sent' and 'declined' keep their meaning. 'accepted' is now the first
-- step of a job rather than the end of the story.

alter type public.request_contact_status add value if not exists 'scheduled';
alter type public.request_contact_status add value if not exists 'on_the_way';
alter type public.request_contact_status add value if not exists 'in_progress';
alter type public.request_contact_status add value if not exists 'completed';
alter type public.request_contact_status
  add value if not exists 'customer_confirmed';
alter type public.request_contact_status add value if not exists 'cancelled';

-- When each step happened. Only the four that something in the app can
-- actually set -- no field is added on the chance it might be useful.
alter table public.request_contacts
  add column if not exists scheduled_at timestamptz,
  add column if not exists started_at timestamptz,
  add column if not exists completed_at timestamptz,
  add column if not exists customer_confirmed_at timestamptz,
  add column if not exists updated_at timestamptz not null default now();

comment on column public.request_contacts.scheduled_at is
  'The time the two of them agreed on. Set together with the scheduled '
  'status, never guessed from the customer''s wish.';

-- Reuses the function created with the profiles migration.
create trigger request_contacts_set_updated_at
  before update on public.request_contacts
  for each row execute function public.set_updated_at();
