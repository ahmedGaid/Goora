import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/preferences.dart';
import '../domain/commute_repository.dart';
import '../domain/pricing_service.dart';
import 'fake_commute_repository.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
CommuteRepository commuteRepository(Ref ref) => FakeCommuteRepository(ref.watch(sharedPreferencesProvider));

/// Real rates stay off until the founder sets them (brief §8 open item).
@Riverpod(keepAlive: true)
TripCostConfig tripCostConfig(Ref ref) => const TripCostConfig();
