-- Goora feature 003: the daily commute (specs/003-daily-commute research R12).
-- Written, not executed: no Supabase project exists yet.
--
-- Times: instants are timestamptz; the Edge Functions turn now() into Cairo
-- wall time (research R2) and run the rules in supabase/functions/_shared/.
-- Privacy (constitution IV, FR-032): no table, view or function here returns
-- commute_profiles.home or .work to a client. backup_input() reads them for
-- the service-role backup search only, like 002's match_input().

-- Additions to 002 tables -----------------------------------------------------

alter table public.profiles
  add column privacy_preference text not null default 'verifiedUsers'
    check (privacy_preference in ('verifiedUsers', 'sameCompany', 'sameCompound', 'womenOnly'));

alter table public.groups
  -- First day of the 4-week fairness periods; null = Sunday 4 Jan 2026 (_shared/rotation.ts).
  add column rotation_start date,
  add column arrival time;

-- Days this member commutes; null = the group's days.
alter table public.group_members
  add column days text[] check (days is null or cardinality(days) > 0);

-- Ordered stops of the going leg; the last stop's time is groups.going.
alter table public.group_pickup_points
  add column stop_time time,
  add column stop_order smallint not null default 0;

-- Rides: one leg of one group on one date ----------------------------------------

create table public.rides (
  -- Deterministic: '<group_id>:<yyyy-mm-dd>:<going|return>' (data-model).
  id                text primary key,
  group_id          uuid not null references public.groups (id) on delete cascade,
  ride_date         date not null,
  leg               text not null check (leg in ('going', 'ret')),
  planned_driver_id uuid references public.profiles (id) on delete set null,
  -- Actual driver; null = nobody covers the leg.
  driver_id         uuid references public.profiles (id) on delete set null,
  backup_step       text check (backup_step in ('sameGroup', 'nearbyGroup', 'sameCompany', 'sameCommunity')),
  seats             smallint check (seats between 1 and 4),
  -- [{id, name, time "HH:MM"}] before any delay; pickup points only, never a home.
  stops             jsonb not null default '[]'::jsonb,
  delay_minutes     smallint not null default 0 check (delay_minutes in (0, 5, 10, 15)),
  confirmed         boolean not null default false,
  started_at        timestamptz,
  ended_at          timestamptz,
  -- 16 random hex characters; names no group, date or person (FR-031).
  share_token       text not null unique default encode(extensions.gen_random_bytes(8), 'hex'),
  created_at        timestamptz not null default now(),
  unique (group_id, ride_date, leg)
);

