-- R3, R4, R5, R19: profile and trust.
begin;
create extension if not exists pgtap with schema extensions;
\ir _helpers.psql
select plan(14);

select pg_temp.mk_user('00000000-0000-0000-0000-00000000000a', 'Amr');
select pg_temp.mk_user('00000000-0000-0000-0000-00000000000b', 'Bassma', 'female');
select pg_temp.mk_user('00000000-0000-0000-0000-00000000000d', 'Dina', 'female', 'driver');

-- A group with a driver (Dina) and a rider (Bassma); Amr is outside it.
insert into public.groups (id, origin_area, destination_area, destination, going, return_time, days, price)
values ('10000000-0000-0000-0000-000000000001', 'nasrCity', 'ismailia',
        extensions.st_point(32.27, 30.6)::extensions.geography, '07:00', '16:00', '{sun}', 50);
update public.profiles set phone = '+201001234567' where id = '00000000-0000-0000-0000-00000000000d';
insert into public.group_members (group_id, user_id, role, legs, seats) values
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000d', 'driver', '{going,ret}', 3),
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', 'rider', '{going,ret}', null);

select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
select is((select count(*)::int from public.profiles), 1, 'R3: A sees only their own profile');
select is((select rider_id_status from public.profiles), 'notVerified', 'R3: a new sign-up reads notVerified (009)');
select lives_ok($$update public.profiles set first_name = 'Amro'$$, 'R3: A edits own name');
select is((select count(*)::int from (update public.profiles set first_name = 'X'
           where id = '00000000-0000-0000-0000-00000000000b' returning 1) u), 0, 'R3: A cannot edit B');
select throws_ok($$update public.profiles set rider_id_status = 'verified'$$, '42501', null,
  'R3: A cannot set their own ID status');
select throws_ok($$update public.profiles set rating = 5$$, '42501', null, 'R3: A cannot set their rating');
select is(public.submit_rider_id(), 'verified', 'R3: submit_rider_id verifies');
select throws_ok($$update public.profiles set privacy_preference = 'womenOnly'$$, 'P0001',
  'refused:privacyUnavailable', 'R4: women-only refused for a man');

-- R5: three contacts, the fourth refused; nobody else's are visible.
insert into public.trusted_contacts (user_id, name, phone) values
  ('00000000-0000-0000-0000-00000000000a', 'One', '+201001111111'),
  ('00000000-0000-0000-0000-00000000000a', 'Two', '+201002222222'),
  ('00000000-0000-0000-0000-00000000000a', 'Three', '+201003333333');
select throws_ok($$insert into public.trusted_contacts (user_id, name, phone)
  values ('00000000-0000-0000-0000-00000000000a', 'Four', '+201004444444')$$, '23514', 'contactsFull',
  'R5: a fourth contact is refused');
select throws_ok($$insert into public.trusted_contacts (user_id, name, phone)
  values ('00000000-0000-0000-0000-00000000000b', 'Spy', '+201005555555')$$, '42501', null,
  'R5: A cannot add a contact for B');

-- R19: groups_for to an outsider: driver's name yes, rider's name no, no phones, no homes.
select is((select (g -> 'members') @? '$[*] ? (@.role == "rider" && @.firstName == "")'
           from jsonb_array_elements(public.groups_for('nasrCity', 'ismailia')) g), true,
  'R19: an outsider never sees a rider''s name');
select is((select (g -> 'members') @? '$[*] ? (@.phone != null)'
           from jsonb_array_elements(public.groups_for('nasrCity', 'ismailia')) g), false,
  'R19: an outsider sees no phone number');
select is((select public.groups_for('nasrCity', 'ismailia')::text ~* 'home'), false,
  'R19: no home point in groups_for');
select pg_temp.as_admin();

select pg_temp.as_user('00000000-0000-0000-0000-00000000000b');
select is((select (g -> 'members') @? '$[*] ? (@.role == "driver" && @.phone == "+201001234567")'
           from jsonb_array_elements(public.groups_for('nasrCity', 'ismailia')) g), true,
  'R19: a member sees their driver''s phone');
select pg_temp.as_admin();

select * from finish();
rollback;
