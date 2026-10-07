import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/time/wall_time.dart';
import '../../../../core/widgets/goora_avatar.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_ghost_button.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../../../core/widgets/goora_status_chip.dart';
import '../../../commute/domain/group.dart';
import '../../../wallet/data/providers.dart';
import '../../../wallet/domain/cash_mark.dart';
import '../../../wallet/presentation/wallet/wallet_controller.dart';
import '../../domain/absence.dart';
import '../../domain/attendance_rules.dart';
import '../../domain/check_in.dart';
import '../../domain/ride.dart';
import '../labels.dart';
import '../now_ticker.dart';
import 'today_controller.dart';
import 'today_widgets.dart';

/// Pickup check-in (US3/AC6–8): "I've arrived at …" per stop in order,
/// then per passenger "Picked up" at once or "No-show" after 5 minutes.
/// Riders stay anonymous until picked up (FR-016).
class PickupCheckIn extends ConsumerWidget {
  const PickupCheckIn({super.key, required this.view, required this.leg});

  final TodayView view;
  final LegPlan leg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ride = leg.ride!;
    final arrived = {for (final c in leg.checkIns) c.stopId: c.arrivedAt};
    final outcomes = {for (final o in leg.outcomes) o.personId: o.outcome};
    final nextStop = ride.stops.where((s) => !arrived.containsKey(s.id)).firstOrNull;
    final started = ride.startedAt != null;
    final ended = ride.endedAt != null;
    final controller = ref.read(todayControllerProvider.notifier);
    return GooraCard(
      key: const Key('check-in'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.checkin, style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
          if (arrived.isNotEmpty && !started) Caption(l10n.arrivedNote),
          for (final stop in ride.stops)
            if (arrived[stop.id] != null)
              for (final p in ride.passengersAt(stop.id))
                _PassengerRow(
                  view: view,
                  ride: ride,
                  member: view.group!.member(p.memberId)!,
                  arrivedAt: arrived[stop.id]!,
                  outcome: outcomes[p.memberId] ?? Outcome.waiting,
                  locked: started,
                ),
          if (outcomes.values.contains(Outcome.noShow)) Caption(l10n.noShowNote),
          const SizedBox(height: AppSpacing.md),
          if (nextStop != null)
            GooraPrimaryButton(
              key: Key('arrived-${nextStop.id}'),
              label: l10n.arrivedAt(l10n.stopName(nextStop.name)),
              onPressed: () => controller.arrivedAt(ride.id, nextStop.id),
            )
          else if (!started)
            GooraPrimaryButton(
              key: const Key('start-trip'),
              label: l10n.startTrip,
              onPressed: () => controller.startTrip(ride.id),
            )
          else if (!ended) ...[
            Text(l10n.tripOnWay, style: AppTypography.bodyStrong.copyWith(color: AppColors.greenText)),
            const SizedBox(height: AppSpacing.sm),
            GooraPrimaryButton(
              key: const Key('end-trip'),
              label: l10n.endTrip,
              onPressed: () => controller.endTrip(ride.id),
            ),
          ] else
            Text(l10n.tripEndedNote, style: AppTypography.bodyStrong.copyWith(color: AppColors.greenText)),
        ],
      ),
    );
  }
}

class _PassengerRow extends ConsumerWidget {
  const _PassengerRow({
    required this.view,
    required this.ride,
    required this.member,
    required this.arrivedAt,
    required this.outcome,
    required this.locked,
  });

  final TodayView view;
  final Ride ride;
  final Member member;
  final WallTime arrivedAt;
  final Outcome outcome;

