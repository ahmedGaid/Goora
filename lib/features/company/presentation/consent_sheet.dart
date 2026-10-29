import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/goora_card.dart';
import '../../../core/widgets/goora_ghost_button.dart';
import '../../../core/widgets/goora_icons.dart';
import '../../../core/widgets/goora_primary_button.dart';

/// 010 US2: before enrolling, the employee sees exactly what their company
/// will see and what it never sees (constitution IV, explicit consent).
/// True only on "Agree and join"; declining or closing enrolls nothing.
/// [pausedDays] > 0 says their own plan pauses (Q11 default).
Future<bool> showConsentSheet(BuildContext context, {required String company, int pausedDays = 0}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => ConsentSheet(company: company, pausedDays: pausedDays),
    ) ??
    false;

class ConsentSheet extends StatelessWidget {
  const ConsentSheet({super.key, required this.company, this.pausedDays = 0});

  final String company;
  final int pausedDays;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final body = AppTypography.body.copyWith(color: AppColors.textBody);
    final secondary = AppTypography.bodySmall.copyWith(color: AppColors.textSecondary);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.tabH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.consentTitle(company), style: AppTypography.title.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.gap),
            _ListCard(
              key: const Key('consent-sees'),
              title: l10n.consentSeesTitle,
              icon: GooraIcons.check,
              iconColor: AppColors.greenText,
              items: [l10n.consentSeesName, l10n.consentSeesEmail, l10n.consentSeesSince],
            ),
            const SizedBox(height: AppSpacing.md),
            _ListCard(
              key: const Key('consent-never'),
              title: l10n.consentNeverTitle,
              icon: GooraIcons.hidden,
              iconColor: AppColors.textSecondary,
              items: [l10n.consentNeverTrips, l10n.consentNeverPlace, l10n.consentNeverWho, l10n.consentNeverMoney],
            ),
            const SizedBox(height: AppSpacing.gap),
            Text(l10n.consentFeeLine, style: body),
            if (pausedDays > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.consentPausedLine(pausedDays), key: const Key('consent-paused'), style: secondary),
            ],
            const SizedBox(height: AppSpacing.lg),
            GooraPrimaryButton(
              key: const Key('consent-agree'),
              label: l10n.consentAgree,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.sm),
            GooraGhostButton(
              key: const Key('consent-decline'),
              label: l10n.consentDecline,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({super.key, required this.title, required this.icon, required this.iconColor, required this.items});

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return GooraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          for (final item in items)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: AppSizes.iconSmall, color: iconColor),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item, style: AppTypography.body.copyWith(color: AppColors.textBody))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
