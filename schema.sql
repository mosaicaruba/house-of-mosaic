-- Mosaic Inner Circle — Supabase schema.
-- Paste this whole file into Supabase: SQL Editor -> New query -> Run.

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  email text,
  created_at timestamptz default now()
);

create table public.staff (
  user_id uuid primary key references auth.users(id) on delete cascade
);

create table public.stamps (
  id bigint generated always as identity primary key,
  member_id uuid not null references public.profiles(id) on delete cascade,
  awarded_by uuid references auth.users(id),
  created_at timestamptz default now()
);

create table public.redemptions (
  id bigint generated always as identity primary key,
  member_id uuid not null references public.profiles(id) on delete cascade,
  stamps_used int not null,
  label text not null,
  redeemed_by uuid references auth.users(id),
  created_at timestamptz default now()
);

create table public.settings (
  key text primary key,
  value text not null
);

insert into public.settings values
  ('stamps_per_reward', '8'),
  ('reward_label', 'A gift from the house');

-- Staff check used inside policies (security definer avoids RLS recursion).
create or replace function public.is_staff() returns boolean
language sql stable security definer set search_path = public as
$$ select exists(select 1 from public.staff where user_id = auth.uid()) $$;

alter table public.profiles enable row level security;
alter table public.staff enable row level security;
alter table public.stamps enable row level security;
alter table public.redemptions enable row level security;
alter table public.settings enable row level security;

create policy "read own profile or staff" on public.profiles
  for select using (id = auth.uid() or public.is_staff());
create policy "insert own profile" on public.profiles
  for insert with check (id = auth.uid());
create policy "update own profile" on public.profiles
  for update using (id = auth.uid());

create policy "staff can read staff" on public.staff
  for select using (public.is_staff());

create policy "member or staff reads stamps" on public.stamps
  for select using (member_id = auth.uid() or public.is_staff());
create policy "only staff award stamps" on public.stamps
  for insert with check (public.is_staff());

create policy "member or staff reads redemptions" on public.redemptions
  for select using (member_id = auth.uid() or public.is_staff());
create policy "only staff redeem" on public.redemptions
  for insert with check (public.is_staff());

create policy "signed-in read settings" on public.settings
  for select using (auth.uid() is not null);
create policy "staff update settings" on public.settings
  for update using (public.is_staff());

-- Staff lookup of a member by the short code shown on their card
-- (first 8 characters of their member id).
create or replace function public.find_member(code text)
returns table(id uuid, name text, email text, stamps bigint, redeemed bigint)
language sql stable security definer set search_path = public as $$
  select p.id, p.name, p.email,
    (select count(*) from public.stamps s where s.member_id = p.id),
    coalesce((select sum(r.stamps_used) from public.redemptions r where r.member_id = p.id), 0)
  from public.profiles p
  where public.is_staff()
    and upper(left(replace(p.id::text, '-', ''), 8)) = upper(trim(code))
$$;

-- AFTER Fernando/you sign up in the club page, make that account staff by
-- running (replace the email):
--   insert into public.staff select id from auth.users where email = 'YOUR-EMAIL-HERE';
