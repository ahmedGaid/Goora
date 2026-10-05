import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/goora_card.dart';
import '../../../core/widgets/goora_ghost_button.dart';
import '../../../core/widgets/goora_icons.dart';
import '../../onboarding/domain/onboarding_flow.dart';
import '../../onboarding/presentation/widgets/onboarding_scaffold.dart';

/// Stand-in for screens built in later features (002, 005).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = switch (destination) {
      Destination.commuteSetup => l10n.whereGo,
      Destination.emptySeatsToday => l10n.emptySeatsTitle,
      Destination.offerTrip => l10n.offerTitle,
    };
    return OnboardingScaffold(
      title: title,
      progressIndex: OnboardingFlow.progressIndex(destination: destination),
      onBack: () => context.go(Routes.frequency),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GooraCard(
            padding: const EdgeInsetsDirectional.all(AppSpacing.listCardPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.comingSoonTitle, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.xxs),
                Text(l10n.comingSoonBody, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gap),
          GooraGhostButton(
            key: const Key('open-settings'),
            label: l10n.openSettings,
            icon: GooraIcons.settings,
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
    );
  }
}
