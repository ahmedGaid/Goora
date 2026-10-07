import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_ghost_button.dart';

/// Scrollable tab body: title row (with optional actions) and content,
/// 20 px side padding (brief §3.3 tab padding).
class TabPage extends StatelessWidget {
  const TabPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.actions = const [],
    this.leading,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;

  /// Shown above the title row, at the start edge.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.tabH, AppSpacing.md, AppSpacing.tabH, AppSpacing.lg),
        children: [
          if (leading != null) ...[
            Align(alignment: AlignmentDirectional.centerStart, child: leading),
            const SizedBox(height: AppSpacing.md),
          ],
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

/// A tab's body while it loads, or when it could not (designed states).
class TabLoadState extends StatelessWidget {
  const TabLoadState({super.key, required this.failed, required this.onRetry});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!failed) {
      return Semantics(
        label: l10n.loadingToday,
        child: const Padding(
          padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator(color: AppColors.greenText)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.todayError, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.md),
        GooraGhostButton(label: l10n.retry, onPressed: onRetry),
      ],
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
