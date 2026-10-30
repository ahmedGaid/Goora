import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/backend/backend.dart';
import '../../../core/backend/backend_providers.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/time/now_provider.dart';
import '../../commute/data/providers.dart';
import '../../daily/data/providers.dart';
import '../../daily/domain/notice.dart';
import '../../wallet/data/providers.dart';
import '../../wallet/domain/wallet_repository.dart';
import '../domain/marketplace_repository.dart';
import 'fake_marketplace_repository.dart';
import 'supabase_marketplace_repository.dart';

part 'providers.g.dart';

/// The marketplace wired to its seams (research R9): notices and reliability
/// into 003's fake, seat money into 004's ledger, the gate's balance and plan
/// from the wallet, the verification check from Trust.
///
/// The wallet in turn reads this one's finished one-off trips (see
/// `walletRepository`). Each side reads the other only inside a callback, so
/// the two providers never depend on each other while they build.
@Riverpod(keepAlive: true)
MarketplaceRepository marketplaceRepository(Ref ref) {
  final daily = ref.watch(dailyCommuteRepositoryProvider);
  if (ref.watch(backendModeProvider) == BackendMode.live) {
    return SupabaseMarketplaceRepository(
      ref.watch(backendGatewayProvider),
      trust: ref.watch(trustRepositoryProvider),
      wallet: () => ref.read(walletRepositoryProvider),
      daily: daily,
      corridor: ref.watch(activeCorridorProvider),
    );
  }
  return FakeMarketplaceRepository(
    ref.watch(sharedPreferencesProvider),
    catalog: ref.watch(groupCatalogProvider),
    daily: daily,
    commute: ref.watch(commuteRepositoryProvider),
    // The fake daily repository is both the schedule and the notice sink.
    notices: daily as NoticeSink,
    // Looked up when a story needs them: the wallet reads this provider for
    // its one-off trips, and Riverpod forbids a watch cycle.
    ledger: () => ref.read(walletRepositoryProvider) as SeatLedger,
    wallet: () => ref.read(walletRepositoryProvider),
    trust: ref.watch(trustRepositoryProvider),
    now: ref.watch(nowProvider),
    corridor: ref.watch(activeCorridorProvider),
  );
}
