import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/time/wall_time.dart';
import '../../../../core/widgets/goora_avatar.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../../daily/domain/attendance_rules.dart';
import '../../../wallet/presentation/labels.dart';
import '../../domain/seat_offer.dart';
import '../labels.dart';
import 'empty_seats_controller.dart';

/// One free seat: who drives, when, where, how many are left, the price line.
/// Past 9 PM the evening before, the half-share rule is said before the tap
/// (FR-026), not after.
class SeatCard extends StatelessWidget {
  const SeatCard({super.key, required this.offer, required this.now, required this.busy, required this.onBook, this.chosen = false});

  final SeatOffer offer;
  final WallTime now;
  final bool busy;
  final VoidCallback onBook;

  /// The seat the rider picked before being sent to choose a payment method.
  final bool chosen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final driver = offer.driver;
    final late = AttendanceRules.isLate(offer.date, now);
    return GooraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (chosen) ...[
            Text(l10n.seatChosen, key: const Key('seat-chosen'), style: AppTypography.microBold.copyWith(color: AppColors.greenText)),
            const SizedBox(height: AppSpacing.xs),
          ],
          Row(
            children: [
              GooraAvatar(initials: driver.initials),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.firstName, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
                    Text(
                      l10n.ratingStars(driver.rating.toStringAsFixed(1)),
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(l10n.seatsLeft(offer.freeSeats), style: AppTypography.microBold.copyWith(color: AppColors.greenText)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.seatWhen(offer, now), style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
          Text(l10n.seatPickup(offer), style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.priceLine(offer.price), style: AppTypography.body.copyWith(color: AppColors.textBody)),
          if (late) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.lateBookingNote, style: AppTypography.caption.copyWith(color: AppColors.warningTitle)),
          ],
          const SizedBox(height: AppSpacing.md),
          GooraPrimaryButton(key: Key('book-${seatKey(offer)}'), label: l10n.bookSeat, onPressed: busy ? null : onBook),
        ],
      ),
    );
  }
}
