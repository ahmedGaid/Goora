# Data Model: Foundation, Design System and Onboarding

All types live in `lib/features/onboarding/domain/` and are pure Dart (no Flutter imports).

## PhoneNumber (value object)

| Field | Type | Rule |
|---|---|---|
| `e164` | String | Always `+201XXXXXXXXX` (13 chars) |

- `PhoneNumber.tryParse(String input) → PhoneNumber?`
  - Strip spaces, dashes and parentheses.
  - Accept `01XXXXXXXXX` (11 digits), `+201XXXXXXXXX`, `00201XXXXXXXXX`, `201XXXXXXXXX`.
  - Operator prefix after `01` MUST be `0`, `1`, `2` or `5` (010, 011, 012, 015).
  - Anything else → `null`.
- `local` getter → `01XXXXXXXXX` (for display, Western digits).

## Role (enum)

`driver` ("I can drive") · `rider` ("I need a ride")

## Frequency (enum)

`everyDay` (default) · `once`

## Gender (enum)

`male` · `female` — private; used only for the women-only preference.

## Profile

| Field | Type | Rule |
|---|---|---|
| `phone` | PhoneNumber | required, verified |
| `firstName` | String | required, trimmed, 1–40 chars |
| `lastName` | String | required, trimmed, 1–40 chars |
| `gender` | Gender | required |
| `role` | Role? | null until chosen |
| `frequency` | Frequency? | null until chosen |

Serialised to JSON in `LocalProfileRepository`.

## OnboardingStep (enum) and state transitions

```text
welcome → phone → otp → profile → role → frequency → destination
                     └─(existing account)──────────────────────→ home
```

`OnboardingFlow` (pure functions):

- `resumeStep({bool signedIn, Profile? profile}) → OnboardingStep`
  - not signed in → `welcome`
  - signed in, no profile (name/gender missing) → `profile`
  - no role → `role`; no frequency → `frequency`; else → `destination`
- `destinationFor(Role role, Frequency frequency) → Destination`
  - `everyDay` (either role) → `commuteSetup`
  - `rider` + `once` → `emptySeatsToday`
  - `driver` + `once` → `offerTrip`
- `progressIndex(OnboardingStep) → int?` → role 0, frequency 1, commute setup 2, otherwise null.

## Destination (enum)

`commuteSetup` (feature 002) · `emptySeatsToday` (feature 005-A) · `offerTrip` (feature 005-C) ·
`home` (feature 003). All are placeholders in this feature.

## AppPreferences (device)

| Key | Value |
|---|---|
| `locale` | `ar` (default) or `en` |
| `fake_auth.accounts` | list of e164 numbers registered with the fake auth |
| `fake_auth.session` | e164 of the signed-in number, or absent |
| `profile` | Profile JSON |
