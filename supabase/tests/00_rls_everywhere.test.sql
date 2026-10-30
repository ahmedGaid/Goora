-- R1, R2 (specs/011-real-backend data-model): RLS on every table; anon reads nothing.
begin;
create extension if not exists pgtap with schema extensions;
\ir _helpers.psql
select plan(3);

select is(
  (select coalesce(array_agg(c.relname order by c.relname), '{}')
   from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity),
  '{}'::name[],
  'R1: every table in public has row level security on');

select is(
  (select count(*)::int from information_schema.role_table_grants
   where table_schema = 'public' and grantee = 'anon'),
  0,
  'R2: anon holds no grant on any table or view');

select pg_temp.as_anon();
select throws_ok('select count(*) from public.profiles', '42501', null, 'R2: anon cannot read profiles');
select pg_temp.as_admin();

select * from finish();
rollback;
