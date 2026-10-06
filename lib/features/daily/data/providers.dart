import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/preferences.dart';
import '../../../core/time/now_provider.dart';
import '../../commute/data/providers.dart';
import '../../onboarding/presentation/session_controller.dart';
import '../domain/daily_commute_repository.dart';
import '../domain/phone_dialer.dart';
import '../domain/trip_sharer.dart';
import 'fake_daily_commute_repository.dart';
import 'share_plus_sharer.dart';
import 'url_phone_dialer.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
DailyCommuteRepository dailyCommuteRepository(Ref ref) => FakeDailyCommuteRepository(
      ref.watch(sharedPreferencesProvider),
      commute: ref.watch(commuteRepositoryProvider),
      person: () => ref.read(sessionControllerProvider).profile,
      now: ref.watch(nowProvider),
    );

@Riverpod(keepAlive: true)
PhoneDialer phoneDialer(Ref ref) => const UrlPhoneDialer();

@Riverpod(keepAlive: true)
TripSharer tripSharer(Ref ref) => const SharePlusSharer();
