-- R16–R18: the cost cap, one seat one booking, two trips a day.
begin;
create extension if not exists pgtap with schema extensions;
\ir _helpers.psql
select plan(9);

select pg_temp.mk_user('00000000-0000-0000-0000-00000000000d', 'Dina', 'female', 'driver');
select pg_temp.mk_user('00000000-0000-0000-0000-00000000000a', 'Amr');
select pg_temp.mk_user('00000000-0000-0000-0000-00000000000b', 'Bassma', 'female');

select pg_temp.as_user('00000000-0000-0000-0000-00000000000d');
-- 240 EGP, one seat: an equal share is 240; 241 breaks the cap.
select throws_ok($$select public.market_publish('going', 'nasrCity', 'ismailia', '2026-11-01', '07:00', 1::smallint,
  240, 242, 'once', '{}')$$, '23514', null, 'R16: a contribution over the equal share is refused');
select lives_ok($$select public.market_publish('going', 'nasrCity', 'ismailia', '2026-11-01', '07:00', 1::smallint,
  240, 200, 'once', '{}')$$, 'R18: first trip of the day');
select lives_ok($$select public.market_publish('ret', 'ismailia', 'nasrCity', '2026-11-01', '17:00', 1::smallint,
  240, 200, 'once', '{}')$$, 'R18: second trip of the day');
select throws_ok($$select public.market_publish('ret', 'ismailia', 'nasrCity', '2026-11-01', '19:00', 1::smallint,
  240, 200, 'once', '{}')$$, 'P0001', 'refused:overLimit', 'R18: a third trip the same day is refused');
select pg_temp.as_admin();

select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
select lives_ok(format($$select public.market_book(%L, 200, 0, 'cash')$$,
  (select id from public.offered_trips where departure = '07:00')), 'R17: Amr takes the only seat');
select throws_ok(format($$select public.market_book(%L, 200, 0, 'cash')$$,
  (select id from public.offered_trips where departure = '07:00')), 'P0001', 'refused:seatTaken',
  'R17: booking the same seat again is refused');
select pg_temp.as_admin();

select pg_temp.as_user('00000000-0000-0000-0000-00000000000b');
select throws_ok(format($$select public.market_book(%L, 200, 0, 'cash')$$,
  (select id from public.offered_trips where departure = '07:00')), 'P0001', 'refused:seatTaken',
  'R17: the last seat booked twice → seatTaken');
select pg_temp.as_admin();
select is((select count(*)::int from public.bookings where status = 'booked'), 1, 'R17: one booking exists');
select is((select status from public.offered_trips where departure = '07:00'), 'full', 'R17: the trip reads full');

select * from finish();
rollback;
