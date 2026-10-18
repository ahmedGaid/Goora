import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/goora_card.dart';
import '../data/providers.dart';

/// "InstaPay بتاع (name): (handle)" with Copy, for a rider whose ride with
/// this driver is confirmed (their own group's driver, or a booked seat) —
/// never earlier (007 FR-013, Constitution IV). Goora only shows the handle;
/// the transfer happens outside the app. Nothing when the driver has none.
class DriverInstapayLine extends ConsumerWidget {
  const DriverInstapayLine({super.key, required this.driverId, required this.driverFirstName});

  final String driverId;
  final String driverFirstName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handle = ref.watch(driverInstapayProvider(driverId)).value;
    if (handle == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.gap),
      child: GooraCard(
        key: Key('instapay-of-$driverId'),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.instapayOfDriver(driverFirstName, handle),
                style: AppTypography.body.copyWith(color: AppColors.textBody),
              ),
            ),
            TextButton(
              key: Key('copy-instapay-$driverId'),
              style: TextButton.styleFrom(minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch)),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(ClipboardData(text: handle));
                messenger.showSnackBar(SnackBar(content: Text(l10n.copiedHandle)));
              },
              child: Text(l10n.copyHandle, style: AppTypography.bodyStrong.copyWith(color: AppColors.greenText)),
            ),
          ],
        ),
      ),
    );
  }
}
