import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/preferences.dart';
import '../domain/commute_repository.dart';
import '../domain/corridor.dart';
import '../domain/pricing_service.dart';
import 'corridors.dart';
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
