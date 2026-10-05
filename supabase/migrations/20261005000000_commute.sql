-- Goora feature 002: profiles, commute profiles, groups, waitlist.
-- Privacy (constitution IV): home/work points are readable only by their
-- owner and by the service-role matching function; nobody else ever sees them.

create extension if not exists postgis with schema extensions;

-- People ---------------------------------------------------------------------

create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  first_name  text not null check (char_length(first_name) between 1 and 40),
  last_name   text not null check (char_length(last_name) between 1 and 40),
  gender      text not null check (gender in ('male', 'female')),
  role        text check (role in ('driver', 'rider')),
  frequency   text check (frequency in ('everyDay', 'once')),
  company     text,
  compound    text,
  rating      numeric(2, 1) not null default 5.0 check (rating between 0 and 5),
  reliability numeric(5, 2) not null default 100 check (reliability between 0 and 100),
  women_only_pref        boolean not null default false,
  same_company_only_pref boolean not null default false,
  same_compound_only_pref boolean not null default false,
  created_at  timestamptz not null default now()
);

create table public.commute_profiles (
  user_id      uuid primary key references public.profiles (id) on delete cascade,
  home         extensions.geography(point, 4326) not null,
  home_area    text not null check (home_area in ('sheikhZayed', 'october', 'smartVillage')),
  work         extensions.geography(point, 4326) not null,
  work_area    text not null check (work_area in ('sheikhZayed', 'october', 'smartVillage')),
  departure    time not null,
  return_time  time not null check (return_time > departure),
  days         text[] not null check (cardinality(days) > 0),
  seats        smallint check (seats between 1 and 4),
  driven_trips text check (driven_trips in ('both', 'going', 'ret')),
  contribution smallint check (contribution > 0),
  updated_at   timestamptz not null default now(),
  check ((seats is null) = (driven_trips is null) and (seats is null) = (contribution is null))
);

-- Groups ---------------------------------------------------------------------

create table public.groups (
  id                 uuid primary key default gen_random_uuid(),
  origin_area        text not null,
  destination_area   text not null,
  destination        extensions.geography(point, 4326) not null,
  going              time not null,
  return_time        time not null,
  days               text[] not null check (cardinality(days) > 0),
  price              smallint not null check (price > 0),
  detour_minutes     smallint not null default 0 check (detour_minutes >= 0),
  women_only         boolean not null default false,
  same_company_only  text,
  same_compound_only text,
  created_at         timestamptz not null default now()
);

create index groups_destination_gix on public.groups using gist (destination);

create table public.group_pickup_points (
  id       uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  point    extensions.geography(point, 4326) not null,
  label    text not null
);

create index group_pickup_points_gix on public.group_pickup_points using gist (point);

