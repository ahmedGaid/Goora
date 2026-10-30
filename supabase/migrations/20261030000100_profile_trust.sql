-- Goora feature 011: profile and trust on the server, and the commute calls the
-- app needs (specs/011-real-backend data-model, research D10, D11, D18, D22).
--
-- Privacy (constitution IV): profiles stay owner-only (002). Other people's
-- public facts reach a client only through groups_for(), which never returns
-- a home point, never a rider's name to someone outside the rider's group,
-- and never a phone number except a driver's to the driver's own group.

-- Profile and trust columns -------------------------------------------------------

alter table public.profiles
  add column phone text check (phone is null or phone ~ '^\+201[0125][0-9]{8}$'),
  -- 009: a person signing up now has had no ID check yet.
  add column rider_id_status text not null default 'notVerified'
    check (rider_id_status in ('notVerified', 'pending', 'verified')),
  add column driver_docs text not null default 'notNeeded'
    check (driver_docs in ('notNeeded', 'pending', 'verified')),
  add column work_email text check (work_email is null or work_email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  add column work_email_verified boolean not null default false;

-- The owner writes their own facts; statuses, rating and reliability are the
-- server's (research D10).
revoke insert, update on public.profiles from authenticated;
grant insert (id, first_name, last_name, gender, role, frequency, company, compound, phone,
              privacy_preference, women_only_pref, same_company_only_pref, same_compound_only_pref)
  on public.profiles to authenticated;
grant update (first_name, last_name, gender, role, frequency, company, compound, phone,
              privacy_preference, women_only_pref, same_company_only_pref, same_compound_only_pref)
  on public.profiles to authenticated;

-- A privacy choice must be available to the person (003 research R7; the facts
-- PrivacyRules.available reads): women-only for a woman, same-company with a
-- company, same-compound with a compound.
create function public.check_privacy_available() returns trigger
  language plpgsql set search_path = public as $$
begin
  if (new.privacy_preference = 'womenOnly' and new.gender <> 'female')
     or (new.privacy_preference = 'sameCompany' and new.company is null)
     or (new.privacy_preference = 'sameCompound' and new.compound is null) then
    raise exception 'refused:privacyUnavailable' using errcode = 'P0001';
  end if;
  return new;
end $$;

create trigger profiles_privacy_available before insert or update on public.profiles
  for each row execute function public.check_privacy_available();

-- 009 FR-003/FR-004: both sides captured and sent. Verified at once, as the
-- fakes do; a real check may leave it pending first (later feature).
create function public.submit_rider_id() returns text
  language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'refused:signedOut' using errcode = 'P0001'; end if;
  update profiles set rider_id_status = 'verified' where id = auth.uid();
  return 'verified';
end $$;

-- A rider switching to driving: licence and vehicle wait for verification.
create function public.start_driver_verification() returns void
  language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'refused:signedOut' using errcode = 'P0001'; end if;
  update profiles set driver_docs = 'pending' where id = auth.uid() and driver_docs <> 'verified';
end $$;

-- Commute profile: which of the corridor's named places was picked (the app
-- shows places by id; the points stay the matching input and never leave).
alter table public.commute_profiles
  add column home_place text,
  add column work_place text;

-- Groups: the display document ----------------------------------------------------
-- research D22: the 002 columns stay the matching inputs (PostGIS); `card`
-- holds the rest of the group as the app's CommuteGroup JSON (stops, vehicle,
-- trip cost, rider seats, free seats) without members, which groups_for()
-- builds from group_members and profiles.

alter table public.groups add column card jsonb not null default '{}'::jsonb;

-- A member's car and days as the app's Member JSON (vehicle, seats, legs,
-- days); names, gender, company, rating come from profiles at read time.
alter table public.group_members add column card jsonb not null default '{}'::jsonb;

create function public.groups_for(p_origin text, p_destination text) returns jsonb
  language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(
    g.card || jsonb_build_object(
      'id', g.id::text,
      'origin', g.origin_area,
      'destination', g.destination_area,
      'members', (
        select coalesce(jsonb_agg(
          m.card || jsonb_build_object(
            'id', m.user_id::text,
            'role', m.role,
            'legs', to_jsonb(m.legs),
            'seats', m.seats,
            'isWoman', p.gender = 'female',
            'company', p.company,
            'compound', p.compound,
            'rating', p.rating,
            'reliability', p.reliability,
            'privacy', p.privacy_preference,
            -- A rider's name only inside the rider's own group (constitution IV).
            'firstName', case when m.role = 'driver' or public.is_group_member(g.id) then p.first_name else '' end,
            'initials', case when m.role = 'driver' or public.is_group_member(g.id)
                             then upper(left(p.first_name, 1) || left(p.last_name, 1)) else '' end,
            -- A driver's phone only to their own group; nobody else's ever.
            'phone', case when m.role = 'driver' and public.is_group_member(g.id) then p.phone end
          ) order by m.joined_at), '[]'::jsonb)
        from group_members m join profiles p on p.id = m.user_id
        where m.group_id = g.id)
    ) order by g.going), '[]'::jsonb)
  from groups g
  where g.origin_area = p_origin and g.destination_area = p_destination
$$;

create function public.join_group(p_group uuid, p_role text default 'rider', p_legs text[] default array['going', 'ret'],
                                  p_seats smallint default null) returns void
  language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'refused:signedOut' using errcode = 'P0001'; end if;
  if not exists (select 1 from groups where id = p_group) then
    raise exception 'refused:noSuchGroup' using errcode = 'P0001';
  end if;
  -- One group per person: joining another replaces the old membership.
  delete from group_members where user_id = auth.uid() and group_id <> p_group;
  insert into group_members (group_id, user_id, role, legs, seats)
  values (p_group, auth.uid(), p_role, p_legs, p_seats)
  on conflict (group_id, user_id) do nothing;
end $$;

-- The caller's place on the corridor waitlist: rows ahead + 1.
create function public.join_waitlist(p_origin text, p_destination text) returns int
  language plpgsql security definer set search_path = public as $$
declare
  mine timestamptz;
begin
  if auth.uid() is null then raise exception 'refused:signedOut' using errcode = 'P0001'; end if;
  insert into waitlist (user_id, origin_area, destination_area) values (auth.uid(), p_origin, p_destination)
  on conflict do nothing;
  select created_at into mine from waitlist
  where user_id = auth.uid() and origin_area = p_origin and destination_area = p_destination;
  return (select count(*) from waitlist
          where origin_area = p_origin and destination_area = p_destination
            and (created_at < mine or (created_at = mine and user_id < auth.uid()))) + 1;
end $$;

revoke all on function public.submit_rider_id(), public.start_driver_verification(),
  public.groups_for(text, text), public.join_group(uuid, text, text[], smallint),
  public.join_waitlist(text, text) from public, anon;
grant execute on function public.submit_rider_id(), public.start_driver_verification(),
  public.groups_for(text, text), public.join_group(uuid, text, text[], smallint),
  public.join_waitlist(text, text) to authenticated;
