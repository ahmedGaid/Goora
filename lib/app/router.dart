import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/storage/preferences.dart';
import '../core/time/now_provider.dart';
import '../features/commute/data/fake_commute_repository.dart';
import '../features/commute/presentation/commute_setup_screen.dart';
import '../features/commute/presentation/match_result_screen.dart';
import '../features/commute/presentation/no_match_screen.dart';
import '../features/daily/data/providers.dart';
import '../features/daily/presentation/shell/app_shell.dart';
import '../features/daily/presentation/today/today_screen.dart';
import '../features/daily/presentation/trust/trust_screen.dart';
import '../features/daily/presentation/week/week_screen.dart';
import '../features/design_gallery/presentation/design_gallery_screen.dart';
import '../features/onboarding/domain/choices.dart';
import '../features/onboarding/domain/phone_number.dart';
import '../features/onboarding/presentation/frequency_screen.dart';
import '../features/onboarding/presentation/onboarding_routes.dart';
import '../features/onboarding/presentation/otp_screen.dart';
import '../features/onboarding/presentation/phone_screen.dart';
import '../features/onboarding/presentation/profile_screen.dart';
import '../features/onboarding/presentation/role_screen.dart';
import '../features/onboarding/presentation/session_controller.dart';
import '../features/onboarding/presentation/welcome_screen.dart';
import '../features/placeholder/presentation/placeholder_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/wallet/data/providers.dart';
import '../features/wallet/domain/plan.dart';
import '../features/wallet/domain/wallet_rules.dart';
import '../features/wallet/presentation/plan/plan_screen.dart';
import '../features/wallet/presentation/wallet/wallet_tab.dart';
import 'routes.dart';

part 'router.g.dart';

const _placeholderPaths = {
  PlaceholderKind.emptySeats: Routes.emptySeats,
  PlaceholderKind.offerTrip: Routes.offerTrip,
  PlaceholderKind.postTrip: Routes.postTrip,
};

/// A rider with no plan, or a due/expired one, is sent to the plan screen
/// before they can use Today/Week (research R2); Wallet/Trust stay
/// reachable (FR-014 is a prompt, not a lockout).
Future<String?> _requirePlan(Ref ref, BuildContext context, GoRouterState state) async {
  final role = ref.read(sessionControllerProvider).profile?.role;
  if (role != Role.rider) return null;
  final meId = ref.read(dailyCommuteRepositoryProvider).meId;
  final plan = await ref.read(walletRepositoryProvider).getPlan(meId);
  final today = ref.read(nowProvider)().date;
  final ok = plan != null && (plan.type == PlanType.company || !WalletRules.isPlanDue(plan, today));
  return ok ? null : Routes.plan;
}

/// Built once; the first location is the person's resume step.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: routeForSession(
      ref.read(sessionControllerProvider),
      isMember: FakeCommuteRepository.hasMembership(ref.read(sharedPreferencesProvider)),
    ),
    routes: [
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: Routes.phone, builder: (_, _) => const PhoneScreen()),
      GoRoute(
        path: Routes.otp,
        redirect: (_, state) =>
            PhoneNumber.tryParse(state.uri.queryParameters[Routes.phoneParam] ?? '') == null
                ? Routes.phone
                : null,
        builder: (_, state) =>
            OtpScreen(phone: PhoneNumber.tryParse(state.uri.queryParameters[Routes.phoneParam]!)!),
      ),
      GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen()),
      GoRoute(path: Routes.role, builder: (_, _) => const RoleScreen()),
      GoRoute(path: Routes.frequency, builder: (_, _) => const FrequencyScreen()),
      GoRoute(path: Routes.commuteSetup, builder: (_, _) => const CommuteSetupScreen()),
      GoRoute(path: Routes.match, builder: (_, _) => const MatchResultScreen()),
      GoRoute(path: Routes.noMatch, builder: (_, _) => const NoMatchScreen()),
      GoRoute(path: Routes.plan, builder: (_, _) => const PlanScreen()),
      for (final kind in PlaceholderKind.values)
        GoRoute(path: _placeholderPaths[kind]!, builder: (_, _) => PlaceholderScreen(kind: kind)),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.today,
                redirect: (context, state) => _requirePlan(ref, context, state),
                builder: (_, _) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.week,
                redirect: (context, state) => _requirePlan(ref, context, state),
                builder: (_, _) => const WeekScreen(),
              ),
            ],
          ),
          StatefulShellBranch(routes: [GoRoute(path: Routes.wallet, builder: (_, _) => const WalletTab())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.trust, builder: (_, _) => const TrustScreen())]),
        ],
      ),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      if (kDebugMode) GoRoute(path: Routes.gallery, builder: (_, _) => const DesignGalleryScreen()),
    ],
  );
}
