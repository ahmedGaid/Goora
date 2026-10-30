-- R6–R9: wallet ledger, money checks, Law 87, share marks.
begin;
create extension if not exists pgtap with schema extensions;
\ir _helpers.psql
select plan(16);

select pg_temp.mk_user('00000000-0000-0000-0000-00000000000a', 'Amr');
select pg_temp.mk_user('00000000-0000-0000-0000-00000000000b', 'Bassma', 'female');
select pg_temp.mk_user('00000000-0000-0000-0000-00000000000d', 'Dina', 'female', 'driver');

-- R8 (Law 87/2018): no driver-income kind, column or function.
select is((select pg_get_constraintdef(oid) ~* 'tripIncome|feeReceived|cashReceived'
           from pg_constraint where conname = 'wallet_entries_kind_check'), false,
  'R8: the ledger has no driver-income kind');
select is((select count(*)::int from information_schema.columns
           where table_schema = 'public' and column_name ~* 'income|earning|payout|profit'), 0,
  'R8: no column holds driver income');
select is((select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'public' and p.proname ~* 'income|earning|payout|profit'), 0,
  'R8: no function pays a driver');

select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
select throws_ok($$insert into public.wallet_entries (person_id, id, kind, amount, delta)
  values ('00000000-0000-0000-0000-00000000000a', 'x', 'topUp', 1000, 1000)$$, '42501', null,
  'R6: nobody writes the ledger directly');
select lives_ok($$select public.wallet_top_up('card', 100)$$, 'R7: a top-up');
select is((select balance from public.wallet_balances), 100, 'R7: balance 100 after the top-up');
select throws_ok($$select public.wallet_withdraw(101)$$, 'P0001', 'refused:insufficient',
  'R7: withdrawing more than the balance is refused');
select throws_ok($$select public.wallet_top_up('card', -5)$$, 'P0001', 'refused:amount', 'R7: negative top-up refused');
select is(public.wallet_subscribe('yearly'), 'needsTopUp', 'R7: yearly 1490 with 100 → needs top-up');
select is((select count(*)::int from public.plans), 0, 'R7: … and no plan written');
select lives_ok($$select public.wallet_top_up('card', 49)$$, 'R7: top up to 149');
select is(public.wallet_subscribe('monthly'), 'subscribed', 'R7: monthly 149 with 149 → subscribed');
select is((select balance from public.wallet_balances), 0, 'R7: the price left the balance');
select pg_temp.as_admin();

-- R6: B sees none of A's wallet.
select pg_temp.as_user('00000000-0000-0000-0000-00000000000b');
select is((select count(*)::int from public.wallet_entries), 0, 'R6: B reads none of A''s ledger');
select pg_temp.as_admin();

-- R9: a one-off trip Dina drives.
insert into public.offered_trips (id, driver_id, leg, origin_area, destination_area, trip_date, departure, seats,
  rider_seats, trip_cost, contribution, repeat, pickup)
values ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000d', 'going', 'nasrCity',
  'ismailia', '2026-11-01', '07:00', 3, 3, 240, 60, 'once', '{}');
select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
select throws_ok($$select public.wallet_mark_share('offer:20000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-00000000000b', 'received', 60, '2026-11-01')$$, 'P0001', 'refused:notDriver',
  'R9: only the ride''s driver marks a share');
select pg_temp.as_admin();
select pg_temp.as_user('00000000-0000-0000-0000-00000000000d');
select lives_ok($$select public.wallet_mark_share('offer:20000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-00000000000b', 'didNotPay', 60, '2026-11-01')$$, 'R9: the driver marks it');
select pg_temp.as_admin();

select * from finish();
rollback;
