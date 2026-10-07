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
