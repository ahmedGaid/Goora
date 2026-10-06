import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_dashed_button.dart';
import '../../../../core/widgets/goora_ghost_button.dart';
import '../../../../core/widgets/goora_icons.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../../commute/domain/commute_profile.dart';
import '../../../commute/presentation/labels.dart';
import '../labels.dart';
import 'cant_come_sheet.dart';
import 'delay_sheet.dart';
import 'pickup_check_in.dart';
import 'rider_today.dart';
import 'today_controller.dart';
import 'today_widgets.dart';

/// Driver Today (US3/AC1–5).
class DriverToday extends StatelessWidget {
  const DriverToday({super.key, required this.view});

  final TodayView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final drive = view.drive;
    final checkIn = drive != null && drive.date == view.now.date
        ? drive.driving.where((l) => !l.overAt(view.now)).firstOrNull
        : null;
    final riding = view.display != null && view.display!.date != drive?.date ? view.display : null;
    // A leg I ride off duty today: the same live map and countdown riders get.
    final rideToday = view.upcomingRides.where((l) => l.date == view.now.date).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TodayBanners(view: view),
        Row(
          children: [
            Expanded(
              child: GooraGhostButton(
                key: const Key('offer-trip'),
                label: l10n.offerBtn,
                icon: GooraIcons.car,
                onPressed: () => context.push(Routes.offerTrip),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: GooraGhostButton(
                key: const Key('find-riders'),
                label: l10n.browseBtn,
                icon: GooraIcons.person,
                onPressed: () => context.push(Routes.offerTrip),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gap),
        if (drive == null)
          GooraCard(child: Text(l10n.notDrivingSoon, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)))
        else
          DriveHero(view: view, day: drive),
        if (checkIn != null) ...[
          const SizedBox(height: AppSpacing.gap),
          PickupCheckIn(view: view, leg: checkIn),
        ],
        if (riding != null && riding.riding.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.gap),
          _RidingCard(view: view, day: riding),
        ],
        if (rideToday != null) ...[
          const SizedBox(height: AppSpacing.gap),
          TripMapCard(key: const Key('riding-map'), view: view, next: rideToday),
        ],
        const SizedBox(height: AppSpacing.gap),
        SectionTitle(l10n.reqsOnRoute),
        GooraDashedButton(
          key: const Key('requests'),
          label: l10n.reqsPlaceholder,
          onPressed: () => context.push(Routes.offerTrip),
        ),
        Caption(l10n.reqPrivacy),
        const SizedBox(height: AppSpacing.gap),
        SafetyRow(view: view),
      ],
    );
  }
}

/// "Tomorrow · Going · N passengers", stops with times, return line,
/// estimated contribution, Confirm ⇄ Undo, Report delay, Can't drive.
class DriveHero extends ConsumerWidget {
  const DriveHero({super.key, required this.view, required this.day});

  final TodayView view;
  final DayPlan day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final g = view.group!;
    final legs = day.driving.toList();
    final going = day.driving.where((l) => l.leg == Leg.going).firstOrNull;
    final ret = day.driving.where((l) => l.leg == Leg.ret).firstOrNull;
    final passengers = legs.map((l) => l.ride!.passengers.length).reduce((a, b) => a > b ? a : b);
    // Passengers × price for each trip driven (FR-013).
    final contribution = legs.fold<int>(0, (sum, l) => sum + l.ride!.passengers.length * g.price);
    final confirmed = legs.every((l) => l.ride!.confirmed);
    final gap = view.now.date.daysUntil(day.date);
    final secondary = AppTypography.bodySmall.copyWith(color: AppColors.onDarkSecondary);
    final body = AppTypography.bodySemi.copyWith(color: AppColors.white);
    final pending = legs.where((l) => !l.overAt(view.now)).firstOrNull;

