-- Goora feature 005: the seat marketplace (specs/005-seat-marketplace research R17).
-- Written, not executed: no Supabase project exists yet.
--
-- The rules (2 trips a day, the cost cap, the refund) run in
-- supabase/functions/_shared/ (pricing.ts, marketplace.ts); these tables only
-- hold what they decide. Money lives in the ledger partner, not here.
-- Privacy (constitution IV, FR-023): a driver-facing read never returns a
-- rider's name, photo or home. driver_request_cards below is the only way a
-- driver reads a request.

-- A trip a driver offers (published, or made by accepting a request) ---------------

create table public.offered_trips (
  id              uuid primary key default extensions.gen_random_uuid(),
  driver_id       uuid not null references public.profiles (id) on delete cascade,
  leg             text not null check (leg in ('going', 'ret')),
  origin_area     text not null check (origin_area in ('sheikhZayed', 'october', 'smartVillage')),
  destination_area text not null check (destination_area in ('sheikhZayed', 'october', 'smartVillage')),
  trip_date       date not null,
  departure       time not null,
  duration_minutes smallint not null default 40,
  seats           smallint not null check (seats between 1 and 4),
  -- The price basis (research R6): published = seats; from a request = the request's.
  rider_seats     smallint not null check (rider_seats between 1 and 4 and seats <= rider_seats),
  trip_cost       integer not null check (trip_cost > 0),
  -- Inside range(trip_cost, rider_seats), 2 EGP steps (FR-015). Never typed by a client.
  contribution    integer not null check (contribution > 0 and contribution % 2 = 0),
  repeat          text not null check (repeat in ('once', 'daily')),
  -- A public pickup point, never a home.
  pickup          jsonb not null,
  status          text not null default 'open'
                    check (status in ('open', 'full', 'departed', 'done', 'cancelled', 'grouped')),
  group_id        uuid references public.groups (id) on delete set null,
  origin          text not null default 'published' check (origin in ('published', 'fromRequest')),
  -- Cancelled with at least one booking still counts on the driver's day (research R5).
  cancelled_with_riders boolean not null default false,
  created_at      timestamptz not null default now()
);

create index offered_trips_driver_day on public.offered_trips (driver_id, trip_date);
create index offered_trips_route_day on public.offered_trips (origin_area, destination_area, trip_date)
  where status in ('open', 'full');

-- A trip a rider posts for a driver to accept ---------------------------------------

create table public.trip_requests (
  id              uuid primary key default extensions.gen_random_uuid(),
  rider_id        uuid not null references public.profiles (id) on delete cascade,
  leg             text not null check (leg in ('going', 'ret')),
  origin_area     text not null check (origin_area in ('sheikhZayed', 'october', 'smartVillage')),
  destination_area text not null check (destination_area in ('sheikhZayed', 'october', 'smartVillage')),
  trip_date       date not null,
  departure       time not null,
  repeat          text not null check (repeat in ('once', 'daily')),
  pickup          jsonb not null,
  -- Quoted at posting and fixed from then on (FR-022).
  contribution    integer not null check (contribution > 0),
  fee             integer not null default 0 check (fee >= 0),
  status          text not null default 'posted'
                    check (status in ('posted', 'accepted', 'withdrawn', 'cancelled', 'expired')),
  accepted_by     uuid references public.profiles (id) on delete set null,
  trip_ref        text,
  created_at      timestamptz not null default now()
);

create index trip_requests_open on public.trip_requests (origin_area, destination_area, trip_date)
  where status = 'posted';

-- One rider in one seat on one leg-date ---------------------------------------------

create table public.bookings (
  id              uuid primary key default extensions.gen_random_uuid(),
  rider_id        uuid not null references public.profiles (id) on delete cascade,
  -- Exactly one source: a group's free seat, an offered trip, or an accepted request.
  group_id        uuid references public.groups (id) on delete set null,
  offered_trip_id uuid references public.offered_trips (id) on delete set null,
  request_id      uuid references public.trip_requests (id) on delete set null,
  trip_date       date not null,
  leg             text not null check (leg in ('going', 'ret')),
  -- The 003 ride id once the trip is a group's, else 'offer:<id>' (research R10).
  ride_id         text not null,
  contribution    integer not null check (contribution > 0),
  fee             integer not null default 0 check (fee >= 0),
  paid_by         text not null check (paid_by in ('wallet', 'plan', 'cash')),
  paid            integer not null default 0 check (paid >= 0),
  booked_at       timestamptz not null default now(),
  -- A subscriber's own seat is never reclaimed (FR-025).
  is_subscriber   boolean not null default false,
  status          text not null default 'booked'
                    check (status in ('booked', 'done', 'cancelled', 'reclaimed', 'refunded')),
  check (num_nonnulls(group_id, offered_trip_id, request_id) = 1),
  -- One booking per rider per leg-date (FR-007).
  unique (rider_id, trip_date, leg) deferrable initially deferred
);

create index bookings_trip on public.bookings (offered_trip_id) where status in ('booked', 'done');

-- Row-level security --------------------------------------------------------------

alter table public.offered_trips enable row level security;
alter table public.trip_requests enable row level security;
alter table public.bookings      enable row level security;

create policy "drivers manage their own trips" on public.offered_trips
for all to authenticated
using (driver_id = auth.uid()) with check (driver_id = auth.uid());

-- Riders see open and full offers on any route (Empty seats); the driver's own id is public, the home never is.
create policy "riders read open offers" on public.offered_trips
for select to authenticated using (status in ('open', 'full'));

create policy "riders manage their own requests" on public.trip_requests
for all to authenticated
using (rider_id = auth.uid()) with check (rider_id = auth.uid());

create policy "riders read and cancel their own bookings" on public.bookings
for select to authenticated using (rider_id = auth.uid());

create policy "drivers read bookings on their trips" on public.bookings
for select to authenticated using (
  exists (select 1 from public.offered_trips t where t.id = offered_trip_id and t.driver_id = auth.uid())
);

-- What a driver may read of a request (FR-023, SC-004) -----------------------------
-- No name, no photo, no home: only whether the rider is a woman, their rating,
-- the public pickup point and the fixed price.

create view public.driver_request_cards
with (security_invoker = false) as
select
  r.id,
  r.leg,
  r.origin_area,
  r.destination_area,
  r.trip_date,
  r.departure,
  r.repeat,
  r.pickup,
  r.contribution,
  p.gender = 'female' as is_woman,
  p.rating
from public.trip_requests r
join public.profiles p on p.id = r.rider_id
where r.status = 'posted' and r.rider_id <> auth.uid();

revoke all on public.driver_request_cards from public, anon;
grant select on public.driver_request_cards to authenticated;
