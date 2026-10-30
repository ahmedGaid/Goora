-- Goora feature 011: the wallet on the server (specs/011-real-backend data-model,
-- research D8, D9, D10). Goora's own money only, as a ledger; whole EGP.
--
-- Law 87/2018 (constitution II): no table, column, ledger kind or function here
-- records money a driver earns. The driver's share is paid outside Goora and
-- lives here only as a status (share_marks / share_claims), never as an amount
-- credited to anyone. The ledger kinds are the rider-side ActivityKind names;
-- the legacy 004 driver kinds (tripIncome, feeReceived, cashReceived) are
-- deliberately absent.

-- Cairo wall time as the app's WallTime text ('YYYY-MM-DD HH24:MI'), research R2.
create function public.cairo_wall() returns text
  language sql stable set search_path = public as $$
    select to_char(now() at time zone 'Africa/Cairo', 'YYYY-MM-DD HH24:MI')
  $$;

create function public.cairo_today() returns date
  language sql stable set search_path = public as $$
    select (now() at time zone 'Africa/Cairo')::date
  $$;

-- Prices (brief §6; FakeWalletRepository.priceFor) -------------------------------------
-- Config, not a rule: the server reads the price here so a client can't
-- subscribe for less than the app shows.
create table public.plan_prices (
  type  text primary key check (type in ('monthly', 'yearly', 'company')),
  price integer not null check (price >= 0),
  months smallint check (months > 0)
);
insert into public.plan_prices values ('monthly', 149, 1), ('yearly', 1490, 12), ('company', 0, null);

create table public.plans (
  person_id  uuid primary key references public.profiles (id) on delete cascade,
  type       text not null references public.plan_prices (type),
  status     text not null default 'active' check (status in ('active', 'due')),
  price      integer not null check (price >= 0),
  start_wall text not null,
  until_date date,
  check (type <> 'company' or (price = 0 and until_date is null))
);

-- 010 research R8: a personal plan paused while its owner is enrolled.
create table public.paused_plans (
  person_id uuid primary key references public.profiles (id) on delete cascade,
  type      text not null check (type in ('monthly', 'yearly')),
  price     integer not null check (price >= 0),
  days_left integer not null check (days_left >= 0)
);

create table public.payment_settings (
  person_id       uuid primary key references public.profiles (id) on delete cascade,
  method          text check (method in ('cash', 'instapay')),
  -- 007 research R7: trimmed, at most 40 characters, empty = null.
  instapay_handle text check (instapay_handle is null
                              or (instapay_handle = btrim(instapay_handle)
                                  and char_length(instapay_handle) between 1 and 40)),
  since_date      date,
  no_trial        boolean not null default false,
  no_trial_from   text
);

create table public.wallet_entries (
  person_id       uuid not null references public.profiles (id) on delete cascade,
  -- The app's ActivityEntry id; 'seat:<booking>' / 'refund:<booking>' make the
  -- seat rows idempotent per booking (005 research R7).
  id              text not null,
  kind            text not null check (kind in (
                    'topUp', 'withdrawal', 'subscription', 'seatBooked', 'seatRefund',
                    'settlement', 'bundle', 'bundleTrip', 'trip', 'cashTrip',
                    'tripDeduction', 'lateCancelCharge', 'freeCancelZero')),
  -- As shown (never negative); `delta` is the signed effect on the balance.
  amount          integer not null check (amount >= 0),
  delta           integer not null,
  fee             integer not null default 0 check (fee >= 0),
  -- 007: the share handed to the driver directly — shown, never in the balance.
  share_to_driver integer not null default 0 check (share_to_driver >= 0),
  ride_id         text,
  leg             text check (leg in ('going', 'ret')),
  entry_date      date not null default public.cairo_today(),
  created_at      timestamptz not null default clock_timestamp(),
  primary key (person_id, id),
  check (delta between -amount and amount)
);

create index wallet_entries_newest on public.wallet_entries (person_id, created_at desc);

-- The driver's answer for one rider's share on one ride (007 FR-004).
create table public.share_marks (
  ride_id       text not null,
  rider_id      uuid not null references public.profiles (id) on delete cascade,
  driver_id     uuid not null references public.profiles (id) on delete cascade,
  outcome       text not null check (outcome in ('received', 'didNotPay')),
  -- The share as shown; nobody is credited it.
  amount        integer not null check (amount >= 0),
  ride_date     date not null,
  marked_at     timestamptz not null default now(),
  reversed_once boolean not null default false,
  primary key (ride_id, rider_id)
);

-- The rider's "دفعت" on a share marked not received (007 FR-006).
create table public.share_claims (
  ride_id    text not null,
  rider_id   uuid not null references public.profiles (id) on delete cascade,
  claimed_at timestamptz not null default now(),
  primary key (ride_id, rider_id)
);

