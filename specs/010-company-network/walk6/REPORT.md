# 010 walk 6 — quickstart 8 + full company walk, Arabic then English 1.3× (2026-10-29)

Build: branch `lane-w/walk-010-nits` @ `30b8181` (main, 010 P0–P9 merged), debug APK, emulator-5554
(1080×2400) started by `start-emulator.ps1`. Flags `companyInvoicesLive` / `hrStatementExport` OFF.
Fresh app data, fake OTP, rider "Omar Ali", New Cairo → Ismailia, going 6:30 / return 4:30 PM.
Arabic (RTL) at font scale 1.0, then English at **1.3×** (`settings put system font_scale 1.3`, reset to 1.0
after). Labels were read from the screen's accessibility tree and the key screens were looked at as PNGs.
PNGs live next to this file, named `<quickstart>-<screen>-<ar|en>.png`.

**One session on the emulator.** Before driving: `mCurrentFocus` checked at 12:37:52 and again 16 s and 21 s
later (same Goora window), three screenshots compared (only a status-bar icon differed), no new files in any
`walk*/` folder outside this worktree. Nothing interfered with this walk. (Contrast with walk 5.)

**Result: 0 blockers · 1 should-fix (F-W1) · 1 copy item (F-W2) · 5 nits. Quickstart 8 passes in ar and en.
Quickstarts 1, 3, 4, 5, 6, 7 re-walked and pass. Quickstart 2 not walkable (see below).**

## Quickstart 8 — HR statement + consent (T049)
| Step | Expected | Seen | Result | PNG |
|---|---|---|---|---|
| Employee: consent switch default | Off, "what HR sees" text visible | Off. "مقفول. الشركة مش بتشوف مشاويرك." + sees/never-sees line under the switch | PASS | q8-wallet-company-card-off-ar · -en |
| Turn on | On line, no confirm | "شغال. الشركة بتستلم كشف الشهر اللي فات أول كل شهر." No confirm dialog | PASS (copy: F-W2) | q8-wallet-company-card-on-ar · -en |
| HR home | Fifth button "Trips statement" | "كشف المشاوير" next to Numbers, Invoices, Roster, Log | PASS | q8-hr-home-ar · q1-company-home-hr-en |
| HR statement, last month (clock 29/10) | Only consenting employees, only received shares, no export | 9/2026: Dina Samir 30 trips 1,200; Hossam Nabil 21 trips 840; total 2,040. Yasmin (withdrew 15th of 9) is absent; Karim (driver) and non-consenters absent, not even a name. No share/export control. Fee line "0 ج". 8/2026 adds Yasmin: total 2,840 | PASS | q8-statement-list-ar · q8-statement-2026-08-ar · q8-statement-en |
| Clock to 24/11, October closed | Month appears | Pills 10/2026, 9/2026, 8/2026. 10/2026 = Dina + Hossam, total 2,040. **I am not listed although my consent is on** — the statement's source is the seed (`TripSharesSource`, R9), my real trips wait for the server | PASS (expected, see note) | q8-statement-2026-10-ar |
| Withdraw | Confirm explains issued statements stay | "توقّف إرسال مشاويرك لـ HR؟ الكشوف اللي الشركة استلمتها قبل كده هتفضل زي ما هي…" No / Yes buttons, both fit at 1.3× | PASS | q8-withdraw-confirm-ar · -en |
| After withdraw | Off line, last month unchanged | Switch off, "مقفول…". 10/2026 and earlier months identical | PASS | q8-wallet-company-card-off-after-ar · q8-statement-after-withdraw-ar |
| Not walked on device | Next month leaves the employee out | Needs a closed month with my own shares and a clock past 1 December; the demo clock only has the 24/11 jump and the seed has no shares for me. Covered by `company_statement_test` / `company_consent_test` | not walkable | — |

