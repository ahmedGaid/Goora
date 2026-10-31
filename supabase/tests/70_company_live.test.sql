-- 013 D11, D12 / T035: company coverage, dashboard totals under k = 5, reset, staff functions.
begin;
create extension if not exists pgtap with schema extensions;
\ir _helpers.psql
select plan(21);

create or replace function pg_temp.as_service() returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  perform set_config('request.jwt.claim.sub', '', true);
  execute 'set local role service_role';
end $$;

-- HR (h), six employees e1..e6, a stranger (x).
select pg_temp.mk_user('00000000-0000-0000-0000-0000000000f0', 'Hala');
select pg_temp.mk_user('00000000-0000-0000-0000-0000000000f7', 'Xavi');
select pg_temp.mk_user(('00000000-0000-0000-0000-0000000000e' || n)::uuid, 'Emp' || n) from generate_series(1, 6) n;
insert into public.companies (id, name, status, hr_contact_id, contract_start, approved_at)
values ('60000000-0000-0000-0000-000000000001', 'Demo Motors', 'active', '00000000-0000-0000-0000-0000000000f0',
        public.cairo_today() - 90, '2026-01-01T09:00:00');
insert into public.company_domains (domain, company_id) values ('cltestco.test', '60000000-0000-0000-0000-000000000001');
insert into public.enrollments (company_id, person_id, name, work_email, enrolled_at)
select '60000000-0000-0000-0000-000000000001', ('00000000-0000-0000-0000-0000000000e' || n)::uuid, 'Emp' || n,
       'emp' || n || '@cltestco.test', '2026-01-02T09:00:00' from generate_series(1, 6) n;

-- One finished going leg this month on a group of price 40 / trip cost 160; e1..e5 rode it.
insert into public.groups (id, origin_area, destination_area, destination, going, return_time, days, price, card)
values ('20000000-0000-0000-0000-000000000003', 'newCairo', 'ismailia',
        extensions.st_point(32.27, 30.6)::extensions.geography, '07:00', '16:00', '{sun,mon,tue,wed,thu}', 40,
        '{"tripCost":160,"riderSeats":3}'::jsonb);
insert into public.rides (id, group_id, ride_date, leg, driver_id, ended_at)
values ('g3:today:going', '20000000-0000-0000-0000-000000000003', public.cairo_today(), 'going',
        '00000000-0000-0000-0000-0000000000e6', now());
insert into public.ride_passengers (ride_id, user_id, stop_id)
select 'g3:today:going', ('00000000-0000-0000-0000-0000000000e' || n)::uuid, 'stop' from generate_series(1, 5) n;
insert into public.commute_profiles (user_id, home, home_area, work, work_area, departure, return_time, days)
select ('00000000-0000-0000-0000-0000000000e' || n)::uuid,
       extensions.st_point(31.47, 30.03)::extensions.geography, 'newCairo',
       extensions.st_point(32.27, 30.6)::extensions.geography, 'ismailia', '06:30', '16:30', '{sun,mon}'
from generate_series(1, 5) n;

-- CL1–CL4: totals under k = 5 --------------------------------------------------------------
select pg_temp.as_user('00000000-0000-0000-0000-0000000000f0');
select is((public.company_dashboard('60000000-0000-0000-0000-000000000001', to_char(public.cairo_today(), 'YYYY-MM'))
           ->> 'moneySaved')::int, 600, 'CL1: 5 riders saved 5 x (160 - 40) = 600');
select is((public.company_dashboard('60000000-0000-0000-0000-000000000001', to_char(public.cairo_today(), 'YYYY-MM'))
           ->> 'co2Kg')::int, 101, 'CL2: CO2 is 5 legs x 123 km x 0.1645 = 101 kg');
select isnt((public.company_dashboard('60000000-0000-0000-0000-000000000001', to_char(public.cairo_today(), 'YYYY-MM'))
             ->> 'parkingPerDay'), null, 'CL3: parking per day shows with 5 going riders');
select is((public.company_dashboard('60000000-0000-0000-0000-000000000001', to_char(public.cairo_today(), 'YYYY-MM'))
           -> 'routeGaps'), '[{"area": "newCairo", "count": 5}]'::jsonb,
  'CL4: 5 employees in New Cairo with a commute and no group are one route gap');
select pg_temp.as_admin();

delete from public.ride_passengers where user_id = '00000000-0000-0000-0000-0000000000e5';
insert into public.group_members (group_id, user_id, role, legs, seats)
values ('20000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-0000000000e4', 'rider', '{going,ret}', null);
select pg_temp.as_user('00000000-0000-0000-0000-0000000000f0');
select is((public.company_dashboard('60000000-0000-0000-0000-000000000001', to_char(public.cairo_today(), 'YYYY-MM'))
           ->> 'moneySaved'), null, 'CL5: with 4 riders the money total is withheld, not shown as 480');
select is((public.company_dashboard('60000000-0000-0000-0000-000000000001', to_char(public.cairo_today(), 'YYYY-MM'))
           ->> 'co2Kg'), null, 'CL6: and so is CO2');
select is((public.company_dashboard('60000000-0000-0000-0000-000000000001', to_char(public.cairo_today(), 'YYYY-MM'))
           ->> 'parkingPerDay'), null, 'CL7: and parking');