-- 008 FR-007: 20 trips for 75 EGP, paid outside the balance.
create table public.bundles (
  id        uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.profiles (id) on delete cascade,
  trips     smallint not null default 20 check (trips = 20),
  price     integer not null default 75 check (price = 75),
  bought_at timestamptz not null default now()
);

create view public.wallet_balances with (security_invoker = true) as
  select person_id, coalesce(sum(delta), 0)::integer as balance
  from public.wallet_entries group by person_id;

-- Row Level Security ---------------------------------------------------------------

alter table public.plan_prices      enable row level security;
alter table public.plans            enable row level security;
alter table public.paused_plans     enable row level security;
alter table public.payment_settings enable row level security;
alter table public.wallet_entries   enable row level security;
alter table public.share_marks      enable row level security;
alter table public.share_claims     enable row level security;
alter table public.bundles          enable row level security;

create policy "prices are listed" on public.plan_prices for select to authenticated using (true);
create policy "own plan" on public.plans for select to authenticated using (person_id = auth.uid());
create policy "own paused plan" on public.paused_plans for select to authenticated using (person_id = auth.uid());
create policy "own payment settings" on public.payment_settings
  for all to authenticated using (person_id = auth.uid()) with check (person_id = auth.uid());
create policy "own ledger" on public.wallet_entries for select to authenticated using (person_id = auth.uid());
create policy "rider or driver reads a mark" on public.share_marks
  for select to authenticated using (rider_id = auth.uid() or driver_id = auth.uid());
create policy "rider or the marking driver reads a claim" on public.share_claims
  for select to authenticated using (
    rider_id = auth.uid()
    or exists (select 1 from public.share_marks m
               where m.ride_id = share_claims.ride_id and m.rider_id = share_claims.rider_id
                 and m.driver_id = auth.uid()));
create policy "own bundles" on public.bundles for select to authenticated using (person_id = auth.uid());

grant select on public.plan_prices, public.plans, public.paused_plans, public.wallet_entries,
  public.share_marks, public.share_claims, public.bundles, public.wallet_balances to authenticated;
grant select, insert, update, delete on public.payment_settings to authenticated;
grant all on public.plan_prices, public.plans, public.paused_plans, public.payment_settings,
  public.wallet_entries, public.share_marks, public.share_claims, public.bundles,
  public.wallet_balances to service_role;

-- Functions --------------------------------------------------------------------------
-- Every money move: the caller, the amount and the balance are checked inside
-- the same transaction; a refusal writes nothing.

create function public.wallet_me() returns uuid
  language plpgsql stable set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'refused:signedOut' using errcode = 'P0001'; end if;
  return auth.uid();
end $$;

create function public.wallet_balance_of(p_person uuid) returns integer
  language sql stable set search_path = public as $$
    select coalesce(sum(delta), 0)::integer from wallet_entries where person_id = p_person
  $$;

create function public.wallet_post(p_person uuid, p_kind text, p_amount integer, p_delta integer,
                                   p_id text default null, p_fee integer default 0, p_share integer default 0,
                                   p_ride text default null, p_date date default null) returns text
  language plpgsql set search_path = public as $$
declare
  v_id text := coalesce(p_id, p_kind || ':' || gen_random_uuid());
begin
  insert into wallet_entries (person_id, id, kind, amount, delta, fee, share_to_driver, ride_id, entry_date)
  values (p_person, v_id, p_kind, p_amount, p_delta, p_fee, p_share, p_ride, coalesce(p_date, cairo_today()))
  on conflict (person_id, id) do nothing;
  return v_id;
end $$;

-- Until 012 adds the payment partner's confirmation, the top-up trusts the
-- device's (fake) payment result; hosted deploy stays blocked until then.
create function public.wallet_top_up(p_method text, p_amount integer) returns text
  language plpgsql security definer set search_path = public as $$
begin
  if p_amount is null or p_amount <= 0 then raise exception 'refused:amount' using errcode = 'P0001'; end if;
  return wallet_post(wallet_me(), 'topUp', p_amount, p_amount);
end $$;

create function public.wallet_withdraw(p_amount integer) returns text
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
begin
  if p_amount is null or p_amount <= 0 then raise exception 'refused:amount' using errcode = 'P0001'; end if;
  perform pg_advisory_xact_lock(hashtext(me::text));
  if wallet_balance_of(me) < p_amount then raise exception 'refused:insufficient' using errcode = 'P0001'; end if;
  return wallet_post(me, 'withdrawal', p_amount, -p_amount);
end $$;

