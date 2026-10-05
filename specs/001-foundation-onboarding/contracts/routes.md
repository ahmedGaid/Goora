# UI Contract: Routes

| Path | Screen | Notes |
|---|---|---|
| `/` | Welcome | Language pill, logo (long-press opens gallery in debug), Get started → `/phone?mode=signup`, Log in → `/phone?mode=login` |
| `/phone` | Phone entry | `mode=signup|login`; Continue disabled until `PhoneNumber.tryParse` succeeds |
| `/otp` | Code entry | 6 digits, resend after 60 s; success → `/profile` (new account) or resume step (existing) |
| `/profile` | Name + gender | Continue disabled until all three present |
| `/role` | Role choice | Progress dots step 0 |
| `/frequency` | Frequency choice | Progress dots step 1; Every day preselected |
| `/commute-setup` | Placeholder (feature 002) | Progress dots step 2 |
| `/empty-seats` | Placeholder (feature 005-A) | Back → `/frequency` |
| `/offer-trip` | Placeholder (feature 005-C) | Back → `/frequency` |
| `/home` | Placeholder (feature 003) | Settings entry |
| `/settings` | Settings | Language pill + role switch |
| `/debug/gallery` | Design gallery | Registered only when `kDebugMode` |

**Redirect on launch**: `OnboardingFlow.resumeStep` decides the first route, so a person who
leaves mid-onboarding returns to the last incomplete step.

**Language pill**: on every onboarding screen (top end corner) and in Settings; label shows the
*other* language ("English" in ar, "عربي" in en), semantic label `langAria`.
