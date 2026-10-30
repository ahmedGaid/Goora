-- Goora feature 011: the company network on the server (specs/010-company-network
-- research R9; specs/011-real-backend data-model, research D12, D13).
--
-- Privacy (constitution IV: companies never see an employee's data without
-- consent): an employee reads their own enrollment and consent; the HR contact
-- reads their company row, domains, invoices and log. Individual employee
-- facts reach HR only as the four roster columns (company_roster) and, after
-- the employee said yes, the statement (company_statement). The dashboard
-- (company_dashboard) withholds any count built from fewer than 5 people.
-- No HR-facing object returns a person id, group, pickup, time, share status
-- or role. Staff writes (approve, mark paid, HR contact, end contract) are
-- service role only. Flags companyInvoicesLive / hrStatementExport stay off:
-- nothing here issues a real invoice or exports a statement.

create table public.companies (
  id             uuid primary key default gen_random_uuid(),
  name           text not null check (char_length(name) between 1 and 80),
  status         text not null default 'pending' check (status in ('pending', 'active', 'suspended', 'ended')),
  hr_contact_id  uuid references public.profiles (id) on delete set null,
  contract_start date,
  contract_end   date,
  minimum_seats  integer not null default 20 check (minimum_seats >= 0),
  price_per_seat integer not null default 99 check (price_per_seat >= 0),
  approved_at    text,
  ended_at       text,
  created_at     timestamptz not null default now()
);

create table public.company_domains (
  domain     text primary key check (domain = lower(domain) and domain ~ '^[a-z0-9.-]+\.[a-z]{2,}$'),
  company_id uuid not null references public.companies (id) on delete cascade
);

create table public.enrollments (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  person_id   uuid not null references public.profiles (id) on delete cascade,
  name        text not null,
  work_email  text not null,
  enrolled_at text not null,
  left_at     text,
  left_why    text check (left_why in ('self', 'removedByHr', 'domainRemoved', 'contractEnded')),
  check ((left_at is null) = (left_why is null))
);

-- One open enrollment per person.
create unique index enrollments_one_open on public.enrollments (person_id) where left_at is null;

create table public.invoices (
  id             uuid primary key default gen_random_uuid(),
  company_id     uuid not null references public.companies (id) on delete cascade,
  month          text not null check (month ~ '^\d{4}-\d{2}$'),
  peak_enrolled  integer not null check (peak_enrolled >= 0),
  billed_seats   integer not null check (billed_seats >= 0),
  price_per_seat integer not null check (price_per_seat >= 0),
  total          integer not null check (total = billed_seats * price_per_seat),
  issued_on      date not null,
  due_on         date not null,
  reference      text not null,
  paid_at        text,
  bank_ref       text,
  unique (company_id, month)
);

create table public.company_log (
  id         uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id) on delete cascade,
  at         text not null,
  actor      text not null check (actor in ('hr', 'employee', 'goora')),
  kind       text not null check (kind in ('approved', 'domainAdded', 'domainRemoved', 'employeeRemoved',
               'employeeLeft', 'invoiceIssued', 'invoicePaid', 'suspended', 'resumed', 'contractEnded',
               'hrContactChanged', 'registered', 'employeeEnrolled')),
  detail     text,
  created_at timestamptz not null default clock_timestamp()
);

create table public.hr_consents (
  person_id  uuid primary key references public.profiles (id) on delete cascade,
  "on"       boolean not null default false,
  changed_at timestamptz not null default now()
);

-- Row Level Security ------------------------------------------------------------------

alter table public.companies       enable row level security;
alter table public.company_domains enable row level security;
alter table public.enrollments     enable row level security;
alter table public.invoices        enable row level security;
alter table public.company_log     enable row level security;
alter table public.hr_consents     enable row level security;

create function public.is_hr_of(p_company uuid) returns boolean
  language sql stable security definer set search_path = public as $$
    select exists (select 1 from companies where id = p_company and hr_contact_id = auth.uid())
  $$;

create policy "HR reads their company" on public.companies
  for select to authenticated using (hr_contact_id = auth.uid());
create policy "HR reads their domains" on public.company_domains
  for select to authenticated using (public.is_hr_of(company_id));
create policy "employee reads own enrollments" on public.enrollments
  for select to authenticated using (person_id = auth.uid());
create policy "HR reads their invoices" on public.invoices
  for select to authenticated using (public.is_hr_of(company_id));
create policy "HR reads their log" on public.company_log
  for select to authenticated using (public.is_hr_of(company_id));
create policy "own HR consent" on public.hr_consents
  for select to authenticated using (person_id = auth.uid());

grant select on public.companies, public.company_domains, public.enrollments, public.invoices,
  public.company_log, public.hr_consents to authenticated;
grant all on public.companies, public.company_domains, public.enrollments, public.invoices,
  public.company_log, public.hr_consents to service_role;

-- The roster: four columns, the HR contact's company only (010 research R6).
create view public.company_roster with (security_invoker = false) as
  select e.company_id, e.name, e.work_email, e.enrolled_at, e.left_at
  from public.enrollments e
  where public.is_hr_of(e.company_id);

