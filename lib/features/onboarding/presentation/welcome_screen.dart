import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/language_toggle.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/goora_logo.dart';
import '../../../core/widgets/goora_primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final otherFamily = AppTypography.otherFamilyFor(Localizations.localeOf(context).languageCode);
    return Scaffold(
      backgroundColor: AppColors.forest,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: AlignmentDirectional.centerEnd,
                child: LanguageToggle(onDark: true),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        key: const Key('welcome-logo'),
                        onLongPress: kDebugMode ? () => context.push(Routes.gallery) : null,
                        child: const GooraLogo(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(l10n.tagline, style: AppTypography.taglineLarge.copyWith(color: AppColors.white)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.taglineOther,
                        style: AppTypography.taglineSmall.copyWith(
                          color: AppColors.mint,
                          fontFamily: otherFamily,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
                        child: Text(
                          l10n.splashSub,
                          style: AppTypography.splashSub.copyWith(color: AppColors.onDarkSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GooraPrimaryButton(
                label: l10n.getStarted,
                trailingArrow: true,
                variant: GooraPrimaryVariant.onDark,
                onPressed: () => context.go(Routes.phone),
              ),
              const SizedBox(height: AppSpacing.md),
              GooraPrimaryButton(
                label: l10n.login,
                variant: GooraPrimaryVariant.outlineOnDark,
                onPressed: () => context.go(Routes.phone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
