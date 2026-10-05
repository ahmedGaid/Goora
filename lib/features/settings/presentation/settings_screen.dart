import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/language_toggle.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/goora_card.dart';
import '../../../core/widgets/goora_ghost_button.dart';
import '../../onboarding/domain/choices.dart';
import '../../onboarding/presentation/session_controller.dart';
import '../../onboarding/presentation/widgets/onboarding_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(sessionControllerProvider).profile?.role;
    final labelStyle = AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary);
    final valueStyle = AppTypography.bodySmall.copyWith(color: AppColors.textSecondary);
    return OnboardingScaffold(
      title: l10n.settingsTitle,
      onBack: () => context.pop(),
      body: GooraCard.rows(
        padding: const EdgeInsetsDirectional.all(AppSpacing.listCardPad),
        rows: [
          Row(
            children: [
              Expanded(child: Text(l10n.languageLabel, style: labelStyle)),
              const LanguageToggle(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.roleLabel, style: labelStyle),
              if (role != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(role == Role.driver ? l10n.canDrive : l10n.needRide, style: valueStyle),
                const SizedBox(height: AppSpacing.md),
                GooraGhostButton(
                  key: const Key('switch-role'),
                  label: role == Role.driver ? l10n.toRider : l10n.toDriver,
                  onPressed: () => ref
                      .read(sessionControllerProvider.notifier)
                      .setRole(role == Role.driver ? Role.rider : Role.driver),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
