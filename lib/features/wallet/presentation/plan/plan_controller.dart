import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/now_provider.dart';
import '../../../daily/data/providers.dart';
import '../../data/providers.dart';
import '../../domain/plan.dart';

part 'plan_controller.g.dart';

@riverpod
class PlanController extends _$PlanController {
  @override
  Future<Plan?> build() async {
    final meId = ref.watch(dailyCommuteRepositoryProvider).meId;
    return ref.watch(walletRepositoryProvider).getPlan(meId);
  }

  /// Monthly/Yearly start the trial immediately (FR-002). Company only
  /// after the work-email verify sheet confirms (FR-003).
  Future<void> choosePlan(PlanType type) async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    final today = ref.read(nowProvider)().date;
    await ref.read(walletRepositoryProvider).choosePlan(meId, type, today: today);
    ref.invalidateSelf();
    await future;
  }
}
