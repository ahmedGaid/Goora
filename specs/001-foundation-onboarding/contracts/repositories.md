# Contract: Repositories

Interfaces live in `lib/features/onboarding/domain/`; implementations in `data/`. Widget tests
override them via Riverpod.

## AuthRepository

```dart
abstract interface class AuthRepository {
  /// Sends a one-time code. Throws [AuthNetworkException] when offline/unreachable.
  Future<void> sendCode(PhoneNumber phone);

  /// Verifies the code. Returns whether this number already had an account.
  /// Throws [InvalidCodeException] on a wrong code.
  Future<VerifyResult> verifyCode(PhoneNumber phone, String code);

  PhoneNumber? get currentPhone;   // signed-in number, or null
  Future<void> signOut();
  bool get isFake;                 // true → code screen shows the dev hint
}

final class VerifyResult { final bool existingAccount; }
```

`FakeAuthRepository`: code `123456`; `sendCode` never fails unless constructed with
`simulateOffline: true` (tests); registers numbers on first verify.

Later: `SupabaseAuthRepository` (phone OTP) — same interface, added when keys are provided.

## ProfileRepository

```dart
abstract interface class ProfileRepository {
  Future<Profile?> load();
  Future<void> save(Profile profile);
  Future<void> clear();
}
```

`LocalProfileRepository`: JSON in shared_preferences under `profile`.
