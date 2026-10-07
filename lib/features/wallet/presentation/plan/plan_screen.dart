import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_banner.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_icons.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../../../core/widgets/goora_radio_card.dart';
import '../../../onboarding/presentation/widgets/onboarding_scaffold.dart';
import '../../data/fake_wallet_repository.dart';
import '../../domain/plan.dart';
import '../../domain/wallet_repository.dart';
import '../labels.dart';
import '../wallet/top_up_sheet.dart';
import '../wallet/wallet_controller.dart';
import 'company_verify_sheet.dart';
import 'plan_controller.dart';

/// The optional subscription (v2 US3), reached from the payment-method
/// screen's "Subscribe and pay no fees" link and from the Wallet. Drivers
/// never route here.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  PlanType _selected = PlanType.monthly;
  bool _busy = false;
  bool _needsTopUp = false;

  Future<void> _subscribe() async {
    if (_selected == PlanType.company) {
      await showCompanyVerifySheet(context);
      if (!mounted || ref.read(planControllerProvider).value?.type != PlanType.company) return;
      return _leave();
    }
    setState(() => _busy = true);
    final result = await ref.read(planControllerProvider.notifier).subscribe(_selected);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _needsTopUp = result == SubscribeResult.needsTopUp;
    });
    if (result == SubscribeResult.subscribed) _leave();
  }

  /// Back to the Wallet when opened from it; otherwise on to Today.
  void _leave() => context.canPop() ? context.pop() : context.go(Routes.today);

  @override
  Widget build(BuildContext context) {
    // Keeps the auto-dispose controllers alive for the screen's lifetime.
    ref.watch(planControllerProvider);
    final balance = ref.watch(walletControllerProvider).value?.wallet.balance ?? 0;
    final l10n = AppLocalizations.of(context);
    final secondary = AppTypography.bodySmall.copyWith(color: AppColors.textSecondary);
    final price = FakeWalletRepository.priceFor(_selected);
    void select(PlanType type) => setState(() {
          _selected = type;
          _needsTopUp = false;
        });
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
            onTap: () => select(PlanType.monthly),
          ),
          const SizedBox(height: AppSpacing.md),
          GooraRadioCard(
            key: const Key('plan-yearly'),
            title: l10n.planTypeTitle(PlanType.yearly),
            subtitle: l10n.planTypeSub(PlanType.yearly),
            chipLabel: l10n.planYearlyChip,
            selected: _selected == PlanType.yearly,
            onTap: () => select(PlanType.yearly),
          ),
          const SizedBox(height: AppSpacing.md),
          GooraRadioCard(
            key: const Key('plan-company'),
            title: l10n.planTypeTitle(PlanType.company),
            subtitle: l10n.planTypeSub(PlanType.company),
            selected: _selected == PlanType.company,
            onTap: () => select(PlanType.company),
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
          if (_needsTopUp) ...[
            const SizedBox(height: AppSpacing.gap),
            GooraBanner(
              key: const Key('sub-needs-top-up'),
              kind: GooraBannerKind.warning,
              title: l10n.needsTopUp,
              body: l10n.subNeedsTopUp(price - balance, balance),
              actionLabel: l10n.topUp,
              onAction: () => showTopUpSheet(context),
            ),
          ],
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GooraPrimaryButton(
            key: const Key('plan-cta'),
            label: _selected == PlanType.company ? l10n.planCtaVerify : l10n.subscribeCta(price),
            onPressed: _busy ? null : _subscribe,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.planFooter, textAlign: TextAlign.center, style: secondary),
        ],
      ),
    );
  }
}
