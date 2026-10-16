# Writes pricing_vectors.json: the 004 v2.1 per-trip price (brief 6.7, research R6,
# the "fee sits inside the cap" amendment, research R17), computed independently of
# the Dart/TS code with decimal half-up rounding.
# 005 adds the cash amount (FR-029, research R3): every case gains `cash`.
# Run: python test/fixtures/gen_pricing_vectors.py
import json
import os
from decimal import Decimal, ROUND_HALF_UP

FEE_RATE = Decimal("0.10")

# The demo corridor's basis (004 v2.1 research R15/R16): 160 EGP trip, 3 rider
# seats, equal share 53. Every existing contribution is <= 48, so the cap never
# trims these — see the "cap:" rows below for the cases where it does.
TRIP_COST = 160
RIDER_SEATS = 3

# The +/-20% contribution range in 2 EGP steps (brief 6.2), plus odd values that
# exercise the half-up edge.
CONTRIBUTIONS = list(range(32, 49, 2)) + [25, 35, 45, 15, 5, 0]
MODES = [
    ("wallet", False, False),
    ("subscriber", True, False),
    ("cash", False, True),
]


def fee_for(contribution, trip_cost, rider_seats, subscriber, cash):
    if subscriber or cash:
        return 0
    rounded = int((Decimal(contribution) * FEE_RATE).quantize(Decimal(1), rounding=ROUND_HALF_UP))
    room = trip_cost // rider_seats - contribution
    return max(0, min(rounded, room))


STEP = 2
RANGE_PERCENT = 20


def price_range(trip_cost, riders):
    """002's +/-20% range in 2 EGP steps, top capped at an equal share (brief 6.2)."""
    s = int((Decimal(trip_cost) / ((riders + 1) * STEP)).quantize(Decimal(1), rounding=ROUND_HALF_UP)) * STEP
    lo = -(-s * (100 - RANGE_PERCENT) // (100 * STEP)) * STEP
    hi = (s * (100 + RANGE_PERCENT) // (100 * STEP)) * STEP
    cap = trip_cost // (riders * STEP) * STEP
    return lo, min(hi, cap)


def cash_for(c, trip_cost, rider_seats):
    """Research R3: nearest 5 EGP, kept inside the range; None = cash not offered."""
    down = c - c % 5
    up = down + 5
    lo, hi = price_range(trip_cost, rider_seats)
    result = down if c % 5 <= 2 else up
    if result > hi:
        result = down
    if result < lo:
        result = up
    if result < lo or result > hi or result == 0:
        return None
    return result


cases = []
for c in CONTRIBUTIONS:
    for mode, subscriber, cash in MODES:
        fee = fee_for(c, TRIP_COST, RIDER_SEATS, subscriber, cash)
        cases.append(dict(
            name=f"{c} EGP, {mode}",
            contribution=c,
            tripCost=TRIP_COST,
            riderSeats=RIDER_SEATS,
            isSubscriber=subscriber,
            isCashTrial=cash,
            fee=fee,
            total=c + fee,
            cash=cash_for(c, TRIP_COST, RIDER_SEATS),
        ))

# The spec's "fee sits inside the cap" table (004 v2.1 spec, Amendment).
CAP_ROWS = [
    ("cap: 160/3 suggested", 40, 160, 3),
    ("cap: 160/3 top of range", 48, 160, 3),
    ("cap: 160/4 suggested", 32, 160, 4),
    ("cap: 160/4 top of range, trimmed", 38, 160, 4),
    ("cap: 96/4 at the share, no room", 24, 96, 4),
]
for name, c, trip_cost, rider_seats in CAP_ROWS:
    fee = fee_for(c, trip_cost, rider_seats, False, False)
    cases.append(dict(
        name=name,
        contribution=c,
        tripCost=trip_cost,
        riderSeats=rider_seats,
        isSubscriber=False,
        isCashTrial=False,
        fee=fee,
        total=c + fee,
        cash=cash_for(c, trip_cost, rider_seats),
    ))

# The spec's cash rounding examples (005 contracts/pricing.md, research R3).
CASH_ROWS = [
    ("cash: 44 up to 45", 44, 160, 3),
    ("cash: 42 down to 40", 42, 160, 3),
    ("cash: 48 down, 50 passes range top 48", 48, 160, 3),
    ("cash: 32 up, 30 below range floor 32", 32, 160, 3),
    ("cash: 41 down to 40", 41, 160, 3),
    ("cash: 38 down, 40 passes range top 38", 38, 160, 4),
    ("cash: 38 down at 156/4, range top 38", 38, 156, 4),
    ("cash: no multiple of 5 in range 2-2", 2, 8, 4),
]
for name, c, trip_cost, rider_seats in CASH_ROWS:
    cases.append(dict(
        name=name,
        contribution=c,
        tripCost=trip_cost,
        riderSeats=rider_seats,
        isSubscriber=False,
        isCashTrial=True,
        fee=0,
        total=c,
        cash=cash_for(c, trip_cost, rider_seats),
    ))

# 006 Cairo <-> Ismailia: 300 EGP per leg (spec FR / research R8, cap_sweep.ts).
# Rows are appended after the 004/005 rows, which stay byte-identical.
CORRIDOR_COST = 300
CORRIDOR_ROWS = [
    # (contribution, rider seats, modes)  3 seats: range 62-90, suggested 76.
    (62, 3, MODES), (76, 3, MODES), (90, 3, MODES),
    # 4 seats: range 48-72, suggested 60. Wallet only.
    (48, 4, MODES[:1]), (60, 4, MODES[:1]), (72, 4, MODES[:1]),
]
for c, rider_seats, modes in CORRIDOR_ROWS:
    for mode, subscriber, cash in modes:
        fee = fee_for(c, CORRIDOR_COST, rider_seats, subscriber, cash)
        cases.append(dict(
            name=f"corridor 300/{rider_seats}: {c} EGP, {mode}",
            contribution=c,
            tripCost=CORRIDOR_COST,
            riderSeats=rider_seats,
            isSubscriber=subscriber,
            isCashTrial=cash,
            fee=fee,
            total=c + fee,
            cash=cash_for(c, CORRIDOR_COST, rider_seats),
        ))

path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "pricing_vectors.json")
with open(path, "w", newline="\n") as f:
    json.dump(dict(cases=cases), f, indent=1)
print(f"{len(cases)} cases -> {path}")
