import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/backend/backend.dart';
import '../../../core/backend/backend_providers.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/time/now_provider.dart';
import '../../commute/data/providers.dart';
import '../../onboarding/presentation/session_controller.dart';
import '../domain/daily_commute_repository.dart';
import '../domain/location_source.dart';
import '../domain/phone_dialer.dart';
import '../domain/trip_sharer.dart';
import '../domain/trust_repository.dart';
import 'fake_daily_commute_repository.dart';
import 'fake_trust_repository.dart';
import 'share_plus_sharer.dart';
import 'simulated_location_source.dart';
import 'supabase_daily_commute_repository.dart';
import 'supabase_trust_repository.dart';
import 'url_phone_dialer.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
DailyCommuteRepository dailyCommuteRepository(Ref ref) => switch (ref.watch(backendModeProvider)) {
  BackendMode.fake => FakeDailyCommuteRepository(
    ref.watch(sharedPreferencesProvider),
    commute: ref.watch(commuteRepositoryProvider),
    person: () => ref.read(sessionControllerProvider).profile,
    now: ref.watch(nowProvider),
    catalog: ref.watch(groupCatalogProvider),
  ),
  BackendMode.live => SupabaseDailyCommuteRepository(ref.watch(backendGatewayProvider)),
};

@Riverpod(keepAlive: true)
TrustRepository trustRepository(Ref ref) => switch (ref.watch(backendModeProvider)) {
  BackendMode.fake => FakeTrustRepository(
    ref.watch(sharedPreferencesProvider),
    person: () => ref.read(sessionControllerProvider).profile,
    now: ref.watch(nowProvider),
  ),
  BackendMode.live => SupabaseTrustRepository(
    ref.watch(backendGatewayProvider),
    person: () => ref.read(sessionControllerProvider).profile,
    now: ref.watch(nowProvider),
  ),
};

@Riverpod(keepAlive: true)
PhoneDialer phoneDialer(Ref ref) => const UrlPhoneDialer();

@Riverpod(keepAlive: true)
TripSharer tripSharer(Ref ref) => const SharePlusSharer();

/// Simulated until maps and the server exist (research R8).
@Riverpod(keepAlive: true)
LocationSource locationSource(Ref ref) =>
    SimulatedLocationSource(ref.watch(dailyCommuteRepositoryProvider), now: ref.watch(nowProvider));
