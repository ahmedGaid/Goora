import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/time/now_provider.dart';
import '../../../core/widgets/goora_icons.dart';
import '../../daily/data/providers.dart';
import '../data/providers.dart';

/// Whether the signed-in employee shares their trips with HR (010 US6,
/// FR-024). False when not enrolled.
final hrConsentProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(companyRepositoryProvider).hrConsent(ref.watch(dailyCommuteRepositoryProvider).meId);
});

/// "Share my trips with HR" on the Wallet's company card: off by default, the
/// exact list of what HR sees right under it, and a confirm before it stops
/// that says statements already issued stay (FR-024, FR-027).
class HrConsentToggle extends ConsumerWidget {
  const HrConsentToggle({super.key});

  Future<void> _set(BuildContext context, WidgetRef ref, bool on) async {
    final l10n = AppLocalizations.of(context);
    if (!on) {
      final stop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.companyHrShareStopTitle),
          content: Text(l10n.companyHrShareStopBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.keepIt)),
            TextButton(
              key: const Key('hr-share-stop-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.companyHrShareStopConfirm),
            ),
          ],
        ),
      );
      if (stop != true) return;
    }
    await ref
        .read(companyRepositoryProvider)
        .setHrConsent(ref.read(dailyCommuteRepositoryProvider).meId, on, ref.read(nowProvider)());
    ref.invalidate(hrConsentProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final on = ref.watch(hrConsentProvider).value ?? false;
    final small = AppTypography.bodySmall.copyWith(color: AppColors.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MergeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.companyHrShareTitle,
                  style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary),
                ),
              ),
              Switch(
                key: const Key('hr-share-toggle'),
                value: on,
                onChanged: (v) => _set(context, ref, v),
                activeTrackColor: AppColors.greenText,
                activeThumbColor: AppColors.white,
                inactiveThumbColor: AppColors.textSecondary,
                inactiveTrackColor: AppColors.surface,
                trackOutlineColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected) ? Colors.transparent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          on ? l10n.companyHrShareOnLine : l10n.companyHrShareOffLine,
          key: const Key('hr-share-line'),
          style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(GooraIcons.hidden, size: AppSizes.iconSmall, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(l10n.companyHrShareSees, style: small)),
          ],
        ),
      ],
    );
  }
}