revoke all on public.company_roster from public, anon;
grant select on public.company_roster to authenticated;

-- Functions ------------------------------------------------------------------------------

create function public.company_log_line(p_company uuid, p_actor text, p_kind text, p_detail text default null)
  returns void language sql set search_path = public as $$
    insert into company_log (company_id, at, actor, kind, detail) values (p_company, cairo_wall(), p_actor, p_kind, p_detail)
  $$;

create function public.company_must_be_hr(p_company uuid) returns void
  language plpgsql stable security definer set search_path = public as $$
begin
  if not is_hr_of(p_company) then raise exception 'refused:notHrContact' using errcode = 'P0001'; end if;
end $$;

-- US1: a pending company with the caller as its HR contact. Public-mail
-- domains are refused on the device (CompanyRules, research D13); Goora's
-- approval is the server-side gate.
create function public.company_register(p_name text, p_domains text[], p_hr_work_email text) returns uuid
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  d text;
  cid uuid;
begin
  if cardinality(p_domains) = 0
     or not (lower(split_part(p_hr_work_email, '@', 2)) = any (select lower(x) from unnest(p_domains) x)) then
    raise exception 'refused:emailNotOnDomain' using errcode = 'P0001';
  end if;
  foreach d in array p_domains loop
    if exists (select 1 from company_domains where domain = lower(d)) then
      raise exception 'refused:domainTaken:%', lower(d) using errcode = 'P0001';
    end if;
  end loop;
  insert into companies (name, hr_contact_id) values (btrim(p_name), me) returning id into cid;
  insert into company_domains (domain, company_id) select distinct lower(x), cid from unnest(p_domains) x;
  perform company_log_line(cid, 'hr', 'registered');
  return cid;
end $$;

create function public.company_for_domain(p_domain text) returns jsonb
  language sql stable security definer set search_path = public as $$
    select jsonb_build_object('id', c.id, 'name', c.name, 'status', c.status)
    from company_domains d join companies c on c.id = d.company_id
    where d.domain = lower(p_domain)
  $$;

-- US2: the caller's verified work email decides the company.
create function public.company_enroll() returns uuid
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  p profiles;
  c companies;
  eid uuid;
begin
  select * into p from profiles where id = me;
  if p.work_email is null or not p.work_email_verified then
    raise exception 'refused:notEligible' using errcode = 'P0001';
  end if;
  select c2.* into c from company_domains d join companies c2 on c2.id = d.company_id
  where d.domain = lower(split_part(p.work_email, '@', 2));
  if c is null or c.status not in ('active', 'suspended') then
    raise exception 'refused:notEligible' using errcode = 'P0001';
  end if;
  insert into enrollments (company_id, person_id, name, work_email, enrolled_at)
  values (c.id, me, btrim(p.first_name || ' ' || p.last_name), p.work_email, cairo_wall())
  returning id into eid;
  insert into hr_consents (person_id, "on") values (me, false) on conflict (person_id) do nothing;
  return eid;
end $$;

create function public.company_leave() returns void
  language plpgsql security definer set search_path = public as $$
declare
  me uuid := wallet_me();
  cid uuid;
begin
  update enrollments set left_at = cairo_wall(), left_why = 'self'
  where person_id = me and left_at is null returning company_id into cid;
  if cid is not null then perform company_log_line(cid, 'employee', 'employeeLeft'); end if;
end $$;

create function public.company_remove_employee(p_company uuid, p_work_email text) returns void
  language plpgsql security definer set search_path = public as $$
begin
  perform company_must_be_hr(p_company);
  update enrollments set left_at = cairo_wall(), left_why = 'removedByHr'
  where company_id = p_company and lower(work_email) = lower(p_work_email) and left_at is null;
  perform company_log_line(p_company, 'hr', 'employeeRemoved', lower(p_work_email));
end $$;

create function public.company_add_domain(p_company uuid, p_domain text) returns void
  language plpgsql security definer set search_path = public as $$
begin
  perform company_must_be_hr(p_company);
  if exists (select 1 from company_domains where domain = lower(p_domain)) then
    raise exception 'refused:domainTaken:%', lower(p_domain) using errcode = 'P0001';
  end if;
  insert into company_domains (domain, company_id) values (lower(p_domain), p_company);
  perform company_log_line(p_company, 'hr', 'domainAdded', lower(p_domain));
end $$;

-- Removing a domain ends the enrollments on it (010 US4).
create function public.company_remove_domain(p_company uuid, p_domain text) returns void
  language plpgsql security definer set search_path = public as $$
begin
  perform company_must_be_hr(p_company);
  delete from company_domains where company_id = p_company and domain = lower(p_domain);
  update enrollments set left_at = cairo_wall(), left_why = 'domainRemoved'
  where company_id = p_company and left_at is null and lower(split_part(work_email, '@', 2)) = lower(p_domain);
  perform company_log_line(p_company, 'hr', 'domainRemoved', lower(p_domain));
