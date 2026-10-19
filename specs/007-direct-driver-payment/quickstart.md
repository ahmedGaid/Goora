# Quickstart: Direct Driver Payment (007)

## Gates

```bash
flutter analyze
flutter test --concurrency=1
node --test "supabase/functions/_shared/*.test.ts"
```

Twin check alone: `flutter test test/unit/direct_pay_vectors_test.dart` and
`node --test supabase/functions/_shared/direct_pay.test.ts` — same vectors, both green.

## Manual walkthrough (emulator: `D:\Company\99-Ops\start-emulator.ps1`, then `flutter run`)

Sign in with any Egyptian mobile, code `123456`.

1. **Rider, trial** — join a group, choose "كاش". Complete 1 trip with the demo clock. Wallet: no
   balance change, activity shows the trip with "40 ج للسواق" and no fee.
2. **Rider, past trial** — Settings → demo clock: run 5 more trips. Trip 6 shows a 4 EGP fee line;
   balance drops by 4, never by 40.
3. **Driver marks** — switch role to driver; after drop-off, mark one rider "ماستلمتش". Switch back:
   the rider's Today shows "عليك 40 ج.م لـ <name>"; Book seat is refused with the debt line.
4. **Dispute** — rider taps "دفعت"; driver sees "<name> بيقول إنه دفع"; driver taps "استلمت" → rider
   unblocked on refresh.
5. **Auto-receive** — leave a rider unanswered, move the clock +24 h: status "اتأكد تلقائي".
6. **Subscriber** — subscribe (149): next trip fee 0, still "40 ج للسواق".
7. **InstaPay** — driver sets a handle in Wallet; a rider with a confirmed seat sees it with "انسخ".
8. Repeat 1–4 in English (Settings → language).

Expected: no screen says Goora took or holds the 40.
