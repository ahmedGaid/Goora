import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_card.dart';

/// Scrollable tab body: title row (with optional actions) and content,
/// 20 px side padding (brief §3.3 tab padding).
class TabPage extends StatelessWidget {
  const TabPage({super.key, required this.title, required this.children, this.subtitle, this.actions = const []});

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.tabH, AppSpacing.md, AppSpacing.tabH, AppSpacing.lg),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.title.copyWith(color: AppColors.textPrimary)),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(subtitle!, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
              ...actions,
            ],
          ),
          const SizedBox(height: AppSpacing.gap),
          ...children,
        ],
      ),
    );
  }
}

/// "Coming soon" body for tabs owned by later stories / features.
class ComingSoonCard extends StatelessWidget {
  const ComingSoonCard({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GooraCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.listCardPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title ?? l10n.comingSoonTitle, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.xxs),
          Text(l10n.comingSoonBody, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
