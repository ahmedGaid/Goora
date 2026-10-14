import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/time/wall_time.dart';
import '../../../../core/widgets/goora_avatar.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_dashed_button.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../../wallet/presentation/labels.dart';
import '../../domain/booking.dart';
import '../../domain/seat_offer.dart';
import '../labels.dart';

/// The summary after a seat is booked. A rider who isn't a subscriber is
/// offered the daily commute; everyone can go back to Today.
class BookedView extends StatelessWidget {
  const BookedView({super.key, required this.offer, required this.booking, required this.now, required this.onUpsell, required this.onBack});

  final SeatOffer offer;
  final Booking booking;
  final WallTime now;
  final VoidCallback onUpsell;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const Key('booked-view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.seatBookedTitle, style: AppTypography.h2.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.md),
        GooraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  GooraAvatar(initials: offer.driver.initials),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(offer.driver.firstName, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary))),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.seatWhen(offer, now), style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
              Text(l10n.seatPickup(offer), style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.priceLine(booking.price), style: AppTypography.body.copyWith(color: AppColors.textBody)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!booking.isSubscriber) ...[
          GooraDashedButton(key: const Key('upsell-daily'), label: l10n.upsellDaily, onPressed: onUpsell),
          const SizedBox(height: AppSpacing.md),
        ],
        GooraPrimaryButton(key: const Key('back-to-today'), label: l10n.backToToday, onPressed: onBack),
      ],
    );
  }
}
