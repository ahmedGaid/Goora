import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/preferences.dart';
import '../../../core/time/now_provider.dart';
import '../../commute/domain/group.dart';
import '../../company/data/providers.dart';
import '../../daily/data/providers.dart';
import '../../marketplace/data/providers.dart';
import '../../onboarding/domain/choices.dart';
import '../../onboarding/presentation/session_controller.dart';
import '../domain/payment_method.dart';
import '../domain/payment_provider.dart';
import '../domain/share.dart';
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
      // Read when called, not while building: the marketplace watches this
      // provider back for its ledger (005 research R9).
      oneOffs: () => ref.read(marketplaceRepositoryProvider).doneOneOffs(),
      // Read when called too (010 T019): the company network never reads the
      // wallet back while building. Someone who never enrolled gets null, so
      // a company plan from before 010 keeps covering from its start.
      companyCoverage: (personId) async {
        final company = ref.read(companyRepositoryProvider);
        if (!await company.hasEnrolled(personId)) return null;
        return company.coverageFor(personId, ref.read(nowProvider)());
      },
    );

/// For a driver's check-in after drop-off (004 FR-012, 007 US2): this
/// passenger's share on this ride and where it stands; null hides the
/// buttons (no share there).
@riverpod
Future<Share?> driverShare(Ref ref, String rideId, String riderId) =>
    ref.watch(walletRepositoryProvider).driverShareOn(rideId, riderId);

/// A driver's InstaPay handle, for a rider with a confirmed ride (007 FR-013).
@riverpod
Future<String?> driverInstapay(Ref ref, String driverId) =>
    ref.watch(walletRepositoryProvider).instapayHandleOf(driverId);

/// The signed-in rider's shares a driver hasn't confirmed, open debts first
/// (007 US3 debt banner).
@riverpod
Future<List<Share>> myOpenShares(Ref ref) =>
    ref.watch(walletRepositoryProvider).openShares(ref.watch(dailyCommuteRepositoryProvider).meId);

/// How the signed-in rider pays the driver (cash unless they chose InstaPay):
/// price lines read it for the share (007 R4).
@riverpod
Future<PaymentMethod> riderPayMethod(Ref ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  return await repo.getMethod(ref.watch(dailyCommuteRepositoryProvider).meId) ?? PaymentMethod.cash;
}

/// The signed-in rider's current price mode (FR-004). Price lines watch this;
/// screens that change the arrangement invalidate it.
@riverpod
Future<PricingMode> riderPricing(Ref ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  final meId = ref.watch(dailyCommuteRepositoryProvider).meId;
  final wallet = await repo.getWallet(meId);
  return PricingMode.of(
    plan: await repo.getPlan(meId),
    now: ref.read(nowProvider)(),
    trialAvailable: wallet.cashTrial?.available ?? false,
  );
}
