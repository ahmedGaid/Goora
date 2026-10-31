-- Goora feature 013: the wallet's fee state is decided in the database
-- (specs/013-live-parity research D2–D5, D7). Whole EGP. Law 87/2018: nothing
-- here records money a driver earns; the driver's share is a status and a
-- number shown, never credited.
--
-- wallet_state() is the SQL twin of FakeWalletRepository._riderTrips: it walks the
-- caller's finished trips in order and answers the fee-free trial, what is
-- owed, when it fell due and whether it is overdue. The pure rules below are
-- SQL twins of PricingService, DirectPay and FeeBalancePolicy; the same JSON
-- vectors run on them (supabase/tests/60_vectors.test.sql, generated).

-- Pure rule twins ------------------------------------------------------------------------

create function public.pay_equal_share(p_cost integer, p_seats integer) returns integer
  language plpgsql immutable as $$
begin
  if p_seats < 1 then raise exception 'riderSeats must be >= 1'; end if;
  return p_cost / p_seats;
end $$;

-- ±20% of the suggestion in 2 EGP steps, never above an equal share of the cost.
create function public.pay_range(p_cost integer, p_riders integer,
                                 out o_min integer, out o_suggested integer, out o_max integer)
  language plpgsql immutable as $$
declare
  s integer;
begin
  s := floor(p_cost::numeric / ((p_riders + 1) * 2) + 0.5)::integer * 2;
  o_suggested := s;
  o_min := ((s * 80 + 199) / 200) * 2;
  o_max := least(((s * 120) / 200) * 2, (p_cost / (p_riders * 2)) * 2);
end $$;

-- The contribution rounded to a multiple of 5 inside the range; null when none fits.
create function public.pay_cash_amount(p_contribution integer, p_cost integer, p_seats integer) returns integer
  language plpgsql immutable as $$
declare
  down integer := p_contribution - (p_contribution % 5);
  up integer := (p_contribution - (p_contribution % 5)) + 5;
  r record;
  cash integer;
begin
  select * into r from public.pay_range(p_cost, p_seats);
  cash := case when p_contribution % 5 <= 2 then down else up end;
  if cash > r.o_max then cash := down; end if;
  if cash < r.o_min then cash := up; end if;
  if cash = 0 or cash < r.o_min or cash > r.o_max then return null; end if;
  return cash;
end $$;

create function public.direct_pay_share(p_contribution integer, p_method text, p_cost integer, p_seats integer)
  returns integer language sql immutable as $$
    select case when p_method = 'cash'
                then coalesce(public.pay_cash_amount(p_contribution, p_cost, p_seats), p_contribution)
                else p_contribution end
  $$;

-- 10% of the contribution, halves up, trimmed so share + fee never passes the equal share.
create function public.direct_pay_fee(p_contribution integer, p_share integer, p_cost integer, p_seats integer,
                                      p_fee_free boolean) returns integer
  language plpgsql immutable as $$
declare
  base integer := (p_contribution * 10 + 50) / 100;
  room integer;
begin
  if p_fee_free then return 0; end if;
  room := public.pay_equal_share(p_cost, p_seats) - p_share;
  return greatest(least(base, room), 0);
end $$;

-- 8:59:59 PM the evening before is free; 9:00 PM is late.
create function public.is_late(p_ride_date date, p_at timestamp) returns boolean
  language sql immutable as $$ select p_at >= (p_ride_date - 1) + time '21:00' $$;

create function public.fee_is_overdue(p_due date, p_today date) returns boolean
  language sql immutable as $$ select p_due is not null and (p_today - p_due) >= 3 $$;

create function public.fee_use_bundle(p_fee integer, p_left integer) returns boolean
  language sql immutable as $$ select p_fee > 0 and p_left > 0 $$;

-- When the current unpaid run fell due: 150 owed the same day, or 30 or more
-- owed at a month end on the 1st after it; whichever comes first. p_days is
-- ascending [{date, balance}] of end-of-day readings (below zero = owed).
create function public.fee_due_date(p_days jsonb, p_today date) returns date
  language plpgsql immutable as $$
declare
  ds date[] := '{}';
  bs integer[] := '{}';
  n integer := 0;
  r record;
  i integer;
  start_i integer := 1;
  due150 date;
  due_month date;
  month_start date;
  next_m date;
  at_end integer;
