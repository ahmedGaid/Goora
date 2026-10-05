import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';

/// White card, radius 20, 1 px border. Use [GooraCard.rows] for rows
/// separated by 1 px dividers.
class GooraCard extends StatelessWidget {
  const GooraCard({
    super.key,
    required Widget this.child,
    this.padding = const EdgeInsetsDirectional.all(AppSpacing.cardPad),
  }) : rows = null;

  const GooraCard.rows({
    super.key,
    required List<Widget> this.rows,
    this.padding = const EdgeInsetsDirectional.all(AppSpacing.cardPad),
  }) : child = null;

  final Widget? child;
  final List<Widget>? rows;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = child ??
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows!.length; i++) ...[
              if (i > 0) const Divider(height: AppSizes.hairline, thickness: AppSizes.hairline, color: AppColors.divider),
              Padding(padding: padding, child: rows![i]),
            ],
          ],
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: child != null ? Padding(padding: padding, child: content) : content,
    );
  }
}

/// Dark hero card: primary fill, radius 22, padding 20, white text.
class GooraHeroCard extends StatelessWidget {
  const GooraHeroCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadii.hero),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.heroPad),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: AppColors.white),
          child: IconTheme.merge(
            data: const IconThemeData(color: AppColors.mint),
            child: child,
          ),
        ),
      ),
    );
  }
}
