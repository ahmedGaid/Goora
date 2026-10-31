-- 013 D6, D8, D9 / T024: marketplace reads and reclaim in live mode.
begin;
create extension if not exists pgtap with schema extensions;
\ir _helpers.psql
select plan(22);

select pg_temp.mk_user('00000000-0000-0000-0000-0000000000c1', 'Dina', 'female', 'driver');  -- driver
select pg_temp.mk_user('00000000-0000-0000-0000-0000000000c2', 'Omar');                      -- booker
select pg_temp.mk_user('00000000-0000-0000-0000-0000000000c3', 'Hany');                      -- other rider
select pg_temp.mk_user('00000000-0000-0000-0000-0000000000c4', 'Sara', 'female');            -- stranger
update public.profiles set phone = '+201000000011' where id = '00000000-0000-0000-0000-0000000000c1';
update public.profiles set last_name = 'Tawfik', rating = 4.7 where id = '00000000-0000-0000-0000-0000000000c1';

-- A seat offer 3 days out with 2 seats (contribution 40, trip cost 160, 3 rider seats).
insert into public.offered_trips (id, driver_id, leg, origin_area, destination_area, trip_date, departure, seats,
                                  rider_seats, trip_cost, contribution, repeat, pickup)
values ('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000c1', 'going', 'newCairo',
        'ismailia', public.cairo_today() + 3, '07:00', 2, 3, 160, 40, 'once', '{"id":"p","name":"gasStation"}'::jsonb);

-- Omar booked and paid a 4 EGP fee; Hany booked in cash.
insert into public.bookings (id, rider_id, offered_trip_id, trip_date, leg, ride_id, contribution, fee, paid_by, paid,
                             booked_at)
values ('40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000c2',
        '30000000-0000-0000-0000-000000000001', public.cairo_today() + 3, 'going',
        'offer:30000000-0000-0000-0000-000000000001', 40, 4, 'wallet', 4, now()),
       ('40000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-0000000000c3',
        '30000000-0000-0000-0000-000000000001', public.cairo_today() + 3, 'going',
        'offer:30000000-0000-0000-0000-000000000001', 40, 0, 'cash', 0, now());
insert into public.wallet_entries (person_id, id, kind, amount, delta, fee, ride_id)
values ('00000000-0000-0000-0000-0000000000c2', 'seat:40000000-0000-0000-0000-000000000001', 'seatBooked', 4, -4, 4,
        'offer:30000000-0000-0000-0000-000000000001');

-- ML1–ML3: offer cards ---------------------------------------------------------------------
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c4');
select is((select driver_first_name from public.market_offer_cards() limit 1), 'Dina',
  'ML1: a rider sees the driver''s first name on an offer');
select is((select taken from public.market_offer_cards() limit 1), 2,
  'ML2: the taken count is right although bookings are private');
select is((select count(*)::int from pg_proc p
           where p.proname = 'market_offer_cards'
             and pg_get_function_result(p.oid) ~* '(last_name|phone|home|email)'), 0,
  'ML3: offer cards have no surname, phone, home or e-mail column');
select is((select count(*)::int from public.profiles where id = '00000000-0000-0000-0000-0000000000c1'), 0,
  'ML4: the same rider still cannot read the driver''s profile row');
select pg_temp.as_admin();

-- ML5–ML7: requests for me --------------------------------------------------------------------
insert into public.trip_requests (id, rider_id, leg, origin_area, destination_area, trip_date, departure, repeat,
                                  pickup, contribution, fee)
values ('50000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000c4', 'going', 'newCairo',
        'ismailia', public.cairo_today() + 2, '07:00', 'once', '{"id":"q"}'::jsonb, 40, 4),
       ('50000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-0000000000c1', 'going', 'newCairo',
        'ismailia', public.cairo_today() + 2, '07:30', 'once', '{"id":"q"}'::jsonb, 40, 4);
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c1');
select is((select array_agg(id::text) from public.market_requests_for('going')),
          array['50000000-0000-0000-0000-000000000001'],
  'ML5: a driver sees others'' posted requests, not their own');
select is((select rider_is_woman from public.market_requests_for('going') limit 1), true,
  'ML6: only whether the rider is a woman is shown');
select is((select count(*)::int from pg_proc p
           where p.proname = 'market_requests_for' and pg_get_function_result(p.oid) ~* '(rider_id|first_name|name text|phone|home)'),
  0, 'ML6b: no rider id, name, phone or home in the request rows');
select pg_temp.as_admin();
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c3');
select is((select count(*)::int from public.market_requests_for('going')), 0,
  'ML7: a person who never started driver verification sees none');