create function public.wallet_subscribe(p_type text) returns text
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  pp plan_prices;
begin
  select * into pp from plan_prices where type = p_type;
  if pp is null then raise exception 'refused:planType' using errcode = 'P0001'; end if;
  insert into payment_settings (person_id, since_date) values (me, cairo_today())
  on conflict (person_id) do update set since_date = coalesce(payment_settings.since_date, excluded.since_date);
  if p_type = 'company' then
    insert into plans (person_id, type, price, start_wall) values (me, 'company', 0, cairo_wall())
    on conflict (person_id) do update set type = 'company', price = 0, status = 'active',
      start_wall = excluded.start_wall, until_date = null;
    return 'subscribed';
  end if;
  perform pg_advisory_xact_lock(hashtext(me::text));
  if wallet_balance_of(me) < pp.price then return 'needsTopUp'; end if;
  perform wallet_post(me, 'subscription', pp.price, -pp.price);
  insert into plans (person_id, type, price, start_wall, until_date)
  values (me, p_type, pp.price, cairo_wall(), (cairo_today() + make_interval(months => pp.months))::date)
  on conflict (person_id) do update set type = excluded.type, price = excluded.price, status = 'active',
    start_wall = excluded.start_wall, until_date = excluded.until_date;
  return 'subscribed';
end $$;

-- Takes effect next billing date (no pro-rating): only type and price move.
create function public.wallet_change_plan(p_type text) returns void
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  pp plan_prices;
begin
  select * into pp from plan_prices where type = p_type;
  if pp is null then raise exception 'refused:planType' using errcode = 'P0001'; end if;
  insert into plans (person_id, type, price, start_wall) values (me, p_type, pp.price, cairo_wall())
  on conflict (person_id) do update set type = excluded.type, price = excluded.price,
    until_date = case when excluded.type = 'company' then null else plans.until_date end;
end $$;

-- 010 research R8: the company plan replaces a personal one, whose paid days
-- left are paused; no fee-free trial from now on.
create function public.wallet_start_company_plan() returns void
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  cur plans;
begin
  select * into cur from plans where person_id = me;
  if cur.type in ('monthly', 'yearly') and cur.until_date is not null then
    insert into paused_plans (person_id, type, price, days_left)
    values (me, cur.type, cur.price, greatest(0, cur.until_date - cairo_today()))
    on conflict (person_id) do update set type = excluded.type, price = excluded.price, days_left = excluded.days_left;
  end if;
  insert into plans (person_id, type, price, start_wall) values (me, 'company', 0, cairo_wall())
  on conflict (person_id) do update set type = 'company', price = 0, status = 'active',
    start_wall = excluded.start_wall, until_date = null;
  insert into payment_settings (person_id, no_trial_from) values (me, cairo_wall())
  on conflict (person_id) do update set no_trial_from = coalesce(payment_settings.no_trial_from, excluded.no_trial_from);
end $$;

-- On leaving: the paused plan comes back counted from today, else per trip.
create function public.wallet_end_company_plan() returns void
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  p paused_plans;
begin
  select * into p from paused_plans where person_id = me;
  if p is null then
    delete from plans where person_id = me and type = 'company';
  else
    update plans set type = p.type, price = p.price, status = 'active',
      until_date = cairo_today() + p.days_left where person_id = me;
    delete from paused_plans where person_id = me;
  end if;
end $$;

-- 008 FR-003: everything owed to Goora in one row; nothing owed → no row.
create function public.wallet_settle(p_method text) returns integer
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  owed integer;
begin
  perform pg_advisory_xact_lock(hashtext(me::text));
  owed := greatest(0, -wallet_balance_of(me));
  if owed > 0 then perform wallet_post(me, 'settlement', owed, owed); end if;
  return owed;
end $$;

-- 008 FR-007: never touches the balance (a row with delta 0).
create function public.wallet_buy_bundle(p_method text) returns void
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
begin
  insert into bundles (person_id) values (me);
  perform wallet_post(me, 'bundle', 75, 0);
end $$;

-- 005 research R7: Goora's fee for a one-off seat, one row per booking. It only
-- ever lowers the caller's own balance.
create function public.wallet_seat_debit(p_booking text, p_ride text, p_fee integer, p_share integer,
                                         p_date date) returns void
  language plpgsql security definer set search_path = public as $$
begin
  if p_fee < 0 or p_share < 0 then raise exception 'refused:amount' using errcode = 'P0001'; end if;
  perform wallet_post(wallet_me(), 'seatBooked', p_fee, -p_fee, 'seat:' || p_booking, p_fee, p_share, p_ride, p_date);
end $$;

