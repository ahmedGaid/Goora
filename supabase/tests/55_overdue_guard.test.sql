-- 013 D5 / T020: an overdue balance blocks Book, Post, accept and Join on the server (008 FR-005).
begin;
create extension if not exists pgtap with schema extensions;
\ir _helpers.psql
select plan(7);

select pg_temp.mk_user('00000000-0000-0000-0000-0000000000b1', 'Bassem');
select pg_temp.mk_user('00000000-0000-0000-0000-0000000000b2', 'Basma', 'female');
insert into public.groups (id, origin_area, destination_area, destination, going, return_time, days, price, card)
values ('20000000-0000-0000-0000-000000000002', 'newCairo', 'ismailia',
        extensions.st_point(32.27, 30.6)::extensions.geography, '07:00', '16:00', '{sun}', 40,
        '{"tripCost":160,"riderSeats":3}'::jsonb);

-- Bassem owes 150 since 5 days; Basma owes nothing.
insert into public.wallet_entries (person_id, id, kind, amount, delta, entry_date)
values ('00000000-0000-0000-0000-0000000000b1', 'seat:old', 'seatBooked', 150, -150, public.cairo_today() - 5);

select pg_temp.as_user('00000000-0000-0000-0000-0000000000b1');
select throws_ok($$select public.join_group('20000000-0000-0000-0000-000000000002')$$, 'P0001',
  'refused:feeOverdue:150', 'G1: join is refused while overdue, naming the amount');
select throws_ok($$select public.market_book('30000000-0000-0000-0000-000000000009', 40, 4, 'wallet')$$, 'P0001',
  'refused:feeOverdue:150', 'G2: book is refused while overdue');
select throws_ok($$select public.market_post('going', 'newCairo', 'ismailia', current_date + 1, '07:00', 'once',
                   '{}'::jsonb, 40, 4)$$, 'P0001', 'refused:feeOverdue:150', 'G3: post is refused while overdue');
select throws_ok($$select public.market_accept('30000000-0000-0000-0000-000000000009', 160, 3::smallint)$$, 'P0001',
  'refused:feeOverdue:150', 'G4: accept is refused while overdue');
select pg_temp.as_admin();

select pg_temp.as_user('00000000-0000-0000-0000-0000000000b2');
select lives_ok($$select public.join_group('20000000-0000-0000-0000-000000000002')$$,
  'G5: a rider who owes nothing joins');
select is((select count(*)::int from public.group_members where user_id = '00000000-0000-0000-0000-0000000000b2'), 1,
  'G6: and is a member');
select pg_temp.as_admin();

-- Paying clears it: after settling, Bassem may join.
insert into public.wallet_entries (person_id, id, kind, amount, delta, entry_date)
values ('00000000-0000-0000-0000-0000000000b1', 'settle', 'settlement', 150, 150, public.cairo_today());
select pg_temp.as_user('00000000-0000-0000-0000-0000000000b1');
select lives_ok($$select public.join_group('20000000-0000-0000-0000-000000000002')$$,
  'G7: paying lifts the block at once');
select pg_temp.as_admin();

select * from finish();
rollback;
