# Writes company_vectors.json: 010's money rules (research R3 — coverage at an
# exact minute, peak enrolled per day, billed seats, invoice total, due day and
# suspension day, the company's active windows) and the dashboard's k = 5
# suppression, computed independently of
# lib/features/company/domain/company_rules.dart and
# supabase/functions/_shared/company.ts. contracts/company-rules.md lists the
# required rows.
# Run: python test/fixtures/gen_company_vectors.py
import json
import os
from datetime import date

DUE_AFTER_DAYS = 15  # Q10 default
GRACE_DAYS = 7  # Q10 default
SUPPRESS_BELOW = 5  # spec clarification
EPOCH = date(2000, 1, 1)
DAY = 24 * 60
INF = float("inf")


def day(y, m, d):
    """The shared day scale: days since 2000-01-01 (SharePolicy.dayOf)."""
    return (date(y, m, d) - EPOCH).days


def at(y, m, d, hh=0, mm=0):
    """The shared minute scale (SharePolicy.minuteOf)."""
    return day(y, m, d) * DAY + hh * 60 + mm


def w(frm, to=None):
    return {"from": frm, "to": to}


def end(x):
    return INF if x["to"] is None else x["to"]


def merge(ws):
    """Sorted, overlapping or touching windows joined, empty ones dropped."""
    ws = sorted((x for x in ws if end(x) > x["from"]), key=lambda x: (x["from"], end(x)))
    out = []
    for x in ws:
        if out and x["from"] <= end(out[-1]):
            if end(x) > end(out[-1]):
                out[-1] = w(out[-1]["from"], x["to"])
        else:
            out.append(dict(x))
    return out


def coverage(enrolled, active):
    pieces = []
    for a in enrolled:
        for b in active:
            lo = max(a["from"], b["from"])
            hi = min(end(a), end(b))
            if hi > lo:
                pieces.append(w(lo, None if hi == INF else hi))
    return merge(pieces)


def covered(ws, minute):
    return any(x["from"] <= minute < end(x) for x in ws)


def peak(by_person, from_day, to_day):
    best = 0
    for d in range(from_day, to_day):
        lo, hi = d * DAY, (d + 1) * DAY
        n = sum(
            1
            for ws in by_person.values()
            if any(end(x) > x["from"] and x["from"] < hi and end(x) > lo for x in ws)
        )
        best = max(best, n)
    return best


def billed(peak_, minimum):
    return max(peak_, minimum)


def due_day(issue):
    return issue + DUE_AFTER_DAYS


def suspend_from_day(due):
    return due + GRACE_DAYS + 1


def active_windows(approved_at, ended_at, overdue):
    """[approvedAt, endedAt) minus every [suspendFrom, paidAt) of an invoice
    still unpaid at its suspendFrom."""
    gaps = merge(
        w(o["suspendFrom"], o["paidAt"])
        for o in overdue
        if o["paidAt"] is None or o["paidAt"] > o["suspendFrom"]
    )
    out = []
    cur = approved_at
    stop = INF if ended_at is None else ended_at
    for g in gaps:
        if g["from"] >= stop:
            break
        if g["from"] > cur:
            out.append(w(cur, g["from"]))
        cur = max(cur, end(g))
        if cur >= stop:
            break
    if cur < stop:
        out.append(w(cur, ended_at))
    return out


def suppress(count):
    return None if count < SUPPRESS_BELOW else count


OCT1, NOV1, DEC1 = at(2026, 10, 1), at(2026, 11, 1), at(2026, 12, 1)
OCT_DAYS = (day(2026, 10, 1), day(2026, 11, 1))
APPROVED = at(2026, 9, 1, 9, 0)
SUSP_NOV = at(2026, 11, 24)  # issued 1 Nov -> due 16 Nov -> suspended 24 Nov 00:00
SUSP_DEC = at(2026, 12, 24)

