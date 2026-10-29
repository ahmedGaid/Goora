# 010 walk, attempt 3 (2026-10-29) — INCOMPLETE, T040 / T045 NOT ticked

**Cause found:** a SECOND session was driving the same emulator at the same time (it writes `walk5/NN-*.png` every ~10 s from 11:11). Its taps and mine interleaved. Treat this folder as accidental evidence only; the other session's `walk5/` is the real walk.

Build: branch `010-company-network` @ `d0190f2`, debug APK, emulator `emulator-5554`, fresh app data, Arabic.

**Result: quickstarts 5, 6, 7 NOT walked.** Blocker: two sessions on one emulator. Taps landed on screens the other session had opened and pressed Demo buttons neither of us meant, so the app state after onboarding cannot be trusted as a clean scenario.

## Seen by accident (single screenshots, not a proven walk)
| Shot | What it shows | Matches quickstart |
|---|---|---|
| 01 | Inbox: "Valeo plan active: your trips are free" and, newer, "your company plan is paused, trip fees are back" | QS5 notices (cause of the pause unknown — a stray Demo tap) |
| 02 | Invoice 2026-08: paid, 20 seats x 99 = 1,980 EGP, peak enrolled 12, due 16/9/2026, paid 1/9/2026 ref SEED-2026-08, transfer reference GR-1-202608, bank details placeholder | QS5 invoice screen |
| 03 | Settings → Demo list incl. "HR of Valeo", "skip to suspension day", "mark invoice paid", "end Valeo contract", "HR contact leaves" | demo entry points exist |

## Not verified
Roster (name/email/since only), remove → "left on", Log "Removed by HR", fee back after removal,
suspension next-trip fee + book still works, mark paid → fee-free, dashboard figures (12 / 8 / 67% / 2 / 76),
closed-month picker, 1.3x text, Arabic RTL.

## Next try
One session per emulator. Before driving it, check `adb shell dumpsys window | grep mCurrentFocus` twice, 15 s apart, and look for new files in any `walk*/` folder.