select is((public.company_dashboard('60000000-0000-0000-0000-000000000001', to_char(public.cairo_today(), 'YYYY-MM'))
           -> 'routeGaps'), '[]'::jsonb, 'CL8: a gap of 4 is left out entirely');
select pg_temp.as_admin();

select pg_temp.as_user('00000000-0000-0000-0000-0000000000f7');
select throws_ok($$select public.company_dashboard('60000000-0000-0000-0000-000000000001', '2026-10')$$, 'P0001',
  'refused:notHrContact', 'CL9: only the HR contact reads the dashboard');
select pg_temp.as_admin();

-- CL10–CL13: suspensions ----------------------------------------------------------------------------
insert into public.invoices (company_id, month, peak_enrolled, billed_seats, price_per_seat, total, issued_on, due_on,
                             reference)
values ('60000000-0000-0000-0000-000000000001', '2026-09', 6, 20, 99, 1980, public.cairo_today() - 35,
        public.cairo_today() - 20, 'INV-1');
select pg_temp.as_user('00000000-0000-0000-0000-0000000000f0');
select is(jsonb_array_length(public.company_suspensions('60000000-0000-0000-0000-000000000001') -> 'invoices'), 1,
  'CL10: the HR contact reads the invoice whose suspension day has come');
select pg_temp.as_admin();
select pg_temp.as_user('00000000-0000-0000-0000-0000000000e2');
select is((select array_agg(k order by k) from jsonb_object_keys(
             public.company_suspensions('60000000-0000-0000-0000-000000000001') -> 'invoices' -> 0) k),
          array['dueOn', 'paidAt'], 'CL11: an enrolled employee gets dates only, no amount or reference');
select pg_temp.as_admin();
select pg_temp.as_user('00000000-0000-0000-0000-0000000000f7');
select throws_ok($$select public.company_suspensions('60000000-0000-0000-0000-000000000001')$$, 'P0001',
  'refused:notHrContact', 'CL12: a stranger gets nothing');
select pg_temp.as_admin();

-- CL13–CL17: staff functions are service-role only ----------------------------------------------------
insert into public.companies (id, name, status, hr_contact_id)
values ('60000000-0000-0000-0000-000000000002', 'Pending Co', 'pending', '00000000-0000-0000-0000-0000000000f7');
select pg_temp.as_user('00000000-0000-0000-0000-0000000000f7');
select throws_ok($$select public.staff_company_approve('60000000-0000-0000-0000-000000000002')$$, '42501', null,
  'CL13: an ordinary signed-in user cannot approve a company');
select pg_temp.as_admin();
select pg_temp.as_service();
select lives_ok($$select public.staff_company_approve('60000000-0000-0000-0000-000000000002')$$,
  'CL14: the service role approves');
select pg_temp.as_admin();
select is((select status from public.companies where id = '60000000-0000-0000-0000-000000000002'), 'active',
  'CL15: and the company is active');
select is((select count(*)::int from public.company_log
           where company_id = '60000000-0000-0000-0000-000000000002' and kind = 'approved' and actor = 'goora'), 1,
  'CL16: with one log line by Goora');

-- CL17: reset touches only the caller's own rows -------------------------------------------------------
insert into public.hr_consents (person_id, "on") values ('00000000-0000-0000-0000-0000000000e1', true),
  ('00000000-0000-0000-0000-0000000000e2', true);
insert into public.companies (id, name, status, hr_contact_id)
values ('60000000-0000-0000-0000-000000000003', 'Mine Pending', 'pending', '00000000-0000-0000-0000-0000000000e1');
select pg_temp.as_user('00000000-0000-0000-0000-0000000000e1');
select public.company_reset_mine();
select pg_temp.as_admin();
select is((select count(*)::int from public.enrollments where person_id = '00000000-0000-0000-0000-0000000000e1')
        + (select count(*)::int from public.hr_consents where person_id = '00000000-0000-0000-0000-0000000000e1')
        + (select count(*)::int from public.companies where id = '60000000-0000-0000-0000-000000000003'), 0,
  'CL17: reset removes the caller''s enrollment, consent and pending company');
select is((select count(*)::int from public.enrollments where person_id = '00000000-0000-0000-0000-0000000000e2')
        + (select count(*)::int from public.hr_consents where person_id = '00000000-0000-0000-0000-0000000000e2')
        + (select count(*)::int from public.companies where id = '60000000-0000-0000-0000-000000000001'), 3,
  'CL18: and nobody else''s');

-- CL19–CL21 ---------------------------------------------------------------------------------------------------
select pg_temp.as_user('00000000-0000-0000-0000-0000000000e2');
select throws_ok($$select public.workdays_in('2026-10')$$, '42501', null, 'CL19: helpers are not callable by users');
select is((select km from public.corridor_legs where origin_area = 'ismailia' and destination_area = 'newCairo'), 123,
  'CL20: the Cairo-Ismailia leg is 123 km');
select pg_temp.as_admin();
select is((select count(*)::int from information_schema.columns
           where table_schema = 'public' and column_name ~* '(income|earning|payout|profit)'), 0,
  'CL21: still no income, earning, payout or profit column');

select * from finish();
rollback;