Note: because the statement reads the seed, the device cannot show "my consent changes the statement". The
seed's own history (Yasmin out of 9/2026) is the on-device proof of "withdrawal leaves that month out".

## Quickstart 1 — register (US1): PASS (ar, en)
| Step | Expected | Seen | Result | PNG |
|---|---|---|---|---|
| Company account, no company | Join offer + Register | "خطة شركتك … اشترك من خلال Valeo" + "سجّل شركتك" | PASS | q1-company-home-none-ar · -en |
| Form | name + work email, one button | Two fields, "ابعتلي كود" | PASS | q1-register-form-ar |
| `hr@gmail.com` | Refused under the email | "gmail.com إيميل عام أي حد يقدر يعمل عليه حساب. استخدم إيميل الشغل." | PASS | q1-public-email-ar · -en |
| `hr@valeo.com` | Refused, taken | "valeo.com متسجّل لشركة تانية على جورة." | PASS | q1-taken-email-ar · -en |
| `hr@acme.com` + code | Code sent, then pending | "بعتنا كود لـ hr@acme.com", test code 123456 → "مستني موافقة جورة" | PASS | q1-code-sent-ar · q1-pending-ar · -en |
| Demo "Goora approves my company" | Active, minimum 20, 99 per employee, contract with year | Active, "أقل عدد في الفاتورة: 20 موظف", "99 ج لجورة عن كل موظف في الشهر", "العقد من 24/11/2026 لـ 24/11/2027" (year shown — F-1 from walk 4 is fixed) | PASS | q1-approved-home-ar |

## Quickstart 2 — not on Goora (US2 AC4): not walkable
The fake work email is always `@valeo.com`; covered by `company_enroll_test.dart` (as in walk 4).

## Quickstart 3 — enroll (US2): PASS (ar, en 1.3×)
| Step | Expected | Seen | Result | PNG |
|---|---|---|---|---|
| Join through Valeo | Sheet lists what Valeo sees / never sees | Both lists, fee line "…هتبقى 0…", Agree / Not now. At 1.3× nothing clipped, both buttons visible | PASS | q3-consent-sheet-ar · -en |
| Agree and join | Home shows enrolled | "مشترك في خطة Valeo من 29/10" | PASS | q3-company-home-enrolled-ar · -en |
| Wallet | Company card, fee-free | "شركة · Valeo — مجانية · شركتك بتدفعها"; rules block says "خطة شركتك بتغطي رسوم جورة، فمفيش عليك رسوم خدمة" (F-2 from walk 4 is fixed) | PASS | q8-wallet-company-card-off-ar |
| Trip pay tile | No fee, driver share unchanged | "بتدفع في المشوار 75 ج — 75 ج · من غير رسوم (الشركة)" | PASS | q5-today-pay-nofee-ar |

## Quickstart 4 — paused personal plan (US2 AC6): PASS (ar)
| Step | Expected | Seen | Result | PNG |
|---|---|---|---|---|
| Monthly subscribe with empty wallet | Top-up banner, then clears | Banner "اشحن 149 ج الأول — محفظتك فيها 0 ج"; after top-up 200 the banner is gone and Subscribe works (F-3 from walk 4 is fixed). Active until 29/11 | PASS | q4-subscribe-needs-topup-ar · q4-wallet-monthly-ar |
| Enroll | Consent adds the pause line | "اشتراكك الشخصي (فاضل 31 يوم) هيتوقف، ويرجعلك لو سبت الشركة." | PASS | q4-consent-paused-ar |
| Wallet | Paused days shown | "اشتراكك الشخصي متوقف: فاضل 31 يوم، يرجعلك لو سبت الشركة." | PASS | q4-wallet-paused-ar |
| Leave | Confirm; Monthly back, same days | Confirm sheet, then "شهري | مشترك لحد 29/11" | PASS | q4-leave-sheet-ar · q4-monthly-back-ar |
| Plan sheet "Through my company" while not enrolled | (N-1 from walk 4: see F-W1) | Switched the wallet to a company plan with no consent sheet | **should-fix** | q4-via-company-ar · q4-via-company-after-ar |

