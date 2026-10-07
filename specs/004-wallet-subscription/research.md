# Phase 0 Research: Wallet and Subscription

All three spec-level clarifications were already resolved in `spec.md`'s Clarifications section
(trips-covered formula, company verification timing, mid-cycle plan change). What's left here is
implementation-level: how to build what the spec already decided.

## R1 — "one calendar month" trial end date

- **Decision**: add `CalendarDate.addMonths(int months)` that keeps the day-of-month when the
  target month has at least that many days, and clamps to the target month's last day otherwise
  (e.g. 31 Jan + 1 month → 28/29 Feb, not an overflow into March).
- **Rationale**: `DateTime.utc(y, m + 1, d)` in Dart silently rolls an out-of-range day into the
  next month (31 Jan → 3 Mar), which would make a trial that starts on the 31st end on the wrong
  date in short months. Clamping is the common "same date next month, or month-end" rule used by
  subscription billing (Stripe, App Store) and matches founder intent ("free month" means a
  month, not sometimes 32 days).
- **Alternatives considered**: let it overflow (rejected — wrong date, and only the last 3 days of
  a 31-day month would ever hit it, making it a rare, confusing bug); always use 30 days flat
  (rejected — "free until {date}" would show a date that visibly isn't "a month" to a user
  checking a calendar).

## R2 — where the plan-required redirect lives

- **Decision**: a redirect check added to the shell's `today`/`week` `GoRoute`s (next to the
  existing `routeForSession` pattern from onboarding), not a new top-level guard. If the session
  is a rider with no `Plan` (or a due/expired one) and no Company verification, redirect to
  `Routes.plan`.
- **Rationale**: `go_router`'s per-route `redirect` is the existing idiom in this codebase (see
  `Routes.otp`'s redirect in `router.dart`); no new dependency or architecture needed. Wallet and
  Trust tabs stay reachable even with a due plan (FR-014 says "prompted... before their next trip
  is confirmed", not "locked out of the app"), so only Today/Week redirect; Wallet shows the due
  state inline instead.
- **Alternatives considered**: a global `GoRouter.redirect` callback (rejected — would need to
  special-case every other route, including settings/gallery, for no benefit); blocking in the
  shell's `build()` instead of routing (rejected — `today`/`week` are independent branches of one
  `StatefulShellRoute`, so a route-level redirect is the only place that catches direct deep
  links too).

## R3 — reusing 003's `Charge` records for the rider's activity list

- **Decision**: `WalletRepository` reads existing `Charge` records (via the daily feature's
  `DailyCommuteRepository`) to build late-cancel/no-show activity rows, and reads a `Ride`'s
  attendance outcome to add the zero-amount free-cancellation rows; it does not duplicate that
  data into its own store.
- **Rationale**: FR-013 makes the wallet's own ledger the source of truth for *balances*, but
  003 already owns the source of truth for *why* a charge happened (`AttendanceRules`,
  `Charge`). Duplicating those records into the wallet feature would create two copies that can
  drift; reading across features (wallet → daily) keeps one writer per fact, the same seam 003
  used when it read `PrivacyPreference` from 002 instead of copying it.