end $$;

create function public.company_set_consent(p_on boolean) returns void
  language plpgsql security definer set search_path = public as $$
begin
  insert into hr_consents (person_id, "on", changed_at) values (wallet_me(), p_on, now())
  on conflict (person_id) do update set "on" = excluded."on", changed_at = now();
end $$;

-- Employees enrolled at any moment of [p_month] (YYYY-MM, wall-time text compare).
create function public.company_month_people(p_company uuid, p_month text) returns setof uuid
  language sql stable security definer set search_path = public as $$
    select distinct person_id from enrollments
    where company_id = p_company
      and enrolled_at < to_char((p_month || '-01')::date + interval '1 month', 'YYYY-MM-DD')
      and (left_at is null or left_at >= p_month || '-01')
  $$;

-- US5: aggregates only; any count over fewer than 5 people is withheld (k = 5).
create function public.company_dashboard(p_company uuid, p_month text) returns jsonb
  language plpgsql stable security definer set search_path = public as $$
declare
  k constant integer := 5;
  m_start date := (p_month || '-01')::date;
  m_end date := ((p_month || '-01')::date + interval '1 month')::date;
  enrolled integer;
  active integer;
  grps integer;
  trips integer;
begin
  perform company_must_be_hr(p_company);
  select count(*) into enrolled from company_month_people(p_company, p_month);
  -- Riders or drivers on a group ride in the month, or a one-off seat.
  with people as (select * from company_month_people(p_company, p_month) as person_id),
  legs as (
    select r.id as ride, pe.person_id from rides r
      join ride_passengers rp on rp.ride_id = r.id join people pe on pe.person_id = rp.user_id
      where r.ride_date >= m_start and r.ride_date < m_end and r.ended_at is not null
    union
    select r.id, pe.person_id from rides r join people pe on pe.person_id = r.driver_id
      where r.ride_date >= m_start and r.ride_date < m_end and r.ended_at is not null
    union
    select b.ride_id, pe.person_id from bookings b join people pe on pe.person_id = b.rider_id
      where b.trip_date >= m_start and b.trip_date < m_end and b.status = 'done'
  )
  select count(distinct person_id), count(distinct ride) into active, trips from legs;
  select count(distinct gm.group_id) into grps from group_members gm
    where gm.user_id in (select * from company_month_people(p_company, p_month));
  return jsonb_build_object(
    'month', p_month,
    'enrolled', case when enrolled >= k then enrolled end,
    'active', case when active >= k then active end,
    -- Rate and trips are built from the active people: withheld with them.
    'carpoolRatePct', case when active >= k and enrolled >= k then (active * 100) / enrolled end,
    'tripsShared', case when active >= k then trips end,
    'groups', case when active >= k then grps end);
end $$;

-- US6: one line per leg for employees who said yes; nobody else, ever.
create function public.company_statement(p_company uuid, p_month text) returns jsonb
  language plpgsql stable security definer set search_path = public as $$
declare
  m_start date := (p_month || '-01')::date;
  m_end date := ((p_month || '-01')::date + interval '1 month')::date;
begin
  perform company_must_be_hr(p_company);
  return coalesce((
    select jsonb_agg(jsonb_build_object('name', e.name, 'date', s.ride_date, 'leg', s.leg, 'sharePaid', s.amount)
                     order by e.name, s.ride_date, s.leg)
    from (select distinct on (person_id) person_id, name from enrollments
          where company_id = p_company order by person_id, enrolled_at desc) e
    join hr_consents hc on hc.person_id = e.person_id and hc."on"
    join lateral (
      select m.ride_date, coalesce(r.leg, b.leg) as leg, m.amount
      from share_marks m
      left join rides r on r.id = m.ride_id
      left join bookings b on b.ride_id = m.ride_id and b.rider_id = m.rider_id
      where m.rider_id = e.person_id and m.outcome = 'received'
        and m.ride_date >= m_start and m.ride_date < m_end
    ) s on true
    where e.person_id in (select * from company_month_people(p_company, p_month))), '[]'::jsonb);
end $$;

revoke all on function public.company_log_line(uuid, text, text, text), public.company_month_people(uuid, text)
  from public, anon, authenticated;
revoke all on function public.company_register(text, text[], text), public.company_for_domain(text),
  public.company_enroll(), public.company_leave(), public.company_remove_employee(uuid, text),
  public.company_add_domain(uuid, text), public.company_remove_domain(uuid, text),
  public.company_set_consent(boolean), public.company_dashboard(uuid, text),
  public.company_statement(uuid, text), public.is_hr_of(uuid), public.company_must_be_hr(uuid) from public, anon;
grant execute on function public.company_register(text, text[], text), public.company_for_domain(text),
  public.company_enroll(), public.company_leave(), public.company_remove_employee(uuid, text),
  public.company_add_domain(uuid, text), public.company_remove_domain(uuid, text),
  public.company_set_consent(boolean), public.company_dashboard(uuid, text),
  public.company_statement(uuid, text), public.is_hr_of(uuid) to authenticated;
