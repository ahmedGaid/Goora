import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/time/now_provider.dart';
import '../../daily/data/providers.dart';
import '../../daily/domain/notice.dart';
import '../../wallet/data/providers.dart';
import '../../wallet/domain/plan.dart';
import '../../wallet/presentation/plan/plan_controller.dart';
import '../../wallet/presentation/wallet/wallet_controller.dart';
import '../data/providers.dart';
import '../domain/company_repository.dart';

part 'company_controller.g.dart';

/// What the company area and the Wallet's company card show the signed-in
/// person: the company they are HR for (null = none), what "Through my
/// company" offers them, and the personal plan their enrollment paused.
typedef CompanyAccountView = ({CompanyHome? home, EnrollOffer offer, PausedPlan? paused});

@riverpod
Future<CompanyAccountView> companyAccount(Ref ref) async {
  final company = ref.watch(companyRepositoryProvider);
  final meId = ref.watch(dailyCommuteRepositoryProvider).meId;
  final now = ref.read(nowProvider)();
  return (
    home: await company.myCompanyAccount(meId, now),
    offer: await company.offerFor(meId, now),
    paused: await ref.watch(walletRepositoryProvider).pausedPlan(meId),
  );
}

/// Joins and leaves call both sides here (research "Lane A notes" #6): the
/// company network may not import wallet code, so this presentation helper
/// is the one place that starts and ends the company plan in the wallet.
/// Leaving through HR, a removed domain or a contract end is P6 (T037).
abstract final class CompanyEnrollment {
  /// Consent given now: enrolled, the personal plan paused, no trial from now.
  static Future<void> enroll(WidgetRef ref) async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    final now = ref.read(nowProvider)();
    final company = ref.read(companyRepositoryProvider);
    final offer = await company.offerFor(meId, now);
    if (offer is! CanEnroll) return;
    await company.enroll(meId, now: now);
    await ref.read(walletRepositoryProvider).startCompanyPlan(meId, now);
    await _notices(ref).post(NoticeKind.companyPlanStarted, {'company': offer.companyName});
    _refresh(ref);
  }

  /// Self-leave: the company plan ends now, a paused personal plan comes back.
  static Future<void> leave(WidgetRef ref) async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    final now = ref.read(nowProvider)();
    final company = ref.read(companyRepositoryProvider);
    final wallet = ref.read(walletRepositoryProvider);
    final offer = await company.offerFor(meId, now);
    if (offer is! Enrolled) return;
    final paused = await wallet.pausedPlan(meId);
    await company.leave(meId, now: now);
    await wallet.endCompanyPlan(meId, now);
    final notices = _notices(ref);
    await notices.post(NoticeKind.companyPlanEnded, {'company': offer.companyName});
    if (paused != null) await notices.post(NoticeKind.personalPlanBack, {'days': '${paused.daysLeft}'});
    _refresh(ref);
  }

  static NoticeSink _notices(WidgetRef ref) => ref.read(dailyCommuteRepositoryProvider) as NoticeSink;

  static void _refresh(WidgetRef ref) {
    ref.invalidate(companyAccountProvider);
    ref.invalidate(planControllerProvider);
    ref.invalidate(riderPricingProvider);
    ref.invalidate(walletControllerProvider);
  }
}
