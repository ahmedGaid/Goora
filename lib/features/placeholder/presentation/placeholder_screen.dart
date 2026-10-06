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
import '../../onboarding/presentation/widgets/onboarding_scaffold.dart';

/// Screens owned by later features.
enum PlaceholderKind {
  emptySeats(Routes.frequency), // 005-A
  offerTrip(Routes.frequency), // 005-C
  postTrip(Routes.noMatch); // 005-B

  const PlaceholderKind(this.backRoute);
  final String backRoute;
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.kind});

  final PlaceholderKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = switch (kind) {
      PlaceholderKind.emptySeats => l10n.emptySeatsTitle,
      PlaceholderKind.offerTrip => l10n.offerTitle,
      PlaceholderKind.postTrip => l10n.postReq,
    };
    return OnboardingScaffold(
      title: title,
      onBack: () => context.canPop() ? context.pop() : context.go(kind.backRoute),
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
