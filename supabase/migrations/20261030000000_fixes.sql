-- Goora feature 011: what the 002/003/005 migrations miss (specs/011-real-backend research D17).
--
-- 1. API grants. New tables are no longer exposed to the API roles without an
--    explicit grant (supabase/config.toml, [api]); none of the three
--    migrations granted anything. RLS still decides which rows; a grant only
--    lets the role reach the table at all. anon gets nothing.
-- 2. The six areas 006 added (lib/features/commute/domain/place.dart Area).
-- 3. The cost cap as an invariant on offered trips (constitution II, Law
--    87/2018): contribution <= floor(trip_cost / rider_seats), i.e. the riders
--    together never pay more than the trip costs. The maths stays in the
--    pricing twins; this only refuses a row that breaks the boundary.

-- 1. Grants ---------------------------------------------------------------------

revoke all on all tables in schema public from anon;
grant all on all tables in schema public to service_role;

-- 002
grant select, insert, update, delete on public.profiles         to authenticated;
grant select, insert, update, delete on public.commute_profiles to authenticated;
grant select                         on public.groups              to authenticated;
grant select                         on public.group_pickup_points to authenticated;
grant select, insert, delete         on public.group_members       to authenticated;
grant select, insert, update, delete on public.waitlist            to authenticated;

-- 003
grant select         on public.rides              to authenticated;
grant select         on public.ride_passengers    to authenticated;
grant select, insert on public.absences           to authenticated;
grant select, insert on public.pickup_check_ins   to authenticated;
grant select         on public.passenger_outcomes to authenticated;
grant select         on public.charges            to authenticated;
grant select         on public.reliability_events to authenticated;
grant select         on public.backup_assignments to authenticated;
grant select         on public.notices            to authenticated;
grant update (read_at) on public.notices          to authenticated;
grant select, insert, update, delete on public.trusted_contacts to authenticated;
grant select, insert on public.sos_alerts         to authenticated;
-- cutoff_runs: service role only.

-- 005: writes go through the market_* functions (20261030000400); clients read.
grant select on public.offered_trips to authenticated;
grant select on public.trip_requests to authenticated;
grant select on public.bookings      to authenticated;
grant select on public.driver_request_cards to authenticated;

-- 2. Nine areas -------------------------------------------------------------------

create function public.is_area(a text) returns boolean
  language sql immutable set search_path = public as $$
    select a in ('sheikhZayed', 'october', 'smartVillage', 'newCairo', 'nasrCity',
                 'heliopolis', 'obour', 'tenthOfRamadan', 'ismailia')
  $$;

alter table public.commute_profiles
  drop constraint commute_profiles_home_area_check,
  drop constraint commute_profiles_work_area_check,
  add constraint commute_profiles_home_area_check check (public.is_area(home_area)),
  add constraint commute_profiles_work_area_check check (public.is_area(work_area));

alter table public.offered_trips
  drop constraint offered_trips_origin_area_check,
  drop constraint offered_trips_destination_area_check,
  add constraint offered_trips_origin_area_check check (public.is_area(origin_area)),
  add constraint offered_trips_destination_area_check check (public.is_area(destination_area));

alter table public.trip_requests
  drop constraint trip_requests_origin_area_check,
  drop constraint trip_requests_destination_area_check,
  add constraint trip_requests_origin_area_check check (public.is_area(origin_area)),
  add constraint trip_requests_destination_area_check check (public.is_area(destination_area));

-- 3. Cost cap ------------------------------------------------------------------------

alter table public.offered_trips
  add constraint offered_trips_cost_cap check (contribution * rider_seats <= trip_cost);
