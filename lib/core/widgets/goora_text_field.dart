import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Labelled text field in Goora style. [ltr] forces left-to-right input
/// (phone numbers, codes) while the label follows the app direction.
class GooraTextField extends StatelessWidget {
  const GooraTextField({
    super.key,
    required this.controller,
    required this.label,
    this.ltr = false,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.style,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final bool ltr;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final int? maxLength;
  final TextAlign textAlign;
  final TextStyle? style;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      maxLength: maxLength,
      textAlign: textAlign,
      textDirection: ltr ? TextDirection.ltr : null,
      style: (style ?? AppTypography.bodySemi).copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
        errorText: errorText,
        errorStyle: AppTypography.caption.copyWith(color: AppColors.dangerText),
        counterText: '',
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.cardPad,
          vertical: AppSpacing.cardPad,
        ),
        enabledBorder: border(AppColors.borderStrong),
        focusedBorder: border(AppColors.green, 2),
        errorBorder: border(AppColors.dangerBorder),
        focusedErrorBorder: border(AppColors.dangerText, 2),
      ),
    );
  }
}
