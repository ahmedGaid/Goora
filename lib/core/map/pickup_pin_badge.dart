import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_typography.dart';
import '../widgets/goora_icons.dart';
import 'pickup_pin.dart';

/// The round pin used on the map and in the legend: pickups show their
/// number on `primary`, the arrival a flag on `mapDestination` — never colour
/// alone (Constitution VII). Fixed size, so large text never breaks it.
class PickupPinBadge extends StatelessWidget {
  const PickupPinBadge({super.key, required this.pin});

  final PickupPin pin;

  @override
  Widget build(BuildContext context) {
    final arrival = pin.kind == PickupPinKind.arrival;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: AppSizes.mapPin,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: arrival ? AppColors.mapDestination : AppColors.primary,
            border: Border.all(color: AppColors.white, width: AppSizes.mapPinRing),
          ),
          child: Center(
            child: arrival
                ? const Icon(GooraIcons.arrival, size: AppSizes.iconTiny, color: AppColors.white)
                : MediaQuery.withNoTextScaling(
                    child: Text('${pin.number}', style: AppTypography.microBold.copyWith(color: AppColors.white, height: 1)),
                  ),
          ),
        ),
      ),
    );
  }
}
