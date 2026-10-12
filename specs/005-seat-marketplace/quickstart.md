# Quickstart: Seat Marketplace — validation

Proves the feature end-to-end. It is a run guide, not code; details live in
[data-model.md](data-model.md) and [contracts/](contracts/).

## Prerequisites

- The Flutter SDK and Node 24 used by 001–004 (`flutter --version`, `node --version`).
- No backend keys. Sign-in is the fake OTP: any Egyptian mobile number, code `123456`.
- Device runs need an Android phone or emulator listed by `flutter devices`.
  - On the founder's personal phone, check focus and that no systemui is showing before every
    tap (`flutter-lessons` #15).
- **Debug build** (Settings → Demo exists only in debug). Settings → Demo gives:
  - the demo clock ("Ride day 7:15", "8:55 PM", "9:05 PM", "Real time");
  - "Reset demo data";
  - the new actions: **Verify my driver documents**, **A rider books your seat**, **A driver
    accepts your request** and **A subscriber takes this seat**.

## 0 — Gates (every scenario depends on them)

```bash
flutter analyze                                    # 0 issues
flutter test --concurrency=1                       # all green, incl. the new rules + ar/en widget tests
node --test "supabase/functions/_shared/*.test.ts" # pricing (+cash) and marketplace twins
python test/fixtures/gen_pricing_vectors.py && python test/fixtures/gen_marketplace_vectors.py && git diff --exit-code test/fixtures
```

Expected: everything green. The vector files regenerate with no diff, so both twins agree with
the independent generator. The two sweeps report 0 cases over the cap and 0 cash exceptions
(SC-002). The scripted sequences report 0 drivers over 2 trips (SC-003).

## 1 — Rider books an empty seat (US1, P1)

1. Reset demo data. Sign up as a rider and pick **Just one trip**. **Expect** Empty seats; Back →
   frequency screen.
2. **Expect**:
   - a Going/Return toggle and the route line "Sheikh Zayed → Smart Village" (the corridor
     default for a rider with no saved route, R14);
   - cards for the seeded Sheikh Zayed cars that have a free seat, and Tarek's offer (no
     October car);
   - the subscriber-priority caption;
   - the dashed "Nothing fits your time? Post your trip".
3. With no payment method, tap **Book seat** on sz-0740. **Expect** the payment-method screen.
   Choose **Use wallet**. **Expect** a return to Empty seats with the same seat ready to confirm.
4. With balance 0, **expect** "Top up 44 EGP first", and nothing booked. Top up 200, then book.
   **Expect**:
   - the booked summary with "Liked it? Make it your daily commute";
   - the seat count on that card drops by 1;
   - Wallet shows one "seat" row of 44 (40 + 4 fee), balance 156.
5. Today **expect** the one-off trip card with Share and SOS.
6. Tap the upsell: commute setup opens with **Every day** preselected.

## 2 — Prices by plan, cash rounding (FR-005, FR-029)

1. Same rider on Empty seats. **Expect** on group cars "44 EGP · 40 to the driver + 4 service
   fee". On Tarek's offer (contribution 44) **expect** "48 EGP · 44 to the driver + 4 service fee".
2. Reset. Sign up as a rider, Just one trip, choose **Pay cash**. **Expect** group cars "Pay 40
   EGP cash to the driver" and Tarek's offer "Pay **45** EGP cash to the driver".
3. Subscribe (top up 129, Monthly). **Expect** "40 EGP · no fees (subscribed)". The booked state
   shows "Back to today" and no upsell.
4. 004 amendment, group trip: as a driver of sz-0725 with a cash rider, after drop-off **expect**
   "Received 40 EGP cash" (40 is already a multiple of 5 on the corridor). The 45 case is proven
   by the widget test at contribution 44.

## 3 — Driver offers a trip; daily becomes a group (US2)

1. Reset. Sign up as a driver, Just one trip. **Expect** Offer a trip with license and vehicle
   chips "not verified" and Publish off.
2. Settings → Demo → **Verify my driver documents**. Back to Offer a trip: **expect** all chips
   verified.
3. Pick From Sheikh Zayed, To Smart Village, 7:30, 3 seats, Just once. **Expect** the stepper
   at "Suggested price" 40, with steps 38/42 reading "2 EGP below/above suggested" and stops at
   32 and 48. Below it, the rider price is "44 EGP".
