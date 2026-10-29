import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/storage/preferences.dart';
import '../core/time/now_provider.dart';
import '../features/commute/data/fake_commute_repository.dart';
import '../features/commute/domain/commute_profile.dart';
import '../features/commute/presentation/commute_setup_screen.dart';
import '../features/commute/presentation/match_result_screen.dart';
import '../features/commute/presentation/no_match_screen.dart';
import '../features/company/presentation/company_dashboard_screen.dart';
import '../features/company/presentation/company_home_screen.dart';
import '../features/company/presentation/company_log_screen.dart';
import '../features/company/presentation/invoice_screen.dart';
import '../features/company/presentation/invoices_screen.dart';
import '../features/company/presentation/register_company_screen.dart';
import '../features/company/presentation/roster_screen.dart';
import '../features/company/presentation/statement_screen.dart';
import '../features/daily/data/daily_seed.dart';
import '../features/daily/data/providers.dart';
import '../features/daily/presentation/shell/app_shell.dart';
import '../features/daily/presentation/today/today_screen.dart';
import '../features/daily/presentation/trust/id_check_screen.dart';
import '../features/daily/presentation/trust/trust_screen.dart';
import '../features/daily/presentation/week/week_screen.dart';
import '../features/design_gallery/presentation/design_gallery_screen.dart';
import '../features/marketplace/data/fake_marketplace_repository.dart';
import '../features/marketplace/presentation/empty_seats/empty_seats_screen.dart';
import '../features/marketplace/presentation/find_riders/find_riders_screen.dart';
import '../features/marketplace/presentation/offer_trip/offer_trip_screen.dart';
import '../features/marketplace/presentation/post_trip/post_trip_controller.dart';
import '../features/marketplace/presentation/post_trip/post_trip_screen.dart';
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
import '../features/settings/presentation/settings_screen.dart';
import '../features/wallet/data/providers.dart';
import '../features/wallet/presentation/pay_method/pay_method_screen.dart';
import '../features/wallet/presentation/plan/plan_screen.dart';
import '../features/wallet/presentation/wallet/wallet_tab.dart';
import 'routes.dart';

part 'router.g.dart';

/// A rider with no payment arrangement — a payment method, a paid-up
/// subscription or a company plan — is sent to the payment-method screen
/// before Today/Week (004 v2 research R9); Wallet/Trust stay reachable.
Future<String?> _requireArrangement(Ref ref, BuildContext context, GoRouterState state) async {
  final role = ref.read(sessionControllerProvider).profile?.role;
  if (role != Role.rider) return null;
  final meId = ref.read(dailyCommuteRepositoryProvider).meId;
  final repo = ref.read(walletRepositoryProvider);
  if (await repo.getMethod(meId) != null) return null;
  final plan = await repo.getPlan(meId);
  final today = ref.read(nowProvider)().date;
  return plan != null && plan.coversDate(today) ? null : Routes.payMethod;
}

/// Built once; the first location is the person's resume step.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: routeForSession(
      ref.read(sessionControllerProvider),
      isMember: FakeCommuteRepository.hasMembership(ref.read(sharedPreferencesProvider)),
      hasOneOff: FakeMarketplaceRepository.hasOneOff(ref.read(sharedPreferencesProvider), DailySeed.meId),
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
      GoRoute(
        path: Routes.commuteSetup,
        builder: (_, state) => CommuteSetupScreen(
          presetFrequency: state.uri.queryParameters['frequency'] == 'everyDay' ? Frequency.everyDay : null,
        ),
      ),
      GoRoute(path: Routes.match, builder: (_, _) => const MatchResultScreen()),
      GoRoute(path: Routes.noMatch, builder: (_, _) => const NoMatchScreen()),
      GoRoute(path: Routes.plan, builder: (_, _) => const PlanScreen()),
      GoRoute(
        path: Routes.payMethod,
        builder: (_, state) => PayMethodScreen(next: state.uri.queryParameters['next']),
      ),
      GoRoute(
        path: Routes.idCheck,
        builder: (_, state) => IdCheckScreen(next: state.uri.queryParameters['next']),
      ),
      GoRoute(
        path: Routes.emptySeats,
        builder: (_, state) => EmptySeatsScreen(
          leg: state.uri.queryParameters['leg'] == 'return' ? Leg.ret : Leg.going,
          seat: state.uri.queryParameters['seat'],
        ),
      ),
      GoRoute(
        path: Routes.offerTrip,
        builder: (_, state) => OfferTripScreen(id: state.uri.queryParameters['id']),
      ),
      GoRoute(
        path: Routes.postTrip,
        builder: (_, state) {
          final q = state.uri.queryParameters;
          return PostTripScreen(
            id: q['id'],
            draft: PostTripDraft.parse(from: q['from'], to: q['to'], at: q['at'], repeat: q['repeat']),
          );
        },
      ),
      GoRoute(path: Routes.findRiders, builder: (_, _) => const FindRidersScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.today,
                redirect: (context, state) => _requireArrangement(ref, context, state),
                builder: (_, _) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.week,
                redirect: (context, state) => _requireArrangement(ref, context, state),
                builder: (_, _) => const WeekScreen(),
              ),
            ],
          ),
          StatefulShellBranch(routes: [GoRoute(path: Routes.wallet, builder: (_, _) => const WalletTab())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.trust, builder: (_, _) => const TrustScreen())]),
        ],
      ),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(path: Routes.company, builder: (_, _) => const CompanyHomeScreen()),
      GoRoute(path: Routes.companyRegister, builder: (_, _) => const RegisterCompanyScreen()),
      GoRoute(path: Routes.companyInvoices, builder: (_, _) => const InvoicesScreen()),
      GoRoute(
        path: Routes.companyInvoice,
        builder: (_, state) => InvoiceScreen(invoiceId: state.uri.queryParameters['id'] ?? ''),
      ),
      GoRoute(path: Routes.companyRoster, builder: (_, _) => const RosterScreen()),
      GoRoute(path: Routes.companyLog, builder: (_, _) => const CompanyLogScreen()),
      GoRoute(path: Routes.companyDashboard, builder: (_, _) => const CompanyDashboardScreen()),
      GoRoute(path: Routes.companyStatement, builder: (_, _) => const StatementScreen()),
      if (kDebugMode) GoRoute(path: Routes.gallery, builder: (_, _) => const DesignGalleryScreen()),
    ],
  );
}
