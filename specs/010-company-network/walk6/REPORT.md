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