4. Publish. **Expect** the live state "0 of 3 seats booked". Demo → **A rider books your seat**
   ×3. **Expect** the bar filling, anonymous rows ("Verified rider" / "Verified rider (woman)",
   rating or New, no names), then "Your car is full!".
5. Move the demo clock past 7:30. **Expect** first names shown (boarded). Past 8:10, **expect**
   the cash rows for any cash rider.
6. Offer a second trip: Return 17:00, **Every workday**. Demo → A rider books your seat.
   **Expect** it becomes a group: Today/Week show the return leg like a 003 group. Week shows
   **no** going leg and no "no driver" notice (R10 risk).
7. Cancel the first trip while it has bookings (repeat steps 3–4 on a fresh reset). **Expect**
   each booked rider refunded in full, and the trip still counted for the day.

## 4 — Rider posts a trip (US3)

1. Rider with a wallet balance ≥ 44. Empty seats → dashed card → Post your trip. **Expect**
   From/To/Time prefilled from the rider's route when one exists, Just once / Every workday, the
   three rules and Post.
2. Post (Just once, 7:45). **Expect** "Sent to N drivers on your route", progress and Cancel.
3. Demo → **A driver accepts your request**. **Expect** the accepted state (driver card, pickup,
   time, price line) and the wallet debited 44.
4. Post again with **Every workday** and accept via Demo. **Expect** "You're now a commute group"
   → payment-method screen → Today as a member.
5. Post a Just once request, then move the demo clock past its time. **Expect** expired, "Post
   again / See empty seats", and nothing charged.
6. As a rider already in a group: **expect** Every workday turned off with "You're already in a
   daily group".

## 5 — Driver finds riders; the daily limit (US4, SC-003 by hand)

1. Verified driver with no trips today (Just one trip onboarding). Find riders. **Expect** the
   "Leaving from" filter, Morning/Evening, **Trips left today 2**, and anonymous cards with fixed
   prices.
2. Accept a 7:30 going request. **Expect** the inline confirm "This creates your trip: … ·
   7:30 AM. Trips left after this: 1". Confirm → counter 1.
3. A 7:45 going request reads "This joins your trip at 7:30 AM". Accept → counter stays 1.
4. A 9:30 going request reads "Doesn't fit your trip". Evening: accept a 17:00 return → counter 0.
5. **Expect** every remaining non-joinable request to read "Daily limit reached", and no price
   input anywhere.

## 6 — Driver Today requests (US5)

1. Driver of sz-0725 on Today. **Expect** "Requests on your route": a banner "12 people want
   Sheikh Zayed → Smart Village in the morning" and cards with detour minutes.
2. On a day the driver drives both group legs, **expect** no Accept on any card. Cards within
   7:25 ± 30 read "Your car is full" (the 160/3 car is full once the off-duty driver rides, R6);
   the rest read "Daily limit reached" (group legs count, R4/R5). This is the rule working.
3. Move the demo clock to a day the driver is off duty (Week shows who drives). **Expect** Accept
   on the cards. Accept one → "Accepted ✓", a trip is created and the counter drops to 1.
4. With no matching requests (a driver whose area no request fits, e.g. a profile leaving from
   6th of October with only Sheikh Zayed requests left), **expect** the calm empty state plus the
   privacy caption.

## 7 — Subscriber priority and refunds (US6)

1. Wallet rider. Demo clock "8:55 PM" the evening before a ride day. Book a seat on a car for
   tomorrow (44). Demo → **A subscriber takes this seat**. **Expect**:
   - the booking gone from Today;
   - Wallet with one "Refund" row of 44, balance back to the pre-booking value;
   - a notice offering Empty seats / Post your trip.
2. Repeat at "9:05 PM". **Expect** "Too late to reclaim — this booking is final".
3. Cash rider: book (cash), reclaim before 9 PM. **Expect** no wallet movement, and the cash
   counter unchanged.

## 8 — Edge cases worth a manual look

- Two sessions are not possible in the fakes. "Seat just taken" is proven by a repository test
  that books the last seat between list and confirm.
- A group member whose own car carries them going sees "You already have a ride on this trip"
  for that leg.
- Women-only preference: only women-driven cars and offers are listed.
- Every screen above in **English and Arabic** (language pill in Settings), checked against the
  `goora-brand` checklist.
