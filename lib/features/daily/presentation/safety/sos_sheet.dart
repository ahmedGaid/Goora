import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../data/providers.dart';

/// SOS: one confirm step → Call 122 (FR-030, SC-006). Alerting trusted
/// contacts is added with US7; until then the sheet invites adding one.
Future<void> showSosSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      builder: (_) => const SosSheet(),
    );

class SosSheet extends ConsumerWidget {
  const SosSheet({super.key});

  static const emergencyNumber = '122';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.tabH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.sosTitle, style: AppTypography.title.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.gap),
            GooraPrimaryButton(
              key: const Key('sos-call'),
              label: l10n.sosCall,
              onPressed: () => ref.read(phoneDialerProvider).dial(emergencyNumber),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.sosNoContacts, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
