-- 013 D2, D5, D7 / T017: the wallet's fee state is decided in the database.
-- Numbers follow the app's rules: contribution 40, trip cost 160, 3 rider seats →
-- equal share 53, cash share 40, fee 10% = 4 (007 R4, 008).
begin;
create extension if not exists pgtap with schema extensions;
\ir _helpers.psql
select plan(24);

select pg_temp.mk_user('00000000-0000-0000-0000-0000000000a1', 'Amr');
select pg_temp.mk_user('00000000-0000-0000-0000-0000000000d1', 'Dina', 'female', 'driver');
update public.profiles set phone = '+201000000009' where id = '00000000-0000-0000-0000-0000000000d1';

insert into public.groups (id, origin_area, destination_area, destination, going, return_time, days, price, card)
values ('20000000-0000-0000-0000-000000000001', 'newCairo', 'ismailia',
        extensions.st_point(32.27, 30.6)::extensions.geography, '07:00', '16:00', '{sun,mon,tue,wed,thu}', 40,
        '{"tripCost":160,"riderSeats":3}'::jsonb);
insert into public.group_members (group_id, user_id, role, legs, seats) values
  ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000d1', 'driver', '{going,ret}', 3),
  ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000a1', 'rider', '{going,ret}', null);
insert into public.payment_settings (person_id, method, since_date)
values ('00000000-0000-0000-0000-0000000000a1', 'cash', public.cairo_today() - 30);

-- One finished group trip for Amr n days ago (driver Dina).
create or replace function pg_temp.kept(n integer) returns void language plpgsql as $$
declare
  d date := public.cairo_today() - n;
  rid text := 'g1:' || d || ':going';
begin
  insert into public.rides (id, group_id, ride_date, leg, planned_driver_id, driver_id, ended_at)
  values (rid, '20000000-0000-0000-0000-000000000001', d, 'going',
          '00000000-0000-0000-0000-0000000000d1', '00000000-0000-0000-0000-0000000000d1',
          (d + time '08:00') at time zone 'Africa/Cairo');
  insert into public.reliability_events (user_id, ride_id, ride_date, kind)
  values ('00000000-0000-0000-0000-0000000000a1', rid, d, 'kept');
end $$;
create or replace function pg_temp.state() returns jsonb language sql as $$ select public.wallet_state() $$;
create or replace function pg_temp.kinds() returns text[] language sql as $$
  select coalesce(array_agg(e ->> 'kind' order by e ->> 'date', e ->> 'id'), '{}')
  from jsonb_array_elements(public.wallet_state() -> 'entries') e $$;

-- W1–W3: three trips are all inside the fee-free trial -----------------------------------
select pg_temp.kept(n) from generate_series(3, 1, -1) n;
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select is(pg_temp.kinds(), array['cashTrip', 'cashTrip', 'cashTrip'], 'W1: the first trips are fee-free cash trips');
select is((pg_temp.state() -> 'cashTrial' ->> 'tripsDone')::int, 3, 'W2: the trial counts 3 trips done');
select is((pg_temp.state() ->> 'balance')::int, 0, 'W3: nothing is owed inside the trial');
select pg_temp.as_admin();

-- W4–W7: trips 6 and 7 carry Goora's 4 EGP fee ----------------------------------------------
select pg_temp.kept(n) from generate_series(7, 4, -1) n;
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select is(pg_temp.kinds(),
          array['cashTrip', 'cashTrip', 'cashTrip', 'cashTrip', 'cashTrip', 'trip', 'trip'],
  'W4: five cash trips, then paid trips');
select is((pg_temp.state() ->> 'debits')::int, 8, 'W5: two paid trips owe 2 x 4');
select is((pg_temp.state() ->> 'balance')::int, -8, 'W6: the balance reads minus 8');
select is((pg_temp.state() -> 'cashTrial' ->> 'tripsDone')::int, 5, 'W7: the trial stopped at 5 trips');
select is((select (e ->> 'shareToDriver')::int from jsonb_array_elements(pg_temp.state() -> 'entries') e
           order by e ->> 'date' desc limit 1), 40, 'W8: the share for the driver is shown, never debited');
select is(pg_temp.state() ->> 'feeDue', null::text, 'W9: 8 EGP owed is not due yet');
select pg_temp.as_admin();

