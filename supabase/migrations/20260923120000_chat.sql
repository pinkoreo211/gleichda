-- A private conversation between the customer and the provider who took
-- the job, and the messages in it.
--
-- Two decisions worth stating, because both differ from the obvious shape:
--
-- 1. The conversation is keyed by (request_id, provider_id), not by
--    request_id alone. A request in this app can be sent to several
--    providers and more than one of them may accept -- those are two
--    separate jobs, and giving them one shared chat would put strangers in
--    the same room. "One conversation per job" is exactly what this pair
--    expresses; request_contacts already uses the same key.
--
-- 2. Clients cannot insert a conversation at all. There is no insert grant,
--    so the only way one exists is through get_or_create_conversation()
--    below, which checks that the job was really accepted and that the
--    caller is one of the two people in it. A policy could only check what
--    the client sends; the function checks what the database holds.
--
-- sender_id is not grantable either. It defaults to auth.uid(), so a
-- message in someone else's name is not something the app can express --
-- not merely something a policy refuses.

-- Tables ---------------------------------------------------------------------

create table public.conversations (
  id uuid primary key default gen_random_uuid(),

  request_id uuid not null
    references public.service_requests (id) on delete cascade,

  -- The auth user. Requests already store the customer this way.
  customer_id uuid not null
    references auth.users (id) on delete cascade,

  -- The provider profile, not the auth user: that is how providers are
  -- referenced everywhere else. The policies below resolve it to the
  -- account through public.providers.
  provider_id uuid not null
    references public.providers (id) on delete cascade,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- One conversation per job.
  unique (request_id, provider_id)
);

comment on table public.conversations is
  'One private conversation per accepted job. Written only by '
  'get_or_create_conversation(), never directly by a client.';

create table public.messages (
  id uuid primary key default gen_random_uuid(),

  conversation_id uuid not null
    references public.conversations (id) on delete cascade,

  -- Defaults to the caller and is not grantable, so a message cannot be
  -- written in someone else's name.
  sender_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,

  message text not null check (
    char_length(btrim(message)) > 0 and char_length(message) <= 4000
  ),

  created_at timestamptz not null default now()
);

comment on column public.messages.sender_id is
  'Who wrote it. Defaults to auth.uid() and is never granted to clients.';

create index messages_conversation_created_idx
  on public.messages (conversation_id, created_at);
create index conversations_customer_idx on public.conversations (customer_id);
create index conversations_provider_idx on public.conversations (provider_id);
create index conversations_request_idx on public.conversations (request_id);

create trigger conversations_set_updated_at
  before update on public.conversations
  for each row execute function public.set_updated_at();

-- A new message moves its conversation to the top of any list sorted by
-- activity. Security definer because the writer is a participant, who has
-- no update rights on conversations at all.
create function public.touch_conversation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.conversations
     set updated_at = now()
   where id = new.conversation_id;
  return new;
end;
$$;

revoke execute on function public.touch_conversation() from public, anon,
  authenticated;

create trigger messages_touch_conversation
  after insert on public.messages
  for each row execute function public.touch_conversation();

-- Access ---------------------------------------------------------------------

alter table public.conversations enable row level security;
alter table public.messages enable row level security;

revoke all on public.conversations from anon, authenticated;
revoke all on public.messages from anon, authenticated;

-- Readable, never writable: the function below is the only writer.
grant select on public.conversations to authenticated;

grant select on public.messages to authenticated;
-- sender_id and created_at are deliberately absent.
grant insert (conversation_id, message) on public.messages to authenticated;

-- No update or delete grant on either table. A sent message stays as it
-- was sent; editing and deleting are their own decisions, not side effects
-- of building a chat.

create policy "Participants read their conversations"
  on public.conversations for select
  to authenticated
  using (
    customer_id = (select auth.uid())
    or exists (
      select 1 from public.providers p
      where p.id = provider_id and p.user_id = (select auth.uid())
    )
  );

create policy "Participants read their messages"
  on public.messages for select
  to authenticated
  using (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id
        and (
          c.customer_id = (select auth.uid())
          or exists (
            select 1 from public.providers p
            where p.id = c.provider_id and p.user_id = (select auth.uid())
          )
        )
    )
  );

create policy "Participants write their own messages"
  on public.messages for insert
  to authenticated
  with check (
    -- Stated as well as enforced by the column grant, so the rule is
    -- readable in one place even if the grants ever change.
    sender_id = (select auth.uid())
    and exists (
      select 1 from public.conversations c
      where c.id = conversation_id
        and (
          c.customer_id = (select auth.uid())
          or exists (
            select 1 from public.providers p
            where p.id = c.provider_id and p.user_id = (select auth.uid())
          )
        )
    )
  );

-- Opening a conversation ------------------------------------------------------

-- Returns the conversation for one accepted job, creating it the first
-- time. Called by both sides:
--
-- * the customer passes the provider they picked;
-- * the provider passes nothing, and the server uses their own profile --
--   so a provider cannot open someone else's job by guessing an id.
create function public.get_or_create_conversation(
  target_request_id uuid,
  target_provider_id uuid default null
)
returns public.conversations
language plpgsql
security definer
set search_path = ''
as $$
declare
  resolved_provider_id uuid := target_provider_id;
  job_customer_id uuid;
  result public.conversations;
begin
  if resolved_provider_id is null then
    select p.id into resolved_provider_id
    from public.providers p
    where p.user_id = (select auth.uid());

    if resolved_provider_id is null then
      raise exception 'No provider profile' using errcode = '42501';
    end if;
  end if;

  -- The job must exist and must have been accepted. A chat before a yes
  -- would be a channel nobody agreed to.
  select r.customer_id into job_customer_id
  from public.request_contacts c
  join public.service_requests r on r.id = c.request_id
  where c.request_id = target_request_id
    and c.provider_id = resolved_provider_id
    and c.status = 'accepted';

  if not found then
    raise exception 'No accepted job for this request'
      using errcode = '42501';
  end if;

  -- And the caller has to be one of the two people in it.
  if not (
    job_customer_id = (select auth.uid())
    or exists (
      select 1 from public.providers p
      where p.id = resolved_provider_id and p.user_id = (select auth.uid())
    )
  ) then
    raise exception 'Not part of this job' using errcode = '42501';
  end if;

  -- do nothing, then read: if both sides tap at the same moment, one
  -- insert wins and both end up with the same row.
  insert into public.conversations (request_id, customer_id, provider_id)
  values (target_request_id, job_customer_id, resolved_provider_id)
  on conflict (request_id, provider_id) do nothing;

  select * into result
  from public.conversations
  where request_id = target_request_id
    and provider_id = resolved_provider_id;

  return result;
end;
$$;

comment on function public.get_or_create_conversation is
  'The only writer of conversations. Opens the chat for one accepted job, '
  'once, and only for the two people in that job.';

revoke execute on function public.get_or_create_conversation(uuid, uuid)
  from public, anon;
grant execute on function public.get_or_create_conversation(uuid, uuid)
  to authenticated;