- **Alternatives considered**: have 003 push a `WalletActivity` row whenever it creates a
  `Charge` (rejected — adds a cross-feature write dependency in the wrong direction; 003 already
  shipped and its tests shouldn't need to know wallet exists); copy+transform at seed time only
  (rejected — would go stale the moment a live cancellation happens after the wallet is seeded).

## R4 — top-up/withdrawal failure simulation

- **Decision**: `FakePaymentProvider` takes an optional `shouldFail` hook (defaults to "never"),
  settable from the debug Demo section (same pattern as 003's demo-clock override in Settings),
  so SC-005's failure path is reachable without hand-editing code.
  **As shipped (checked 2026-10-08): the hook exists but nothing wires it to a Settings control —
  `paymentProvider` in `data/providers.dart` always constructs a plain `FakePaymentProvider()`.
  Only widget tests (`top_up_sheet_test.dart`, `withdraw_sheet_test.dart`) exercise `shouldFail`
  today via a provider override. quickstart.md Scenario 2/3's "force the next top-up/withdrawal to
  fail" steps have no live UI path yet** — either add the Settings → Demo toggle this decision
  describes, or update quickstart.md to say the failure path is test-only. Not decided this
  session; flagging for the founder/next session.
- **Rationale**: 003 already has precedent (research R11) for a debug-only way to force
  demo-relevant edge cases; a widget test can also inject a provider that always fails without
  touching the debug UI.
- **Alternatives considered**: random failure chance (rejected — flaky, not testable
  deterministically); no way to trigger a failure at all outside unit tests (rejected — SC-005's
  "verified by a unit test for each path" still needs the widget-level inline error reachable for
  manual device walkthroughs, same as every other feature's quickstart).

## R5 Drafted copy (founder review) — not in the prototype dictionary

Same pattern as 003's R14: everything else is taken from the existing dictionary and brief §6.7;
these ~67 keys are new to this feature, Arabic in `lib/core/l10n/app_ar.arb`, English in
`app_en.arb`. `shortDate` (`labels.dart`) is a Dart formatting helper, not an ARB key — no copy to
review there.

| key | ar | en |
|---|---|---|
| planSubline | تدفع لأول مرة بعد ما نلقى جروبك — ولقيناه. | You only pay once we find your group — and we did. |
| planMonthlyTitle / planMonthlySub | شهري / 129 جنيه/الشهر | Monthly / 129 EGP/month |
| planYearlyTitle / planYearlySub / planYearlyChip | سنوي / 1,290 جنيه/السنة / شهرين مجانًا | Yearly / 1,290 EGP/year / 2 months free |
| planCompanyTitle / planCompanySub | عن طريق شركتي / مجاني — أكّد إيميل الشغل | Through my company / Free — verify your work email |
| planIncludedTitle | هتحصل على | What's included |
| planIncludedMatch | ترشيح يومي لجروب ركوبتك | Matching with your daily group |
| planIncludedBackup | سواق بدّل لو سواقك اتأخر | A backup driver when yours can't make it |
| planIncludedTrust | تتبّع الالتزام وأدوات أمان SOS | Reliability tracking and SOS safety tools |
| planFuelNote | مصاريف البنزين والرسوم اللي تدفعها كل رحلة تروح كلها للسواق. | The fuel & tolls you pay each trip go straight to your driver, in full. |
| planCtaStart / planCtaVerify | ابدأ الشهر المجاني / أكّد إيميل الشغل | Start free month / Verify work email |
| planFooter | تقدر تلغي في أي وقت. جورة مجانية للسواقين. | Cancel anytime. Goora is free for drivers. |
| verifyEmailTitle / verifyEmailBody | أكّد إيميل شغلك / {company} هتدفع خطة جورة بتاعتك بعد تأكيد إيميل شغلك. | Verify your work email / {company} will cover your Goora plan once your work email is verified. |
| verifyConfirm / verifyNotVerified | تأكيد / أكّد إيميل شغلك من تبويب الموثوقية الأول. | Confirm / Verify your work email in Trust first. |
| balanceLabel / topUp / coversTrips | رصيد المحفظة / اشحن / {count, plural, =0{لسه مش بيغطي أي رحلة} =1{بيغطي حوالي رحلة واحدة} other{بيغطي حوالي {count} رحلات}} | Wallet balance / Top up / {count, plural, =0{Covers no trips yet} =1{Covers about 1 trip} other{Covers about {count} trips}} |
| planChange / planFreeUntil / planActiveLine / planCompanyActive | تغيير / مجاني لحد {date} · بعدها {price} جنيه/الشهر / مفعّلة · {price} جنيه/الشهر / مجانية · شركتك بتدفعها | Change / Free until {date} · then {price} EGP/month / Active · {price} EGP/month / Free · paid by your company |
| planDueTitle / planDueBody | خطتك محتاجة تجديد / اشحن محفظتك أو حوّل لخطة الشركة علشان مكانك يفضل متأكد. | Plan due / Top up your wallet or switch to Through my company to keep your seat confirmed. |
| howPayTitle / howPayRule1-3 | إزاي الدفع بيشتغل / اشتراكك بيغطي ترشيح الجروب والسواق البديل وأدوات الأمان. / البنزين والرسوم بتروح كلها للسواق على طول — جورة مالهاش نسبة. / الإلغاء المتأخر والغياب من غير اعتذار بتدفعهم من محفظتك. | How paying works / Your subscription covers matching, backup drivers and trust tools. / Fuel & tolls go straight to your driver — Goora takes no cut. / Late cancellations and no-shows are charged from your wallet. |
| topUpSheetTitle / topUpMethodInstaPay / topUpMethodVodafone / topUpMethodCard | اشحن محفظتك / InstaPay / فودافون كاش / كارت | Top up your wallet / InstaPay / Vodafone Cash / Card |
| topUpConfirm / topUpFailTitle / topUpFailBody | أكّد الشحن / الشحن ملحقش يتم / مفيش حاجة اتحصلت — جرّب تاني. | Confirm top-up / Top-up didn't go through / Nothing was charged — try again. |
| changePlanTitle / changePlanNote / changePlanConfirm | غيّر خطتك / الخطة الجديدة تتفعل من تاريخ الفوترة الجاي — مفيش تغيير في الفترة الحالية. / أكّد التغيير | Change your plan / Takes effect on your next billing date — nothing changes for your current period. / Confirm change |
| breakdownTitle / breakdownFuel / breakdownFees / breakdownTotal | بتدفع كام في الرحلة / البنزين والرسوم / رسوم جورة: ضمن اشتراكك / الإجمالي | What you pay per trip / Fuel & tolls / Goora fees: in your plan / Total |
| activityTitle / activityEmpty | الحركة / لسه مفيش حركة | Activity / No activity yet |
| actTopUp / actTripDeduction / actLateCancelCharge / actFreeCancelZero / actTripIncome / actFeeReceivedFrom / actWithdrawal | شحن / تكلفة رحلة / إلغاء متأخر / إلغاء مجاني / دخل الرحلة / رسوم {name} / سحب | Top-up / Trip cost / Late cancel / Free cancellation / Trip income / {name}'s fee / Withdrawal |
| recoveredTitle / payoutNote | اتجمّع الأسبوع ده / بيتصرف كل خميس · من غير أي رسوم عليك | Recovered this week / Paid out every Thursday · no fees taken from you |
| withdraw / withdrawSheetTitle | اسحب على InstaPay (both keys, same copy) | Withdraw to InstaPay (both keys, same copy) |
| withdrawConfirm / withdrawFailTitle / withdrawFailBody | أكّد السحب / السحب ملحقش يتم / مفيش حاجة تحرّكت — جرّب تاني. | Confirm withdrawal / Withdrawal didn't go through / Nothing moved — try again. |
| driverBreakdownTitle / driverBreakdownCost / driverBreakdownReceived / driverBreakdownGap / driverBreakdownFree | تكلفة رحلتك / تكلفة الرحلة / بتستلم من الركاب / بتدفعه من جيبك / جورة مجانية للسواقين | Your trip cost / Trip cost / You receive from riders / What you pay yourself / Goora is free for drivers |

**v2 note**: `planTitle`, `planSubline`, `planCtaStart`, `planFreeUntil`, `breakdownFees` and
`howPayRule1` above belong to the v1 free-month model and are replaced in v2 (R13). Separately,
several v1 strings use رحلة for a trip (`coversTrips`, `breakdownTitle`, `actTripDeduction`,
`actTripIncome`), where the lexicon says مشوار. Not changed here (out of the payment-model scope);
listed for the founder's copy review.

# v2 — payment model (2026-10-08)

## R6 — fee rounding

- **Decision**: `fee = (contribution + 5) ~/ 10` for wallet non-subscribers — 10%, nearest whole
  EGP, halves up. 40 → 4, 44 → 4, 45 → 5, 48 → 5, 32 → 3.
- **Rationale**: integer-only (money is whole EGP everywhere in this codebase), deterministic in
  both Dart and TS, matches the brief's "rounded to the nearest whole EGP".
- **Alternatives considered**: `(c * 0.1).round()` — floating point, and Dart/JS disagree on
  some halves; banker's rounding — surprising to riders.

## R7 — where a trip is charged

- **Decision**: derive it. A rider's completed trip is 003's settled `ReliabilityEvent(kept)` for
  that person on a ride they did not drive. The wallet reads those events (≤ 60 days), prices each
  with `PricingService`, and the rider's balance = own ledger (top-ups − subscriptions) − derived
  debits (wallet trips + wallet-period charges).
- **Rationale**: 003 already settles each ride exactly once (idempotent, and catches up on read
  for trips that end without "End trip"). Writing a debit at `endTrip` would add a second writer
  for the same fact and miss catch-up settlements. Same seam as R3.
- **Alternatives considered**: debit inside 003's `_settle` (rejected — 003 would need to know
  wallet, wrong dependency direction); debit from the Today controller (rejected — misses trips
  settled on read and rides the person didn't open the app for).
- **Side effect, intended**: v1 showed 003's charges in activity but never took them off the
  balance. v2 deducts them (FR-007), which is what "How paying works" always said.

## R8 — cash trial as a fold

- **Decision**: walk the rider's completed trips and charges in date order. While the method is
  `cash` and `CashTrialPolicy.cashAvailable(cashTripsDone, strikes)` holds, a trip is a cash trip
  (no wallet movement, no fee) and a charge is not collected (zero row, reliability only); after
  that, trips and charges hit the wallet.
- **Rationale**: one pure rule, replayable, no stored "trial state" that can drift from history.
  Strikes come from `CashMark`s against this rider and count from the moment they are recorded.

## R9 — the guard

- **Decision**: a rider passes the Today/Week guard when they have a payment method, or an active
  subscription, or a company plan. Otherwise → `Routes.payMethod`. Match result's "Join" goes to
  `Routes.payMethod` for riders.
- **Rationale**: same per-route redirect idiom as v1 (R2); the arrangement replaces "has a plan".

## R10 — paying for a subscription

- **Decision**: subscribing debits the wallet ledger (kind `subscription`) and sets `paidUntil =
  today + 1 month / 1 year` (`CalendarDate.addMonths`, R1). Not enough balance → nothing changes,
  the screen says how much to top up. After `paidUntil` the plan is `due` and the rider pays per
  trip again. Company: no debit, no date. Change between monthly/yearly keeps v1's "next billing
  date" rule.
- **Rationale**: one money source (the ledger); no recurring billing engine in the fakes.

## R11 — cash marks and the seeded cash rider

- **Decision**: `CashMark {rideId, riderId, driverId, outcome, amount, date}` stored by the wallet
  repository. In the fakes, other riders' payment methods are seeded: Youssef (group `sz-0725`) is
  a cash-trial rider, so a driver on that group sees the cash buttons. Driver Today's
  PickupCheckIn shows them once the ride has ended, for each picked-up passenger whose method is
  cash and who has no mark on that ride yet.
- **Rationale**: drivers are fakes for a rider and riders are fakes for a driver; a seed is the
  only way the driver-side flow is reachable on device (same posture as v1's driver income seed).

## R12 — twin and vectors

- **Decision**: `supabase/functions/_shared/pricing.ts` exports `serviceFee` and `riderTotal`;
  `test/fixtures/pricing_vectors.json` (hand-written, small) is read by both
  `pricing.test.ts` and `test/unit/rider_total_test.dart`. The cash-trial and savings rules
  stay app-only for now (no server consumer yet), documented as such.

## R13 — copy

Brief §7 strings are used verbatim. Drafted for founder review (not in §7):

| key | ar | en |
|---|---|---|
| priceCompany | {price} ج · من غير رسوم (الشركة) | {price} EGP · no fees (company) |
| payMethodSub | تقدر تشحن المحفظة أو تشترك في أي وقت. | You can top up or subscribe anytime. |
| payCashSub | من غير رسوم خدمة على مشاوير الكاش. | No service fee on cash trips. |
| payContinue | كمّل | Continue |
| planTitle (replaced) / planSubline (replaced) | اشترك ومن غير رسوم / من غير رسوم خدمة على أي مشوار أو كرسي. | Subscribe and pay no fees / No service fee on any trip or seat. |
| subscribeCta | اشترك · {price} ج | Subscribe · {price} EGP |
| subNeedsTopUp | اشحن {gap} ج الأول — محفظتك فيها {balance} ج. | Top up {gap} EGP first — your wallet has {balance} EGP. |
| planSubscribedLine | مشترك لحد {date} · من غير رسوم | Subscribed until {date} · no fees |
| planPerTripLine | {fee} ج رسوم خدمة على كل مشوار | {fee} EGP service fee per trip |
| planLapsedLine | الاشتراك خلص · رجعت بالمشوار | Subscription ended · back to pay per trip |
| cashTripsLeft (plural) | فاضل مشوار كاش واحد / فاضل مشوارين كاش / فاضل {count} مشاوير كاش | 1 cash trip left / {count} cash trips left |
| cashEnded | مشاوير الكاش خلصت — اشحن محفظتك عشان تكمّل. | Your cash trips are done — top up your wallet to keep riding. |
| cashOff | الكاش اتقفل بعد ما مشوارين اتسجّلوا من غير دفع — اشحن محفظتك عشان تكمّل. | Cash is off after 2 trips were marked unpaid — top up your wallet to keep riding. |
| needsTopUp | اشحن عشان تكمّل مشاويرك | Top up to keep riding |
| actTrip / actCashTrip / actSubscription | مشوار / مشوار كاش / اشتراك | Trip / Cash trip / Subscription |
| cashPaidLine | دفعت {price} ج كاش للسواق | Paid {price} EGP cash to the driver |
| notChargedCash | مش محسوبة في فترة الكاش | Not charged during the cash trial |
| howPayRule1 (replaced) | بتدفع نصيب السواق + 10% رسوم خدمة على كل مشوار. المشتركين من غير رسوم. | You pay the driver's share + a 10% service fee per trip. Subscribers pay no fee. |
| howPayRule3 (replaced) | الإلغاء المتأخر والغياب بيروحوا للسواق من غير رسوم خدمة. | Late cancellations and no-shows go to the driver, with no service fee. |
| breakdownShare / breakdownFee / breakdownNoFee | نصيب السواق / رسوم الخدمة (10%) / رسوم الخدمة: مفيش | Driver's share / Service fee (10%) / Service fee: none |
| cashMarkedReceived / cashMarkedUnpaid | الكاش وصل / اتسجّل إنه مدفعش | Cash received / Marked unpaid |
| cashReceivedTitle / cashReceivedNote | الكاش اللي استلمته / متسجّل بس — مش بيتسحب | Cash received / Recorded only — not withdrawable |
| priceDriver | {price} ج ليك من كل راكب · جورة مجانية للسواقين | {price} EGP to you per passenger · Goora is free for drivers |
| needsTopUpBody | رصيدك أقل من تمن مشوار واحد ({total} ج). | Your balance is below one trip ({total} EGP). |

## R14 — a real bug: subscribing retroactively waives same-day fees already charged (found live, T077)

`_riderTrips` (`fake_wallet_repository.dart:229`) computes `feeFree = plan != null &&
plan.coversDate(item.date)` for every historical trip in the lookback window, every time the
wallet is read. `Plan.coversDate` only compares `CalendarDate`s (day granularity, no time of
day), so once a rider subscribes, `plan.startDate` is today and `coversDate(today)` is true for
the rest of that day's reads — including a trip that already settled, and was already correctly
debited its 4 EGP service fee, *before* the rider subscribed that same day.

Observed live on device: rider joined on wallet pay, let the return leg settle (wallet showed
"Trip · 40 EGP to the driver + 4 EGP service fee · -44 EGP", balance 156 — correct), then
subscribed Monthly (-129 EGP). The same trip's activity row silently changed to
"Trip · Service fee: none · -40 EGP" and the balance came out to 31 EGP (200 − 40 − 129) instead
of the expected 27 EGP (156 − 129) — the already-paid 4 EGP fee was credited back with no
activity row explaining why. Reproduced identically in English.

Because the derivation recomputes every entry from the live ride/charge records on every read
instead of storing what was actually charged at the time, this is a day-granularity bug, not a
one-off: any trip taken earlier the same day a rider subscribes gets its fee quietly refunded.
Smallest fix is likely to use a timestamp (not just a date) for `plan.startDate`/`coversDate`, or
to stop recomputing `feeFree` from the current plan for entries that already happened — a trip's
fee should be fixed at settlement time, not recomputed against the rider's current plan every
time the wallet is read.

Founder/implementer call: fix before merging `004-wallet-subscription`, or merge and fix in a
follow-up — this is a real-money correctness bug (small amounts, direction favors the rider),
not a cosmetic one.

`priceDriver` exists because a driver viewing the match result would otherwise read "+ 4 EGP
service fee" as a fee on them (goora-brand check 4). Copy check for review: the cash-trial copy
uses مشوار/مشاوير for trips per the lexicon; the v1 رحلة drift noted above is unchanged.

### R7 addendum — trips before payment setup (found while implementing)

003 seeds ~30 days of demo reliability history (`kept` events before the person joined). Billing
those would hit a brand-new rider with ~13 trips (−572 EGP) and use up a cash trial at once. The
wallet only bills trips from the day the rider set up payment (`wallet.since.<id>`: the day they
chose a method or a plan started).