  /// Marks are final once the trip starts.
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final known = outcome == Outcome.pickedUp;
    final anonymousLabel = member.isWoman ? l10n.verifiedRiderWoman : l10n.verifiedRider;
    return Padding(
      key: Key('passenger-${member.id}'),
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.md),
      child: NowTicker(
        builder: (context, now) {
          final available = AttendanceRules.noShowAvailableAt(arrivedAt);
          final remaining = now.secondsUntil(available);
          final canNoShow = AttendanceRules.canMarkNoShow(arrivedAt, now);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  known
                      ? GooraAvatar(initials: member.initials, paletteIndex: paletteFor(view, member.id))
                      : GooraAvatar.anonymous(semanticLabel: anonymousLabel),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          known ? member.firstName : anonymousLabel,
                          style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary),
                        ),
                        Text(l10n.rating(member.rating), style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: switch (outcome) {
                  Outcome.waiting =>
                    GooraStatusChip(status: GooraStatus.waiting, label: l10n.stWaiting(l10n.mmss(remaining))),
                  Outcome.pickedUp => GooraStatusChip(status: GooraStatus.pickedUp, label: l10n.pickedUp),
                  Outcome.noShow => GooraStatusChip(status: GooraStatus.noShow, label: l10n.stNoShow),
                },
              ),
              if (ride.endedAt != null && outcome == Outcome.pickedUp) _CashRow(ride: ride, member: member, price: view.group!.price),
              if (!locked) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: GooraGhostButton(
                        key: Key('picked-${member.id}'),
                        label: l10n.pickedUp,
                        onPressed: outcome == Outcome.pickedUp ? null : () => _mark(context, ref, Outcome.pickedUp),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GooraGhostButton(
                            key: Key('noshow-${member.id}'),
                            label: l10n.noShow,
                            danger: true,
                            onPressed: !canNoShow || outcome == Outcome.noShow
                                ? null
                                : () => _mark(context, ref, Outcome.noShow),
                          ),
                          if (!canNoShow) Caption(l10n.noShowAvailableIn(l10n.mmss(remaining))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _mark(BuildContext context, WidgetRef ref, Outcome o) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(todayControllerProvider.notifier).mark(ride.id, member.id, o);
    } on AttendanceRefused catch (e) {
      final text = e.reason == RefusalReason.noShowTooEarly ? l10n.refusedNoShowEarly : l10n.refusedTripStarted;
      messenger.showSnackBar(SnackBar(content: Text(text)));
    }
  }
}

/// After drop-off, a picked-up cash rider gets "Received N EGP cash" /
/// "Didn't pay" (004 v2 FR-012); once recorded, a status instead. Wallet
/// riders show nothing here.
class _CashRow extends ConsumerWidget {
  const _CashRow({required this.ride, required this.member, required this.price});

  final Ride ride;
  final Member member;
  final int price;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(cashStatusProvider(ride.id, member.id)).value;
    if (status == null || !status.isCash) return const SizedBox.shrink();
    final outcome = status.outcome;
    return Padding(
      key: Key('cash-${member.id}'),
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
      child: outcome != null
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              child: outcome == CashOutcome.received
                  ? GooraStatusChip(status: GooraStatus.covered, label: l10n.cashMarkedReceived)
                  : GooraStatusChip(status: GooraStatus.off, label: l10n.cashMarkedUnpaid),
            )
          : Row(
              children: [
                Expanded(
                  child: GooraGhostButton(
                    key: Key('cash-received-${member.id}'),
                    label: l10n.cashReceived(price),
                    onPressed: () => _record(ref, CashOutcome.received),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GooraGhostButton(
                    key: Key('cash-unpaid-${member.id}'),
                    label: l10n.didNotPay,
                    onPressed: () => _record(ref, CashOutcome.didNotPay),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _record(WidgetRef ref, CashOutcome outcome) async {
    await ref.read(walletRepositoryProvider).markCash(CashMark(
          rideId: ride.id,
          riderId: member.id,
          driverId: ride.driverId!,
          outcome: outcome,
          amount: price,
          date: ride.date,
        ));
    ref
      ..invalidate(cashStatusProvider(ride.id, member.id))
      ..invalidate(walletControllerProvider);
  }
}
