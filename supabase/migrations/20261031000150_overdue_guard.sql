-- Goora feature 013 (research D5): the server refuses Book, Post, accept and Join
-- while the caller's Goora balance is overdue (008 FR-005). The device gate stays
-- the friendly first line; this is the backstop. Bodies are those of
-- 20261030000100 (join_group) and 20261030000400 (market_*) plus the guard as the
-- first statement. Grants are unchanged by `create or replace`.

create or replace function public.join_group(p_group uuid, p_role text default 'rider',
                                             p_legs text[] default array['going', 'ret'],
                                             p_seats smallint default null) returns void
  language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'refused:signedOut' using errcode = 'P0001'; end if;
  perform wallet_assert_open();
  if not exists (select 1 from groups where id = p_group) then
    raise exception 'refused:noSuchGroup' using errcode = 'P0001';
  end if;
  -- One group per person: joining another replaces the old membership.
  delete from group_members where user_id = auth.uid() and group_id <> p_group;
  insert into group_members (group_id, user_id, role, legs, seats)
  values (p_group, auth.uid(), p_role, p_legs, p_seats)
  on conflict (group_id, user_id) do nothing;
end $$;

create or replace function public.market_post(p_leg text, p_origin text, p_destination text, p_date date,
                                              p_departure time, p_repeat text, p_pickup jsonb,
                                              p_contribution integer, p_fee integer) returns uuid
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  rid uuid;
begin
  perform wallet_assert_open();
  if p_repeat = 'daily' and exists (select 1 from group_members where user_id = me) then
    raise exception 'refused:dailyNotAllowed' using errcode = 'P0001';
  end if;
  insert into trip_requests (rider_id, leg, origin_area, destination_area, trip_date, departure, repeat, pickup,
                             contribution, fee)
  values (me, p_leg, p_origin, p_destination, p_date, p_departure, p_repeat, p_pickup, p_contribution, p_fee)
  returning id into rid;
  return rid;
end $$;

create or replace function public.market_book(p_offer uuid, p_contribution integer, p_fee integer,
                                              p_paid_by text) returns uuid
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  t offered_trips;
  taken integer;
  bid uuid;
begin
  perform wallet_assert_open();
  select * into t from offered_trips where id = p_offer for update;
  if t is null or t.status not in ('open', 'full') or t.driver_id = me then
    raise exception 'refused:seatTaken' using errcode = 'P0001';
  end if;
  if p_contribution <> t.contribution or (p_contribution + p_fee) * t.rider_seats > t.trip_cost then
    raise exception 'refused:price' using errcode = 'P0001';
  end if;
  select count(*) into taken from bookings where offered_trip_id = p_offer and status in ('booked', 'done');
  if taken >= t.seats then raise exception 'refused:seatTaken' using errcode = 'P0001'; end if;
  if exists (select 1 from bookings where rider_id = me and trip_date = t.trip_date and leg = t.leg
             and status in ('booked', 'done')) then
    raise exception 'refused:alreadyRiding' using errcode = 'P0001';
  end if;
  insert into bookings (rider_id, offered_trip_id, trip_date, leg, ride_id, contribution, fee, paid_by, paid)
  values (me, p_offer, t.trip_date, t.leg, 'offer:' || p_offer, p_contribution, p_fee, p_paid_by,
          case when p_paid_by = 'cash' then 0 else p_fee end)
  returning id into bid;
  if p_paid_by <> 'cash' and p_fee > 0 then
    perform wallet_post(me, 'seatBooked', p_fee, -p_fee, 'seat:' || bid, p_fee, p_contribution,
                        'offer:' || p_offer, t.trip_date);
  end if;
  if taken + 1 >= t.seats then update offered_trips set status = 'full' where id = p_offer; end if;
  return bid;
end $$;

create or replace function public.market_accept(p_request uuid, p_trip_cost integer, p_seats smallint) returns uuid
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  r trip_requests;
  tid uuid;
begin
  perform wallet_assert_open();
  select * into r from trip_requests where id = p_request for update;
  if r is null or r.status <> 'posted' or r.rider_id = me then
    raise exception 'refused:gone' using errcode = 'P0001';
  end if;
  perform pg_advisory_xact_lock(hashtext('market:' || me::text));
  if market_trips_today(me, r.trip_date) >= 2 then raise exception 'refused:overLimit' using errcode = 'P0001'; end if;
  insert into offered_trips (driver_id, leg, origin_area, destination_area, trip_date, departure, seats, rider_seats,
                             trip_cost, contribution, repeat, pickup, origin)
  values (me, r.leg, r.origin_area, r.destination_area, r.trip_date, r.departure, p_seats, p_seats, p_trip_cost,
          r.contribution, r.repeat, r.pickup, 'fromRequest')
  returning id into tid;
  insert into bookings (rider_id, offered_trip_id, trip_date, leg, ride_id, contribution, fee, paid_by)
  values (r.rider_id, tid, r.trip_date, r.leg, 'offer:' || tid, r.contribution, r.fee, 'cash');
  update trip_requests set status = 'accepted', accepted_by = me, trip_ref = tid::text where id = p_request;
  return tid;
end $$;
