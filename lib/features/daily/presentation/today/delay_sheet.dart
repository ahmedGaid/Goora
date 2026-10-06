import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_pill.dart';
import '../../../commute/presentation/labels.dart';
import 'today_controller.dart';

/// Report delay: 5 / 10 / 15 minutes; riders get the new pickup time (US3/AC3).
Future<void> showDelaySheet(BuildContext context, LegPlan leg) => showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      builder: (_) => DelaySheet(leg: leg),
    );

class DelaySheet extends ConsumerWidget {
  const DelaySheet({super.key, required this.leg});

  static const options = [5, 10, 15];

  final LegPlan leg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ride = leg.ride!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.tabH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.delayTitle, style: AppTypography.title.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.gap),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final m in options)
                  GooraPill(
                    key: Key('delay-$m'),
                    label: l10n.delayMinutes(m),
                    selected: ride.delayMinutes == m,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      // Delays replace each other; times shift from the schedule.
                      final first = ride.stops.first.time.shift(m - ride.delayMinutes);
                      await ref.read(todayControllerProvider.notifier).reportDelay(ride.id, m);
                      navigator.pop();
                      messenger.showSnackBar(SnackBar(content: Text(l10n.delaySent(l10n.time(first)))));
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