## Quickstart 5 — invoice and suspension (US3): PASS (ar, en 1.3×)
| Step | Expected | Seen | Result | PNG |
|---|---|---|---|---|
| HR invoices | One per closed month, 20 × 99 | 2026-09 and 2026-08, "20 موظف × 99 ج = 1,980 ج", paid | PASS | q5-invoices-ar · -en |
| Invoice detail | Reference, peak, due, bank | GR-1-202609, peak 12, due 16/10/2026, paid 1/10. Bank line is English placeholder inside the Arabic screen (N-14, still open) | PASS / nit | q5-invoice-detail-ar · -en |
| Clock to 24/11 (unpaid) | Notice + fee, booking works | Notice "خطة شركتك متوقفة دلوقتي، رسوم جورة على المشوار رجعت عادي." Wallet pay-per-trip, fee 8; Today tile "83 ج = 75 ج للسواق + 8 ج رسوم خدمة" (fee is 8, not 4, because the corridor trip is 76 — as in walk 5). Trip still shows "توصيلتك متأكدة" | PASS | q5-notices-paused-ar · -en · q5-today-pay-fee-ar · -en · q5-wallet-paused-ar |
| Demo "Goora marks the invoice paid" | Fee gone, notice | "خطة شركتك رجعت تشتغل: مشاويرك من غير رسوم جورة تاني." Tile back to "75 ج · من غير رسوم (الشركة)" | PASS | q5-notices-resumed-ar · q5-today-pay-nofee-ar |

## Quickstart 6 — roster and leaving (US4): PASS (ar, en 1.3×)
| Step | Expected | Seen | Result | PNG |
|---|---|---|---|---|
| Roster | name, work email, since; nothing else | Exactly those three + Remove, "ده كل اللي الشركة بتشوفه…" | PASS | q6-roster-en |
| Remove (HR removes the demo employee, me) | Confirm states consequence | "تشيل Omar Ali من خطة الشركة؟ من دلوقتي رسوم جورة هترجع على مشاويرهم…" | PASS | q6-remove-confirm-ar · -en |
| After remove | "left on <date>", no Remove | "آخر يوم في الخطة: 24/11/2026" / "Left on 29/10/2026" | PASS | q6-roster-left-ar · -en |
| Log | "Removed by HR" | "اتشال من الخطة: Omar Ali · HR · 24/11/2026 10:04 ص"; en "Removed from the plan: Mona Adel · HR". Leaving by the employee logs "Left the plan: Omar Ali" | PASS | q6-log-ar · -en |
| **Gap from walk 5: removed employee's next trip carries the fee + notice** | Fee on the next trip, notice in the inbox | Notice "خطة Valeo خلصت. رسوم جورة على المشوار رجعت عادي." (en "Your Valeo plan has ended. The usual Goora fee applies to your trips."). Today tile "83 ج = 75 + 8 رسوم خدمة" | PASS | q6-notices-removed-ar · q6-today-pay-removed-ar |

## Quickstart 7 — dashboard (US5): PASS (ar, en 1.3×)
| Step | Expected | Seen | Result | PNG |
|---|---|---|---|---|
| Valeo dashboard | Totals with one-line methods, no names | 12 enrolled, 8 active, 67%, 2 groups, 76 trips, savings **15,840 ج** (N-13 separator fixed), CO₂ 282 kg, parking 3, "مفيش منطقة فيها 5 موظفين…". No name anywhere | PASS | q7-dashboard-valeo-ar · -bottom-ar |
| English 1.3× | Nothing clipped | Month pills wrap to two rows, method lines wrap, no clipping | PASS | q7-dashboard-valeo-en · -bottom-en |
| **Gap from walk 5: a "Fewer than 5" figure** | Replaced by the words | Acme (0 enrolled): every figure reads "أقل من 5" / "Fewer than 5", method lines stay, footer "أي رقم طالع من أقل من 5 موظفين بنخبّيه، عشان محدش يتعرف." | PASS | q7-dashboard-acme-ar · -bottom-ar · -en |