create table public.group_members (
  group_id  uuid not null references public.groups (id) on delete cascade,
  user_id   uuid not null references public.profiles (id) on delete cascade,
  role      text not null check (role in ('driver', 'rider')),
  legs      text[] not null check (legs <@ array['going', 'ret'] and cardinality(legs) > 0),
  seats     smallint check (seats between 1 and 4),
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create table public.waitlist (
  user_id          uuid not null references public.profiles (id) on delete cascade,
  origin_area      text not null,
  destination_area text not null,
  created_at       timestamptz not null default now(),
  primary key (user_id, origin_area, destination_area)
);

-- Row Level Security: on for every table ---------------------------------------

alter table public.profiles            enable row level security;
alter table public.commute_profiles    enable row level security;
alter table public.groups              enable row level security;
alter table public.group_pickup_points enable row level security;
alter table public.group_members       enable row level security;
alter table public.waitlist            enable row level security;

create policy "own profile" on public.profiles
  for all to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy "own commute profile" on public.commute_profiles
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "groups are listed" on public.groups
  for select to authenticated using (true);

create policy "pickup points are listed" on public.group_pickup_points
  for select to authenticated using (true);

-- Members see their own groups' membership; other people's profiles (names,
-- photos) are served only through the matching function, which anonymises
-- riders for drivers until they ride together.
create function public.is_group_member(g uuid) returns boolean
  language sql stable security definer set search_path = public as $$
    select exists (select 1 from public.group_members where group_id = g and user_id = auth.uid())
  $$;

create policy "members see their group" on public.group_members
  for select to authenticated using (public.is_group_member(group_id));

create policy "join as yourself" on public.group_members
  for insert to authenticated with check (user_id = auth.uid());

create policy "leave as yourself" on public.group_members
  for delete to authenticated using (user_id = auth.uid());

create policy "own waitlist rows" on public.waitlist
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Matching input (service role only) ------------------------------------------
-- Returns the seeker and the PostGIS-prefiltered candidate groups as JSON in
-- the shape of supabase/functions/_shared/matching.ts.

create function public.match_input(p_user uuid, p_pickup_m float default 1000, p_dest_m float default 1500)
  returns jsonb language sql stable security definer set search_path = public, extensions as $$
  with me as (
    select p.*, c.*,
           array[st_y(c.home::geometry), st_x(c.home::geometry)] as home_pt,
           array[st_y(c.work::geometry), st_x(c.work::geometry)] as work_pt
    from profiles p join commute_profiles c on c.user_id = p.id
    where p.id = p_user
  ),
  candidates as (
    select g.* from groups g, me
    where st_dwithin(g.destination, me.work, p_dest_m)
      and exists (select 1 from group_pickup_points pp
                  where pp.group_id = g.id and st_dwithin(pp.point, me.home, p_pickup_m))
  )
  select jsonb_build_object(
    'seeker', (select jsonb_build_object(
        'role', role, 'home', home_pt, 'work', work_pt,
        'departure', to_char(departure, 'HH24:MI'), 'ret', to_char(return_time, 'HH24:MI'),
        'days', days,
        'legs', case when role = 'rider' or driven_trips = 'both' then array['going', 'ret']
                     else array[driven_trips] end,
        'isWoman', gender = 'female', 'company', company, 'compound', compound,
        'womenOnly', women_only_pref, 'sameCompanyOnly', same_company_only_pref,
        'sameCompoundOnly', same_compound_only_pref,
        'homeArea', home_area, 'workArea', work_area) from me),
    'groups', coalesce((select jsonb_agg(jsonb_build_object(
        'id', g.id, 'destination', g.destination_area,
        'destinationPoint', array[st_y(g.destination::geometry), st_x(g.destination::geometry)],
        'pickupPoints', (select jsonb_agg(array[st_y(pp.point::geometry), st_x(pp.point::geometry)])
                         from group_pickup_points pp where pp.group_id = g.id),
        'going', to_char(g.going, 'HH24:MI'), 'ret', to_char(g.return_time, 'HH24:MI'),
        'days', g.days, 'detourMinutes', g.detour_minutes, 'womenOnly', g.women_only,
        'sameCompanyOnly', g.same_company_only, 'sameCompoundOnly', g.same_compound_only,
        'members', (select coalesce(jsonb_agg(jsonb_build_object(
            'id', m.user_id, 'role', m.role, 'legs', m.legs, 'isWoman', p.gender = 'female',
            'company', p.company, 'compound', p.compound,
            'rating', p.rating, 'reliability', p.reliability)), '[]'::jsonb)
          from group_members m join profiles p on p.id = m.user_id where m.group_id = g.id),
        'freeSeatsGoing', greatest(0,
            coalesce((select sum(seats) from group_members where group_id = g.id and role = 'driver' and 'going' = any(legs)), 0)
          - (select count(*) from group_members where group_id = g.id and role = 'rider' and 'going' = any(legs))),
        'freeSeatsReturn', greatest(0,
            coalesce((select sum(seats) from group_members where group_id = g.id and role = 'driver' and 'ret' = any(legs)), 0)
          - (select count(*) from group_members where group_id = g.id and role = 'rider' and 'ret' = any(legs)))
      )) from candidates g), '[]'::jsonb)
  )
$$;

revoke all on function public.match_input(uuid, float, float) from public, anon, authenticated;
grant execute on function public.match_input(uuid, float, float) to service_role;
