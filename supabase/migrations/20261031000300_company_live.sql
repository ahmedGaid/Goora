-- Goora feature 013: the company side in live mode (specs/013-live-parity research
-- D11, D12). Whole EGP. HR sees totals only, and a total built from fewer than 5
-- people is withheld, never shown as a small number (010 R9, constitution IV).
-- Goora-staff writes are service-role functions only; the app is not a staff tool.

-- Leg kilometres for the CO2 estimate (010 R7). Estimates: Cairo <-> Ismailia 123 km
-- (006 research), Sheikh Zayed / October <-> Smart Village 13 km (010 P7). Pairs are
-- stored once, alphabetical; a pair that is not listed counts as 0 km.
create table public.corridor_legs (
  origin_area      text not null check (public.is_area(origin_area)),
  destination_area text not null check (public.is_area(destination_area)),
  km               integer not null check (km > 0),
  primary key (origin_area, destination_area),
  check (origin_area < destination_area)
);
insert into public.corridor_legs (origin_area, destination_area, km) values
  ('heliopolis', 'ismailia', 123), ('ismailia', 'nasrCity', 123), ('ismailia', 'newCairo', 123),
  ('ismailia', 'obour', 123), ('ismailia', 'tenthOfRamadan', 123),
  ('october', 'smartVillage', 13), ('sheikhZayed', 'smartVillage', 13);
alter table public.corridor_legs enable row level security;
create policy "corridor legs are listed" on public.corridor_legs for select to authenticated using (true);
grant select on public.corridor_legs to authenticated;
grant all on public.corridor_legs to service_role;

-- US3 (013 D11): what the device needs to work out an employee's coverage: when the
-- company was approved and ended, and the invoices whose suspension day has come, as
-- dates only. For the company's HR contact and its enrolled employees (an employee cannot
-- read the company row). The device feeds it to CompanyRules.activeWindows; no invoice
-- amount, reference or bank detail leaves.
create function public.company_suspensions(p_company uuid) returns jsonb
  language plpgsql stable security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  now_c timestamp := now() at time zone 'Africa/Cairo';
begin
  if not (is_hr_of(p_company)
          or exists (select 1 from enrollments e where e.company_id = p_company and e.person_id = me)) then
    raise exception 'refused:notHrContact' using errcode = 'P0001';
  end if;
  return jsonb_build_object(
    'approvedAt', (select c.approved_at from companies c where c.id = p_company),
    'endedAt', (select c.ended_at from companies c where c.id = p_company),
    'invoices', coalesce((
      select jsonb_agg(jsonb_build_object('dueOn', i.due_on, 'paidAt', i.paid_at) order by i.due_on)
      from invoices i
      where i.company_id = p_company and (i.due_on + 8)::timestamp <= now_c), '[]'::jsonb));
end $$;

-- Days Sunday-Thursday in a month, counted up to today while the month is running.
create function public.workdays_in(p_month text) returns integer
  language sql stable set search_path = public as $$
    select count(*)::integer
    from generate_series(
      (p_month || '-01')::date,
      least(((p_month || '-01')::date + interval '1 month' - interval '1 day')::date,
            case when p_month = to_char(cairo_today(), 'YYYY-MM') then cairo_today()
                 else ((p_month || '-01')::date + interval '1 month' - interval '1 day')::date end),
      interval '1 day') d
    where extract(isodow from d) not in (5, 6)
  $$;

-- US5: replaces the 011 dashboard. Same keys plus moneySaved, co2Kg, parkingPerDay
-- and routeGaps; each is withheld below 5 people.
create or replace function public.company_dashboard(p_company uuid, p_month text) returns jsonb
  language plpgsql stable security definer set search_path = public as $$
declare
  k constant integer := 5;
  co2_kg_per_km constant numeric := 0.1645;
  m_start date := (p_month || '-01')::date;
  m_end date := ((p_month || '-01')::date + interval '1 month')::date;
  enrolled integer;
  active integer;
  grps integer;
  trips integer;
  rider_people integer;
  going_people integer;
  going_trips integer;
  saved integer;
  km integer;
  workdays integer := workdays_in(p_month);
  gaps jsonb;
