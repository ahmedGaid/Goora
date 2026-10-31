-- Goora feature 013: the marketplace reads and the reclaim that live mode lacked
-- (specs/013-live-parity research D6, D8, D9). `profiles` stays owner-only: every
-- other person's name reaches the caller through these narrow functions, first
-- name (and the driver's rating and initials) only — never a surname, phone,
-- home or e-mail (constitution IV). Whole EGP; no income kind (Law 87/2018).

-- The reclaim tells the booker (the fake posts the same notice).
alter table public.notices drop constraint notices_kind_check;
alter table public.notices add constraint notices_kind_check check (kind = any (array[
  'driverConfirmed', 'driverUnconfirmed', 'delay', 'backupCover', 'noCover', 'driverArrived', 'lateCancelCharged',
  'noShowCharged', 'noShowWarning', 'removed', 'seatOffered', 'sosSent', 'driverNoShow', 'seatReclaimed']));

-- Open seat offers with the driver's first name, rating and initials, and how many
-- seats are taken (bookings are not readable by other riders, so the count is
-- made here). Without p_ids: the open offers. With p_ids: those offers, open or
-- full, plus any the caller drives or holds a booking on (a booked seat's card).
create function public.market_offer_cards(p_ids uuid[] default null)
  returns table (id uuid, driver_id uuid, leg text, origin_area text, destination_area text, trip_date date,
                 departure time, duration_minutes smallint, seats smallint, rider_seats smallint, trip_cost integer,
                 contribution integer, repeat text, pickup jsonb, status text, group_id uuid, origin text,
                 cancelled_with_riders boolean, taken integer, driver_first_name text, driver_initials text,
                 driver_rating numeric, driver_is_woman boolean)
  language sql stable security definer set search_path = public as $$
    select t.id, t.driver_id, t.leg, t.origin_area, t.destination_area, t.trip_date, t.departure,
           t.duration_minutes, t.seats, t.rider_seats, t.trip_cost, t.contribution, t.repeat, t.pickup, t.status,
           t.group_id, t.origin, t.cancelled_with_riders,
           (select count(*)::integer from bookings b
            where b.offered_trip_id = t.id and b.status in ('booked', 'done')),
           p.first_name, upper(left(p.first_name, 1) || left(p.last_name, 1)), p.rating, p.gender = 'female'
    from offered_trips t join profiles p on p.id = t.driver_id
    where auth.uid() is not null
      and case when p_ids is null then t.status = 'open'
               else t.id = any (p_ids)
                    and (t.status in ('open', 'full') or t.driver_id = auth.uid()
                         or exists (select 1 from bookings b where b.offered_trip_id = t.id and b.rider_id = auth.uid()))
          end
    order by t.trip_date, t.departure
  $$;

-- Posted requests a driver may take: not their own, for one leg. No rider id, name or home —
-- only whether the rider is a woman (the driver's privacy choice decides on the device).
-- A person who never started driver verification sees none.
create function public.market_requests_for(p_leg text)
  returns table (id uuid, leg text, origin_area text, destination_area text, trip_date date, departure time,
                 repeat text, pickup jsonb, contribution integer, fee integer, status text, rider_is_woman boolean)
  language plpgsql stable security definer set search_path = public as $$
declare
  me uuid := wallet_me();
begin
  if not exists (select 1 from profiles me_p
                 where me_p.id = me and (me_p.role = 'driver' or me_p.driver_docs in ('pending', 'verified'))) then
    return;
  end if;
  return query
    select r.id, r.leg, r.origin_area, r.destination_area, r.trip_date, r.departure, r.repeat, r.pickup,
           r.contribution, r.fee, r.status, rp.gender = 'female'
    from trip_requests r join profiles rp on rp.id = r.rider_id
    where r.status = 'posted' and r.rider_id <> me and r.leg = p_leg and r.trip_date >= cairo_today()
    order by r.trip_date, r.departure, r.id;
end $$;

-- Every finished one-off seat the caller rode or drove, with first names. Only trips that
-- have ended (or are marked done), so a driver never learns a rider's name before boarding.
create function public.market_done_one_offs()
  returns table (ride_id text, trip_date date, leg text, paid_by text, contribution integer, trip_cost integer,
                 rider_seats integer, rider_id uuid, driver_id uuid, rider_first_name text, driver_first_name text,
                 trip_end text)
  language sql stable security definer set search_path = public as $$
    select b.ride_id, b.trip_date, b.leg, b.paid_by, b.contribution, t.trip_cost, t.rider_seats::integer,
           b.rider_id, t.driver_id, rp.first_name, dp.first_name,
           to_char(b.trip_date + t.departure + make_interval(mins => coalesce(t.duration_minutes, 40)),
                   'YYYY-MM-DD"T"HH24:MI:SS')
    from bookings b
    join offered_trips t on t.id = b.offered_trip_id
    join profiles rp on rp.id = b.rider_id
    join profiles dp on dp.id = t.driver_id
    where b.status in ('booked', 'done')
      and (b.rider_id = auth.uid() or t.driver_id = auth.uid())
      and (b.status = 'done'
           or b.trip_date + t.departure + make_interval(mins => coalesce(t.duration_minutes, 40))
              <= now() at time zone 'Africa/Cairo')
    order by b.trip_date, b.leg
  $$;

-- A subscriber takes the seat (005 US6): the booker gets what they paid back and a
-- full offer opens again. A subscriber's own seat and one booked after the cut-off are
-- final; after the cut-off nothing can be reclaimed. The booker or the offer's driver
-- may call it; the fake has no caller, a stranger is refused.
create function public.market_reclaim(p_booking uuid) returns integer
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  b bookings;
  t offered_trips;
  v_refund integer;
  now_c timestamp := now() at time zone 'Africa/Cairo';
begin
  select * into b from bookings where id = p_booking for update;
  if b is null or b.status <> 'booked' then raise exception 'refused:notReclaimable' using errcode = 'P0001'; end if;
  select * into t from offered_trips where id = b.offered_trip_id;
  if me <> b.rider_id and me is distinct from t.driver_id then
    raise exception 'refused:notReclaimable' using errcode = 'P0001';
  end if;
  if coalesce(b.is_subscriber, false) or is_late(b.trip_date, b.booked_at at time zone 'Africa/Cairo') then
    raise exception 'refused:notReclaimable' using errcode = 'P0001';
  end if;
  if is_late(b.trip_date, now_c) then raise exception 'refused:reclaimTooLate' using errcode = 'P0001'; end if;

  v_refund := coalesce(b.paid, 0);
  update bookings set status = 'reclaimed' where id = p_booking;
  if v_refund > 0 then
    perform wallet_post(b.rider_id, 'seatRefund', v_refund, v_refund, 'refund:' || b.id, 0, 0, b.ride_id, b.trip_date);
  end if;
  update offered_trips set status = 'open' where id = b.offered_trip_id and status = 'full';
  insert into notices (user_id, kind, params)
  values (b.rider_id, 'seatReclaimed', jsonb_build_object('day', b.trip_date, 'amount', v_refund::text));
  return v_refund;
end $$;

revoke all on function public.market_offer_cards(uuid[]), public.market_requests_for(text),
  public.market_done_one_offs(), public.market_reclaim(uuid) from public, anon;
grant execute on function public.market_offer_cards(uuid[]), public.market_requests_for(text),
  public.market_done_one_offs(), public.market_reclaim(uuid) to authenticated;
