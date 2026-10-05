import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/design_gallery/presentation/design_gallery_screen.dart';
import '../features/onboarding/domain/onboarding_flow.dart';
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
import 'routes.dart';

part 'router.g.dart';

/// Built once; the first location is the person's resume step.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: routeForSession(ref.read(sessionControllerProvider)),
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
        builder: (_, _) => const PlaceholderScreen(destination: Destination.commuteSetup),
      ),
      GoRoute(
        path: Routes.emptySeats,
        builder: (_, _) => const PlaceholderScreen(destination: Destination.emptySeatsToday),
      ),
      GoRoute(
        path: Routes.offerTrip,
        builder: (_, _) => const PlaceholderScreen(destination: Destination.offerTrip),
      ),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      if (kDebugMode) GoRoute(path: Routes.gallery, builder: (_, _) => const DesignGalleryScreen()),
    ],
  );
}
