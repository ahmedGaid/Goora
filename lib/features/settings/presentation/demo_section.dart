import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/now_provider.dart';
import '../../../core/time/wall_time.dart';
import '../../../core/widgets/goora_card.dart';
import '../../../core/widgets/goora_ghost_button.dart';
import '../../commute/data/fake_commute_repository.dart';
import '../../commute/data/providers.dart';
import '../../commute/domain/clock.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/group.dart';
import '../../commute/presentation/labels.dart';
import '../../daily/data/fake_daily_commute_repository.dart';
import '../../daily/data/fake_trust_repository.dart';
import '../../daily/data/providers.dart';
import '../../daily/domain/schedule.dart';
import '../../daily/presentation/labels.dart';
import '../../daily/presentation/today/today_controller.dart';
import '../../onboarding/data/providers.dart';
import '../../onboarding/presentation/session_controller.dart';
import '../../wallet/data/fake_wallet_repository.dart';

/// Debug builds only (research R11): move the demo clock to the moments the
/// rules care about, or reset the fake daily data. Release builds never
/// show this and always use real time.
class DemoSection extends ConsumerWidget {
  const DemoSection({super.key});

  static const _lookAhead = 21;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(nowProvider)();
    return GooraCard(
      key: const Key('demo-section'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.listCardPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.demoSection, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.demoNow(l10n.demoNowValue(l10n.dayOf(now.date), now.date.toIso(), l10n.time(now.time))),
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          for (final (key, label, action) in [
            ('demo-ride-day', l10n.demoRideDay, () => _rideDay(ref)),
            ('demo-855', l10n.demo855, () => _eveningBefore(ref, const Clock.hm(20, 55))),
            ('demo-905', l10n.demo905, () => _eveningBefore(ref, const Clock.hm(21, 5))),
            ('demo-real', l10n.demoRealTime, () => _setClock(ref, null)),
            ('demo-driver-arrives', l10n.demoDriverArrives, () => _driverArrives(ref)),
            ('demo-backup', l10n.demoBackup, () => _driverOut(ref, cover: true)),
            ('demo-no-cover', l10n.demoNoCover, () => _driverOut(ref, cover: false)),
            ('demo-reset', l10n.demoReset, () => _reset(context, ref)),
          ]) ...[
            const SizedBox(height: AppSpacing.md),
            GooraGhostButton(key: Key(key), label: label, onPressed: action),
          ],
        ],
      ),
    );
  }

  Future<void> _setClock(WidgetRef ref, WallTime? at) async {
    await DemoClock.write(ref.read(sharedPreferencesProvider), at);
    ref.invalidate(nowProvider);
  }

  /// The next day the person drives (drivers) or rides, at 7:15 AM.
  Future<void> _rideDay(WidgetRef ref) async {
    final day = await _nextDuty(ref, from: 0);
    if (day != null) await _setClock(ref, WallTime(day, const Clock.hm(7, 15)));
  }

  /// The evening before the next ride day, around the 9 PM cut-off.
  Future<void> _eveningBefore(WidgetRef ref, Clock time) async {
    final day = await _nextDuty(ref, from: 1);
    if (day != null) await _setClock(ref, WallTime(day.addDays(-1), time));
  }

  Future<CalendarDate?> _nextDuty(WidgetRef ref, {required int from}) async {
    final repo = ref.read(dailyCommuteRepositoryProvider);
    final g = await repo.myGroup();
    if (g == null) return null;
    final me = g.member(repo.meId)!;
    final today = ref.read(nowProvider)().date;
    for (final d in await repo.schedule(today.addDays(from), today.addDays(_lookAhead))) {
      final duties = [
        for (final leg in Leg.values)
          if (d.assignment(leg) != null) d.dutyOf(me.id, leg, travels: travelsOn(g, me, d.date, leg)),
      ];
      final wanted = me.role == MemberRole.driver ? Duty.drive : Duty.ride;
      if (duties.contains(wanted)) return d.date;
    }
    return null;
  }

  /// My next trip's driver checks in at my stop at my pickup time, so the
  /// live trip (marker + arrival countdown, US7) can be seen on one device.
  Future<void> _driverArrives(WidgetRef ref) async {
    final view = await ref.read(todayControllerProvider.future);
    final leg = view.upcomingRides.firstOrNull;
    final ride = leg?.ride;
    if (leg == null || ride == null || ride.driverId == null) return;
    await _setClock(ref, leg.pickup);
    await ref.read(dailyCommuteRepositoryProvider).arrivedAt(ride.id, leg.stop.id, leg.pickup);
    ref.invalidate(todayControllerProvider);
  }

  /// Next Tuesday's driver can't drive, with or without a cover.
  Future<void> _driverOut(WidgetRef ref, {required bool cover}) async {
    final repo = ref.read(dailyCommuteRepositoryProvider);
    if (repo is FakeDailyCommuteRepository) await repo.demoDriverOut(cover: cover);
    ref.invalidate(dailyCommuteRepositoryProvider);
  }

  /// Everything the demo built up: daily schedule/attendance, trust data,
  /// the saved commute (profile, group membership, waitlist) and the signed-
  /// in person — a real start-over, not just the daily-commute slice.
  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(dailyCommuteRepositoryProvider);
    if (repo is FakeDailyCommuteRepository) await repo.reset();
    final prefs = ref.read(sharedPreferencesProvider);
    for (final key in [...FakeTrustRepository.allKeys, ...FakeCommuteRepository.allKeys]) {
      await prefs.remove(key);
    }
    await FakeWalletRepository.clearAll(prefs);
    await ref.read(profileRepositoryProvider).clear();
    await ref.read(sessionControllerProvider.notifier).signOut();
    ref.invalidate(dailyCommuteRepositoryProvider);
    ref.invalidate(commuteRepositoryProvider);
    // Signed out now — go back to the very start, not just show a message.
    if (context.mounted) context.go(Routes.welcome);
  }
}
