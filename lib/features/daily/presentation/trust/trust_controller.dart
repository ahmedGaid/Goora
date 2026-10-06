import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/now_provider.dart';
import '../../../onboarding/domain/choices.dart';
import '../../../onboarding/domain/phone_number.dart';
import '../../../onboarding/presentation/session_controller.dart';
import '../../data/providers.dart';
import '../../domain/privacy.dart';
import '../../domain/reliability_rules.dart';
import '../../domain/trust.dart';
import '../today/today_controller.dart';
import '../week/week_controller.dart';

part 'trust_controller.g.dart';

/// Everything the Trust tab shows (US6).
final class TrustView {
  const TrustView({required this.profile, required this.reliability, required this.isDriver, required this.contacts});

  final TrustProfile profile;
  final Reliability reliability;
  final bool isDriver;
  final List<TrustedContact> contacts;
}

@riverpod
class TrustController extends _$TrustController {
  @override
  Future<TrustView> build() async {
    final today = ref.watch(nowProvider)().date;
    final role = ref.watch(sessionControllerProvider).profile?.role;
    final trust = ref.watch(trustRepositoryProvider);
    // Events up to the coming days too, so a fresh late cancel shows in the
    // month caption at once.
    final events = await ref
        .watch(dailyCommuteRepositoryProvider)
        .events(today.addDays(-ReliabilityRules.windowDays), today.addDays(TodayController.lookAheadDays));
    return TrustView(
      profile: await trust.profile(),
      reliability: ReliabilityRules.compute(events, today),
      isDriver: role == Role.driver,
      contacts: await trust.contacts(),
    );
  }

  Future<void> _act(Future<void> Function() action) async {
    await action();
    ref.invalidateSelf();
    await future;
  }

  /// Applies to future matching and backups, never the current group (FR-026).
  Future<void> setPrivacy(PrivacyPreference p) => _act(() => ref.read(trustRepositoryProvider).setPrivacy(p));

  Future<void> addContact(String name, PhoneNumber phone) =>
      _act(() => ref.read(trustRepositoryProvider).addContact(name, phone));

  Future<void> removeContact(String id) => _act(() => ref.read(trustRepositoryProvider).removeContact(id));
}

/// Rider → driver: license and vehicle wait for verification. Driver →
/// rider keeps the saved commute (US6/AC4). From the Trust tab and Settings;
/// uses only kept-alive providers, so it works with the Trust tab closed.
Future<void> switchCommuteRole(WidgetRef ref) async {
  final session = ref.read(sessionControllerProvider.notifier);
  if (ref.read(sessionControllerProvider).profile?.role == Role.driver) {
    await session.setRole(Role.rider);
  } else {
    await ref.read(trustRepositoryProvider).startDriverVerification();
    await session.setRole(Role.driver);
  }
  ref
    ..invalidate(todayControllerProvider)
    ..invalidate(weekControllerProvider)
    ..invalidate(trustControllerProvider);
}
