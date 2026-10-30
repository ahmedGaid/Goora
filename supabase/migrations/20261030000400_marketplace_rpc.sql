-- Goora feature 011: marketplace writes on the server (specs/011-real-backend
-- research D16). The 005 tables are read under their RLS; every write goes
-- through these functions, which re-check inside the transaction.
--
-- Constitution II (Law 87/2018): the price comes from the pricing twins on the
-- device; offered_trips_cost_cap (20261030000000) refuses any contribution
-- above floor(trip_cost / rider_seats), and a driver offers at most 2 trips a
-- day (counted here, cancelled-with-riders included, 005 research R5).

create function public.market_trips_today(p_driver uuid, p_date date) returns integer
  language sql stable security definer set search_path = public as $$
    select count(*)::integer from offered_trips
    where driver_id = p_driver and trip_date = p_date
      and (status <> 'cancelled' or cancelled_with_riders)
  $$;

create function public.market_publish(p_leg text, p_origin text, p_destination text, p_date date, p_departure time,
                                      p_seats smallint, p_trip_cost integer, p_contribution integer, p_repeat text,
                                      p_pickup jsonb) returns uuid
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  tid uuid;
begin
  if (select driver_docs from profiles where id = me) = 'pending' then
    raise exception 'refused:notVerified' using errcode = 'P0001';
  end if;
  perform pg_advisory_xact_lock(hashtext('market:' || me::text));
  if market_trips_today(me, p_date) >= 2 then raise exception 'refused:overLimit' using errcode = 'P0001'; end if;
  insert into offered_trips (driver_id, leg, origin_area, destination_area, trip_date, departure, seats, rider_seats,
                             trip_cost, contribution, repeat, pickup)
  values (me, p_leg, p_origin, p_destination, p_date, p_departure, p_seats, p_seats, p_trip_cost, p_contribution,
          p_repeat, p_pickup)
  returning id into tid;
  return tid;
end $$;

create function public.market_post(p_leg text, p_origin text, p_destination text, p_date date, p_departure time,
                                   p_repeat text, p_pickup jsonb, p_contribution integer, p_fee integer) returns uuid
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  rid uuid;
begin
  if p_repeat = 'daily' and exists (select 1 from group_members where user_id = me) then
    raise exception 'refused:dailyNotAllowed' using errcode = 'P0001';
  end if;
  insert into trip_requests (rider_id, leg, origin_area, destination_area, trip_date, departure, repeat, pickup,
                             contribution, fee)
  values (me, p_leg, p_origin, p_destination, p_date, p_departure, p_repeat, p_pickup, p_contribution, p_fee)
  returning id into rid;
  return rid;
end $$;

create function public.market_cancel_request(p_request uuid) returns void
  language plpgsql security definer set search_path = public as $$
begin
  update trip_requests set status = 'withdrawn'
  where id = p_request and rider_id = wallet_me() and status = 'posted';
end $$;

-- One seat on an offered trip: the offer row is locked, so two people booking
-- the last seat at once get one booking and one seatTaken. The unique key
-- (rider, date, leg) makes a second booking on the same leg alreadyRiding.
create function public.market_book(p_offer uuid, p_contribution integer, p_fee integer, p_paid_by text) returns uuid
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  t offered_trips;
  taken integer;
  bid uuid;
begin
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

-- The rider cancels: the fee comes back in full (005 BookingRefund).
create function public.market_cancel_booking(p_booking uuid) returns integer
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  b bookings;
  refund integer;
begin
  select * into b from bookings where id = p_booking and rider_id = me for update;
  if b is null or b.status <> 'booked' then raise exception 'refused:notCancellable' using errcode = 'P0001'; end if;
  update bookings set status = 'cancelled' where id = p_booking;
  refund := b.paid;
  if refund > 0 then
    perform wallet_post(me, 'seatRefund', refund, refund, 'refund:' || p_booking, 0, 0, b.ride_id, b.trip_date);
  end if;
  update offered_trips set status = 'open' where id = b.offered_trip_id and status = 'full';
  return refund;
end $$;

-- The driver cancels: every booking refunded in full (FR-017).
create function public.market_cancel_offer(p_trip uuid) returns void
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  b bookings;
  n integer := 0;
begin
  if not exists (select 1 from offered_trips where id = p_trip and driver_id = me) then
    raise exception 'refused:notYours' using errcode = 'P0001';
  end if;
  for b in select * from bookings where offered_trip_id = p_trip and status = 'booked' for update loop
    update bookings set status = 'refunded' where id = b.id;
    if b.paid > 0 then
      perform wallet_post(b.rider_id, 'seatRefund', b.paid, b.paid, 'refund:' || b.id, 0, 0, b.ride_id, b.trip_date);
    end if;
    n := n + 1;
  end loop;
  update offered_trips set status = 'cancelled', cancelled_with_riders = (n > 0) where id = p_trip;
end $$;

-- A driver accepts a posted request: a trip is made from it at the request's
-- fixed price, within the 2-a-day cap.
create function public.market_accept(p_request uuid, p_trip_cost integer, p_seats smallint) returns uuid
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  r trip_requests;
  tid uuid;
begin
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

revoke all on function public.market_trips_today(uuid, date) from public, anon, authenticated;
revoke all on function public.market_publish(text, text, text, date, time, smallint, integer, integer, text, jsonb),
  public.market_post(text, text, text, date, time, text, jsonb, integer, integer), public.market_cancel_request(uuid),
  public.market_book(uuid, integer, integer, text), public.market_cancel_booking(uuid), public.market_cancel_offer(uuid),
  public.market_accept(uuid, integer, smallint) from public, anon;
grant execute on function public.market_publish(text, text, text, date, time, smallint, integer, integer, text, jsonb),
  public.market_post(text, text, text, date, time, text, jsonb, integer, integer), public.market_cancel_request(uuid),
  public.market_book(uuid, integer, integer, text), public.market_cancel_booking(uuid), public.market_cancel_offer(uuid),
  public.market_accept(uuid, integer, smallint) to authenticated;
