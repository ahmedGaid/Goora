import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/time/wall_time.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_ghost_button.dart';
import '../../../../core/widgets/goora_icons.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../../../core/widgets/goora_status_chip.dart';
import '../../../commute/presentation/labels.dart';
import '../../../daily/presentation/labels.dart';
import '../../domain/driver_day_rules.dart';
import '../../domain/marketplace_repository.dart';
import '../../domain/offered_trip.dart';

/// One request as a driver sees it: no name and no photo — only "Verified
/// rider", the rating or "New" (FR-023, SC-004). It takes a [RequestCard]
/// alone, so nothing that identifies the rider is reachable from here. Every
/// limit is said in words; Accept is off, with the reason, when it can't work.
class RequestCardView extends StatefulWidget {
  const RequestCardView({
    super.key,
    required this.card,
    required this.now,
    required this.onAccept,
    this.accepted = false,
    this.busy = false,
  });

  final RequestCard card;
  final WallTime now;

  /// Called once the driver has confirmed (create) or tapped (join).
  final VoidCallback onAccept;
  final bool accepted;
  final bool busy;

  @override
  State<RequestCardView> createState() => _RequestCardViewState();
}

class _RequestCardViewState extends State<RequestCardView> {
  bool _confirming = false;

  RequestCard get _c => widget.card;

  /// The words for a state that can't be accepted; null when it can.
  String? _blocked(AppLocalizations l10n) => switch (_c.fit.kind) {
        TripFitKind.create || TripFitKind.join => null,
        TripFitKind.full => l10n.yourCarFull,
        TripFitKind.limitReached => l10n.dailyLimitReached,
        TripFitKind.doesntFit => l10n.doesntFit,
        TripFitKind.oneGroupOnly => l10n.oneGroupOnly,
        TripFitKind.overlap => l10n.overlapTrip,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = _c;
    final blocked = _blocked(l10n);
    final id = c.requestId;
    final route = l10n.routeLine(l10n.area(c.from), l10n.area(c.to));
    return GooraCard(
      key: Key('request-$id'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(GooraIcons.person, size: AppSizes.iconSmall, color: AppColors.greenText),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  c.rider.isWoman ? l10n.verifiedRiderWoman : l10n.verifiedRider,
                  style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary),
                ),
              ),
              Text(
                c.rider.rating == null ? l10n.newRider : l10n.ratingStars(c.rider.rating!.toStringAsFixed(1)),
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(route, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
          Text(
            '${l10n.heroWhen(c.date, widget.now.date)} · ${l10n.time(c.departure)} · ${c.repeat == Repeat.daily ? l10n.everyWorkday : l10n.justOnce}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            '${l10n.tlPickup(l10n.time(c.pickup.time))} — ${l10n.stopName(c.pickup.name)} · ${l10n.detourMin(c.detourMinutes)}',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.egpAmount(c.price.contribution),
            key: Key('request-price-$id'),
            style: AppTypography.bodyStrong.copyWith(color: AppColors.textBody),
          ),
          const SizedBox(height: AppSpacing.md),
          if (widget.accepted)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: GooraStatusChip(key: Key('accepted-$id'), status: GooraStatus.covered, label: l10n.accepted),
            )
          else if (blocked != null)
            Text(blocked, key: Key('blocked-$id'), style: AppTypography.bodyStrong.copyWith(color: AppColors.textBody))
          else if (_confirming && _c.fit.kind == TripFitKind.create) ...[
            Text(
              l10n.createsTrip(route, l10n.time(c.departure), c.fit.tripsLeftAfter ?? 0),
              key: Key('creates-$id'),
              style: AppTypography.bodySmall.copyWith(color: AppColors.textBody),
            ),
            const SizedBox(height: AppSpacing.sm),
            GooraPrimaryButton(
              key: Key('confirm-accept-$id'),
              label: l10n.acceptConfirm,
              onPressed: widget.busy ? null : widget.onAccept,
            ),
          ] else ...[
            if (c.fit.kind == TripFitKind.join)
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
                child: Text(
                  l10n.joinsTripInstead(l10n.time(c.joinTime ?? c.departure)),
                  key: Key('joins-$id'),
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textBody),
                ),
              ),
            GooraGhostButton(
              key: Key('accept-$id'),
              label: l10n.accept,
              onPressed: widget.busy
                  ? null
                  : () {
                      if (_c.fit.kind == TripFitKind.create) {
                        setState(() => _confirming = true);
                      } else {
                        widget.onAccept();
                      }
                    },
            ),
          ],
        ],
      ),
    );
  }
}