## Findings (010 — reported, not fixed, `lib/features/company/**` and company copy belong to goora-5b)
| ID | Severity | What | Where |
|---|---|---|---|
| F-W1 | should-fix | Plan sheet's old "عن طريق شركتي / Through my company — مجاني — أكّد إيميل الشغل" row still applies at once. Wallet → تغيير → عن طريق شركتي → أكّد التغيير turned the wallet card into "عن طريق شركتي · مجانية · شركتك بتدفعها" with **no consent sheet and no enrollment step**, replacing the paid Monthly (balance stayed 51, no pause line). The sheet itself says "الخطة الجديدة تتفعل من تاريخ الفوترة الجاي". Same two-entrance problem as walk 4 N-1. State: rider, Monthly active, HR contact of Acme. Not checked: whether Valeo's roster got a row. | plan sheet (`plan_screen.dart`) · q4-via-company-ar, q4-via-company-after-ar |
| F-W2 | open copy | Consent "on" line: "شغال. الشركة بتستلم كشف الشهر اللي فات أول كل شهر." (en "Your company gets last month's statement on the 1st of each month.") promises a delivery the fake does not do (HR must open the screen). Law 151/2020 wording is the open legal item (Q8 b). | `companyHrShareOnLine` · q8-wallet-company-card-on-ar |
| F-W3 | nit | The HR switch row: only the small switch toggles; a tap on the label or the text under it does nothing (row semantics say clickable). | `HrConsentToggle` · q8-wallet-company-card-off-ar |
| F-W4 | nit (demo) | "Reset demo data" wipes sign-in and the company but **keeps the demo clock** (it stayed at 24/11/2026, so a company registered after the reset got a contract starting 24/11/2026). "الوقت الحقيقي" fixes it. | Settings → demo |
| F-W5 | nit | Plan sheet copy: "كل رحلة تروح كلها للسواق" uses رحلة for a trip (lexicon: مشوار); the same sheet mixes "149 جنيه/الشهر" with "149 ج". Not a company string; for the copy audit. | plan sheet · q4-plan-sheet-ar |
| F-W6 | nit | Dates on the HR screens print d/m/yyyy in English too ("1/9/2026", "Left on 29/10/2026"); "On Valeo's plan since 29/10" has no year. Fine in Egypt, ambiguous for 1–12 days. The wallet-side fix is N-7 (below). | statement, roster, company home |
| N-14 | nit (known) | Bank line is English placeholder inside the Arabic invoice. | q5-invoice-detail-ar |

Already fixed since walk 4 / 5 and seen working: F-1 (contract line has year), F-2 (rules block under a company plan), F-3
(top-up banner clears), N-13 (thousands separator on savings).
Also seen and confirming a Phase 3 nit: **N-5** — the balance card shows "٠ ج" with the ج sitting lower than the
digit (q8-wallet-company-card-off-ar).

## Not walked
- Quickstart 2 (fake email always `@valeo.com`).
- "Next month leaves the employee out" on the HR statement for my own consent (no shares of mine in the seed, no
  clock beyond 24/11).
- Quickstart 4 and the removed-employee trip in English (strings checked on the removal and pause notices; the
  Arabic run is the full one).
- 1.3× on every Arabic screen (only English was run at 1.3×).

## Ticks ready for goora-5b (not ticked here)
- **T049 walk: ready to tick** — quickstart 8 walked in Arabic and English at 1.3×, 0 blockers.
- **T054 walk part: ready to tick** — the company screens walked in Arabic and in English at 1.3×. The README text
  itself was not re-read in this lane (5b owns the accuracy re-read).