COVERAGE = [
    ("coverage: enrolled before approval starts at approval",
     [w(at(2026, 8, 20, 10))], [w(APPROVED)]),
    ("coverage: enrolled inside a suspension starts when it is paid",
     [w(at(2026, 11, 25, 8))], [w(APPROVED, SUSP_NOV), w(at(2026, 11, 27, 12))]),
    ("coverage: suspension cuts an open enrollment in two",
     [w(at(2026, 10, 3, 8))], [w(APPROVED, SUSP_NOV), w(at(2026, 11, 27, 12))]),
    ("coverage: leave and re-join keep two windows",
     [w(at(2026, 10, 3, 8), at(2026, 10, 20, 17)), w(at(2026, 10, 25, 9))], [w(APPROVED)]),
    ("coverage: both open stays open", [w(at(2026, 10, 3, 8))], [w(APPROVED)]),
    ("coverage: left before approval -> nothing", [w(at(2026, 8, 1), at(2026, 8, 31))], [w(APPROVED)]),
    ("coverage: ended contract closes an open enrollment",
     [w(at(2026, 10, 3, 8))], [w(APPROVED, at(2027, 9, 1))]),
    ("coverage: touching windows merge", [w(at(2026, 10, 3), at(2026, 10, 5)), w(at(2026, 10, 5))], [w(APPROVED)]),
    ("coverage: no company window -> nothing", [w(at(2026, 10, 3))], []),
    ("coverage: empty window dropped", [w(at(2026, 10, 3), at(2026, 10, 3))], [w(APPROVED)]),
]

WIN = [w(at(2026, 10, 3, 8), at(2026, 10, 20, 17)), w(at(2026, 10, 25, 9))]
COVERED = [
    ("covered: exactly at from", WIN, at(2026, 10, 3, 8)),
    ("covered: one minute before from", WIN, at(2026, 10, 3, 8) - 1),
    ("covered: exactly at to", WIN, at(2026, 10, 20, 17)),
    ("covered: one minute before to", WIN, at(2026, 10, 20, 17) - 1),
    ("covered: in the gap", WIN, at(2026, 10, 22, 12)),
    ("covered: open window far ahead", WIN, at(2030, 1, 1)),
    ("covered: no windows", [], at(2026, 10, 10)),
]

TWELVE = {f"e{i:02d}": [w(at(2026, 9, 15, 9))] for i in range(1, 13)}
PEAK = [
    ("peak: 12 people all month -> 12", TWELVE),
    ("peak: leave on the 20th, re-join on the 25th counts once",
     {"a": [w(at(2026, 10, 1, 9), at(2026, 10, 20, 12)), w(at(2026, 10, 25, 9))]}),
    ("peak: non-overlapping halves of the month -> 1",
     {"a": [w(OCT1, at(2026, 10, 16))], "b": [w(at(2026, 10, 16))]}),
    ("peak: A leaves 10:00, B joins 14:00 same day -> 2 (day-based)",
     {"a": [w(OCT1, at(2026, 10, 12, 10))], "b": [w(at(2026, 10, 12, 14))]}),
    ("peak: nobody -> 0", {}),
    ("peak: leaving at 00:00 does not count that day",
     {"a": [w(OCT1, at(2026, 10, 12))], "b": [w(at(2026, 10, 12, 8))]}),
    ("peak: enrolled only on the last day counts", {"a": [w(at(2026, 10, 31, 23, 59))]}),
    ("peak: joined next month does not count", {"a": [w(NOV1)]}),
    ("peak: left before the month does not count", {"a": [w(at(2026, 9, 1), OCT1)]}),
    ("peak: empty window does not count", {"a": [w(at(2026, 10, 5, 9), at(2026, 10, 5, 9))]}),
    ("peak: 34 people -> 34", {f"p{i:02d}": [w(at(2026, 10, 1 + i % 28, 9))] for i in range(34)}),
]