-- W10–W12: due at 150, overdue after the 3-day grace ------------------------------------------
insert into public.wallet_entries (person_id, id, kind, amount, delta, entry_date)
values ('00000000-0000-0000-0000-0000000000a1', 'seat:big', 'seatBooked', 150, -150, public.cairo_today() - 2);
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select is((pg_temp.state() ->> 'feeDue')::date, public.cairo_today() - 2, 'W10: owing 150 or more is due that day');
select is((pg_temp.state() ->> 'feeOverdue')::boolean, false, 'W11: two days after the due date is still in grace');
select pg_temp.as_admin();
update public.wallet_entries set entry_date = public.cairo_today() - 3
  where person_id = '00000000-0000-0000-0000-0000000000a1' and id = 'seat:big';
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select is((pg_temp.state() ->> 'feeOverdue')::boolean, true, 'W12: three days after the due date it is overdue');
select throws_ok('select public.wallet_assert_open()', 'P0001', null, 'W13: an overdue rider is refused (D5)');
select pg_temp.as_admin();

-- W14: month end, 30 or more carries to the 1st; below 30 carries over --------------------------
delete from public.wallet_entries where person_id = '00000000-0000-0000-0000-0000000000a1' and id = 'seat:big';
insert into public.wallet_entries (person_id, id, kind, amount, delta, entry_date)
values ('00000000-0000-0000-0000-0000000000a1', 'seat:old', 'seatBooked', 40, -40,
        (date_trunc('month', public.cairo_today()) - interval '40 days')::date);
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select is((pg_temp.state() ->> 'feeDue')::date,
          (date_trunc('month', (date_trunc('month', public.cairo_today()) - interval '40 days')::date)
           + interval '1 month')::date,
  'W14: 40 owed at a month end is due on the 1st after it');
select pg_temp.as_admin();

-- W15: a bundle covers the fee ---------------------------------------------------------------------
delete from public.wallet_entries where person_id = '00000000-0000-0000-0000-0000000000a1' and id = 'seat:old';
insert into public.bundles (person_id, bought_at) values ('00000000-0000-0000-0000-0000000000a1', now() - interval '60 days');
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select is(pg_temp.kinds(),
          array['cashTrip', 'cashTrip', 'cashTrip', 'cashTrip', 'cashTrip', 'bundleTrip', 'bundleTrip'],
  'W15: a bundle trip replaces the paid trip and owes nothing');
select is((pg_temp.state() ->> 'bundleLeft')::int, 18, 'W16: 20 bundle trips less the 2 used');
select pg_temp.as_admin();
delete from public.bundles where person_id = '00000000-0000-0000-0000-0000000000a1';

-- W17: 2 "didn't pay" marks end the trial early --------------------------------------------------
-- Trips are counted oldest first: 7 days ago is trip 1, 6 days ago is trip 2.
insert into public.share_marks (ride_id, rider_id, driver_id, outcome, amount, ride_date)
select 'g1:' || (public.cairo_today() - n) || ':going', '00000000-0000-0000-0000-0000000000a1',
       '00000000-0000-0000-0000-0000000000d1', 'didNotPay', 40, public.cairo_today() - n
from generate_series(7, 6, -1) n;
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select is((pg_temp.state() -> 'cashTrial' ->> 'strikes')::int, 2, 'W17: two "didn''t pay" marks are two strikes');
select is((pg_temp.state() -> 'cashTrial' ->> 'tripsDone')::int, 2, 'W18: two strikes end the trial after trip 2');
select is((pg_temp.kinds())[3], 'trip', 'W19: the third trip already pays Goora''s fee');
select pg_temp.as_admin();
delete from public.share_marks;

-- W20–W22: share rows carry a first name and the real method, nothing private ----------------------
insert into public.payment_settings (person_id, method) values ('00000000-0000-0000-0000-0000000000d1', 'instapay');
update public.payment_settings set method = 'instapay' where person_id = '00000000-0000-0000-0000-0000000000a1';
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select is((select other_first_name from public.wallet_share_rows('rider') limit 1), 'Dina',
  'W20: the rider sees the driver''s first name');
select is((select method from public.wallet_share_rows('rider') limit 1), 'instapay',
  'W21: the share carries the rider''s real method, not always cash');
select is((select count(*)::int from pg_proc p
           where p.proname = 'wallet_share_rows'
             and pg_get_function_result(p.oid) ~* '(last_name|phone|home|email)'), 0,
  'W22: share rows have no surname, phone, home or e-mail column');
select pg_temp.as_admin();

-- W23–W24: Law 87/2018 and exposure ------------------------------------------------------------------
select is((select count(*)::int from information_schema.columns
           where table_schema = 'public' and column_name ~* '(income|earning|payout|profit)'), 0,
  'W23: no income, earning, payout or profit column anywhere');
select pg_temp.as_anon();
select throws_ok('select public.wallet_state()', '42501', null, 'W24: a signed-out caller cannot read wallet state');
select pg_temp.as_admin();

select * from finish();
rollback;