- T049/T054 open items for 5b: F-W1, F-W2, F-W3, F-W5, N-14 above.

## Environment notes (for the next walker)
- Drive the app by label: `adb shell uiautomator dump` shows every Flutter label (Arabic too, read it with
  `exec-out cat`). Tap the centre of the node. Python output needs `sys.stdout.reconfigure(encoding="utf-8")`.
- `adb install` needs a Windows path (`D:/…`), not `/d/…`.
- Tab bar x-order flips with language (ar: Today at the right; en: Today at the left).
- A stray `Back` from the home screen leaves the app and a tap on the launcher opens other apps — keep the
  tab bar taps inside the app.
- Demo rider matches only at going 6:30 / return 4:30 (corridor groups). Default times shown on the form change after a
  reset; step them with the ±5 min buttons until 6:30 / 4:30.

---

# Phase 2 + 3 — walk 007–009 merged, five nits fixed

**Phase 2.** `docs/walk-007-009` merged into this branch (`Docs/walks/2026-10-20-007-009.md` + `Docs/walks/2026-10-20/*.png`).
`Docs/NEXT_GOAL.md` conflicted → main's side taken (it equals main). Main was also merged in three times
(the conductor moved it twice while this lane ran); ARB and generated l10n merged without conflict.

**Phase 3.** Each fix: test first, seen failing, then the fix, then the suites. One commit each, pushed.

| Nit | Fix | Test (was failing first) | Goldens regenerated |
|---|---|---|---|
| N-5 `0 ج` drops | Unit (after the last space) is a title-size run in the same line as the digits (`GooraBalanceValue`) | `goora_balance_card_test.dart` | `wallet_widgets`, `screen_wallet_rider`, `screen_wallet_rider_cash` (ltr+rtl) |
| N-5b same drop on the driver's "received directly" amount (found while checking N-5; not in the brief) | Same widget reused | `driver_wallet_test.dart` | `screen_wallet_driver` (ltr+rtl) |
| N-7 dates `d/m` | `shortDate` = day + month name, Western digits: "3 يناير", "3 Jan". New ARB key `dayAndMonth` (appended). Used by plan card, activity, driver share rows, fee-due banner | `short_date_test.dart`, `rider_wallet_test.dart` | `screen_wallet_driver` (ltr+rtl) |
| N-10 identical activity rows | `ActivityEntry.leg` (trip, bundle trip, paid trip, charge, free cancel); date line "5 Oct · Going" | `activity_row_test.dart`, `fake_wallet_repository_test.dart` | none (no golden shows an activity row) |
| N-11 once rider, no shell | Rider + once lands on **Today** (its no-group state offers Empty seats); Today's payment gate skips a once rider; Empty seats with nothing to pop goes Back to Today | `onboarding_flow_test`, `onboarding_route_test`, `app_flow_test` (+ 3 older tests that assumed the old landing updated) | none |
| N-12 Fawry | Two steps: "Get my Fawry code" shows the code (title size, tabular digits) + how to pay; only "I paid at Fawry" settles. New keys `fawryGetCode`, `fawryHow` (appended) | `rider_wallet_test.dart` (3 new, incl. 1.3×) | none (no golden shows the pay sheet) |

**Gates in this worktree (final tree):** `flutter analyze` 0 issues · `flutter test --concurrency=1` **1767 passed, 0 failed** ·
`node --test "supabase/functions/_shared/*.test.ts"` **276 pass, 0 fail**. Re-run once more after N-5b (driver wallet,
goldens, analyze): green.

**Seen on the emulator after the fixes** (rebuilt APK from this branch, Arabic):
- N-11: once rider onboarding ends on Today with the four tabs (`fix-n11-once-rider-lands-today-ar`); "عايز مشوار زيادة؟" opens
  Empty seats (`fix-n11-empty-seats-ar`); Back returns to Today; Trust opens from the tab bar (`fix-n11-trust-reachable-ar`).