BILLING = [
    ("billing: 12 enrolled, minimum 20 -> 20 x 99", 12, 20, 99),
    ("billing: 34 enrolled, minimum 20 -> 34 x 99", 34, 20, 99),
    ("billing: nobody enrolled still pays the minimum", 0, 20, 99),
    ("billing: exactly the minimum", 20, 20, 99),
    ("billing: price 75 (Q1 alternative)", 34, 20, 75),
]

DUE = [
    ("due: issued 1 Nov -> due 16 Nov -> suspended 24 Nov", day(2026, 11, 1)),
    ("due: issued 1 Dec -> due 16 Dec -> suspended 24 Dec", day(2026, 12, 1)),
    ("due: issued 1 Feb 2027 -> due 16 Feb -> suspended 24 Feb", day(2027, 2, 1)),
]

ACTIVE = [
    ("active: never overdue stays open", APPROVED, None, []),
    ("active: paid before suspension leaves no gap", APPROVED, None,
     [dict(suspendFrom=SUSP_NOV, paidAt=at(2026, 11, 10, 11))]),
    ("active: paid exactly at suspension leaves no gap", APPROVED, None,
     [dict(suspendFrom=SUSP_NOV, paidAt=SUSP_NOV)]),
    ("active: paid during suspension closes the gap at paidAt", APPROVED, None,
     [dict(suspendFrom=SUSP_NOV, paidAt=at(2026, 11, 27, 12))]),
    ("active: never paid leaves an open gap", APPROVED, None,
     [dict(suspendFrom=SUSP_NOV, paidAt=None)]),
    ("active: contract ended", APPROVED, at(2027, 9, 1), []),
    ("active: suspended then ended", APPROVED, at(2026, 12, 1),
     [dict(suspendFrom=SUSP_NOV, paidAt=None)]),
    ("active: two overdue invoices, one payment each", APPROVED, None,
     [dict(suspendFrom=SUSP_NOV, paidAt=at(2026, 11, 26, 9)),
      dict(suspendFrom=SUSP_DEC, paidAt=at(2026, 12, 28, 15))]),
    ("active: second invoice overdue while the first is still unpaid", APPROVED, None,
     [dict(suspendFrom=SUSP_NOV, paidAt=at(2027, 1, 2, 10)),
      dict(suspendFrom=SUSP_DEC, paidAt=at(2026, 12, 30, 10))]),
    ("active: suspension after the end changes nothing", APPROVED, at(2026, 11, 20),
     [dict(suspendFrom=SUSP_NOV, paidAt=None)]),
]

SUPPRESS = [("suppress: 4 -> fewer than 5", 4), ("suppress: 5 -> 5", 5), ("suppress: 0 -> fewer than 5", 0),
            ("suppress: 120 -> 120", 120)]

out = dict(
    coverage=[dict(name=n, enrolled=e, companyActive=a, expect=coverage(e, a)) for n, e, a in COVERAGE],
    covered=[dict(name=n, windows=ws, minute=m, expect=covered(ws, m)) for n, ws, m in COVERED],
    peakEnrolled=[dict(name=n, byPerson=b, monthFromDay=OCT_DAYS[0], monthToDay=OCT_DAYS[1],
                       expect=peak(b, *OCT_DAYS)) for n, b in PEAK],
    billing=[dict(name=n, peak=p, minimumSeats=m, pricePerSeat=pr, billedSeats=billed(p, m),
                  total=billed(p, m) * pr) for n, p, m, pr in BILLING],
    due=[dict(name=n, issueDay=i, dueDay=due_day(i), suspendFromDay=suspend_from_day(due_day(i))) for n, i in DUE],
    activeWindows=[dict(name=n, approvedAt=a, endedAt=e, overdue=o, expect=active_windows(a, e, o))
                   for n, a, e, o in ACTIVE],
    suppress=[dict(name=n, count=c, expect=suppress(c)) for n, c in SUPPRESS],
)
path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "company_vectors.json")
with open(path, "w", newline="\n") as f:
    json.dump(out, f, indent=1)
print(" + ".join(f"{len(v)} {k}" for k, v in out.items()) + f" -> {path}")
