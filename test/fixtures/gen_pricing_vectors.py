# Writes pricing_vectors.json: the 004 v2.1 per-trip price (brief 6.7, research R6,
# the "fee sits inside the cap" amendment, research R17), computed independently of
# the Dart/TS code with decimal half-up rounding.
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
    ))

path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "pricing_vectors.json")
with open(path, "w", newline="\n") as f:
    json.dump(dict(cases=cases), f, indent=1)
print(f"{len(cases)} cases -> {path}")
