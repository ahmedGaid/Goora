import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/now_provider.dart';
import '../../../daily/data/providers.dart';
import '../../data/providers.dart';
import '../../domain/plan.dart';
import '../../domain/wallet_repository.dart';
import '../wallet/wallet_controller.dart';

part 'plan_controller.g.dart';

@riverpod
class PlanController extends _$PlanController {
  @override
  Future<Plan?> build() async {
    final meId = ref.watch(dailyCommuteRepositoryProvider).meId;
    return ref.watch(walletRepositoryProvider).getPlan(meId);
  }

  /// Monthly/yearly are paid from the wallet (research R10); company only
  /// after the work-email sheet confirms. Nothing changes on `needsTopUp`.
  Future<SubscribeResult> subscribe(PlanType type) async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    final today = ref.read(nowProvider)().date;
    final result = await ref.read(walletRepositoryProvider).subscribe(meId, type, today: today);
    if (result == SubscribeResult.subscribed) {
      ref.invalidate(riderPricingProvider);
      ref.invalidate(walletControllerProvider);
      ref.invalidateSelf();
      await future;
    }
    return result;
  }
}