    Widget line(String label, String time, {Key? key}) => Padding(
          key: key,
          padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(child: Text(label, style: body)),
              const SizedBox(width: AppSpacing.md),
              Text(time, style: body),
            ],
          ),
        );

    return GooraHeroCard(
      key: const Key('drive-hero'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.heroDriver(l10n.heroWhen(day.date, view.now.date), l10n.direction({for (final l in legs) l.leg}), passengers),
            style: AppTypography.bodyStrong.copyWith(color: AppColors.white),
          ),
          if (going != null) ...[
            for (final (i, s) in going.ride!.stops.indexed)
              line(l10n.pickupN(i + 1, l10n.stopName(s.name)), l10n.time(s.time), key: Key('stop-${s.id}')),
            line(l10n.stopName(g.workStop.name), l10n.time(going.end.time)),
          ],
          if (ret != null) line(l10n.returnFrom(l10n.stopName(g.workStop.name)), l10n.time(ret.stop.time)),
          const Divider(color: AppColors.onDarkDivider, height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: Text(l10n.estContrib, style: secondary)),
              Text(
                key: const Key('contribution'),
                l10n.egpAmount(contribution),
                style: AppTypography.stat.copyWith(color: AppColors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gap),
          if (confirmed) ...[
            Text(l10n.confirmedNote, style: AppTypography.bodySmall.copyWith(color: AppColors.onDarkBody)),
            const SizedBox(height: AppSpacing.sm),
            GooraPrimaryButton(
              key: const Key('undo-confirm'),
              label: l10n.undoConfirm,
              variant: GooraPrimaryVariant.outlineOnDark,
              onPressed: () => ref.read(todayControllerProvider.notifier).setConfirmed(day, false),
            ),
          ] else
            GooraPrimaryButton(
              key: const Key('confirm-drive'),
              label: switch (gap) {
                0 => l10n.confirmDriveToday,
                1 => l10n.confirmDrive,
                _ => l10n.confirmDriveDay(l10n.dayOf(day.date)),
              },
              variant: GooraPrimaryVariant.onDark,
              onPressed: () => ref.read(todayControllerProvider.notifier).setConfirmed(day, true),
            ),
          const SizedBox(height: AppSpacing.md),
          GooraPrimaryButton(
            key: const Key('report-delay'),
            label: l10n.reportDelay,
            variant: GooraPrimaryVariant.outlineOnDark,
            onPressed: pending == null ? null : () => showDelaySheet(context, pending),
          ),
          const SizedBox(height: AppSpacing.md),
          GooraPrimaryButton(
            key: const Key('cant-drive'),
            label: l10n.cantDrive,
            variant: GooraPrimaryVariant.outlineOnDark,
            onPressed: () => _cantDrive(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _cantDrive(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.cantDriveConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.keepDriving)),
          TextButton(
            key: const Key('confirm-cant-drive'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.cantDriveYes),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(todayControllerProvider.notifier).cantDrive(day);
  }
}

/// Off-duty drivers ride with the driver on duty and pay like riders (FR-022a).
class _RidingCard extends StatelessWidget {
  const _RidingCard({required this.view, required this.day});

  final TodayView view;
  final DayPlan day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final first = day.riding.first;
    return GooraCard(
      key: const Key('riding-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(GooraIcons.person, size: AppSizes.iconSmall, color: AppColors.greenText),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.rideWith(
                    l10n.when(day.date, view.now.date),
                    first.driver == null ? l10n.noDriverYet : nameFor(l10n, view, first.driver!.id),
                  ),
                  style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary),
                ),
              ),
              Text(l10n.time(first.stop.time), style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          if (day.date.isAfter(view.now.date)) ...[
            const SizedBox(height: AppSpacing.md),
            GooraGhostButton(
              key: const Key('cant-come'),
              label: l10n.cantCome,
              danger: true,
              onPressed: () => showCantComeSheet(context, day),
            ),
            Caption(l10n.cantComeNote),
          ],
        ],
      ),
    );
  }
}
