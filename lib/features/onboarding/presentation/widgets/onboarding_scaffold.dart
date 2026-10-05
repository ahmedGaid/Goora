import 'package:flutter/material.dart';

import '../../../../app/language_toggle.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_icons.dart';
import '../../../../core/widgets/goora_progress_dots.dart';
import '../../domain/onboarding_flow.dart';

/// Shared layout for onboarding-style screens: back (start) + language pill
/// (end), optional progress dots, title, subtitle, scrollable body, bottom CTA.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.onBack,
    this.progressIndex,
    this.bottom,
    this.header,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final VoidCallback? onBack;
  final int? progressIndex;
  final Widget? bottom;

  /// Shown above the title (e.g. a match chip).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: onBack == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack?.call();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.pageH,
              AppSpacing.sm,
              AppSpacing.pageH,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (onBack != null)
                      IconButton(
                        onPressed: onBack,
                        tooltip: l10n.back,
                        icon: const Icon(GooraIcons.back, size: AppSizes.icon, color: AppColors.textPrimary),
                        constraints: const BoxConstraints(
                          minWidth: AppSizes.backButton,
                          minHeight: AppSizes.backButton,
                        ),
                      ),
                    const Spacer(),
                    const LanguageToggle(),
                  ],
                ),
                if (progressIndex != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GooraProgressDots(
                      count: OnboardingFlow.progressSteps,
                      current: progressIndex!,
                      semanticLabel: l10n.stepOf(progressIndex! + 1, OnboardingFlow.progressSteps),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (header != null) ...[
                          Align(alignment: AlignmentDirectional.centerStart, child: header),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        Text(title, style: AppTypography.h1.copyWith(color: AppColors.textPrimary)),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(subtitle!, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        body,
                      ],
                    ),
                  ),
                ),
                if (bottom != null) ...[
                  const SizedBox(height: AppSpacing.gap),
                  bottom!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
