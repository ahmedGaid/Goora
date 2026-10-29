# 010 P4 emulator walk — T030 (2026-10-21)

Build: branch `010-company-network` @ `78d2d98`, debug APK, emulator `Goora_Test` (1080×2400) via
`start-emulator.ps1`. Fresh app data. Arabic first, then English at 1.3× system text. Fake OTP.

**Result: 0 blockers · 3 should-fix · 2 notes.** Quickstart 1, 3, 4 pass. Quickstart 2 not walkable
(fake work email is always `@valeo.com`; covered by `company_enroll_test.dart`).

## Setup path used (rider)
Welcome → phone `01012345678` → code `123456` → name → rider → every day → New Cairo ⇄ Ismailia,
**going 6:30 / return 4:30 PM** → match (75%) → Join → ID check (fake photos) → pay method (cash).
A going time of 7:30 or return 5:00 PM finds no group ("You're #7") — corridor groups leave at
6:30 with a 15-minute tolerance (006 research, walk §3), so that is expected, not a bug.

## Quickstart 1 — register (US1): PASS (ar)
| Step | Result | Shot |
|---|---|---|
| Settings → Company account (no company) | Two cards: "Your company plan" (Valeo, join) + "Register your company" | 11 |
| Register form | name + work email, one button | 12 |
| `hr@gmail.com` | Refused under the email: "gmail.com is a public email service…" | 13 |
| `hr@valeo.com` | Refused: "valeo.com is already registered to another company on Goora" | 14 |
| `hr@acme.com` → code | "We sent a code to hr@acme.com", test code shown, Send the request | 15 |
| Code `123456` | Home shows Acme · Waiting for Goora · domain acme.com | 16 |
| Demo → Goora approves my company | Home shows Active · minimum 20 · 99 EGP per employee · privacy note | 18 |

## Quickstart 3 — enroll (US2): PASS (ar, en 1.3×)
| Step | Result | Shot |
|---|---|---|
| Join through Valeo | Consent sheet: sees (name, work email, since) / never sees (trips, home, who rides, money), fee line, buttons | 19 |
| Not now | Sheet closes, nothing changes (company home still offers Join) | — |
| Agree and join | Home: "On Valeo's plan since 21/10" | 20 |
| Wallet | Card "Company · Valeo / Free · paid by your company", Leave | 21 |
| Today pay tile | "Pay on the trip · 75 EGP" with no fee, driver share unchanged | 22 |
| Leave → confirm | Company card gone; personal plan card back ("per trip, 8 EGP fee") | 23, 24 |
| English, 1.3× | Company home, consent sheet (all text + both buttons visible, no scroll), Wallet card all fit | 33, 34, 35 |

## Quickstart 4 — paused personal plan (US2 AC6): PASS
Top up 200 → subscribe Monthly (149) → active until 21/11 (26–28). Enroll through Valeo: consent adds
"Your own plan (31 days left) pauses…" (29); Wallet card shows "Your own plan is paused: 31 days left,
back if you leave your company" (30). Leave → Monthly back, still until 21/11, 31 days (31).

## Findings
| ID | Severity | What | Where |
|---|---|---|---|
| F-1 | should-fix | Contract line prints d/m with no year: a 12-month contract reads "21/10 to 21/10" (ar: "من 21/10 لـ 21/10"). Same family as walk nit N-7. Fix: show the year when the two dates differ in year, or always for contract dates. | `companyContractLine` (company home) · shots 18, 33 |
| F-2 | should-fix | Wallet "How paying works" still says "Goora adds only a service fee of up to 10% per trip; subscribers pay no fee" while a company plan is active (a covered rider pays no fee). The rules block does not know about company plans. | rider wallet · shots 21, 30, 35 |
| F-3 | should-fix (older, 004 S-4 area) | After a top-up inside the Plan sheet the amber banner stays and reads "Top up -51 EGP first — your wallet has 200". `_needsTopUp` is set on the failed subscribe and never cleared by the top-up. Subscribe then works. | `plan_screen.dart` · shot 27 |
| N-1 | note | Two company entrances: Plan sheet still lists "Through my company — free, confirm your work email" beside Settings → Company account → Join. Not walked; T026 says the sheet now follows `offerFor`. Check in P5/P6 walk. | shot 25 |
| N-2 | note | Cash price reads 75 while the match card says 76 (known, founder item). | shot 22 |

Not walked: quickstart 2 (see above), HR-side invoices/roster/dashboard (P5–P7), leaving through HR
or contract end (P6), a covered trip actually settled with the demo clock (covered by T028 unit tests;
the pay tile showing "no fee" is the on-device evidence).