-- One credit back per booking, never more than that booking's own debit.
create function public.wallet_seat_refund(p_booking text, p_ride text, p_amount integer, p_date date) returns void
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  paid integer;
begin
  if p_amount = 0 then return; end if;
  select amount into paid from wallet_entries where person_id = me and id = 'seat:' || p_booking;
  if paid is null or p_amount < 0 or p_amount > paid then
    raise exception 'refused:amount' using errcode = 'P0001';
  end if;
  perform wallet_post(me, 'seatRefund', p_amount, p_amount, 'refund:' || p_booking, 0, 0, p_ride, p_date);
end $$;

-- Who drives a ride: a 003 group ride, or a 005 one-off ('offer:<trip id>').
create function public.ride_driver(p_ride text) returns uuid
  language sql stable security definer set search_path = public as $$
    select coalesce(
      (select driver_id from rides where id = p_ride),
      (select driver_id from offered_trips
       where p_ride like 'offer:%' and id::text = substr(p_ride, 7)))
  $$;

-- The driver's answer for one rider's share (007 R2): only the ride's driver;
-- a received share may be turned into "didn't pay" once.
create function public.wallet_mark_share(p_ride text, p_rider uuid, p_outcome text, p_amount integer,
                                         p_date date) returns void
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  cur share_marks;
begin
  if ride_driver(p_ride) is distinct from me then raise exception 'refused:notDriver' using errcode = 'P0001'; end if;
  select * into cur from share_marks where ride_id = p_ride and rider_id = p_rider;
  if cur is null then
    insert into share_marks (ride_id, rider_id, driver_id, outcome, amount, ride_date)
    values (p_ride, p_rider, me, p_outcome, p_amount, p_date);
  elsif cur.outcome <> p_outcome and not cur.reversed_once then
    update share_marks set outcome = p_outcome, marked_at = now(), reversed_once = true
    where ride_id = p_ride and rider_id = p_rider;
  end if;
end $$;

create function public.wallet_claim_paid(p_ride text) returns void
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
begin
  if not exists (select 1 from share_marks where ride_id = p_ride and rider_id = me and outcome = 'didNotPay') then
    raise exception 'refused:noOpenMark' using errcode = 'P0001';
  end if;
  insert into share_claims (ride_id, rider_id) values (p_ride, me)
  on conflict (ride_id, rider_id) do update set claimed_at = now();
end $$;

-- Two people share a ride: same group, or a booking on the other's offer.
create function public.rides_with(p_a uuid, p_b uuid) returns boolean
  language sql stable security definer set search_path = public as $$
    select exists (select 1 from group_members x join group_members y on y.group_id = x.group_id
                   where x.user_id = p_a and y.user_id = p_b)
        or exists (select 1 from bookings b join offered_trips t on t.id = b.offered_trip_id
                   where (b.rider_id = p_a and t.driver_id = p_b) or (b.rider_id = p_b and t.driver_id = p_a))
  $$;

create function public.payment_method_of(p_rider uuid) returns text
  language sql stable security definer set search_path = public as $$
    select method from payment_settings
    where person_id = p_rider and (p_rider = auth.uid() or rides_with(auth.uid(), p_rider))
  $$;

create function public.instapay_handle_of(p_driver uuid) returns text
  language sql stable security definer set search_path = public as $$
    select instapay_handle from payment_settings
    where person_id = p_driver and (p_driver = auth.uid() or rides_with(auth.uid(), p_driver))
  $$;

revoke all on function public.wallet_post(uuid, text, integer, integer, text, integer, integer, text, date),
  public.wallet_balance_of(uuid), public.rides_with(uuid, uuid), public.ride_driver(text)
  from public, anon, authenticated;

revoke all on function public.wallet_top_up(text, integer), public.wallet_withdraw(integer),
  public.wallet_subscribe(text), public.wallet_change_plan(text), public.wallet_start_company_plan(),
  public.wallet_end_company_plan(), public.wallet_settle(text), public.wallet_buy_bundle(text),
  public.wallet_seat_debit(text, text, integer, integer, date), public.wallet_seat_refund(text, text, integer, date),
  public.wallet_mark_share(text, uuid, text, integer, date), public.wallet_claim_paid(text),
  public.payment_method_of(uuid), public.instapay_handle_of(uuid) from public, anon;
grant execute on function public.wallet_top_up(text, integer), public.wallet_withdraw(integer),
  public.wallet_subscribe(text), public.wallet_change_plan(text), public.wallet_start_company_plan(),
  public.wallet_end_company_plan(), public.wallet_settle(text), public.wallet_buy_bundle(text),
  public.wallet_seat_debit(text, text, integer, integer, date), public.wallet_seat_refund(text, text, integer, date),
  public.wallet_mark_share(text, uuid, text, integer, date), public.wallet_claim_paid(text),
  public.payment_method_of(uuid), public.instapay_handle_of(uuid) to authenticated;
