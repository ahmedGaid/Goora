import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/goora_card.dart';
import '../../../core/widgets/goora_icons.dart';
import '../../../core/widgets/goora_primary_button.dart';
import '../../onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'commute_controller.dart';
import 'labels.dart';

class NoMatchScreen extends ConsumerWidget {
  const NoMatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final outcome = ref.watch(lastMatchProvider);
    if (outcome == null || outcome.waitlistPosition == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(Routes.commuteSetup);
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    final from = l10n.area(outcome.profile.home!.area);
    final to = l10n.area(outcome.profile.work!.area);
    return OnboardingScaffold(
      title: l10n.routeLine(from, to),
      onBack: () => context.go(Routes.commuteSetup),
      body: GooraCard(
        padding: const EdgeInsetsDirectional.all(AppSpacing.listCardPad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(GooraIcons.week, size: AppSizes.icon, color: AppColors.greenText),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                l10n.noMatch(outcome.waitlistPosition!, from, to),
                key: const Key('no-match-text'),
                style: AppTypography.body.copyWith(color: AppColors.textBody),
              ),
            ),
          ],
        ),
      ),
      bottom: GooraPrimaryButton(
        key: const Key('post-trip'),
        label: l10n.postReq,
        trailingArrow: true,
        onPressed: () => context.go(Routes.postTrip),
      ),
    );
  }
}
