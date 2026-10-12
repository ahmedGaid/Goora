import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../../../core/widgets/goora_radio_card.dart';
import '../../domain/plan.dart';
import '../labels.dart';
import 'wallet_controller.dart';

Future<void> showChangePlanSheet(BuildContext context, {required PlanType current}) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => ChangePlanSheet(current: current),
    );

/// FR-004: switch Monthly/Yearly/Company; takes effect next billing date,
/// no pro-rating — the current period's card is unaffected (edge cases).
class ChangePlanSheet extends ConsumerStatefulWidget {
  const ChangePlanSheet({super.key, required this.current});

  final PlanType current;

  @override
  ConsumerState<ChangePlanSheet> createState() => _ChangePlanSheetState();
}

class _ChangePlanSheetState extends ConsumerState<ChangePlanSheet> {
  late PlanType _selected = widget.current;
  bool _busy = false;

  Future<void> _confirm() async {
    setState(() => _busy = true);
    await ref.read(walletControllerProvider.notifier).changePlan(_selected);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.tabH,
          end: AppSpacing.tabH,
          top: AppSpacing.tabH,
          bottom: AppSpacing.tabH + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.changePlanTitle, style: AppTypography.title.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.xxs),
            Text(l10n.changePlanNote, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.gap),
            for (final type in PlanType.values) ...[
              GooraRadioCard(
                key: Key('change-plan-${type.name}'),
                title: l10n.planTypeTitle(type),
                subtitle: l10n.planTypeSub(type),
                chipLabel: type == PlanType.yearly ? l10n.planYearlyChip : null,
                selected: _selected == type,
                onTap: () => setState(() => _selected = type),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            GooraPrimaryButton(
              key: const Key('change-plan-confirm'),
              label: l10n.changePlanConfirm,
              onPressed: _busy ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }
}
