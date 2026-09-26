-- Verification: the documents a provider hands in, and who may look at them.
--
-- `provider_documents` already exists from the providers migration, where it
-- was prepared but never written to. This fills it in rather than replacing
-- it, and tightens the way in:
--
--   * The table loses its insert grant and its select grant. A provider can
--     no longer write a row claiming any file path they like, and cannot
--     read `reviewed_by` -- which team member looked at a document is the
--     team's business, not the provider's.
--   * One function writes documents, one function reads them. The read
--     function's return type is the contract: what it does not list, no
--     client can reach.
--   * Nothing here can set `verification_status` to 'verified'. Handing in
--     a document starts a check; only the team ends it.
--
-- The files themselves live in a private storage bucket. A provider may put
-- files only into a folder named after their own provider id, and may read
-- only from it, so one provider can never reach another's documents -- not
-- through the app, and not through a link.

-- Columns -------------------------------------------------------------------

alter table public.provider_documents
  add column file_name text check (char_length(file_name) <= 200),
  -- Written by the team when they turn a document down. Deliberately a
  -- separate column from `note`: `note` used to be writable by the
  -- provider, and a reason the provider could edit is not a reason.
  add column rejection_reason text check (char_length(rejection_reason) <= 500),
  add column reviewed_by uuid references auth.users (id) on delete set null;

comment on column public.provider_documents.rejection_reason is
  'Team-written. Never granted to clients; shown to the provider through '
  'my_provider_documents().';

-- One current document per type. Handing in a new identity document
-- replaces the old one instead of leaving the team with two to choose
-- between. (The table has never been written to, so nothing can clash.)
create unique index provider_documents_one_per_type
  on public.provider_documents (provider_id, document_type);

-- Which documents a service needs -------------------------------------------

-- Empty for most services: the baseline in my_required_documents() already
-- covers identity and a business registration. A row here adds a
-- requirement on top, for work where more is fair to ask.
create table public.service_document_requirements (
  service_id uuid not null
    references public.services (id) on delete cascade,
  document_type public.provider_document_type not null,
  -- False means "shown as optional", not "ignored".
  is_required boolean not null default true,
  primary key (service_id, document_type)
);

comment on table public.service_document_requirements is
  'Per-service verification requirements, maintained by the team. Read by '
  'my_required_documents(); no client can write it.';

alter table public.service_document_requirements enable row level security;

revoke all on public.service_document_requirements from anon, authenticated;
grant select on public.service_document_requirements to authenticated;

-- Not secret: a provider deciding whether to offer a service should be able
-- to see what it would ask of them.
create policy "Signed-in people read the requirements"
  on public.service_document_requirements for select
  to authenticated
  using (true);

-- Connecting a ceiling light is electrical work, so proof of qualification
-- is asked for on top of the baseline. One real example, so the structure
-- is exercised rather than only described.
insert into public.service_document_requirements (service_id, document_type)
select s.id, 'qualification'
from public.services s
where s.slug = 'lampenmontage'
on conflict do nothing;

-- Storage -------------------------------------------------------------------

-- Private: `public = false` means there is no public URL at all. The app
-- reaches a file through a signed link that expires, and only for files it
-- is allowed to read.
insert into storage.buckets (id, name, public)
values ('provider-documents', 'provider-documents', false)
on conflict (id) do nothing;

-- Every path starts with the provider id: `<provider_id>/<type>/<file>`.
-- `storage.foldername(name)[1]` is that first folder, and it has to be a
-- provider profile belonging to the caller.
create policy "Providers upload files into their own folder"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'provider-documents'
    and exists (
      select 1 from public.providers p
      where p.user_id = (select auth.uid())
        and p.id::text = (storage.foldername(name))[1]
    )
  );

create policy "Providers read files in their own folder"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'provider-documents'
    and exists (
      select 1 from public.providers p
      where p.user_id = (select auth.uid())
        and p.id::text = (storage.foldername(name))[1]
    )
  );

