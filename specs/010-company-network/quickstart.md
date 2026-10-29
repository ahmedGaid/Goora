# Quickstart: Company Network (010) — manual walk

Emulator only: `powershell -ExecutionPolicy Bypass -File D:\Company\99-Ops\start-emulator.ps1`.
Fake OTP: any Egyptian mobile, code `123456`. Settings → Reset before each scenario. Numbers use
the Q1–Q3 defaults (99 EGP, minimum 20); change them here if the founder decides otherwise.

1. **Register (US1)** — Settings → Company account → Register your company: name "Acme", work
   email `hr@gmail.com` → refused under the email ("public email"). `hr@valeo.com` → refused (taken
   by the seed). `hr@acme.com` → Send me a code → code `123456` → "Waiting for Goora". Settings →
   Demo → Goora approves my company → home shows active, minimum 20, 99 EGP per employee.
2. **Not on Goora (US2 AC4)** — as a rider whose work email is `@acme-not-real.com`: Plan → Through
   my company → "Your company isn't on Goora yet" + Tell your HR; no plan. *(P4: the fake work
   email is always `@valeo.com`, so on a device this needs Valeo ended first — Settings → Demo has
   no "end contract" yet (P5/P6). Covered by `company_enroll_test.dart`.)*
3. **Enroll (US2)** — as a rider with `@valeo.com` verified: Through my company → consent sheet lists
   what Valeo sees / never sees → Agree → plan card "Company · Valeo". Ride a trip (demo clock):
   fee none, "40 ج للسواق" unchanged.
4. **Paused personal plan (US2 AC6)** — subscribe Monthly first, then enroll: plan card shows the
   paused days. Leave: Monthly back with the same days left.
5. **Invoice and suspension (US3)** — HR of Valeo (Settings → Demo → Make me Valeo's HR contact):
   Invoices lists one per closed month, 20 seats × 99 = 1,980 EGP when ≤ 20 enrolled. Demo clock to
   the 24th after an unpaid due date → as an employee, the next trip shows the 4 EGP fee and the
   "plan paused" notice; booking still works. Demo → Mark invoice paid → next trip fee-free.
6. **Roster and leaving (US4)** — HR → Roster: name, work email, since — nothing else. Remove the
   demo employee → their next trip carries the fee; Roster shows "left on <date>"; Log shows
   "Removed by HR".
7. **Dashboard (US5)** — HR → Dashboard: totals with one-line methods; a figure built from < 5
   shows "Fewer than 5"; no names anywhere. Switch Arabic ↔ English.
8. **HR statement (US6, if shipped)** — employee: Wallet → company card → Share my trips with HR
   (off by default) → on. HR → Statement for last month: only that employee, only received shares.
   Turn off → next month leaves them out; last month unchanged.
