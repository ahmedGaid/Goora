# Writes marketplace_vectors.json: 005's driver day rule (research R4 — the 2-trip
# limit and the +/-30 min join) and the booking refund (research R7), computed
# independently of lib/features/marketplace/domain/*.dart and
# supabase/functions/_shared/marketplace.ts. contracts/marketplace-rules.md lists
# the required rows.
# Run: python test/fixtures/gen_marketplace_vectors.py
import json
import os

MAX_TRIPS = 2
JOIN_WINDOW = 30  # minutes, inclusive
SZ, OCT, SV = "sheikhZayed", "october", "smartVillage"


def hm(s):
    h, m = s.split(":")
    return int(h) * 60 + int(m)


def trip(id, leg, at, seats=3, taken=1, frm=None, to=None, dur=40):
    frm = frm or (SZ if leg == "going" else SV)
    to = to or (SV if leg == "going" else SZ)
    return dict(id=id, leg=leg, **{"from": frm}, to=to, departure=hm(at), durationMinutes=dur, seats=seats, taken=taken)


def cand(leg, at, frm=None, to=None, dur=40, daily=False, leads=False):
    frm = frm or (SZ if leg == "going" else SV)
    to = to or (SV if leg == "going" else SZ)
    return dict(leg=leg, **{"from": frm}, to=to, departure=hm(at), durationMinutes=dur, daily=daily, leadsGroup=leads)


def fit(trips, c):
    """Research R4, first match wins."""
    near = sorted(
        (abs(t["departure"] - c["departure"]), t["id"], t)
        for t in trips
        if (t["leg"], t["from"], t["to"]) == (c["leg"], c["from"], c["to"])
        and abs(t["departure"] - c["departure"]) <= JOIN_WINDOW
    )
    with_seat = [t for _, _, t in near if t["taken"] < t["seats"]]
    if with_seat:
        return dict(kind="join", tripId=with_seat[0]["id"])
    if near:
        return dict(kind="full", tripId=near[0][2]["id"])
    if len(trips) >= MAX_TRIPS:
        return dict(kind="limitReached")
    if c["leg"] in {t["leg"] for t in trips}:
        return dict(kind="doesntFit")
    if c["daily"] and c["leadsGroup"]:
        return dict(kind="oneGroupOnly")
    c_minutes = set(range(c["departure"], c["departure"] + c["durationMinutes"]))
    for t in trips:
        if c_minutes & set(range(t["departure"], t["departure"] + t["durationMinutes"])):
            return dict(kind="overlap")
    return dict(kind="create", tripsLeftAfter=max(0, MAX_TRIPS - len(trips)) - 1)


def refund(paid_total, fee, owed):
    """Research R7: the fee is inside paid_total and never part of owed."""
    back = paid_total - owed
    if back > paid_total:
        back = paid_total
    return back if back > 0 else 0


FIT = [
    ("fit: empty day creates", [], cand("going", "7:30")),
    ("fit: join within 30", [trip("t1", "going", "7:30")], cand("going", "8:00")),
    ("fit: 31 min is not a join", [trip("t1", "going", "7:30")], cand("going", "8:01")),
    ("fit: join beats limit", [trip("t1", "going", "7:30"), trip("t2", "return", "17:00")], cand("going", "7:45")),
    ("fit: full", [trip("t1", "going", "7:30", taken=3)], cand("going", "7:40")),
    ("fit: other direction creates", [trip("t1", "going", "7:30")], cand("return", "17:00")),
    ("fit: two trips -> limit", [trip("t1", "going", "7:30"), trip("t2", "return", "17:00")], cand("going", "9:30")),
    ("fit: group leg counts", [trip("g:sz-0725:going", "going", "7:25", taken=3)], cand("return", "17:00")),
    ("fit: other route same leg", [trip("t1", "going", "7:30")], cand("going", "7:30", frm=OCT)),
    ("fit: one daily group", [], cand("going", "7:30", daily=True, leads=True)),
    ("fit: once ok when leading", [], cand("going", "7:30", leads=True)),
    ("fit: overlap other direction", [trip("t1", "going", "7:30")], cand("return", "8:00")),
    ("fit: back-to-back ok", [trip("t1", "going", "7:30")], cand("return", "8:10")),
    # Edge rows.
    ("fit: join picks the nearest departure", [trip("a", "going", "7:10"), trip("b", "going", "7:40")], cand("going", "7:35")),
    ("fit: join tie -> lowest id", [trip("b", "going", "7:20"), trip("a", "going", "7:50")], cand("going", "7:35")),
    ("fit: join 30 min earlier (inclusive)", [trip("t1", "going", "7:30")], cand("going", "7:00")),
    ("fit: join skips a full trip for one with a seat", [trip("a", "going", "7:30", taken=3), trip("b", "going", "7:50")], cand("going", "7:35")),
    ("fit: limit with a joinable full trip -> full", [trip("t1", "going", "7:30", taken=3), trip("t2", "return", "17:00")], cand("going", "7:40")),
    ("fit: overlap half-open, ends at start ok", [trip("t1", "going", "7:30")], cand("return", "6:50")),
    ("fit: overlap half-open, one minute in", [trip("t1", "going", "7:30")], cand("return", "6:51")),
    ("fit: full, return leg", [trip("t1", "return", "17:00", taken=3)], cand("return", "17:30")),
]

REFUND = [
    ("refund: before cut-off", 44, 4, 0),
    ("refund: after cut-off half share", 44, 4, 20),
    ("refund: subscriber after cut-off", 40, 0, 20),
    ("refund: cash", 0, 0, 0),
    ("refund: no-show full share keeps the fee coming back", 44, 4, 40),
    ("refund: never negative", 0, 0, 20),
]

out = dict(
    fit=[dict(name=n, trips=t, candidate=c, expect=fit(t, c)) for n, t, c in FIT],
    refund=[dict(name=n, paidTotal=p, fee=f, owed=o, expect=refund(p, f, o)) for n, p, f, o in REFUND],
)
path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "marketplace_vectors.json")
with open(path, "w", newline="\n") as f:
    json.dump(out, f, indent=1)
print(f"{len(out['fit'])} fit + {len(out['refund'])} refund -> {path}")