select pg_temp.as_admin();

-- ML8–ML9: finished one-offs --------------------------------------------------------------------
update public.bookings set trip_date = public.cairo_today() - 1 where offered_trip_id = '30000000-0000-0000-0000-000000000001';
update public.offered_trips set trip_date = public.cairo_today() - 1 where id = '30000000-0000-0000-0000-000000000001';
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c2');
select is((select driver_first_name from public.market_done_one_offs() limit 1), 'Dina',
  'ML8: the rider sees the finished seat with the driver''s first name');
select pg_temp.as_admin();
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c1');
select is((select array_agg(rider_first_name order by rider_first_name) from public.market_done_one_offs()),
          array['Hany', 'Omar'], 'ML9: the driver sees the riders'' first names once the trip is over');
select pg_temp.as_admin();
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c4');
select is((select count(*)::int from public.market_done_one_offs()), 0, 'ML10: a stranger sees none');
select pg_temp.as_admin();
update public.bookings set trip_date = public.cairo_today() + 3 where offered_trip_id = '30000000-0000-0000-0000-000000000001';
update public.offered_trips set trip_date = public.cairo_today() + 3, status = 'full'
  where id = '30000000-0000-0000-0000-000000000001';

-- ML11–ML16: reclaim ---------------------------------------------------------------------------------
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c4');
select throws_ok($$select public.market_reclaim('40000000-0000-0000-0000-000000000001')$$, 'P0001',
  'refused:notReclaimable', 'ML11: a stranger cannot reclaim');
select pg_temp.as_admin();
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c2');
select is(public.market_reclaim('40000000-0000-0000-0000-000000000001'), 4, 'ML12: the booker gets the 4 EGP fee back');
select pg_temp.as_admin();
select is((select status from public.bookings where id = '40000000-0000-0000-0000-000000000001'), 'reclaimed',
  'ML13: the booking is reclaimed');
select is((select status from public.offered_trips where id = '30000000-0000-0000-0000-000000000001'), 'open',
  'ML14: a full offer opens again');
select is((select delta from public.wallet_entries where person_id = '00000000-0000-0000-0000-0000000000c2'
           and id = 'refund:40000000-0000-0000-0000-000000000001'), 4, 'ML15: one refund row, a credit of 4');
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c2');
select throws_ok($$select public.market_reclaim('40000000-0000-0000-0000-000000000001')$$, 'P0001',
  'refused:notReclaimable', 'ML16: a second reclaim is refused');
select pg_temp.as_admin();

-- Hany's cash seat: a subscriber's seat is final, so is one booked after the cut-off, and
-- after the cut-off nothing can be reclaimed.
update public.bookings set is_subscriber = true where id = '40000000-0000-0000-0000-000000000002';
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c3');
select throws_ok($$select public.market_reclaim('40000000-0000-0000-0000-000000000002')$$, 'P0001',
  'refused:notReclaimable', 'ML17: a subscriber''s seat is final');
select pg_temp.as_admin();
update public.bookings set is_subscriber = false,
  booked_at = ((trip_date - 1) + time '22:00') at time zone 'Africa/Cairo'
  where id = '40000000-0000-0000-0000-000000000002';
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c3');
select throws_ok($$select public.market_reclaim('40000000-0000-0000-0000-000000000002')$$, 'P0001',
  'refused:notReclaimable', 'ML18: a seat booked after the cut-off is final');
select pg_temp.as_admin();
update public.bookings set booked_at = now() - interval '4 days', trip_date = public.cairo_today()
  where id = '40000000-0000-0000-0000-000000000002';
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c3');
select throws_ok($$select public.market_reclaim('40000000-0000-0000-0000-000000000002')$$, 'P0001',
  'refused:reclaimTooLate', 'ML19: after the cut-off a seat can no longer be reclaimed');
select pg_temp.as_admin();

-- ML20-ML21: a booked seat's card stays readable after the offer is cancelled; to nobody else.
update public.offered_trips set status = 'cancelled' where id = '30000000-0000-0000-0000-000000000001';
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c3');
select is((select driver_first_name from public.market_offer_cards(array['30000000-0000-0000-0000-000000000001']::uuid[])),
          'Dina', 'ML20: the booker still reads the card of their booked seat');
select pg_temp.as_admin();
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c4');
select is((select count(*)::int from public.market_offer_cards(array['30000000-0000-0000-0000-000000000001']::uuid[])),
          0, 'ML21: a stranger gets no card for a cancelled offer');
select pg_temp.as_admin();

select * from finish();
rollback;
