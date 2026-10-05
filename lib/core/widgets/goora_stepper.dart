import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'goora_icons.dart';

/// − / value / + with 48 px circular buttons.
class GooraStepper extends StatelessWidget {
  const GooraStepper({
    super.key,
    required this.valueLabel,
    required this.decreaseLabel,
    required this.increaseLabel,
    this.onDecrease,
    this.onIncrease,
  });

  final String valueLabel;
  final String decreaseLabel;
  final String increaseLabel;

  /// Null disables the button.
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(icon: GooraIcons.minus, label: decreaseLabel, onTap: onDecrease),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.cardPad),
          child: Text(valueLabel, style: AppTypography.title.copyWith(color: AppColors.textPrimary)),
        ),
        _StepButton(icon: GooraIcons.plus, label: increaseLabel, onTap: onIncrease),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        shape: CircleBorder(
          side: enabled ? BorderSide.none : const BorderSide(color: AppColors.border),
        ),
        color: enabled ? AppColors.primary : AppColors.background,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: AppSizes.stepperButton,
            height: AppSizes.stepperButton,
            child: Icon(icon, size: AppSizes.icon, color: enabled ? AppColors.white : AppColors.disabled),
          ),
        ),
      ),
    );
  }
}
