import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/preferences.dart';
import '../domain/commute_repository.dart';
import '../domain/pricing_service.dart';
import 'fake_commute_repository.dart';
import 'group_catalog.dart';

part 'providers.g.dart';

/// Every commute group the fakes know: the corridor seed plus groups the
/// marketplace created (005 research R10). The commute and daily
/// repositories watch it, so invalidating it rebuilds both.
@Riverpod(keepAlive: true)
GroupCatalog groupCatalog(Ref ref) => GroupCatalog(ref.watch(sharedPreferencesProvider));

@Riverpod(keepAlive: true)
CommuteRepository commuteRepository(Ref ref) =>
    FakeCommuteRepository(ref.watch(sharedPreferencesProvider), catalog: ref.watch(groupCatalogProvider));

/// Real rates stay off until the founder sets them (brief §8 open item).
@Riverpod(keepAlive: true)
TripCostConfig tripCostConfig(Ref ref) => const TripCostConfig();