begin
  for r in
    select (e ->> 'date')::date as d, (e ->> 'balance')::integer as b
    from jsonb_array_elements(p_days) e
    where (e ->> 'date')::date <= p_today
    order by 1
  loop
    n := n + 1; ds[n] := r.d; bs[n] := r.b;
  end loop;
  if n = 0 or bs[n] >= 0 then return null; end if;
  for i in 1..n loop
    if bs[i] >= 0 then start_i := i + 1; end if;
  end loop;
  for i in start_i..n loop
    if -bs[i] >= 150 then due150 := ds[i]; exit; end if;
  end loop;
  month_start := date_trunc('month', ds[start_i])::date;
  loop
    next_m := (month_start + interval '1 month')::date;
    exit when next_m > p_today;
    at_end := null;
    for i in reverse n..start_i loop
      if ds[i] <= next_m - 1 then at_end := bs[i]; exit; end if;
    end loop;
    if -coalesce(at_end, 0) >= 30 then due_month := next_m; exit; end if;
    month_start := next_m;
  end loop;
  if due150 is null then return due_month; end if;
  if due_month is null then return due150; end if;
  return least(due150, due_month);
end $$;

-- Who pays which fee ---------------------------------------------------------------------

-- The money-deciding fields are the server's, not the owner's: the owner picks a
-- method and a handle, and "since" starts the day the method is first chosen
-- (the fake's _markSince). The owner cannot move it, nor delete the row to reset it.
create function public.payment_settings_since() returns trigger
  language plpgsql set search_path = public as $$
begin
  if new.method is not null and new.since_date is null then new.since_date := public.cairo_today(); end if;
  return new;
end $$;
create trigger payment_settings_since before insert or update on public.payment_settings
  for each row execute function public.payment_settings_since();

revoke insert, update, delete on public.payment_settings from authenticated;
grant insert (person_id, method, instapay_handle), update (method, instapay_handle)
  on public.payment_settings to authenticated;

-- What a company plan made fee-free until it ended (010 R8: trips taken while
-- covered stay fee-free). The open company plan is the `plans` row itself.
create table public.plan_cover_windows (
  person_id uuid not null references public.profiles (id) on delete cascade,
  from_wall text not null,
  to_wall   text not null,
  primary key (person_id, from_wall)
);
alter table public.plan_cover_windows enable row level security;
create policy "own cover windows" on public.plan_cover_windows
  for select to authenticated using (person_id = auth.uid());
grant select on public.plan_cover_windows to authenticated;
grant all on public.plan_cover_windows to service_role;

create or replace function public.wallet_end_company_plan() returns void
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  p paused_plans;
begin
  insert into plan_cover_windows (person_id, from_wall, to_wall)
  select me, start_wall, cairo_wall() from plans where person_id = me and type = 'company'
  on conflict do nothing;
  select * into p from paused_plans where person_id = me;
  if p is null then
    delete from plans where person_id = me and type = 'company';
  else
    update plans set type = p.type, price = p.price, status = 'active',
      until_date = cairo_today() + p.days_left where person_id = me;
    delete from paused_plans where person_id = me;
  end if;
end $$;

-- A company is suspended from the day after the 7 days of grace that follow an
-- invoice's due date, until that invoice is paid (010 FR-014).
create function public.company_suspended_at(p_person uuid, p_at timestamp) returns boolean
  language sql stable security definer set search_path = public as $$
    select exists (
      select 1
      from enrollments e join invoices i on i.company_id = e.company_id
      where e.person_id = p_person
        and e.enrolled_at::timestamp <= p_at
        and (e.left_at is null or p_at < e.left_at::timestamp)
        and (i.due_on + 8)::timestamp <= p_at
        and (i.paid_at is null or p_at < i.paid_at::timestamp))
  $$;

-- Was a trip at p_at already fee-free: a paid personal plan, the company plan
-- (unless suspended), or a company window that has since ended.
create function public.wallet_covered_at(p_person uuid, p_at timestamp) returns boolean
  language sql stable security definer set search_path = public as $$
    select exists (
      select 1 from plans pl
      where pl.person_id = p_person
        and ((pl.type in ('monthly', 'yearly') and pl.status = 'active'
              and pl.start_wall::timestamp <= p_at and pl.until_date is not null and p_at::date <= pl.until_date)
          or (pl.type = 'company' and pl.start_wall::timestamp <= p_at
              and not public.company_suspended_at(p_person, p_at))))
    or exists (
      select 1 from plan_cover_windows w
      where w.person_id = p_person and w.from_wall::timestamp <= p_at and p_at < w.to_wall::timestamp
        and not public.company_suspended_at(p_person, p_at))
  $$;

-- The fee state ----------------------------------------------------------------------------

create function public.wallet_state() returns jsonb
  language plpgsql stable security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  today date := cairo_today();
  now_c timestamp := now() at time zone 'Africa/Cairo';
  ps payment_settings;
  v_method text;
  v_since date;
  v_from date;
  v_no_trial boolean;
  v_no_trial_from timestamp;
  v_purchases date[];
  v_ledger integer := wallet_balance_of(me);
  v_entries jsonb := '[]'::jsonb;
  v_debits integer := 0;
  v_trial_done integer := 0;
  v_strikes integer := 0;
  v_bundle_used integer := 0;
  v_bundle_left integer;
  it record;
  a record;
  v_free boolean;
  v_trial boolean;
  v_share integer;
  v_fee integer;
  v_series jsonb;
  v_due date;
begin
  select * into ps from payment_settings where person_id = me;
  select coalesce(array_agg((bought_at at time zone 'Africa/Cairo')::date order by bought_at), '{}')
    into v_purchases from bundles where person_id = me;
  v_since := coalesce(ps.since_date, (select start_wall::timestamp::date from plans where person_id = me));
  v_method := coalesce(ps.method, 'cash');
  v_no_trial := coalesce(ps.no_trial, false);
  v_no_trial_from := ps.no_trial_from::timestamp;
  -- Without a "since" there are no derived trips (an empty window), but what the
  -- ledger owes still falls due and goes overdue, as in the fake.
  v_from := case when v_since is null then today + 1 else greatest(v_since, today - 60) end;

  for it in
    with paid_at_booking as (
      select ride_id from wallet_entries where person_id = me and kind = 'seatBooked' and ride_id is not null
    ), trial_one_offs as (
      select distinct b.ride_id from bookings b
      where b.rider_id = me and b.paid_by = 'cash' and b.status in ('booked', 'done')
        and b.ride_id not in (select ride_id from paid_at_booking)
    ), items as (
      select r.ride_date as d, case r.leg when 'going' then 0 else 1 end as leg_i, r.leg, r.id as ride_id,
             0 as is_charge, null::uuid as charge_id, null::text as reason, 0 as charge_amount,
             g.price::integer as contribution,
             coalesce((g.card ->> 'tripCost')::integer, g.price * 3) as trip_cost,
             coalesce((g.card ->> 'riderSeats')::integer, 3) as seats,
             r.ride_date + case r.leg when 'going' then g.going else g.return_time end as at_ts
      from reliability_events e
      join rides r on r.id = e.ride_id join groups g on g.id = r.group_id
      where e.user_id = me and e.kind = 'kept' and r.driver_id is distinct from me
        and r.ride_date between v_from and today
        and r.id not in (select ride_id from paid_at_booking)
        and r.id not in (select ride_id from trial_one_offs)
      union all
      select r.ride_date, case r.leg when 'going' then 0 else 1 end, r.leg, r.id,
             1, c.id, c.reason, c.amount::integer,
             g.price::integer,
             coalesce((g.card ->> 'tripCost')::integer, g.price * 3),
             coalesce((g.card ->> 'riderSeats')::integer, 3),
             r.ride_date + case r.leg when 'going' then g.going else g.return_time end
      from charges c
      join rides r on r.id = c.ride_id join groups g on g.id = r.group_id
      where c.user_id = me and r.ride_date between v_from and today
        and r.id not in (select ride_id from paid_at_booking)
      union all
      select b.trip_date, case b.leg when 'going' then 0 else 1 end, b.leg, b.ride_id,
             0, null::uuid, null::text, 0,
             b.contribution, t.trip_cost, t.rider_seats::integer, b.trip_date + t.departure
      from bookings b join offered_trips t on t.id = b.offered_trip_id
      where b.rider_id = me and b.paid_by = 'cash' and b.status in ('booked', 'done')
        and b.ride_id not in (select ride_id from paid_at_booking)
        and b.trip_date between v_from and today
        and (b.status = 'done'
             or b.trip_date + t.departure + make_interval(mins => coalesce(t.duration_minutes, 40)) <= now_c)
    )
    select * from items order by d, leg_i, is_charge, ride_id
  loop
    if it.is_charge = 1 then
      v_entries := v_entries || jsonb_build_object(
        'id', 'charge:' || it.charge_id, 'kind', case it.reason when 'lateCancel' then 'lateCancelCharge' else 'tripDeduction' end,
        'amount', 0, 'fee', 0, 'date', it.d, 'rideId', it.ride_id, 'shareToDriver', it.charge_amount, 'leg', it.leg);
      continue;
    end if;
    v_free := wallet_covered_at(me, it.at_ts);
    v_share := direct_pay_share(it.contribution, v_method, it.trip_cost, it.seats);
    v_trial := not v_free and not v_no_trial and (v_no_trial_from is null or it.at_ts < v_no_trial_from)
               and v_trial_done < 5 and v_strikes < 2;
    if v_trial then
      v_trial_done := v_trial_done + 1;
      v_strikes := v_strikes + (select count(*)::integer from share_marks m
                                where m.ride_id = it.ride_id and m.rider_id = me and m.outcome = 'didNotPay');
      v_entries := v_entries || jsonb_build_object(
        'id', 'cash:' || it.ride_id, 'kind', 'cashTrip', 'amount', 0, 'fee', 0, 'date', it.d,
        'rideId', it.ride_id, 'shareToDriver', v_share, 'leg', it.leg);
    else
      v_fee := direct_pay_fee(it.contribution, v_share, it.trip_cost, it.seats, v_free);
      v_bundle_left := 20 * (select count(*)::integer from unnest(v_purchases) p where p <= it.d) - v_bundle_used;
      if fee_use_bundle(v_fee, v_bundle_left) then
        v_bundle_used := v_bundle_used + 1;
        v_entries := v_entries || jsonb_build_object(
          'id', 'bundle-trip:' || it.ride_id, 'kind', 'bundleTrip', 'amount', 0, 'fee', 0, 'date', it.d,
          'rideId', it.ride_id, 'shareToDriver', v_share, 'leg', it.leg);
      else
        v_debits := v_debits + v_fee;
        v_entries := v_entries || jsonb_build_object(
          'id', 'trip:' || it.ride_id, 'kind', 'trip', 'amount', v_fee, 'fee', v_fee, 'date', it.d,
          'rideId', it.ride_id, 'shareToDriver', v_share, 'leg', it.leg);
      end if;
    end if;
  end loop;

  for a in
    select ab.ride_date, ab.leg from absences ab
    where ab.user_id = me and ab.kind = 'freeCancel' and ab.ride_date between v_from and today
    order by ab.ride_date, ab.leg
  loop
    v_entries := v_entries || jsonb_build_object(
      'id', 'absence:' || me || ':' || a.ride_date || ':' || a.leg, 'kind', 'freeCancelZero', 'amount', 0,
      'fee', 0, 'date', a.ride_date, 'rideId', null, 'shareToDriver', 0, 'leg', a.leg);
  end loop;

  -- End-of-day readings of the whole ledger plus the derived fees, for the due date.
  select coalesce(jsonb_agg(jsonb_build_object('date', d, 'balance', running) order by d), '[]'::jsonb)
    into v_series
  from (
    select d, sum(day_total) over (order by d) as running
    from (
      select d, sum(amt) as day_total
      from (
        select entry_date as d, delta as amt from wallet_entries where person_id = me
        union all
        select (e ->> 'date')::date, -(e ->> 'amount')::integer
        from jsonb_array_elements(v_entries) e where e ->> 'kind' = 'trip'
      ) x
      group by d
    ) y
  ) z;
  v_due := fee_due_date(v_series, today);

  return jsonb_build_object(
    'balance', v_ledger - v_debits,
    'debits', v_debits,
    'cashTrial', case when v_since is null or v_no_trial or v_no_trial_from is not null then null
                      else jsonb_build_object('tripsDone', v_trial_done, 'strikes', v_strikes) end,
    'bundleLeft', 20 * cardinality(v_purchases) - v_bundle_used,
    'feeDue', v_due,
    'feeOverdue', fee_is_overdue(v_due, today),
    'feesThisMonth', coalesce((select sum((e ->> 'fee')::integer) from jsonb_array_elements(v_entries) e
                               where e ->> 'kind' = 'trip'
                                 and date_trunc('month', (e ->> 'date')::date) = date_trunc('month', today)), 0),
    'entries', v_entries);
end $$;

-- 008 FR-005 (013 D5): an overdue balance blocks new bookings, posts and joins.
create function public.wallet_assert_open() returns void
  language plpgsql stable security definer set search_path = public as $$
declare
  s jsonb := wallet_state();
begin
  if (s ->> 'feeOverdue')::boolean then
    raise exception 'refused:feeOverdue:%', greatest(0, -(s ->> 'balance')::integer) using errcode = 'P0001';
  end if;
end $$;

-- Shares (007): first name of the other party only, never a surname, phone or home. ------------

create function public.wallet_share_rows(p_role text)
  returns table (ride_id text, rider_id uuid, driver_id uuid, other_first_name text, method text, amount integer,
                 trip_end text, mark_outcome text, marked_at text, claimed_at text, reversed_once boolean)
  language plpgsql stable security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  today date := cairo_today();
  now_c timestamp := now() at time zone 'Africa/Cairo';
  v_from date := cairo_today() - 60;
begin
  if p_role not in ('rider', 'driver') then raise exception 'refused:role' using errcode = 'P0001'; end if;
  return query
  with src as (
    -- group trips (a recorded end, else the planned arrival + 1 h as an estimate)
    select r.id as s_ride, e.user_id as s_rider, r.driver_id as s_driver, 0 as s_charge,
           g.price::integer as s_contribution,
           coalesce((g.card ->> 'tripCost')::integer, g.price * 3) as s_cost,
           coalesce((g.card ->> 'riderSeats')::integer, 3) as s_seats,
           coalesce(r.ended_at at time zone 'Africa/Cairo',
                    r.ride_date + case r.leg when 'going' then coalesce(g.arrival, g.going + interval '1 hour')
                                             else g.return_time + interval '1 hour' end) as s_end,
           r.ride_date as s_date
    from reliability_events e join rides r on r.id = e.ride_id join groups g on g.id = r.group_id
    where e.kind = 'kept' and r.driver_id is not null and r.driver_id <> e.user_id and r.ride_date >= v_from
      and ((p_role = 'rider' and e.user_id = me) or (p_role = 'driver' and r.driver_id = me))
    union all
    select c.ride_id, c.user_id, r.driver_id, c.amount::integer, 0, 0, 1,
           coalesce(r.ended_at at time zone 'Africa/Cairo', r.ride_date + time '12:00'), r.ride_date
    from charges c join rides r on r.id = c.ride_id
    where r.driver_id is not null and r.ride_date >= v_from
      and ((p_role = 'rider' and c.user_id = me) or (p_role = 'driver' and r.driver_id = me))
    union all
    select b.ride_id, b.rider_id, t.driver_id, 0, b.contribution, t.trip_cost, t.rider_seats::integer,
           b.trip_date + t.departure + make_interval(mins => coalesce(t.duration_minutes, 40)), b.trip_date
    from bookings b join offered_trips t on t.id = b.offered_trip_id
    where b.status in ('booked', 'done') and b.trip_date >= v_from
      and (b.status = 'done' or b.trip_date + t.departure + make_interval(mins => coalesce(t.duration_minutes, 40)) <= now_c)
      and ((p_role = 'rider' and b.rider_id = me) or (p_role = 'driver' and t.driver_id = me))
  ), shares as (
    select distinct on (s.s_ride, s.s_rider) s.*,
           coalesce((select ps.method from payment_settings ps where ps.person_id = s.s_rider), 'cash') as s_method
    from src s order by s.s_ride, s.s_rider, s.s_charge desc
  )
  select h.s_ride, h.s_rider, h.s_driver,
         coalesce((select p.first_name from profiles p
                   where p.id = case when p_role = 'rider' then h.s_driver else h.s_rider end), ''),
         h.s_method,
         case when h.s_charge > 0 then h.s_charge
              else direct_pay_share(h.s_contribution, h.s_method, h.s_cost, h.s_seats) end,
         to_char(h.s_end, 'YYYY-MM-DD"T"HH24:MI:SS'),
         m.outcome,
         to_char(m.marked_at at time zone 'Africa/Cairo', 'YYYY-MM-DD"T"HH24:MI:SS'),
         to_char(cl.claimed_at at time zone 'Africa/Cairo', 'YYYY-MM-DD"T"HH24:MI:SS'),
         coalesce(m.reversed_once, false)
  from shares h
  left join share_marks m on m.ride_id = h.s_ride and m.rider_id = h.s_rider
  left join share_claims cl on cl.ride_id = h.s_ride and cl.rider_id = h.s_rider
  where case when h.s_charge > 0 then h.s_charge
             else direct_pay_share(h.s_contribution, h.s_method, h.s_cost, h.s_seats) end > 0
  order by h.s_end desc;
end $$;

-- Grants: the helpers are internal; only the three entry points are callable. ------------------
revoke all on function
  public.pay_equal_share(integer, integer), public.pay_range(integer, integer),
  public.pay_cash_amount(integer, integer, integer), public.direct_pay_share(integer, text, integer, integer),
  public.direct_pay_fee(integer, integer, integer, integer, boolean), public.is_late(date, timestamp),
  public.fee_is_overdue(date, date), public.fee_use_bundle(integer, integer), public.fee_due_date(jsonb, date),
  public.payment_settings_since(), public.company_suspended_at(uuid, timestamp),
  public.wallet_covered_at(uuid, timestamp), public.wallet_state(), public.wallet_assert_open(),
  public.wallet_share_rows(text)
  from public, anon, authenticated;
grant execute on function public.wallet_state(), public.wallet_assert_open(), public.wallet_share_rows(text)
  to authenticated;
