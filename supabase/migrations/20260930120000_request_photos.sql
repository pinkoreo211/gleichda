-- Photos on a request.
--
-- Optional, and only ever a help: a picture of the dripping tap says in one
-- glance what a paragraph struggles with. Nothing reads them, nothing prices
-- them, nothing decides anything from them.
--
-- Who may look is the whole point of this file. A photo taken inside
-- somebody's flat is not a thing to leave lying around, so:
--
--   * the bucket is private -- there is no public URL at all, only a signed
--     link that expires,
--   * the customer who owns the request may look,
--   * a provider may look only at a request that was sent to them,
--   * nobody else, and that includes every other provider.
--
-- The third rule is a decision worth naming. A provider sees the photos
-- while deciding whether to accept, not only once they have. That is what
-- the photos are for: accepting blind and looking afterwards helps nobody,
-- and there is no way back out of an accepted job. Who gets to look is
-- still entirely the customer's choice -- they chose who to ask.
--
-- The street address stays where it is, in my_jobs(), behind acceptance.
-- A photo says what the work is; the address says where somebody lives.

-- Table ---------------------------------------------------------------------

create table public.request_photos (
  id uuid primary key default gen_random_uuid(),

  request_id uuid not null
    references public.service_requests (id) on delete cascade,

  -- Where the file sits in the bucket: `<request_id>/<something>.<ext>`.
  -- Unique, so two rows can never claim the same file.
  storage_path text not null unique
    check (char_length(storage_path) between 1 and 500),

  -- The order the customer added them in. They chose which photo comes
  -- first, and that is usually the one that shows the problem.
  sort_order smallint not null default 0,

  created_at timestamptz not null default now()
);

comment on table public.request_photos is
  'Photos a customer attached to their own request. Visible to them and to '
  'the providers that request was sent to, and to nobody else.';

create index request_photos_request_idx
  on public.request_photos (request_id, sort_order);

-- Access to the table -------------------------------------------------------

alter table public.request_photos enable row level security;

-- No grants at all, on purpose. Row policies cannot tell one column from
-- another, so the only safe contract is a function whose return type says
-- exactly what leaves the database. The three functions below are that
-- contract; nothing else reaches this table.
revoke all on public.request_photos from anon, authenticated;

-- Storage -------------------------------------------------------------------

-- Private: `public = false` means no public URL exists. The app reaches a
-- photo through a signed link that expires, and only for photos it is
-- allowed to read.
insert into storage.buckets (id, name, public)
values ('request-photos', 'request-photos', false)
on conflict (id) do nothing;

-- Photos, not documents: no PDF here. The size limit is the bucket's own,
-- so a phone that skipped the app's check still gets nowhere.
update storage.buckets
   set file_size_limit = 10485760,
       allowed_mime_types = array[
         'image/jpeg',
         'image/png',
         'image/heic',
         'image/webp'
       ]
 where id = 'request-photos';

-- May the caller look at the photos of this request?
--
-- Security definer because the answer needs both sides of the question, and
-- a provider cannot read the customer's request row under its own policies.
-- Without this, a storage policy asking the same thing directly would
-- quietly answer "no" for every provider.
--
-- Takes the folder as text and compares `r.id::text` to it, so a path that
-- is not a uuid at all simply matches nothing instead of raising.
create function public.can_see_request_photos(folder text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.service_requests r
    where r.id::text = folder
      and r.customer_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.request_contacts c
    join public.providers p on p.id = c.provider_id
    join public.service_requests r on r.id = c.request_id
    where r.id::text = folder
      and p.user_id = (select auth.uid())
  );
$$;

comment on function public.can_see_request_photos is
  'True for the customer who owns the request and for a provider it was '
  'sent to. Used by the storage policy and by photos_for_request(), so a '
  'listing and the files behind it can never disagree.';

revoke execute on function public.can_see_request_photos(text)
  from public, anon;
grant execute on function public.can_see_request_photos(text) to authenticated;