-- Deleting matters for replacing a document: the new file goes up, then the
-- old one goes away. Same folder rule, so nobody can delete another
-- provider's evidence.
create policy "Providers remove files in their own folder"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'provider-documents'
    and exists (
      select 1 from public.providers p
      where p.user_id = (select auth.uid())
        and p.id::text = (storage.foldername(name))[1]
    )
  );

-- Access to the table -------------------------------------------------------

-- The provider no longer touches this table directly. Both functions below
-- are security definer and check who is asking.
revoke insert on public.provider_documents from authenticated;
revoke select on public.provider_documents from authenticated;

-- Unreachable without the grants above, and leaving them would be
-- misleading about what actually guards this table.
drop policy if exists "Providers read their own documents"
  on public.provider_documents;
drop policy if exists "Providers add their own documents"
  on public.provider_documents;

-- Reading ---------------------------------------------------------------------

-- What the provider is allowed to know about their own documents. The
-- column list is the whole contract: `reviewed_by` is missing on purpose.
create function public.my_provider_documents()
returns table (
  id uuid,
  document_type public.provider_document_type,
  file_path text,
  file_name text,
  status public.provider_document_status,
  rejection_reason text,
  uploaded_at timestamptz,
  reviewed_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    d.id,
    d.document_type,
    d.file_path,
    d.file_name,
    d.status,
    d.rejection_reason,
    d.uploaded_at,
    d.reviewed_at
  from public.provider_documents d
  join public.providers p on p.id = d.provider_id
  where p.user_id = (select auth.uid())
  order by d.uploaded_at desc;
$$;

comment on function public.my_provider_documents is
  'The caller''s own documents. Returns no other provider''s rows and never '
  'reveals who reviewed them.';

revoke execute on function public.my_provider_documents() from public, anon;
grant execute on function public.my_provider_documents() to authenticated;

-- What this provider has to hand in. The baseline holds for everyone; a
-- service can add to it, and a service that asks for something the baseline
-- calls optional makes it required.
create function public.my_required_documents()
returns table (
  document_type public.provider_document_type,
  is_required boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  with baseline (document_type, is_required) as (
    values
      ('identity'::public.provider_document_type, true),
      ('business_registration'::public.provider_document_type, true),
      ('qualification'::public.provider_document_type, false),
      ('insurance'::public.provider_document_type, false)
  ),
  from_services as (
    select r.document_type, r.is_required
    from public.service_document_requirements r
    join public.provider_services ps
      on ps.service_id = r.service_id and ps.is_active
    join public.providers p on p.id = ps.provider_id
    where p.user_id = (select auth.uid())
  ),
  combined as (
    select * from baseline
    union all
    select * from from_services
  )
  select c.document_type, bool_or(c.is_required) as is_required
  from combined c
  group by c.document_type
  -- Required first, then in the order the type was defined, so the list
  -- reads the same way every time.
  order by bool_or(c.is_required) desc, c.document_type;
$$;

comment on function public.my_required_documents is
  'Baseline plus whatever the services this provider offers ask for. '
  'Structure for per-service rules; the team maintains the rows.';

revoke execute on function public.my_required_documents() from public, anon;
grant execute on function public.my_required_documents() to authenticated;

-- Handing a document in ---------------------------------------------------------

-- The only writer. Returns the path it replaced, if any, so the app can
-- clear the old file out of storage afterwards.
create function public.submit_provider_document(
  doc_type public.provider_document_type,
  storage_path text,
  original_file_name text default null
)
returns table (document_id uuid, replaced_path text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  my_provider_id uuid;
  existing_id uuid;
  existing_status public.provider_document_status;
  existing_path text;
  new_id uuid;
begin
  select p.id into my_provider_id
  from public.providers p
  where p.user_id = (select auth.uid());

  if not found then
    raise exception 'No provider profile' using errcode = '42501';
  end if;

  if storage_path is null or btrim(storage_path) = '' then
    raise exception 'A document needs a file' using errcode = '22023';
  end if;

  -- Storage already refuses an upload into a foreign folder. This refuses a
  -- foreign *claim*: a row pointing at a file that is not this provider's.
  if split_part(storage_path, '/', 1) <> my_provider_id::text then
    raise exception 'That file is not yours' using errcode = '42501';
  end if;

  select d.id, d.status, d.file_path
    into existing_id, existing_status, existing_path
  from public.provider_documents d
  where d.provider_id = my_provider_id and d.document_type = doc_type;

  if found then
    -- Swapping a document out from under the team while they are looking
    -- at it, or after they accepted it, is not the provider's call.
    if existing_status in ('in_review', 'accepted') then
      raise exception 'This document is already being checked'
        using errcode = '22023';
    end if;

    update public.provider_documents
       set file_path = storage_path,
           file_name = original_file_name,
           status = 'uploaded',
           rejection_reason = null,
           reviewed_at = null,
           reviewed_by = null,
           uploaded_at = now()
     where id = existing_id;

    new_id := existing_id;
  else
    insert into public.provider_documents (
      provider_id, document_type, file_path, file_name
    )
    values (my_provider_id, doc_type, storage_path, original_file_name)
    returning id into new_id;

    existing_path := null;
  end if;

  -- Handing something in starts a check, and only that. A provider who is
  -- already verified stays verified, and no path through this function
  -- ever writes 'verified'.
  update public.providers
     set verification_status = 'pending'
   where id = my_provider_id
     and verification_status in ('unverified', 'rejected');

  return query select new_id, existing_path;
end;
$$;

comment on function public.submit_provider_document is
  'The only way a document row is written. Checks the caller owns the file '
  'and never sets verification_status to verified.';

revoke execute on function
  public.submit_provider_document(public.provider_document_type, text, text)
  from public, anon;
grant execute on function
  public.submit_provider_document(public.provider_document_type, text, text)
  to authenticated;

-- For the team ------------------------------------------------------------------

-- Prepared for an admin tool that does not exist yet. Both functions are
-- revoked from every client role, so today they run only from the Supabase
-- dashboard, by a person. No app, and no AI, decides a verification.

create function public.pending_verifications()
returns table (
  provider_id uuid,
  display_name text,
  business_name text,
  city text,
  verification_status public.provider_verification_status,
  document_id uuid,
  document_type public.provider_document_type,
  file_name text,
  file_path text,
  document_status public.provider_document_status,
  uploaded_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    p.id,
    p.display_name,
    p.business_name,
    p.city,
    p.verification_status,
    d.id,
    d.document_type,
    d.file_name,
    d.file_path,
    d.status,
    d.uploaded_at
  from public.provider_documents d
  join public.providers p on p.id = d.provider_id
  where d.status in ('uploaded', 'in_review')
  order by d.uploaded_at;
$$;

comment on function public.pending_verifications is
  'Team view of everything waiting to be checked. Not callable by any '
  'client role.';

revoke execute on function public.pending_verifications() from public, anon,
  authenticated;

create function public.review_provider_document(
  document_id uuid,
  new_status public.provider_document_status,
  reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new_status not in ('in_review', 'accepted', 'rejected') then
    raise exception 'Not a review outcome' using errcode = '22023';
  end if;

  update public.provider_documents
     set status = new_status,
         rejection_reason = case
           when new_status = 'rejected' then reason
           else null
         end,
         reviewed_at = now(),
         reviewed_by = (select auth.uid())
   where id = document_id;

  if not found then
    raise exception 'Document not found' using errcode = '22023';
  end if;
end;
$$;

comment on function public.review_provider_document is
  'Team decision on one document. Not callable by any client role.';

revoke execute on function public.review_provider_document(
  uuid, public.provider_document_status, text
) from public, anon, authenticated;

create function public.set_provider_verification(
  target_provider_id uuid,
  new_status public.provider_verification_status
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.providers
     set verification_status = new_status
   where id = target_provider_id;

  if not found then
    raise exception 'Provider not found' using errcode = '22023';
  end if;
end;
$$;

comment on function public.set_provider_verification is
  'The only way a provider becomes verified, and it is not reachable from '
  'any app. A person in the team runs this after looking at the documents.';

revoke execute on function public.set_provider_verification(
  uuid, public.provider_verification_status
) from public, anon, authenticated;
