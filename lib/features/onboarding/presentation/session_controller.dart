import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/providers.dart';
import '../domain/choices.dart';
import '../domain/onboarding_flow.dart';
import '../domain/phone_number.dart';
import '../domain/profile.dart';

part 'session_controller.g.dart';

final class Session {
  const Session({this.phone, this.profile});

  final PhoneNumber? phone;
  final Profile? profile;

  bool get signedIn => phone != null;

  OnboardingStep get resumeStep => OnboardingFlow.resumeStep(signedIn: signedIn, profile: profile);
}

/// Loaded once in `main()` before the first frame, then overridden.
@Riverpod(keepAlive: true)
Session initialSession(Ref ref) => const Session();

@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  @override
  Session build() => ref.read(initialSessionProvider);

  /// After a successful code check. An existing account keeps its profile.
  Future<void> signedIn(PhoneNumber phone) async {
    final stored = await ref.read(profileRepositoryProvider).load();
    final profile = stored?.phone == phone ? stored : null;
    if (stored != null && profile == null) await ref.read(profileRepositoryProvider).clear();
    state = Session(phone: phone, profile: profile);
  }

  Future<void> saveProfile({
    required String firstName,
    required String lastName,
    required Gender gender,
  }) async {
    final profile = Profile(
      phone: state.phone!,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      gender: gender,
    );
    await _persist(profile);
  }

  Future<void> setRole(Role role) => _persist(state.profile!.copyWith(role: role));

  Future<void> setFrequency(Frequency frequency) =>
      _persist(state.profile!.copyWith(frequency: frequency));

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const Session();
  }

  Future<void> _persist(Profile profile) async {
    await ref.read(profileRepositoryProvider).save(profile);
    state = Session(phone: state.phone, profile: profile);
  }
}
