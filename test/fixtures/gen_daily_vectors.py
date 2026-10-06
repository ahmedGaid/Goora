# Shared vectors for the 003 daily-commute rules (contracts/edge-functions.md).
# Attendance and reliability expectations are written by hand and checked
# here against a small reference; rotation and backup expectations come from
# the independent reference below. Dart: test/unit/daily_vectors_test.dart.
# Node: supabase/functions/_shared/{attendance,reliability,rotation,backup}.test.ts.
# Regenerate: python test/fixtures/gen_daily_vectors.py
import json, math, os
from datetime import date, datetime, timedelta
from fractions import Fraction

HERE = os.path.dirname(os.path.abspath(__file__))
DAYS = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat']


def d(s): return date.fromisoformat(s)
def iso(x): return x.isoformat()
def wt(s): return datetime.fromisoformat(s)
def wts(x): return x.strftime('%Y-%m-%dT%H:%M:%S')
def weekday(x): return DAYS[(x.weekday() + 1) % 7]


def dump(name, cases):
    with open(os.path.join(HERE, name), 'w', newline='\n') as f:
        json.dump(dict(cases=cases), f, indent=1)
        f.write('\n')
    print(f'{name}: {len(cases)} cases')


# ---------------------------------------------------------------- attendance
CUTOFF_H, WAIT = 21, 5


def cutoff(ride): return datetime.combine(d(ride) - timedelta(days=1), datetime.min.time()).replace(hour=CUTOFF_H)
def late(ride, made): return wt(made) >= cutoff(ride)