begin
  perform company_must_be_hr(p_company);
  select count(*) into enrolled from company_month_people(p_company, p_month);
  -- Riders or drivers on a group ride in the month, or a one-off seat.
  with people as (select pm as person_id from company_month_people(p_company, p_month) pm),
  legs as (
    select r.id as ride, pe.person_id from rides r
      join ride_passengers rp on rp.ride_id = r.id join people pe on pe.person_id = rp.user_id
      where r.ride_date >= m_start and r.ride_date < m_end and r.ended_at is not null
    union
    select r.id, pe.person_id from rides r join people pe on pe.person_id = r.driver_id
      where r.ride_date >= m_start and r.ride_date < m_end and r.ended_at is not null
    union
    select b.ride_id, pe.person_id from bookings b join people pe on pe.person_id = b.rider_id
      where b.trip_date >= m_start and b.trip_date < m_end and b.status = 'done'
  )
  select count(distinct person_id), count(distinct ride) into active, trips from legs;
  select count(distinct gm.group_id) into grps from group_members gm
    where gm.user_id in (select * from company_month_people(p_company, p_month));

  -- Rider legs: what driving alone would cost minus the share paid, and the km (010 R7).
  with people as (select pm as person_id from company_month_people(p_company, p_month) pm),
  rider_legs as (
    select rp.user_id as person_id, r.leg,
           coalesce((g.card ->> 'tripCost')::integer, g.price * 3) - g.price as saved_egp,
           coalesce(cl.km, 0) as leg_km
    from rides r
    join ride_passengers rp on rp.ride_id = r.id join groups g on g.id = r.group_id
    left join corridor_legs cl on cl.origin_area = least(g.origin_area, g.destination_area)
                              and cl.destination_area = greatest(g.origin_area, g.destination_area)
    where rp.user_id in (select person_id from people)
      and r.ride_date >= m_start and r.ride_date < m_end and r.ended_at is not null
      and not exists (select 1 from passenger_outcomes po
                      where po.ride_id = r.id and po.user_id = rp.user_id and po.outcome = 'noShow')
    union all
    select b.rider_id, b.leg, t.trip_cost - b.contribution, coalesce(cl.km, 0)
    from bookings b join offered_trips t on t.id = b.offered_trip_id
    left join corridor_legs cl on cl.origin_area = least(t.origin_area, t.destination_area)
                              and cl.destination_area = greatest(t.origin_area, t.destination_area)
    where b.rider_id in (select person_id from people)
      and b.trip_date >= m_start and b.trip_date < m_end and b.status = 'done'
  )
  select count(distinct person_id), count(distinct person_id) filter (where leg = 'going'),
         count(*) filter (where leg = 'going'), coalesce(sum(saved_egp), 0), coalesce(sum(leg_km), 0)
    into rider_people, going_people, going_trips, saved, km
  from rider_legs;

  -- Home areas with 5 or more employees who set a commute and are in no group.
  select coalesce(jsonb_agg(jsonb_build_object('area', area, 'count', n) order by n desc, area), '[]'::jsonb)
    into gaps
  from (
    select cp.home_area as area, count(*) as n
    from commute_profiles cp
    where cp.user_id in (select * from company_month_people(p_company, p_month))
      and not exists (select 1 from group_members gm where gm.user_id = cp.user_id)
    group by cp.home_area
    having count(*) >= k
  ) g;

  return jsonb_build_object(
    'month', p_month,
    'enrolled', case when enrolled >= k then enrolled end,
    'active', case when active >= k then active end,
    -- Rate and trips are built from the active people: withheld with them.
    'carpoolRatePct', case when active >= k and enrolled >= k then (active * 100) / enrolled end,
    'tripsShared', case when active >= k then trips end,
    'groups', case when active >= k then grps end,
    'moneySaved', case when rider_people >= k then saved end,
    'co2Kg', case when rider_people >= k then round(km * co2_kg_per_km)::integer end,
    'parkingPerDay', case when going_people >= k and workdays > 0 then going_trips / workdays end,
    'routeGaps', gaps);
end $$;

-- Settings -> Reset: the rows the caller owns, and no others. A company they registered
-- goes only while Goora has not approved it (nothing is billed yet).
create function public.company_reset_mine() returns void
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
begin
  delete from enrollments where person_id = me;
  delete from hr_consents where person_id = me;
  delete from companies where hr_contact_id = me and status = 'pending';
end $$;

-- Goora staff (013 D12). service_role only: an ordinary signed-in user cannot call them.
create function public.staff_company_approve(p_company uuid) returns void
  language plpgsql security definer set search_path = public as $$
begin
  update companies set status = 'active', approved_at = cairo_wall(), contract_start = coalesce(contract_start, cairo_today())
  where id = p_company and status = 'pending';
  if not found then raise exception 'refused:notPending' using errcode = 'P0001'; end if;
  perform company_log_line(p_company, 'goora', 'approved');
end $$;

create function public.staff_invoice_mark_paid(p_invoice uuid, p_bank_ref text) returns void
  language plpgsql security definer set search_path = public as $$
declare
  inv invoices;
begin
  update invoices set paid_at = cairo_wall(), bank_ref = p_bank_ref where id = p_invoice and paid_at is null
  returning * into inv;
  if inv is null then raise exception 'refused:notUnpaid' using errcode = 'P0001'; end if;
  perform company_log_line(inv.company_id, 'goora', 'invoicePaid', inv.month);
end $$;

create function public.staff_company_set_hr(p_company uuid, p_person uuid) returns void
  language plpgsql security definer set search_path = public as $$
begin
  update companies set hr_contact_id = p_person where id = p_company;
  if not found then raise exception 'refused:noSuchCompany' using errcode = 'P0001'; end if;
  perform company_log_line(p_company, 'goora', 'hrContactChanged');
end $$;

create function public.staff_company_end(p_company uuid) returns void
  language plpgsql security definer set search_path = public as $$
declare
  stamp text := cairo_wall();
begin
  update companies set status = 'ended', ended_at = stamp, contract_end = cairo_today()
  where id = p_company and status in ('active', 'suspended');
  if not found then raise exception 'refused:notRunning' using errcode = 'P0001'; end if;
  update enrollments set left_at = stamp, left_why = 'contractEnded' where company_id = p_company and left_at is null;
  perform company_log_line(p_company, 'goora', 'contractEnded');
end $$;

revoke all on function public.company_suspensions(uuid), public.company_reset_mine(), public.workdays_in(text)
  from public, anon;
grant execute on function public.company_suspensions(uuid), public.company_reset_mine() to authenticated;
revoke all on function public.workdays_in(text) from authenticated;
revoke all on function public.staff_company_approve(uuid), public.staff_invoice_mark_paid(uuid, text),
  public.staff_company_set_hr(uuid, uuid), public.staff_company_end(uuid) from public, anon, authenticated;
grant execute on function public.staff_company_approve(uuid), public.staff_invoice_mark_paid(uuid, text),
  public.staff_company_set_hr(uuid, uuid), public.staff_company_end(uuid) to service_role;
