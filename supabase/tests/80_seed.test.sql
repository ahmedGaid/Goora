-- 013 D13 / T012: the demo seed (supabase/seed.sql) is complete, fictional and idempotent.
-- Runs on a database that went through `supabase db reset` (migrations + seed).
begin;
create extension if not exists pgtap with schema extensions;
\ir _helpers.psql
select plan(9);

select cmp_ok((select count(*)::int from public.groups
               where origin_area = 'sheikhZayed' and destination_area = 'smartVillage'), '>=', 1,
  'S1: the Sheikh Zayed corridor has a group');
select cmp_ok((select count(*)::int from public.groups
               where origin_area = 'newCairo' and destination_area = 'ismailia'), '>=', 1,
  'S2: the Cairo-Ismailia corridor has a group');

select is((select count(*)::int from public.groups g
           where not exists (select 1 from public.group_pickup_points p where p.group_id = g.id)
              or not exists (select 1 from public.group_members m where m.group_id = g.id and m.role = 'driver')), 0,
  'S3: every seeded group has a pickup point and a driver');

select is((select count(*)::int from public.group_pickup_points p
           join public.groups g on g.id = p.group_id
           where not exists (select 1 from jsonb_array_elements(g.card -> 'stops') s where s ->> 'id' = p.id::text)), 0,
  'S4: the document''s stop ids are the pickup point ids (ride passengers use them)');

select cmp_ok((select count(*)::int from public.enrollments e
               join public.companies c on c.id = e.company_id
               where c.name = 'Demo Motors' and e.left_at is null), '>=', 5,
  'S5: the demo company has at least five enrolled employees');
select cmp_ok((select count(*)::int from public.hr_consents where "on"), '>=', 5,
  'S6: at least five of them said yes to HR');

select is((select count(*)::int from auth.users u
           where u.email like '%@seed.goora.test'
             and exists (select 1 from public.profiles p
                         where p.id = u.id and p.phone is not null and p.phone !~ '^\+2010000000[0-9]{2}$')), 0,
  'S7: seeded phones are the obviously fake +2010000000xx range, none is a real number');

select is((select count(*)::int from auth.users u
           where u.email like '%@seed.goora.test' and u.encrypted_password is not null), 0,
  'S8: seeded people have no password (they cannot sign in)');

-- Idempotent: applying the seed again changes nothing.
create temp table before_counts as
  select (select count(*) from public.groups) g, (select count(*) from public.group_members) m,
         (select count(*) from public.enrollments) e, (select count(*) from auth.users) u;
\ir ../seed.sql
select is((select row(g, m, e, u) from before_counts),
          (select row((select count(*) from public.groups), (select count(*) from public.group_members),
                      (select count(*) from public.enrollments), (select count(*) from auth.users))),
  'S9: applying the seed a second time adds no rows');

select * from finish();
rollback;
