-- R10–R15: company privacy, k = 5, consent.
begin;
create extension if not exists pgtap with schema extensions;
\ir _helpers.psql
select plan(17);

select pg_temp.mk_user('00000000-0000-0000-0000-0000000000a1', 'Hana', 'female');   -- HR of Acme
select pg_temp.mk_user('00000000-0000-0000-0000-0000000000b1', 'Basem');            -- HR of Beta
select pg_temp.mk_user('00000000-0000-0000-0000-0000000000e1', 'Emad');             -- Acme employee
update public.profiles set work_email = 'emad@acme.com', work_email_verified = true
  where id = '00000000-0000-0000-0000-0000000000e1';

select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select throws_ok($$select public.company_register('Acme', array['acme.com'], 'hana@gmail.com')$$, 'P0001',
  'refused:emailNotOnDomain', 'R15: the HR email must be on a domain');
select lives_ok($$select public.company_register('Acme', array['acme.com'], 'hana@acme.com')$$, 'R15: Acme registers');
select pg_temp.as_admin();
select pg_temp.as_user('00000000-0000-0000-0000-0000000000b1');
select throws_ok($$select public.company_register('Beta', array['ACME.com'], 'b@acme.com')$$, 'P0001',
  'refused:domainTaken:acme.com', 'R15: a taken domain is refused');
select lives_ok($$select public.company_register('Beta', array['beta.io'], 'b@beta.io')$$, 'R15: Beta registers');
select pg_temp.as_admin();

-- R15: a pending company takes no enrollment; Goora approves Acme (service role).
select pg_temp.as_user('00000000-0000-0000-0000-0000000000e1');
select throws_ok($$select public.company_enroll()$$, 'P0001', 'refused:notEligible', 'R15: no enrollment while pending');
select pg_temp.as_admin();
update public.companies set status = 'active' where name = 'Acme';
select pg_temp.as_user('00000000-0000-0000-0000-0000000000e1');
select lives_ok($$select public.company_enroll()$$, 'R15: enrolls once Acme is active');
select is((select count(*)::int from public.enrollments), 1, 'R14: the employee reads their own enrollment');
select is((select count(*)::int from public.companies), 0, 'R14: an employee does not read the company row');
select is((select count(*)::int from public.company_roster), 0, 'R14: an employee does not read the roster');
select pg_temp.as_admin();

-- R10: Beta's HR reads nothing of Acme and may not call Acme's HR functions.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000b1');
select is((select count(*)::int from public.company_roster), 0, 'R10: Beta''s HR sees no Acme roster row');
select is((select count(*)::int from public.companies), 1, 'R10: Beta''s HR reads only Beta');
select throws_ok(format($$select public.company_dashboard(%L, '2026-10')$$,
  (select id from public.companies where name = 'Acme')), 'P0001', 'refused:notHrContact',
  'R10: Beta''s HR may not read Acme''s dashboard');
select throws_ok(format($$select public.company_statement(%L, '2026-10')$$,
  (select id from public.companies where name = 'Acme')), 'P0001', 'refused:notHrContact',
  'R10: … nor its statement');
select pg_temp.as_admin();

select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select is((select array_agg(column_name::text order by ordinal_position) from information_schema.columns
           where table_schema = 'public' and table_name = 'company_roster'),
  array['company_id', 'name', 'work_email', 'enrolled_at', 'left_at'], 'R11: the roster holds only the roster columns');
select is((select count(*)::int from public.company_roster), 1, 'R11: Acme''s HR sees its one employee');
select is((public.company_dashboard((select id from public.companies where name = 'Acme'),
           to_char(now() at time zone 'Africa/Cairo', 'YYYY-MM')) ->> 'enrolled'), null,
  'R12: 1 enrolled (< 5) is withheld');
select is(jsonb_array_length(public.company_statement((select id from public.companies where name = 'Acme'),
           to_char(now() at time zone 'Africa/Cairo', 'YYYY-MM'))), 0,
  'R13: no consent → nobody in the statement');
select pg_temp.as_admin();

select * from finish();
rollback;
