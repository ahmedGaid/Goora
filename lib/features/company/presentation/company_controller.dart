import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/preferences.dart';
import '../../../core/time/now_provider.dart';
import '../../../core/time/wall_time.dart';
import '../../daily/data/providers.dart';
import '../../daily/domain/notice.dart';
import '../../wallet/data/providers.dart';
import '../../wallet/domain/direct_pay.dart';
import '../../wallet/domain/plan.dart';
import '../../wallet/presentation/plan/plan_controller.dart';
import '../../wallet/presentation/wallet/wallet_controller.dart';
import '../data/providers.dart';
import '../domain/company_repository.dart';
import '../domain/company_rules.dart';

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
  final wallet = ref.watch(walletRepositoryProvider);
  final offer = await company.offerFor(meId, now);
  if (offer is Enrolled) await _syncCoverageNotice(ref, meId, now);
  return (
    home: await company.myCompanyAccount(meId, now),
    offer: offer,
    paused: await wallet.pausedPlan(meId),
  );
}

/// The company plan stops covering an enrolled employee's trips when the
/// company's invoice is unpaid past its grace, and covers again once paid
/// (010 US3, T034). One neutral notice per change, no amounts. The last
/// state told is remembered under `company.*`, so Settings → Reset clears it.
Future<void> _syncCoverageNotice(Ref ref, String personId, WallTime now) async {
  final windows = await ref.read(companyRepositoryProvider).coverageFor(personId, now);
  final covered = CompanyRules.covered(windows, SharePolicy.minuteOf(now));
  final prefs = ref.read(sharedPreferencesProvider);
  final key = coverageNoticeKey(personId);
  final told = prefs.getBool(key) ?? true;
  if (covered == told) return;
  await prefs.setBool(key, covered);
  await (ref.read(dailyCommuteRepositoryProvider) as NoticeSink)
      .post(covered ? NoticeKind.companyPlanResumed : NoticeKind.companyPlanPaused, const {});
}

/// What the person was last told about their company plan: true = covering.
String coverageNoticeKey(String personId) => 'company.coverageNotice.$personId';

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
    await ref.read(sharedPreferencesProvider).remove(coverageNoticeKey(meId));
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
    await ref.read(sharedPreferencesProvider).remove(coverageNoticeKey(meId));
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
