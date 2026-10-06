import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_icons.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../../../core/widgets/goora_radio_card.dart';
import '../../../onboarding/presentation/widgets/onboarding_scaffold.dart';
import '../../domain/plan.dart';
import '../labels.dart';
import 'company_verify_sheet.dart';
import 'plan_controller.dart';

/// US1: a rider's entry point to the business model (brief §6.7). Drivers
/// never route here (router.dart only sends riders).
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  PlanType _selected = PlanType.monthly;
  bool _busy = false;

  Future<void> _start(AppLocalizations l10n) async {
    if (_selected == PlanType.company) {
      await showCompanyVerifySheet(context);
    } else {
      setState(() => _busy = true);
      await ref.read(planControllerProvider.notifier).choosePlan(_selected);
      if (!mounted) return;
      setState(() => _busy = false);
    }
    if (!mounted) return;
    if (ref.read(planControllerProvider).value != null) context.go(Routes.today);
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the auto-dispose controller alive for the screen's lifetime —
    // without a watch, nothing holds it between `_start`'s await and its
    // `invalidateSelf` (it would already be disposed).
    ref.watch(planControllerProvider);
    final l10n = AppLocalizations.of(context);
    final secondary = AppTypography.bodySmall.copyWith(color: AppColors.textSecondary);
    return OnboardingScaffold(
      title: l10n.planTitle,
      subtitle: l10n.planSubline,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GooraRadioCard(
            key: const Key('plan-monthly'),
            title: l10n.planTypeTitle(PlanType.monthly),
            subtitle: l10n.planTypeSub(PlanType.monthly),
            selected: _selected == PlanType.monthly,
            onTap: () => setState(() => _selected = PlanType.monthly),
          ),
          const SizedBox(height: AppSpacing.md),
          GooraRadioCard(
            key: const Key('plan-yearly'),
            title: l10n.planTypeTitle(PlanType.yearly),
            subtitle: l10n.planTypeSub(PlanType.yearly),
            chipLabel: l10n.planYearlyChip,
            selected: _selected == PlanType.yearly,
            onTap: () => setState(() => _selected = PlanType.yearly),
          ),
          const SizedBox(height: AppSpacing.md),
          GooraRadioCard(
            key: const Key('plan-company'),
            title: l10n.planTypeTitle(PlanType.company),
            subtitle: l10n.planTypeSub(PlanType.company),
            selected: _selected == PlanType.company,
            onTap: () => setState(() => _selected = PlanType.company),
          ),
          const SizedBox(height: AppSpacing.gap),
          GooraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.planIncludedTitle, style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.sm),
                for (final item in [l10n.planIncludedMatch, l10n.planIncludedBackup, l10n.planIncludedTrust])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(GooraIcons.check, size: 18, color: AppColors.greenText),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(item, style: AppTypography.body.copyWith(color: AppColors.textBody))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gap),
          Text(l10n.planFuelNote, style: secondary),
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GooraPrimaryButton(
            key: const Key('plan-cta'),
            label: _selected == PlanType.company ? l10n.planCtaVerify : l10n.planCtaStart,
            onPressed: _busy ? null : () => _start(l10n),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.planFooter, textAlign: TextAlign.center, style: secondary),
        ],
      ),
    );
  }
}
