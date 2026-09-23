-- The list of conversations a person is part of.
--
-- Nothing is added to the schema: conversations, messages and the policies
-- on them stay exactly as they are. This is one read, and it exists as a
-- function for two reasons.
--
-- 1. Names. A customer needs the provider's name, which lives in
--    `providers` behind a policy that only lets a provider read their own
--    row. A provider needs the customer's name, which lives in `profiles`
--    behind the same kind of policy. Neither side can read the other's
--    table directly, and neither should be able to -- so the one place
--    that may join both is a function whose return type says exactly what
--    comes out.
--
-- 2. One query. The last message per conversation comes from a lateral
--    join, not from one request per row, so a provider with a hundred jobs
--    costs the same round trip as one with two.
--
-- profile_image_url is included only for the provider, and only when the
-- customer is the one looking: a provider uploads that picture so that
-- customers can see it. Customers have no such column, so the other
-- direction is null rather than invented.

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
    -- This where clause is the whole boundary: the function runs with
    -- elevated rights, so nothing else limits which rows are considered.
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
    case when m.viewer_is_customer then p.profile_image_url end,
    s.name,
    s.name_en,
    last_message.message,
    last_message.created_at,
    m.updated_at
  from mine m
  join public.providers p on p.id = m.provider_id
  left join public.profiles prof on prof.id = m.customer_id
  left join public.service_requests r on r.id = m.request_id
  left join public.services s on s.id = r.service_id
  left join lateral (
    select msg.message, msg.created_at
    from public.messages msg
    where msg.conversation_id = m.id
    order by msg.created_at desc
    limit 1
  ) last_message on true
  -- Newest conversation first. A conversation nobody has written in yet
  -- falls back to when it was opened, so it does not sink to the bottom.
  order by coalesce(last_message.created_at, m.updated_at) desc;
$$;

comment on function public.my_conversations is
  'The caller''s own conversations with the other person''s name and the '
  'last message. The return type is the whole contract: no email, no '
  'phone, no address, and never anybody else''s conversation.';

revoke execute on function public.my_conversations() from public, anon;
grant execute on function public.my_conversations() to authenticated;