create table public.ride_passengers (
  ride_id text not null references public.rides (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  stop_id text not null,
  primary key (ride_id, user_id)
);

-- One person missing one trip. Keyed by date and leg, not ride, so a trip can
-- be cancelled before its ride row exists. Drivers' "can't drive" sets driving.
create table public.absences (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  group_id   uuid not null references public.groups (id) on delete cascade,
  ride_date  date not null,
  leg        text not null check (leg in ('going', 'ret')),
  made_at    timestamptz not null default now(),
  kind       text not null check (kind in ('freeCancel', 'lateCancel', 'noCover')),
  driving    boolean not null default false,
  -- A free cancel's seat went to the waitlist at the cut-off: no undo.
  seat_taken boolean not null default false,
  unique (user_id, ride_date, leg)
);

create table public.pickup_check_ins (
  ride_id    text not null references public.rides (id) on delete cascade,
  stop_id    text not null,
  arrived_at timestamptz not null default now(),
  primary key (ride_id, stop_id)
);

-- The driver's latest mark per passenger; switchable until the trip starts.
create table public.passenger_outcomes (
  ride_id   text not null references public.rides (id) on delete cascade,
  user_id   uuid not null references public.profiles (id) on delete cascade,
  outcome   text not null check (outcome in ('waiting', 'pickedUp', 'noShow')),
  marked_at timestamptz not null default now(),
  primary key (ride_id, user_id)
);

-- Owed to the driver; shown and collected in 004. Integer EGP.
create table public.charges (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  ride_id    text not null references public.rides (id) on delete cascade,
  reason     text not null check (reason in ('lateCancel', 'noShow')),
  amount     smallint not null check (amount > 0),
  owed_to    uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  unique (user_id, ride_id, reason)
);

-- Input to the reliability % (FR-036, research R4); free cancels leave none.
create table public.reliability_events (
  user_id   uuid not null references public.profiles (id) on delete cascade,
  ride_id   text not null references public.rides (id) on delete cascade,
  ride_date date not null,
  kind      text not null check (kind in ('kept', 'noShow', 'lateCancel', 'lateCantDrive')),
  primary key (user_id, ride_id)
);

-- Every backup search and its result; cover_id null = no cover found.
create table public.backup_assignments (
  ride_id    text primary key references public.rides (id) on delete cascade,
  planned_id uuid references public.profiles (id) on delete set null,
  cover_id   uuid references public.profiles (id) on delete set null,
  step       text check (step in ('sameGroup', 'nearbyGroup', 'sameCompany', 'sameCommunity')),
  decided_at timestamptz not null default now()
);

-- In-app notices. params hold display values only (names, times, amounts,
-- stop ids) — never a home point or a non-driver's phone number.
create table public.notices (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  kind       text not null check (kind in (
               'driverConfirmed', 'driverUnconfirmed', 'delay', 'backupCover', 'noCover', 'driverArrived',
               'lateCancelCharged', 'noShowCharged', 'noShowWarning', 'removed', 'seatOffered', 'sosSent',
               'driverNoShow')),
  params     jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  read_at    timestamptz
);

create index notices_user_idx on public.notices (user_id, created_at desc);

create table public.trusted_contacts (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  name       text not null check (char_length(name) between 1 and 40),
  -- Egyptian mobile, E.164 (001 PhoneNumber).
  phone      text not null check (phone ~ '^\+201[0125][0-9]{8}$'),
  created_at timestamptz not null default now()
);

create table public.sos_alerts (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  ride_id     text references public.rides (id) on delete set null,
  at          timestamptz not null default now(),
  contact_ids uuid[] not null default '{}'
);

-- evening-cutoff idempotency: one row per (date, step) once that step ran.
create table public.cutoff_runs (
  run_date date not null,
  step     text not null check (step in ('settle', 'plan', 'waitlist', 'backup')),
  ran_at   timestamptz not null default now(),
  primary key (run_date, step)
);

-- Rules the database itself enforces ------------------------------------------

-- Absences written by people: made_at is the server clock and the kind follows
-- the 9 PM cut-off on the day before (mirror of _shared/attendance.ts
-- LIMITS.cutoff), so nobody can file a late cancel as free.
create function public.stamp_absence() returns trigger
  language plpgsql set search_path = public as $$
begin
  if auth.role() = 'service_role' then
    return new;
  end if;
  new.made_at := now();
  new.seat_taken := false;
  new.kind := case
    when (now() at time zone 'Africa/Cairo') >= (new.ride_date - 1) + time '21:00' then 'lateCancel'
    else 'freeCancel'
  end;
  return new;
end $$;

create trigger absences_stamp before insert on public.absences
  for each row execute function public.stamp_absence();

-- Up to 3 trusted contacts per person (research R10).
create function public.limit_trusted_contacts() returns trigger
  language plpgsql set search_path = public as $$
begin
  if (select count(*) from public.trusted_contacts where user_id = new.user_id) >= 3 then
    raise exception 'contactsFull' using errcode = 'check_violation';
  end if;
  return new;
end $$;

create trigger trusted_contacts_limit before insert on public.trusted_contacts
  for each row execute function public.limit_trusted_contacts();

-- Row Level Security: on for every table -----------------------------------------

alter table public.rides              enable row level security;
alter table public.ride_passengers    enable row level security;
alter table public.absences           enable row level security;
alter table public.pickup_check_ins   enable row level security;
alter table public.passenger_outcomes enable row level security;
alter table public.charges            enable row level security;
alter table public.reliability_events enable row level security;
alter table public.backup_assignments enable row level security;
alter table public.notices            enable row level security;
alter table public.trusted_contacts   enable row level security;
alter table public.sos_alerts         enable row level security;
alter table public.cutoff_runs        enable row level security;

create function public.ride_group(r text) returns uuid
  language sql stable security definer set search_path = public as $$
    select group_id from public.rides where id = r
  $$;

create function public.drives_ride(r text) returns boolean
  language sql stable security definer set search_path = public as $$
    select exists (select 1 from public.rides where id = r and driver_id = auth.uid())
  $$;

-- Members read their own group's rides and schedule. Ride state changes go
-- through commute-day (service role), which checks the caller is the driver.
create policy "members read their group's rides" on public.rides
  for select to authenticated using (public.is_group_member(group_id));

create policy "members read their group's passengers" on public.ride_passengers
  for select to authenticated using (public.is_group_member(public.ride_group(ride_id)));

create policy "members read their group's absences" on public.absences
  for select to authenticated using (public.is_group_member(group_id));

create policy "people cancel only their own trips" on public.absences
  for insert to authenticated
  with check (user_id = auth.uid() and public.is_group_member(group_id) and kind <> 'noCover');

create policy "members read their group's check-ins" on public.pickup_check_ins
  for select to authenticated using (public.is_group_member(public.ride_group(ride_id)));

create policy "drivers check in for rides they drive" on public.pickup_check_ins
  for insert to authenticated with check (public.drives_ride(ride_id));

-- The driver sees every mark on their ride; a passenger sees only their own.
create policy "driver or the passenger reads outcomes" on public.passenger_outcomes
  for select to authenticated using (user_id = auth.uid() or public.drives_ride(ride_id));

create policy "own charges and charges owed to me" on public.charges
  for select to authenticated using (user_id = auth.uid() or owed_to = auth.uid());

create policy "own reliability events" on public.reliability_events
  for select to authenticated using (user_id = auth.uid());

create policy "members read their group's backups" on public.backup_assignments
  for select to authenticated using (public.is_group_member(public.ride_group(ride_id)));

create policy "own notices" on public.notices
  for select to authenticated using (user_id = auth.uid());

create policy "mark own notices read" on public.notices
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- People may only mark notices read, never rewrite them.
revoke update on public.notices from authenticated;
grant update (read_at) on public.notices to authenticated;

create policy "own trusted contacts" on public.trusted_contacts
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "own sos alerts" on public.sos_alerts
  for select to authenticated using (user_id = auth.uid());

create policy "raise own sos alerts" on public.sos_alerts
  for insert to authenticated with check (user_id = auth.uid());

-- cutoff_runs: no policies — service role only.

-- Backup search input (service role only) ---------------------------------------
-- The ride, its group and every candidate driver as JSON in the shape of
-- supabase/functions/_shared/backup.ts. Reads drivers' home points, so it is
-- never granted to clients.

create function public.backup_input(p_ride text)
  returns jsonb language sql stable security definer set search_path = public, extensions as $$
  with r as (select * from rides where id = p_ride),
  g as (select groups.* from groups join r on r.group_id = groups.id),
  riders as (
    select p.* from ride_passengers rp join r on r.id = rp.ride_id join profiles p on p.id = rp.user_id
  ),
  member_json as (
    select m.user_id, jsonb_build_object(
      'id', m.user_id, 'role', m.role, 'legs', m.legs, 'isWoman', p.gender = 'female',
      'company', p.company, 'compound', p.compound, 'rating', p.rating, 'reliability', p.reliability,
      'privacy', p.privacy_preference, 'days', m.days) as j
    from group_members m join profiles p on p.id = m.user_id
  ),
  drivers as (
    -- Every driver with a commute profile except the absent planned driver,
    -- with the first step that reaches them.
    select c.user_id, c.home, c.work, c.departure, c.return_time, c.days, c.seats, p.*,
      case
        when exists (select 1 from group_members gm, g where gm.group_id = g.id and gm.user_id = c.user_id)
          then 'sameGroup'
        when exists (select 1 from group_members gm join groups og on og.id = gm.group_id, g
                     where gm.user_id = c.user_id and og.origin_area = g.origin_area
                       and og.destination_area = g.destination_area)
          then 'nearbyGroup'
        when p.company is not null and p.company in (select company from riders)
          then 'sameCompany'
        when p.compound is not null and p.compound in (select compound from riders)
          then 'sameCommunity'
      end as step
    from commute_profiles c join profiles p on p.id = c.user_id, r
    where c.seats is not null and p.role = 'driver' and c.user_id is distinct from r.planned_driver_id
  )
  select jsonb_build_object(
    'ride', (select jsonb_build_object(
        'date', ride_date, 'leg', leg,
        'passengers', coalesce((select jsonb_agg(jsonb_build_object('memberId', user_id, 'stopId', stop_id))
                                from ride_passengers where ride_id = r.id), '[]'::jsonb))
      from r),
    'group', (select jsonb_build_object(
        'id', g.id, 'destination', g.destination_area,
        'destinationPoint', array[st_y(g.destination::geometry), st_x(g.destination::geometry)],
        'pickupPoints', (select jsonb_agg(array[st_y(pp.point::geometry), st_x(pp.point::geometry)]
                                          order by pp.stop_order)
                         from group_pickup_points pp where pp.group_id = g.id),
        'going', to_char(g.going, 'HH24:MI'), 'ret', to_char(g.return_time, 'HH24:MI'),
        'days', g.days, 'detourMinutes', g.detour_minutes, 'womenOnly', g.women_only,
        'sameCompanyOnly', g.same_company_only, 'sameCompoundOnly', g.same_compound_only,
        'freeSeatsGoing', 0, 'freeSeatsReturn', 0,
        'members', (select coalesce(jsonb_agg(mj.j), '[]'::jsonb)
                    from member_json mj join group_members gm on gm.user_id = mj.user_id
                    where gm.group_id = g.id))
      from g),
    'candidates', coalesce((select jsonb_agg(jsonb_build_object(
        'member', jsonb_build_object(
          'id', d.user_id, 'role', 'driver', 'legs', array['going', 'ret'], 'isWoman', d.gender = 'female',
          'company', d.company, 'compound', d.compound, 'rating', d.rating, 'reliability', d.reliability,
          'privacy', d.privacy_preference, 'days', d.days),
        'step', d.step,
        'seeker', jsonb_build_object(
          'home', array[st_y(d.home::geometry), st_x(d.home::geometry)],
          'work', array[st_y(d.work::geometry), st_x(d.work::geometry)],
          'departure', to_char(d.departure, 'HH24:MI'), 'ret', to_char(d.return_time, 'HH24:MI'),
          'days', d.days),
        -- Their car's seats minus the riders already in it on that leg and day.
        'freeSeats', d.seats - coalesce((
            select count(*) from rides o join ride_passengers op on op.ride_id = o.id, r
            where o.driver_id = d.user_id and o.ride_date = r.ride_date and o.leg = r.leg), 0),
        -- Not away themselves, and not already driving another ride then.
        'available', not exists (
            select 1 from absences a, r
            where a.user_id = d.user_id and a.ride_date = r.ride_date and a.leg = r.leg)
          and not exists (
            select 1 from rides o, r
            where o.driver_id = d.user_id and o.ride_date = r.ride_date and o.leg = r.leg and o.id <> r.id)
      )) from drivers d where d.step is not null), '[]'::jsonb)
  )
$$;

revoke all on function public.backup_input(text) from public, anon, authenticated;
grant execute on function public.backup_input(text) to service_role;

-- A member's boarding stop on the going leg: the group stop nearest their
-- home. Returns only the stop id; the home point never leaves the database.
create function public.nearest_stop(p_group uuid, p_user uuid)
  returns uuid language sql stable security definer set search_path = public, extensions as $$
  select pp.id from group_pickup_points pp, commute_profiles c
  where pp.group_id = p_group and c.user_id = p_user
  order by st_distance(pp.point, c.home), pp.stop_order
  limit 1
$$;

revoke all on function public.nearest_stop(uuid, uuid) from public, anon, authenticated;
grant execute on function public.nearest_stop(uuid, uuid) to service_role;

-- Evening cut-off job (FR-033) ---------------------------------------------------
-- pg_cron runs in UTC and Egypt observes summer time, so the job fires at
-- 18:00 and 19:00 UTC; evening-cutoff runs only when it is 21:xx in Cairo and
-- is idempotent per (date, step). Needs the vault secrets 'project_url' and
-- 'service_role_key' (README, server section).

create extension if not exists pg_cron;
create extension if not exists pg_net with schema extensions;

select cron.schedule(
  'evening-cutoff',
  '0 18,19 * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
           || '/functions/v1/evening-cutoff',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key')),
    body := '{}'::jsonb
  );
  $$
);