- N-5: "51 ج" — unit smaller, on the digits' line (`fix-n5-balance-card-ar`). The ج's own tail still dips below the baseline; that is the glyph.
- N-7: "مشترك لحد 29 نوفمبر" (`fix-n7-subscribed-until-ar`).
- **Not seen on the device:** N-10 (needs two settled legs on one day) and N-12 (needs an owed fee past the trial). Covered by
  widget/unit tests only.

## Decisions (picked without asking; the rejected option)
1. **Main moved while the worktree was being made** (the 010 merge landed at `30b8181`, after the brief's check on `b198795`).
   Fast-forwarded the still-empty branch to main instead of recreating the worktree.
2. **Read the screen by its accessibility tree** (uiautomator) and looked at PNGs for the key screens only. Rejected: reading a
   screenshot for every step (slower, no extra evidence for text).
3. **q6 removal was done on myself in Arabic and on a seed employee in English**, so both locales show the "left on" row and the log.
4. **N-5:** shrink the unit inside one `Text.rich`. Rejected: shifting the unit with a baseline `WidgetSpan`/`Transform` (fragile in RTL),
   and a new two-field API (every caller already builds the string with `egpAmount`).
5. **N-7:** change `shortDate` itself. Rejected: Intl `DateFormat` (Arabic gives Eastern digits, the lexicon says Western) and a second
   helper (it would leave the company home's "since" line numeric). Side effect to know: `company_offer_view.dart` ("On Valeo's plan
   since …") now prints "29 Oct" through the helper; the file is untouched. `shortDateYear` (company screens) stays `d/m/yyyy`.
6. **N-10:** store `leg` on the row. Rejected: parse it from `rideId` in the widget (free-cancel rows have no ride id).
7. **N-11:** land on Today. Rejected: a tab bar on Empty seats (it is a pushed task screen; no other pushed screen has one) and
   `go(Today)` + `push(Empty seats)` (a relaunch would still start on a lone Empty seats). **Not changed:** a once *driver* still
   lands on Offer a trip with no tab bar (same shape, not in the brief).
8. **N-12:** reveal the code on a button, settle on a second tap. Rejected: settling when the Fawry pill is tapped.

## 010 findings list (for goora-5b — reported, not fixed)
F-W1 plan sheet "Through my company" applies at once with no consent/enrollment (should-fix) · F-W2 consent-on line promises a
monthly delivery the fake does not make (open copy, legal Q8 b) · F-W3 only the switch toggles, not the label · F-W4 demo reset
keeps the demo clock · F-W5 plan-sheet copy (رحلة, جنيه vs ج) · F-W6 HR dates are numeric d/m/yyyy; "since 29/10" had no year
(now a month name via N-7) · N-14 English bank placeholder in the Arabic invoice. T049 and T054 (walk part): **ready to tick**.

## Files touched in Phase 3 (all mine to touch)
`lib/core/widgets/goora_balance_card.dart` · `lib/features/wallet/presentation/{labels.dart, wallet/activity_row.dart,
wallet/driver_wallet.dart, wallet/pay_sheet.dart}` · `lib/features/wallet/domain/activity_entry.dart` ·
`lib/features/wallet/data/fake_wallet_repository.dart` · `lib/features/onboarding/domain/onboarding_flow.dart` · `lib/app/{router,routes}.dart` ·
`lib/features/marketplace/presentation/empty_seats/empty_seats_screen.dart` · `lib/core/l10n/app_{ar,en}.arb` (+ generated) —
3 keys appended at the end (`dayAndMonth`, `fawryGetCode`, `fawryHow`) · tests: `goora_balance_card`, `short_date`, `activity_row`,
`fake_wallet_repository`, `rider_wallet`, `driver_wallet`, `app_flow`, `marketplace_navigation`, `today_rider`, `reclaim`,
`onboarding_flow`, `onboarding_route` · 8 golden PNGs (list above).
