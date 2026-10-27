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
import '../../company/data/company_seed.dart';
import '../../company/data/fake_company_repository.dart';
import '../../company/data/providers.dart';
import '../../company/domain/company.dart';
import '../../company/domain/invoice.dart';
import '../../company/presentation/company_controller.dart';
import '../../daily/data/fake_daily_commute_repository.dart';
import '../../daily/data/fake_trust_repository.dart';
import '../../daily/data/providers.dart';
import '../../daily/domain/schedule.dart';
import '../../daily/presentation/labels.dart';
import '../../daily/presentation/today/today_controller.dart';
import '../../marketplace/data/fake_marketplace_repository.dart';
import '../../marketplace/data/providers.dart';
import '../../marketplace/domain/marketplace_repository.dart';
import '../../marketplace/presentation/empty_seats/empty_seats_controller.dart';
import '../../marketplace/presentation/offer_trip/offer_trip_controller.dart';
import '../../marketplace/presentation/post_trip/post_trip_controller.dart';
import '../../marketplace/presentation/today/one_off_section.dart';
import '../../onboarding/data/providers.dart';
import '../../onboarding/presentation/session_controller.dart';
import '../../wallet/data/fake_wallet_repository.dart';
import '../../wallet/data/providers.dart';
import '../../wallet/presentation/wallet/wallet_controller.dart';

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
            ('demo-verify-driver', l10n.demoVerifyDriver, () => _verifyDriver(ref)),
            ('demo-rider-books', l10n.demoBookSeat, () => _riderBooks(context, ref)),
            ('demo-driver-accepts', l10n.demoAcceptRequest, () => _driverAccepts(context, ref)),
            ('demo-subscriber-takes', l10n.demoReclaim, () => _subscriberTakes(context, ref)),
            ('demo-approve-company', l10n.demoApproveCompany, () => _approveCompany(ref)),
            ('demo-make-me-hr', l10n.demoMakeMeHr, () => _makeMeHr(ref)),
            ('demo-skip-to-suspension', l10n.demoSkipToSuspension, () => _skipToSuspension(ref)),
            ('demo-mark-invoice-paid', l10n.demoMarkInvoicePaid, () => _markInvoicePaid(ref)),
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
    final today = ref.read(nowProvider)().date;
    // No group (a once rider): there is no schedule, so use the next Sun–Thu.
    if (g == null) return _nextWorkday(today.addDays(from));
    final me = g.member(repo.meId)!;
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

  static CalendarDate _nextWorkday(CalendarDate from) {
    var d = from;
    while (d.weekday == Day.fri || d.weekday == Day.sat) {
      d = d.addDays(1);
    }
    return d;
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

  /// ID, license and vehicle read as verified, so a driver can publish (005 R14).
  Future<void> _verifyDriver(WidgetRef ref) async {
    final trust = ref.read(trustRepositoryProvider);
    if (trust is FakeTrustRepository) await trust.demoVerifyDriver();
    ref.invalidate(offerCheckProvider);
  }

  /// Goora staff approve a company (010 US1): mine while it is pending, else
  /// the seeded pending one (Orange Business).
  Future<void> _approveCompany(WidgetRef ref) async {
    final repo = ref.read(companyRepositoryProvider);
    final now = ref.read(nowProvider)();
    final mine = await repo.myCompanyAccount(ref.read(dailyCommuteRepositoryProvider).meId, now);
    final pending = mine != null && mine.status == CompanyStatus.pending
        ? mine.company
        : await repo.companyForDomain('orange.com');
    if (pending != null && pending.status == CompanyStatus.pending) await repo.demoApprove(pending.id, now);
    ref.invalidate(companyAccountProvider);
  }

  /// Goora staff name me Valeo's HR contact (010 R5), to see an active home.
  Future<void> _makeMeHr(WidgetRef ref) async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    await ref.read(companyRepositoryProvider).demoSetHrContact(CompanySeed.valeoId, meId, ref.read(nowProvider)());
    ref.invalidate(companyAccountProvider);
  }

  /// Valeo's invoices: issued lazily up to [now], newest first.
  Future<List<Invoice>> _valeoInvoices(WidgetRef ref, WallTime now) =>
      ref.read(companyRepositoryProvider).invoices(CompanySeed.valeoId, now);

  /// Goora staff mark Valeo's oldest unpaid invoice paid (010 US3, FR-012).
  /// Coverage returns from this moment, and the employee's notice follows.
  Future<void> _markInvoicePaid(WidgetRef ref) async {
    final now = ref.read(nowProvider)();
    final unpaid = (await _valeoInvoices(ref, now)).where((i) => i.paidAt == null).toList();
    if (unpaid.isNotEmpty) {
      await ref
          .read(companyRepositoryProvider)
          .demoMarkPaid(unpaid.last.id, bankRef: 'DEMO-${unpaid.last.month}', now: now);
    }
    await _refreshCompany(ref);
  }

  /// Moves the clock to 10:00 on the day Valeo's plan pauses for the invoice
  /// that falls due next (the 24th), so the unpaid case can be walked.
  Future<void> _skipToSuspension(WidgetRef ref) async {
    final now = ref.read(nowProvider)();
    final invoices = await _valeoInvoices(ref, now);
    final open = invoices.where((i) => i.paidAt == null).toList();
    // The oldest unpaid one, or the one issued next month.
    final issued = open.isNotEmpty ? open.last.issuedOn : invoices.first.issuedOn.addMonths(1);
    final suspendOn = Invoice.issue(
      company: (await ref.read(companyRepositoryProvider).companyForDomain('valeo.com'))!,
      month: issued.addMonths(-1),
      peakEnrolled: 0,
    ).suspendFrom.date;
    await _setClock(ref, WallTime(suspendOn, const Clock.hm(10, 0)));
    await _refreshCompany(ref);
  }

  /// Re-reads the company area so the employee's notice follows the clock.
  Future<void> _refreshCompany(WidgetRef ref) async {
    ref.invalidate(companyAccountProvider);
    ref.invalidate(riderPricingProvider);
    ref.invalidate(walletControllerProvider);
    await ref.read(companyAccountProvider.future);
  }

  /// The next fake rider books the driver's latest open offer. A daily offer's
  /// first booking turns it into a commute group (005 R10).
  Future<void> _riderBooks(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final result = await ref.read(marketplaceRepositoryProvider).demoRiderBooks(now: ref.read(nowProvider)());
    ref
      ..invalidate(driverOffersProvider)
      ..invalidate(dailyCommuteRepositoryProvider)
      ..invalidate(todayControllerProvider);
    if (result is DemoNothing && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.demoNothingToDo)));
    }
  }

  /// The next fake driver takes the person's latest posted request (005 R10, R8).
  Future<void> _driverAccepts(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final result = await ref.read(marketplaceRepositoryProvider).demoDriverAccepts(now: ref.read(nowProvider)());
    ref
      ..invalidate(postedRequestProvider)
      ..invalidate(myPostedRequestsProvider)
      ..invalidate(oneOffTodayProvider)
      ..invalidate(walletControllerProvider)
      ..invalidate(todayControllerProvider);
    if (result is DemoNothing && context.mounted) _say(context, l10n.demoPostTripFirst);
  }

  /// A subscriber takes the person's latest one-off seat; after 9 PM it is final (US6).
  Future<void> _subscriberTakes(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final result = await ref.read(marketplaceRepositoryProvider).demoSubscriberTakes(now: ref.read(nowProvider)());
    ref
      ..invalidate(oneOffTodayProvider)
      ..invalidate(myBookingsProvider)
      ..invalidate(walletControllerProvider)
      ..invalidate(todayControllerProvider);
    if (!context.mounted) return;
    switch (result) {
      case DemoTooLate():
        _say(context, l10n.reclaimTooLate);
      case DemoNothing():
        _say(context, l10n.demoBookSeatFirst);
      case DemoDone():
        break;
    }
  }

  void _say(BuildContext context, String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  /// Everything the demo built up: daily schedule/attendance, trust data,
  /// the saved commute (profile, group membership, waitlist) and the signed-
  /// in person — a real start-over, not just the daily-commute slice.
  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(dailyCommuteRepositoryProvider);
    if (repo is FakeDailyCommuteRepository) await repo.reset();
    final prefs = ref.read(sharedPreferencesProvider);
    for (final key in [
      ...FakeTrustRepository.allKeys,
      ...FakeCommuteRepository.allKeys,
      ActiveCorridor.storageKey,
    ]) {
      await prefs.remove(key);
    }
    await FakeWalletRepository.clearAll(prefs);
    // Every market.* key: offers, requests, bookings, and the groups and members the catalog keeps.
    await FakeMarketplaceRepository.clearAll(prefs);
    // Every company.* key (010 T021): companies, enrollments, invoices, the
    // log and the personal plans paused while enrolled; the next read re-seeds.
    await FakeCompanyRepository.clearAllKeys(prefs);
    await ref.read(profileRepositoryProvider).clear();
    await ref.read(sessionControllerProvider.notifier).signOut();
    ref.invalidate(groupCatalogProvider);
    ref.invalidate(marketplaceRepositoryProvider);
    ref.invalidate(companyRepositoryProvider);
    ref.invalidate(dailyCommuteRepositoryProvider);
    ref.invalidate(commuteRepositoryProvider);
    ref.invalidate(activeCorridorProvider);
    // Signed out now — go back to the very start, not just show a message.
    if (context.mounted) context.go(Routes.welcome);
  }
}
