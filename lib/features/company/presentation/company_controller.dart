import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/preferences.dart';
import '../../../core/time/now_provider.dart';
import '../../../core/time/wall_time.dart';
import '../../daily/data/providers.dart';
import '../../daily/domain/notice.dart';
import '../../wallet/data/providers.dart';
import '../../wallet/domain/direct_pay.dart';
import '../../wallet/domain/plan.dart';
import '../../wallet/domain/wallet_repository.dart';
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

/// The repositories the company area's catch-up work writes to, read once
/// before the first await: the provider may be rebuilt while it runs, and a
/// disposed Ref may not be read again (Riverpod 3).
typedef _Deps = ({
  CompanyRepository company,
  WalletRepository wallet,
  SharedPreferences prefs,
  NoticeSink notices,
});

@riverpod
Future<CompanyAccountView> companyAccount(Ref ref) async {
  final company = ref.watch(companyRepositoryProvider);
  final meId = ref.watch(dailyCommuteRepositoryProvider).meId;
  final now = ref.read(nowProvider)();
  final wallet = ref.watch(walletRepositoryProvider);
  final _Deps deps = (
    company: company,
    wallet: wallet,
    prefs: ref.read(sharedPreferencesProvider),
    notices: ref.read(dailyCommuteRepositoryProvider) as NoticeSink,
  );
  final offer = await company.offerFor(meId, now);
  if (offer is Enrolled) {
    await _syncCoverageNotice(deps, meId, now);
  } else if (await _syncLeave(deps, meId, now) && ref.mounted) {
    ref.invalidate(planControllerProvider);
    ref.invalidate(riderPricingProvider);
    ref.invalidate(walletControllerProvider);
  }
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
Future<void> _syncCoverageNotice(_Deps d, String personId, WallTime now) async {
  final windows = await d.company.coverageFor(personId, now);
  final covered = CompanyRules.covered(windows, SharePolicy.minuteOf(now));
  final key = coverageNoticeKey(personId);
  final told = d.prefs.getBool(key) ?? true;
  if (covered == told) return;
  await d.prefs.setBool(key, covered);
  await d.notices.post(covered ? NoticeKind.companyPlanResumed : NoticeKind.companyPlanPaused, const {});
}

/// Every leave path ends the company plan here (010 US4, T037): by
/// themselves, removed by HR, their domain removed, the contract ending. The
/// company network may not call the wallet (research R8), so the employee's
/// side catches up when it next reads: the wallet plan still says company
/// while no enrollment is open. The plan ends at the leave moment, so trips
/// before stay fee-free and later ones carry the fee; a paused personal plan
/// comes back; one notice each. Done once: after it the plan is no longer a
/// company plan. A company plan with no enrollment behind it (before 010,
/// `coverage == null`) is left alone. True when it ended a plan.
Future<bool> _syncLeave(_Deps d, String personId, WallTime now) async {
  final plan = await d.wallet.getPlan(personId);
  if (plan == null || plan.type != PlanType.company || plan.coverage == null) return false;
  final left = await d.company.lastLeave(personId, now);
  if (left == null) return false;
  final paused = await d.wallet.pausedPlan(personId);
  await d.wallet.endCompanyPlan(personId, left.at);
  await d.prefs.remove(coverageNoticeKey(personId));
  await d.notices.post(NoticeKind.companyPlanEnded, {'company': left.companyName});
  if (paused != null) await d.notices.post(NoticeKind.personalPlanBack, {'days': '${paused.daysLeft}'});
  return true;
}

/// What the person was last told about their company plan: true = covering.
String coverageNoticeKey(String personId) => 'company.coverageNotice.$personId';

/// Joins and leaves call both sides here (research "Lane A notes" #6): the
/// company network may not import wallet code, so this presentation helper
/// is the one place that starts and ends the company plan in the wallet.
/// Leaving ends the plan through [_syncLeave], whoever made the person leave.
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

  /// Self-leave: ends the enrollment now; reading the company area again
  /// ends the plan in the wallet like every other leave path ([_syncLeave]).
  static Future<void> leave(WidgetRef ref) async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    final now = ref.read(nowProvider)();
    final company = ref.read(companyRepositoryProvider);
    if (await company.offerFor(meId, now) is! Enrolled) return;
    await company.leave(meId, now: now);
    ref.invalidate(companyAccountProvider);
    await ref.read(companyAccountProvider.future);
  }

  static NoticeSink _notices(WidgetRef ref) => ref.read(dailyCommuteRepositoryProvider) as NoticeSink;

  static void _refresh(WidgetRef ref) {
    ref.invalidate(companyAccountProvider);
    ref.invalidate(planControllerProvider);
    ref.invalidate(riderPricingProvider);
    ref.invalidate(walletControllerProvider);
  }
}
