import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/preferences.dart';
import '../domain/commute_repository.dart';
import '../domain/corridor.dart';
import '../domain/pricing_service.dart';
import 'corridors.dart';
import 'fake_commute_repository.dart';
import 'group_catalog.dart';

part 'providers.g.dart';

/// Every commute group the fakes know: the active corridor's seed plus groups the
/// marketplace created (005 research R10). The commute and daily
/// repositories watch it, so invalidating it rebuilds both.
@Riverpod(keepAlive: true)
GroupCatalog groupCatalog(Ref ref) => GroupCatalog(
      ref.watch(sharedPreferencesProvider),
      seed: Corridors.groupsOf(ref.watch(activeCorridorProvider)),
    );

@Riverpod(keepAlive: true)
CommuteRepository commuteRepository(Ref ref) => FakeCommuteRepository(
      ref.watch(sharedPreferencesProvider),
      catalog: ref.watch(groupCatalogProvider),
      corridor: ref.watch(activeCorridorProvider),
    );

/// Real rates stay off until the founder sets them (brief §8 open item); the
/// demo trip cost is the active corridor's (006 T024).
@Riverpod(keepAlive: true)
TripCostConfig tripCostConfig(Ref ref) => TripCostConfig(demoCorridorCost: ref.watch(activeCorridorProvider).tripCost);

/// The corridor the app shows (006 research R4): Cairo ↔ Ismailia unless a
/// demo setting or a test switches it. "Reset demo data" clears the choice.
@Riverpod(keepAlive: true)
class ActiveCorridor extends _$ActiveCorridor {
  static const storageKey = 'demo.corridor';

  @override
  Corridor build() {
    final id = ref.read(sharedPreferencesProvider).getString(storageKey);
    return (id == null ? null : Corridors.byId(id)) ?? Corridors.cairoIsmailia;
  }

  Future<void> select(Corridor corridor) async {
    state = corridor;
    await ref.read(sharedPreferencesProvider).setString(storageKey, corridor.id);
  }
}
