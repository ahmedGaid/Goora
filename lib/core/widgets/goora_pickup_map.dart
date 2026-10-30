import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../map/pickup_map_renderer.dart';
import '../map/pickup_pin.dart';
import '../map/pickup_pin_badge.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'goora_card.dart';
import 'goora_icons.dart';

/// The meeting-point map card (012): a static preview of the group's public
/// stops, a legend naming each one with its time, and — with no tiles
/// configured — a "sketch, not to scale" note. The whole card is one button
/// that opens [showPickupMapSheet]. Display only: no live position, no
/// free-point picking.
class GooraPickupMap extends ConsumerWidget {
  const GooraPickupMap({super.key, required this.pins, this.title, this.showLegend = true});

  /// In driving order, arrival last. Built only from `Stop`s (see [PickupPin]).
  final List<PickupPin> pins;

  /// Defaults to "مكان التجمع" / "Meeting point".
  final String? title;

  /// false when the same lines are already printed right next to the card
  /// (rider Today's trip timeline); the spoken label and the bigger map
  /// still carry them.
  final bool showLegend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final renderer = ref.watch(pickupMapRendererProvider);
    final heading = title ?? l10n.mapCardTitle;
    void open() => showPickupMapSheet(context, pins: pins, title: heading);
    return Semantics(
      button: true,
      label: l10n.mapPointsAria([for (final p in pins) p.spoken(l10n.listSep)].join(l10n.listSep)),
      onTapHint: l10n.mapOpen,
      onTap: open,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const Key('pickup-map-card'),
          onTap: open,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: GooraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(GooraIcons.pin, size: AppSizes.iconSmall, color: AppColors.greenText),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(heading, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
                    ),
                    const Icon(GooraIcons.expand, size: AppSizes.iconSmall, color: AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.button),
                  child: SizedBox(
                    height: AppSizes.routeMapHeight,
                    // The preview is static; a tiles map would swallow the card's tap.
                    child: IgnorePointer(child: renderer.render(context, PickupMapScene(pins: pins))),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (showLegend)
                  _Legend(pins: pins, sketch: !renderer.usesNetwork)
                else if (!renderer.usesNetwork)
                  const _SketchNote(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The bigger map of the same points, over the current screen (no route —
/// 012 research D10). Pans and zooms when real tiles render.
Future<void> showPickupMapSheet(BuildContext context, {required List<PickupPin> pins, required String title}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.hero)),
      ),
      builder: (context) => _PickupMapSheet(pins: pins, title: title),
    );

class _PickupMapSheet extends ConsumerWidget {
  const _PickupMapSheet({required this.pins, required this.title});

  final List<PickupPin> pins;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final renderer = ref.watch(pickupMapRendererProvider);
    return SafeArea(
      key: const Key('pickup-map-sheet'),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * AppSizes.pickupMapSheetFraction,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.cardPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
                  ),
                  IconButton(
                    key: const Key('pickup-map-close'),
                    tooltip: l10n.mapClose,
                    constraints: const BoxConstraints(minWidth: AppSizes.minTouch, minHeight: AppSizes.minTouch),
                    icon: const Icon(GooraIcons.close, size: AppSizes.icon, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  child: renderer.render(context, PickupMapScene(pins: pins, expanded: true)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                flex: 2,
                child: SingleChildScrollView(child: _Legend(pins: pins, sketch: !renderer.usesNetwork)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pin + "التجمع · 7:20" + stop name, one row per point; text carries the
/// meaning, the pin only echoes it (Constitution VII).
class _Legend extends StatelessWidget {
  const _Legend({required this.pins, required this.sketch});

  final List<PickupPin> pins;
  final bool sketch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, p) in pins.indexed)
          Padding(
            padding: EdgeInsetsDirectional.only(top: i == 0 ? 0 : AppSpacing.sm),
            child: Row(
              children: [
                PickupPinBadge(pin: p),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
                      Text(p.place, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (sketch) ...[
          const SizedBox(height: AppSpacing.sm),
          const _SketchNote(),
        ],
      ],
    );
  }
}

class _SketchNote extends StatelessWidget {
  const _SketchNote();

  @override
  Widget build(BuildContext context) => Text(
        AppLocalizations.of(context).mapSketchNote,
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
      );
}