def ref_attendance(fn, i):
    if fn == 'cancel':
        lt = late(i['rideDate'], i['madeAt'])
        charges = [i['share'] // 2 if lt else 0 for _ in i['legs']]
        return dict(cutoff=wts(cutoff(i['rideDate'])), late=lt, kind='lateCancel' if lt else 'freeCancel',
                    charges=charges, total=sum(charges))
    if fn == 'canCancel':
        return wt(i['madeAt']) < wt(i['pickup'])
    if fn == 'undo':
        now, a = wt(i['now']), i['absence']
        if now >= wt(i['pickup']): return 'refusedTooLate'
        if a['kind'] == 'freeCancel' and i['waitlistWaiting'] and now >= cutoff(a['date']): return 'refusedSeatTaken'
        return 'ok'
    if fn == 'noShow':
        avail = wt(i['arrivedAt']) + timedelta(minutes=WAIT)
        return dict(availableAt=wts(avail), allowed=wt(i['now']) >= avail)
    if fn == 'standing':
        return 'removal' if i['count'] >= 3 else 'warning' if i['count'] >= 2 else 'ok'
    if fn == 'driverNoShow':
        return (not i['checkedIn'] and not i['cancelled']
                and wt(i['now']) >= wt(i['firstPickup']) + timedelta(minutes=WAIT))
    if fn == 'noShowCharge':
        return i['share']
    raise ValueError(fn)


attendance = []


def att(name, fn, i, expect):
    got = ref_attendance(fn, i)
    assert got == expect, (name, got, expect)
    attendance.append(dict(name=name, fn=fn, input=i, expect=expect))


TUE, MON_CUT = '2026-10-06', '2026-10-05T21:00:00'
att('8:59:59 PM the evening before is free', 'cancel',
    dict(rideDate=TUE, madeAt='2026-10-05T20:59:59', share=40, legs=['going']),
    dict(cutoff=MON_CUT, late=False, kind='freeCancel', charges=[0], total=0))
att('9:00 PM the evening before is late: half the share (20 EGP)', 'cancel',
    dict(rideDate=TUE, madeAt='2026-10-05T21:00:00', share=40, legs=['going']),
    dict(cutoff=MON_CUT, late=True, kind='lateCancel', charges=[20], total=20))
att('both legs late = 40 EGP', 'cancel',
    dict(rideDate=TUE, madeAt='2026-10-06T06:30:00', share=40, legs=['going', 'ret']),
    dict(cutoff=MON_CUT, late=True, kind='lateCancel', charges=[20, 20], total=40))
att('both legs free days ahead', 'cancel',
    dict(rideDate=TUE, madeAt='2026-10-02T09:00:00', share=40, legs=['going', 'ret']),
    dict(cutoff=MON_CUT, late=False, kind='freeCancel', charges=[0, 0], total=0))
att('a Sunday ride: cut-off is Saturday 9 PM (not a working day)', 'cancel',
    dict(rideDate='2026-10-11', madeAt='2026-10-10T21:30:00', share=40, legs=['ret']),
    dict(cutoff='2026-10-10T21:00:00', late=True, kind='lateCancel', charges=[20], total=20))
att('cut-off across a month end', 'cancel',
    dict(rideDate='2026-11-01', madeAt='2026-10-31T20:00:00', share=60, legs=['going']),
    dict(cutoff='2026-10-31T21:00:00', late=False, kind='freeCancel', charges=[0], total=0))
att('cancel one second before pickup', 'canCancel', dict(pickup='2026-10-06T07:25:00', madeAt='2026-10-06T07:24:59'), True)
att('no cancel at pickup time', 'canCancel', dict(pickup='2026-10-06T07:25:00', madeAt='2026-10-06T07:25:00'), False)
FREE, LATE = dict(date=TUE, kind='freeCancel'), dict(date=TUE, kind='lateCancel')
P = '2026-10-06T07:25:00'
att('undo a free cancel after 9 PM with a waitlist: seat taken', 'undo',
    dict(absence=FREE, now='2026-10-05T21:00:00', pickup=P, waitlistWaiting=True), 'refusedSeatTaken')
att('undo a free cancel after 9 PM, nobody waiting', 'undo',
    dict(absence=FREE, now='2026-10-05T22:00:00', pickup=P, waitlistWaiting=False), 'ok')
att('undo a free cancel before 9 PM with a waitlist', 'undo',
    dict(absence=FREE, now='2026-10-05T20:59:59', pickup=P, waitlistWaiting=True), 'ok')
att('undo a late cancel until pickup', 'undo',
    dict(absence=LATE, now='2026-10-06T07:24:59', pickup=P, waitlistWaiting=True), 'ok')
att('no undo at pickup', 'undo',
    dict(absence=LATE, now=P, pickup=P, waitlistWaiting=False), 'refusedTooLate')
att('no-show at 4:59 after arrival: refused', 'noShow',
    dict(arrivedAt='2026-10-06T07:25:00', now='2026-10-06T07:29:59'),
    dict(availableAt='2026-10-06T07:30:00', allowed=False))
att('no-show at 5:00 after arrival: allowed', 'noShow',
    dict(arrivedAt='2026-10-06T07:25:00', now='2026-10-06T07:30:00'),
    dict(availableAt='2026-10-06T07:30:00', allowed=True))
att('no-show wait across midnight', 'noShow',
    dict(arrivedAt='2026-10-06T23:57:30', now='2026-10-07T00:02:30'),
    dict(availableAt='2026-10-07T00:02:30', allowed=True))
for n, s in [(0, 'ok'), (1, 'ok'), (2, 'warning'), (3, 'removal'), (4, 'removal')]:
    att(f'{n} no-shows this month: {s}', 'standing', dict(count=n), s)
DP = '2026-10-06T07:15:00'
att('driver not checked in at first pickup + 4:59: not yet', 'driverNoShow',
    dict(firstPickup=DP, now='2026-10-06T07:19:59', checkedIn=False, cancelled=False), False)
att('driver not checked in at first pickup + 5:00: no-show', 'driverNoShow',
    dict(firstPickup=DP, now='2026-10-06T07:20:00', checkedIn=False, cancelled=False), True)
att('driver checked in: never a no-show', 'driverNoShow',
    dict(firstPickup=DP, now='2026-10-06T08:00:00', checkedIn=True, cancelled=False), False)
att('driver who cancelled: never a no-show', 'driverNoShow',
    dict(firstPickup=DP, now='2026-10-06T08:00:00', checkedIn=False, cancelled=True), False)
att('a no-show pays the full share', 'noShowCharge', dict(share=40), 40)
dump('attendance_vectors.json', attendance)


# --------------------------------------------------------------- reliability
WINDOW = 30
MISSED = dict(kept=Fraction(0), noShow=Fraction(1), lateCancel=Fraction(1, 2), lateCantDrive=Fraction(1, 2))


def ref_reliability(today, events):
    t = d(today)
    inside = [e for e in events if t - timedelta(days=WINDOW) <= d(e['date']) < t]
    booked = len(inside)
    if booked == 0:
        pct = 100
    else:
        kept = booked - sum(MISSED[e['kind']] for e in inside)
        pct = math.floor(Fraction(100) * kept / booked + Fraction(1, 2))
    month = [e['kind'] for e in events if d(e['date']).year == t.year and d(e['date']).month == t.month]
    return dict(percent=pct,
                monthLateCancels=sum(k in ('lateCancel', 'lateCantDrive') for k in month),
                monthNoShows=sum(k == 'noShow' for k in month))


reliability = []


def rel(name, today, events, expect):
    got = ref_reliability(today, events)
    assert got == expect, (name, got, expect)
    reliability.append(dict(name=name, today=today, events=events, expect=expect))


def ev(day, kind): return dict(date=day, kind=kind)


rel('12.5 of 13 kept → 96 %', TUE,
    [ev(f'2026-09-{n:02d}', 'kept') for n in range(14, 26)] + [ev('2026-09-28', 'lateCancel')],
    dict(percent=96, monthLateCancels=0, monthNoShows=0))
rel('no booked trips → 100 %', TUE, [], dict(percent=100, monthLateCancels=0, monthNoShows=0))
rel('window: 30 days back included, 31 days back and today excluded', TUE,
    [ev('2026-09-06', 'kept'), ev('2026-09-05', 'noShow'), ev(TUE, 'noShow')],
    dict(percent=100, monthLateCancels=0, monthNoShows=1))
rel('x.5 rounds up: 3.5 of 4 → 88 %', TUE,
    [ev('2026-10-01', 'kept'), ev('2026-10-02', 'kept'), ev('2026-10-04', 'kept'), ev('2026-10-05', 'lateCancel')],
    dict(percent=88, monthLateCancels=1, monthNoShows=0))
rel('a no-show misses a whole trip: 3 of 4 → 75 %', TUE,
    [ev('2026-09-29', 'kept'), ev('2026-09-30', 'kept'), ev('2026-10-01', 'kept'), ev('2026-10-05', 'noShow')],
    dict(percent=75, monthLateCancels=0, monthNoShows=1))
rel('month counts: this calendar month only; late "can\'t drive" counts as late', TUE,
    [ev('2026-10-01', 'lateCancel'), ev('2026-10-02', 'lateCantDrive'), ev('2026-10-03', 'noShow'),
     ev('2026-10-04', 'kept'), ev('2026-10-05', 'noShow'), ev('2026-09-20', 'noShow')],
    dict(percent=33, monthLateCancels=2, monthNoShows=2))
rel('the 1st: month counts reset, the % does not', '2026-10-01',
    [ev('2026-09-28', 'noShow'), ev('2026-09-29', 'kept'), ev('2026-09-30', 'lateCancel')],
    dict(percent=50, monthLateCancels=0, monthNoShows=0))
dump('reliability_vectors.json', reliability)


# ---------------------------------------------------------- groups + members
SZ = [30.0400, 30.9800]
SV = [30.0710, 31.0170]


def off(p, dlat=0.0, dlng=0.0): return [round(p[0] + dlat, 6), round(p[1] + dlng, 6)]


def mem(i, role, woman=False, company=None, compound=None, rating=4.8, legs=('going', 'ret'), privacy='verifiedUsers',
        days=None):
    return dict(id=i, firstName=i, initials=i[:2].upper(), role=role, isWoman=woman, company=company,
                compound=compound, rating=rating, reliability=95, legs=list(legs), privacy=privacy, days=days)


def grp(members, days=('sun', 'mon', 'tue', 'wed', 'thu'), rotationStart='2026-10-04', **kw):
    g = dict(id='g1', origin='sheikhZayed', destination='smartVillage', destinationPoint=off(SV, 0.0009),
             pickupPoints=[off(SZ, 0.0027)], going='07:25', ret='17:00', days=list(days), members=members, price=40,
             freeSeatsGoing=1, freeSeatsReturn=1, detourMinutes=6, womenOnly=False, sameCompanyOnly=None,
             sameCompoundOnly=None, rotationStart=rotationStart)
    g.update(kw)
    return g


# ----------------------------------------------------------------- rotation
def ref_rotation(g, frm, to, unavailable):
    start = d(g['rotationStart'] or '2026-01-04')
    def period(x): return (x - start).days // 28
    blocked = {(u[0], u[1], u[2]) for u in unavailable}
    counts = {'going': {}, 'ret': {}}
    last = {'going': {}, 'ret': {}}
    cur = period(d(frm))
    x = start + timedelta(days=28 * cur)
    out = []
    while x <= d(to):
        if period(x) != cur:
            cur = period(x)
            counts = {'going': {}, 'ret': {}}
        if weekday(x) in g['days']:
            row = [iso(x)]
            for leg in ('going', 'ret'):
                drivers = [m for m in g['members'] if m['role'] == 'driver' and leg in m['legs']]
                ok = [m['id'] for m in drivers
                      if weekday(x) in (m['days'] or g['days']) and (m['id'], iso(x), leg) not in blocked]
                pick = min(ok, key=lambda i: (counts[leg].get(i, 0),
                                              last[leg][i].toordinal() if i in last[leg] else -1, i)) if ok else None
                if pick:
                    counts[leg][pick] = counts[leg].get(pick, 0) + 1
                    last[leg][pick] = x
                row.append(pick)
            if x >= d(frm):
                out.append(row)
        x += timedelta(days=1)
    return out


rotation = []


def rot(name, g, frm, to, unavailable=(), check=None):
    days = ref_rotation(g, frm, to, list(unavailable))
    if check: check(days)
    rotation.append(dict(name=name, group=g, **{'from': frm}, to=to, unavailable=[list(u) for u in unavailable],
                         expect=days))


def spread(rows, ids, days=None):
    if days is not None: assert len(rows) == days, len(rows)
    for col in (1, 2):
        n = [sum(r[col] == i for r in rows) for i in ids]
        assert max(n) - min(n) <= 1, n


TWO = [mem('ahmed', 'driver'), mem('mohamed', 'driver'), mem('sara', 'rider', True)]
THREE = TWO[:2] + [mem('karim', 'driver'), mem('sara', 'rider', True)]
rot('2 drivers over 4 weeks: max − min ≤ 1 per leg', grp(TWO), '2026-10-04', '2026-10-31',
    check=lambda r: spread(r, ['ahmed', 'mohamed'], days=20))
rot('3 drivers over 4 weeks: max − min ≤ 1 per leg', grp(THREE), '2026-10-04', '2026-10-31',
    check=lambda r: spread(r, ['ahmed', 'mohamed', 'karim']))
rot('a window inside a period gives the same drivers', grp(THREE), '2026-10-14', '2026-10-20')
rot('a new period resets the counts', grp(THREE), '2026-10-25', '2026-11-07')
rot('an unavailable driver is skipped and the turn moves on', grp(TWO), '2026-10-04', '2026-10-10',
    unavailable=[('ahmed', '2026-10-04', 'going'), ('mohamed', '2026-10-06', 'ret')])
rot('a driver with own days drives only on them', grp([mem('ahmed', 'driver', days=['sun', 'mon', 'tue']),
                                                       mem('mohamed', 'driver'), mem('sara', 'rider', True)]),
    '2026-10-04', '2026-10-17')
rot('a going-only driver: the return leg has no driver', grp([mem('ahmed', 'driver', legs=('going',)),
                                                              mem('sara', 'rider', True)]),
    '2026-10-04', '2026-10-08')
rot('no rotation start: the default Sunday 4 Jan 2026', grp(TWO, rotationStart=None), '2026-10-04', '2026-10-08')
dump('rotation_vectors.json', rotation)


# ------------------------------------------------------------------- backup
R = 6371000.0
LIM = dict(pickup=1000, detour=10, time=20, dest=1500)


def dist(a, b):
    la1, lo1, la2, lo2 = map(math.radians, (a[0], a[1], b[0], b[1]))
    h = math.sin((la2 - la1) / 2) ** 2 + math.cos(la1) * math.cos(la2) * math.sin((lo2 - lo1) / 2) ** 2
    return 2 * R * math.asin(math.sqrt(h))


def hm(s): h, m = s.split(':'); return int(h) * 60 + int(m)


def pickup_meters(s, g):
    """002 hard constraints for a driver seeker; metres to the pickup or None."""
    if dist(s['work'], g['destinationPoint']) > LIM['dest']: return None
    pm = min(dist(s['home'], p) for p in g['pickupPoints'])
    if pm > LIM['pickup'] or g['detourMinutes'] > LIM['detour']: return None
    if not set(s['days']) & set(g['days']): return None
    ms = g['members']
    if g['womenOnly'] and not s['isWoman']: return None
    if s['womenOnly'] and any(not m['isWoman'] for m in ms): return None
    if s['sameCompanyOnly'] and (s['company'] is None or any(m['company'] != s['company'] for m in ms)): return None
    if s['sameCompoundOnly'] and (s['compound'] is None or any(m['compound'] != s['compound'] for m in ms)): return None
    for leg in s['legs']:
        diff = abs(hm(s['departure']) - hm(g['going'])) if leg == 'going' else abs(hm(s['ret']) - hm(g['ret']))
        if diff <= LIM['time'] and any(m['role'] == 'rider' and leg in m['legs'] for m in ms):
            return pm
    return None


def accepts(p, owner, other):
    return {'verifiedUsers': True, 'womenOnly': other['isWoman'],
            'sameCompany': owner['company'] is not None and other['company'] == owner['company'],
            'sameCompound': owner['compound'] is not None and other['compound'] == owner['compound']}[p]


STEPS = ['sameGroup', 'nearbyGroup', 'sameCompany', 'sameCommunity']


def ref_backup(ride, g, candidates):
    members = {m['id']: m for m in g['members']}
    for step in STEPS:
        ok = []
        for c in candidates:
            cover = c['member']
            if c['step'] != step or not c['available']: continue
            riders = [p['memberId'] for p in ride['passengers'] if p['memberId'] != cover['id']]
            if c['freeSeats'] < len(riders): continue
            s = dict(c['seeker'], days=[x for x in c['seeker']['days'] if x == weekday(d(ride['date']))],
                     legs=[ride['leg']], isWoman=cover['isWoman'], company=cover['company'],
                     compound=cover['compound'], womenOnly=cover['privacy'] == 'womenOnly',
                     sameCompanyOnly=cover['privacy'] == 'sameCompany',
                     sameCompoundOnly=cover['privacy'] == 'sameCompound')
            pm = pickup_meters(s, g)
            if pm is None: continue
            if any(r in members and not accepts(members[r]['privacy'], members[r], cover) for r in riders): continue
            ok.append((pm, -cover['rating'], cover['id']))
        if ok:
            return dict(cover=min(ok)[2], step=step)
    return dict(cover=None, step=None)


backup = []


def bk(name, candidates, members=None, ride=None, expect_cover=None, **gkw):
    g = grp(members or BASE, **gkw)
    r = ride or RIDE
    got = ref_backup(r, g, candidates)
    assert got['cover'] == expect_cover, (name, got)
    backup.append(dict(name=name, ride=r, group=g, candidates=candidates, expect=got))


BASE = [mem('ahmed', 'driver', rating=4.9), mem('mohamed', 'driver'), mem('sara', 'rider', True),
        mem('youssef', 'rider')]
# Ahmed (planned) is away; Mohamed, off duty, rides with Sara and Youssef.
RIDE = dict(groupId='g1', date=TUE, leg='going', planned='ahmed',
            passengers=[dict(memberId=m, stopId='main-gate') for m in ('mohamed', 'sara', 'youssef')])


def seek(dlat=0.0, departure='07:30', days=('sun', 'mon', 'tue', 'wed', 'thu')):
    return dict(home=off(SZ, 0.0027 + dlat), work=SV, departure=departure, ret='17:00', days=list(days))


def cand(member, step, dlat=0.0, seats=3, available=True, **skw):
    return dict(member=member, step=step, seeker=seek(dlat, **skw), freeSeats=seats, available=available)


bk('same group before a nearby group', [
    cand(mem('nour', 'driver'), 'nearbyGroup'),
    cand(BASE[1], 'sameGroup', dlat=0.004)], expect_cover='mohamed')
bk('nearby group before the same company', [
    cand(mem('hany', 'driver', company='acme'), 'sameCompany'),
    cand(mem('nour', 'driver'), 'nearbyGroup', dlat=0.005)], expect_cover='nour')
bk('same company before the community', [
    cand(mem('tarek', 'driver'), 'sameCommunity'),
    cand(mem('hany', 'driver', company='acme'), 'sameCompany', dlat=0.006)], expect_cover='hany')
bk('within a step: least detour → highest rating → lowest id', [
    cand(mem('zeina', 'driver', True, rating=5.0), 'nearbyGroup', dlat=0.002),
    cand(mem('omar', 'driver', rating=4.7), 'nearbyGroup'),
    cand(mem('nabil', 'driver', rating=4.9), 'nearbyGroup'),
    cand(mem('adel', 'driver', rating=4.9), 'nearbyGroup')], expect_cover='adel')
bk('a women-only passenger rejects a male cover', [
    cand(mem('nour', 'driver'), 'nearbyGroup'),
    cand(mem('mona', 'driver', True), 'sameCommunity')],
    members=[BASE[0], BASE[1], mem('sara', 'rider', True, privacy='womenOnly'), BASE[3]], expect_cover='mona')
bk('an off-duty driver covering does not need a seat for themselves', [
    cand(BASE[1], 'sameGroup', seats=2)], expect_cover='mohamed')
bk('not enough free seats for every passenger', [
    cand(mem('nour', 'driver'), 'nearbyGroup', seats=2)], expect_cover=None)
bk('unavailable, wrong day, too late or too far: no cover', [
    cand(mem('a1', 'driver'), 'nearbyGroup', available=False),
    cand(mem('a2', 'driver'), 'nearbyGroup', days=('sun', 'mon')),
    cand(mem('a3', 'driver'), 'nearbyGroup', departure='07:50'),
    cand(mem('a4', 'driver'), 'nearbyGroup', dlat=0.010)], expect_cover=None)
bk('departure exactly 20 min away still covers', [
    cand(mem('a3', 'driver'), 'nearbyGroup', departure='07:45')], expect_cover='a3')
bk('a cover who wants same company only, in a mixed group: no', [
    cand(mem('hany', 'driver', company='acme', privacy='sameCompany'), 'sameCompany')], expect_cover=None)
bk('no candidates → none', [], expect_cover=None)
dump('backup_vectors.json', backup)
