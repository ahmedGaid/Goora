# Quickstart: validate feature 002

```bash
flutter analyze
flutter test                                   # incl. pricing, matching, shared vectors, ar/en screens
node --test supabase/functions/_shared/        # same vectors against the TypeScript matcher
```

Manual (`flutter run`, fake data, code 123456):

1. Onboard as rider → Every day → commute setup: Sun–Thu selected, 7:30 AM / 5:00 PM.
2. Home = Sheikh Zayed, Work = Smart Village → "Find my commute" → result with a high % match,
   4 stats, "40 EGP to the driver · no per-trip fees", reasons, "See other options" (3 more).
3. "Join this group" → plan placeholder. Settings → switch to driver → back to setup:
   seats 3, Both ways, stepper at 40 "Suggested price", recover per day 240 EGP.
   Step to 48 → "8 EGP above suggested", 288 per day. Going only → 144 and the other-trip note.
4. Driver result: riders shown as "Verified rider".
5. Set departure to 10:00 AM → "Find my commute" → no-match: "You're #7 on the Sheikh Zayed →
   Smart Village list…" → "Post your trip" → placeholder.
6. Switch language at any point: values stay, layout flips.
