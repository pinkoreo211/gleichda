-- Profiles and roles for app users.
--
-- Security model:
-- * Row level security is enabled on every table; users only see their own rows.
-- * Clients can never write roles directly. They call add_my_role(), which only
--   allows 'customer' and 'provider'. 'admin' is granted manually by the team.
-- * Having the 'provider' role does NOT mean verified. Verification is modelled
--   separately (roadmap step 4).

-- Roles ---------------------------------------------------------------------

create type public.app_role as enum ('customer', 'provider', 'admin');

-- Tables --------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text check (char_length(display_name) <= 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is 'One row per auth user, created automatically on sign-up.';

create table public.user_roles (
  user_id uuid not null references auth.users (id) on delete cascade,
  role public.app_role not null,
  created_at timestamptz not null default now(),
  primary key (user_id, role)
);

comment on table public.user_roles is 'Roles per user. Written only via add_my_role() or by the team.';

-- Access: row level security + explicit grants -------------------------------

alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;

revoke all on public.profiles from anon, authenticated;
revoke all on public.user_roles from anon, authenticated;

grant select on public.profiles to authenticated;
grant update (display_name) on public.profiles to authenticated;
grant select on public.user_roles to authenticated;

create policy "Users can read their own profile"
  on public.profiles for select
  to authenticated
  using ((select auth.uid()) = id);

create policy "Users can update their own profile"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create policy "Users can read their own roles"
  on public.user_roles for select
  to authenticated
  using ((select auth.uid()) = user_id);

-- updated_at ------------------------------------------------------------------

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Profile for every new user --------------------------------------------------

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Users that signed up before this migration also get a profile.
insert into public.profiles (id)
select id from auth.users
on conflict (id) do nothing;

-- Self-service roles ----------------------------------------------------------

create function public.add_my_role(requested_role public.app_role)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  if requested_role not in ('customer', 'provider') then
    raise exception 'Role % cannot be self-assigned', requested_role
      using errcode = '42501';
  end if;

  insert into public.user_roles (user_id, role)
  values ((select auth.uid()), requested_role)
  on conflict do nothing;
end;
$$;

revoke execute on function public.add_my_role(public.app_role) from public, anon;
grant execute on function public.add_my_role(public.app_role) to authenticated;
