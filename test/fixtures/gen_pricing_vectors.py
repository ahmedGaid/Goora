# Writes pricing_vectors.json: the 004 v2 per-trip price (brief 6.7, research R6),
# computed independently of the Dart/TS code with decimal half-up rounding.
# Run: python test/fixtures/gen_pricing_vectors.py
import json
import os
from decimal import Decimal, ROUND_HALF_UP

FEE_RATE = Decimal("0.10")

# The +/-20% contribution range in 2 EGP steps (brief 6.2), plus odd values that
# exercise the half-up edge.
CONTRIBUTIONS = list(range(32, 49, 2)) + [25, 35, 45, 15, 5, 0]
MODES = [
    ("wallet", False, False),
    ("subscriber", True, False),
    ("cash", False, True),
]

cases = []
for c in CONTRIBUTIONS:
    for mode, subscriber, cash in MODES:
        fee = 0 if (subscriber or cash) else int((Decimal(c) * FEE_RATE).quantize(Decimal(1), rounding=ROUND_HALF_UP))
        cases.append(dict(
            name=f"{c} EGP, {mode}",
            contribution=c,
            isSubscriber=subscriber,
            isCashTrial=cash,
            fee=fee,
            total=c + fee,
        ))

path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "pricing_vectors.json")
with open(path, "w", newline="\n") as f:
    json.dump(dict(cases=cases), f, indent=1)
print(f"{len(cases)} cases -> {path}")