-- Uploading is the customer's alone. The folder has to be a request of
-- theirs, which is checked here against their own row -- their own policies
-- already let them read it, so no elevated rights are needed.
create policy "Customers upload photos onto their own request"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'request-photos'
    and exists (
      select 1 from public.service_requests r
      where r.id::text = (storage.foldername(name))[1]
        and r.customer_id = (select auth.uid())
    )
  );

-- Reading is the one place a provider comes in, and only for a request
-- that was handed to them.
create policy "Both sides of a request read its photos"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'request-photos'
    and public.can_see_request_photos((storage.foldername(name))[1])
  );

-- Removing is the customer's alone as well. A provider who dislikes a
-- photo has no business deleting it, and the customer may well have taken
-- it for somebody else too.
create policy "Customers remove photos from their own request"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'request-photos'
    and exists (
      select 1 from public.service_requests r
      where r.id::text = (storage.foldername(name))[1]
        and r.customer_id = (select auth.uid())
    )
  );

-- Functions -----------------------------------------------------------------

-- Records a file the customer has just uploaded.
--
-- The path is checked a second time here. Storage already refused a folder
-- that is not this customer's request; this makes sure the row cannot end
-- up pointing at a different request than the file it describes.
create function public.add_request_photo(
  target_request_id uuid,
  storage_path text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_id uuid;
  photo_count integer;
begin
  if not exists (
    select 1
    from public.service_requests r
    where r.id = target_request_id
      and r.customer_id = (select auth.uid())
  ) then
    raise exception 'Request not found' using errcode = '42501';
  end if;

  if split_part(storage_path, '/', 1) <> target_request_id::text then
    raise exception 'That file does not belong to this request'
      using errcode = '22023';
  end if;

  select count(*) into photo_count
  from public.request_photos
  where request_id = target_request_id;

  -- A limit the server holds, not the app. Six is enough to show a room
  -- from every side, and keeps one request from filling the bucket.
  if photo_count >= 6 then
    raise exception 'A request may carry at most six photos'
      using errcode = '22023';
  end if;

  insert into public.request_photos (request_id, storage_path, sort_order)
  values (target_request_id, storage_path, photo_count)
  returning id into new_id;

  return new_id;
end;
$$;

comment on function public.add_request_photo is
  'Records an uploaded photo against the caller''s own request. Returns the '
  'new row''s id.';

revoke execute on function public.add_request_photo(uuid, text)
  from public, anon;
grant execute on function public.add_request_photo(uuid, text) to authenticated;

-- Takes a photo back off a request.
--
-- Returns the path so the app can delete the file itself: the row and the
-- file are two things, and the row going first means nothing ever points at
-- a file that is already gone.
create function public.remove_request_photo(photo_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  removed_path text;
begin
  delete from public.request_photos ph
   using public.service_requests r
   where ph.id = photo_id
     and r.id = ph.request_id
     and r.customer_id = (select auth.uid())
  returning ph.storage_path into removed_path;

  if removed_path is null then
    raise exception 'Photo not found' using errcode = '42501';
  end if;

  return removed_path;
end;
$$;

comment on function public.remove_request_photo is
  'Removes one photo from the caller''s own request and returns its storage '
  'path, so the app can delete the file behind it.';

revoke execute on function public.remove_request_photo(uuid) from public, anon;
grant execute on function public.remove_request_photo(uuid) to authenticated;

-- The photos of one request, for whoever is allowed to see them.
--
-- The return type is the contract: an id, a path and a time. Not who took
-- them, not the request they hang off, not the customer behind it.
create function public.photos_for_request(target_request_id uuid)
returns table (
  id uuid,
  storage_path text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select ph.id, ph.storage_path, ph.created_at
  from public.request_photos ph
  where ph.request_id = target_request_id
    and public.can_see_request_photos(target_request_id::text)
  order by ph.sort_order, ph.created_at;
$$;

comment on function public.photos_for_request is
  'The photos on one request, for the customer who owns it or a provider it '
  'was sent to. Empty for anybody else, rather than an error: there is '
  'nothing for them to know about.';

revoke execute on function public.photos_for_request(uuid) from public, anon;
grant execute on function public.photos_for_request(uuid) to authenticated;
