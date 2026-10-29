# 010 walk 5 — quickstarts 5, 6, 7 (2026-10-29)

Build: branch `010-company-network` @ `d0190f2`, debug APK, emulator-5554 (Android SDK x86_64, 1080×2400).
Arabic RTL for 5 and 6; 7 in Arabic, then English at font scale 1.3 (reset to 1.0 after).
Path: clean data → fake OTP → rider onboarding (New Cairo → Ismailia, 6:30 / 4:30 PM) → ID check →
Join → Plan "Through my company" → consent sheet → Agree. PNGs in this folder (`NN-*.png`).

**Result: 0 blockers, 0 should-fix, 4 nits. Quickstarts 5, 6, 7 pass for what was walked.**

## Quickstart 5 — invoice and suspension
- Demo "skip to the day the company plan pauses" → clock Tue 24/11/2026 10:00 → bell shows the notice
  "خطة شركتك متوقفة دلوقتي، رسوم جورة على المشوار رجعت عادي" (30, 31). Wallet: pay-per-trip, "8 EGP
  service fee on every trip", owes 8 (32). Fee is 8 not 4 because the corridor price is 76 (10 %).
- Demo "Goora confirms invoice paid" → notice "خطة شركتك رجعت تشتغل: مشاويرك من غير رسوم جورة تاني" (35).
- HR (Demo "make me Valeo's HR"): Company account home shows active, minimum 20, 99 per employee,
  contract 1/8/2026–1/8/2027, privacy line (36). Invoices list: 2026-08, 09, 10, each 20 × 99 = 1,980,
  all paid after the demo button (38). Invoice screen: reference GR-1-202608, peak enrolled 12, due
  date, paid date, bank line (37).
- Booking still works while paused: not exercised on the device (covered by tests).

## Quickstart 6 — roster and leaving
- Roster: 13 enrolled (12 seed + me), each row = name, work email, "since" date, Remove. Nothing else (39, 40).
- Remove → confirm dialog states the consequence (41) → row shows "آخر يوم في الخطة: 24/11/2026" and no
  Remove button (42). Change log, newest first: "اتشال من الخطة: <name> · HR", HR contact changed,
  invoice paid, plan back, plan paused, invoice created (43).
- NOT walked: the removed employee's next trip carrying the fee, and the "left the plan" notice in the
  employee's inbox (needs a second pass as employee after the removal).

## Quickstart 7 — dashboard
- Arabic: 12 enrolled, 8 active, 67 %, 2 groups, 76 trips, savings, CO₂ 282 kg, parking spaces 3,
  "no area has 5 or more employees waiting" (44, 45). No name anywhere.
- English at 1.3×: nothing clipped, month pills wrap to two rows, method lines wrap (46–49).
- Month pills 8–11/2026 switch; 10/2026 shows the same figures as 11/2026 (50) — seed is the same each
  month, so the device cannot show the filter changing data (unit tests do).
- NOT walked: a "Fewer than 5" figure (needs a company with < 5 enrolled; Orange pending has none).

## Nits (founder / next pass)
- N-13 "Estimated savings" prints `15840 EGP` with no thousands separator; the invoice screen prints
  `1,980`. Same in Arabic and English.
- N-14 Bank line on the invoice is English placeholder text inside the Arabic screen ("Goora — bank
  details to be supplied (placeholder)"). Already on the founder's open list.
- N-15 With the company plan paused and no pay method saved, the router sends the rider to "How will
  you pay the driver?" before Today. Probably by design (guard = method or covering plan); founder to
  confirm that a pause should interrupt like this.
- N-16 15,840 EGP savings = 208 EGP per shared trip; the formula (alone cost − seat share) was not
  checked against the 300 EGP / 76 EGP corridor numbers.

## Environment notes (for the next walker)
- `adb shell input text` is unreliable in fields: typed text bleeds into the next field when the screen
  changes mid-typing; `Ctrl+A` does not select. Type one field per call, check the screenshot between.
  The OTP screen auto-submits at 6 digits.
- Demo rider matches only at going 6:30 / return 4:30 PM (corridor groups).
