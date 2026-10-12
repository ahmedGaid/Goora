import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/preferences.dart';
import '../../../core/time/now_provider.dart';
import '../../commute/domain/group.dart';
import '../../daily/data/providers.dart';
import '../../onboarding/domain/choices.dart';
import '../../onboarding/presentation/session_controller.dart';
import '../domain/cash_mark.dart';
import '../domain/payment_method.dart';
import '../domain/payment_provider.dart';
import '../domain/wallet_repository.dart';
import 'fake_payment_provider.dart';
import 'fake_wallet_repository.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
PaymentProvider paymentProvider(Ref ref) => FakePaymentProvider();

@Riverpod(keepAlive: true)
WalletRepository walletRepository(Ref ref) => FakeWalletRepository(
      ref.watch(sharedPreferencesProvider),
      daily: ref.watch(dailyCommuteRepositoryProvider),
      role: () => ref.read(sessionControllerProvider).profile!.role == Role.driver
          ? MemberRole.driver
          : MemberRole.rider,
      now: ref.watch(nowProvider),
      provider: ref.watch(paymentProviderProvider),
    );

/// For a driver's check-in after drop-off (FR-012): is this passenger paying
/// cash, and has the driver already recorded it? `isCash` false hides the
/// buttons entirely.
@riverpod
Future<({bool isCash, CashOutcome? outcome})> cashStatus(Ref ref, String rideId, String riderId) async {
  final repo = ref.watch(walletRepositoryProvider);
  if (await repo.methodOf(riderId) != PaymentMethod.cash) return (isCash: false, outcome: null);
  final mark = (await repo.cashMarks(rideId)).where((m) => m.riderId == riderId).firstOrNull;
  return (isCash: true, outcome: mark?.outcome);
}

/// The signed-in rider's current price mode (FR-004). Price lines watch this;
/// screens that change the arrangement invalidate it.
@riverpod
Future<PricingMode> riderPricing(Ref ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  final meId = ref.watch(dailyCommuteRepositoryProvider).meId;
  final wallet = await repo.getWallet(meId);
  return PricingMode.of(
    method: wallet.method,
    plan: await repo.getPlan(meId),
    today: ref.read(nowProvider)().date,
    cashAvailable: wallet.cashTrial?.available ?? false,
  );
}
