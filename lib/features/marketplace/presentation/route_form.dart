import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/time/wall_time.dart';
import '../../../core/widgets/goora_pill.dart';
import '../../../core/widgets/goora_stepper.dart';
import '../../commute/domain/clock.dart';
import '../../commute/domain/place.dart';
import '../../commute/presentation/labels.dart';
import '../../daily/presentation/labels.dart';
import '../domain/market_day.dart';
import '../domain/offered_trip.dart';

/// The From / To / Time / How often form that Offer a trip and Post your trip
/// share (research R13). There is no date picker: the chosen time resolves to
/// its next workday occurrence and the line under it says which day that is.
class RouteForm extends StatelessWidget {
  const RouteForm({
    super.key,
    required this.from,
    required this.to,
    required this.departure,
    required this.repeat,
    required this.now,
    required this.onFrom,
    required this.onTo,
    required this.onShift,
    required this.onRepeat,
    this.dailyBlockedReason,
  });

  final Area from;
  final Area to;
  final Clock departure;
  final Repeat repeat;
  final WallTime now;
  final ValueChanged<Area> onFrom;
  final ValueChanged<Area> onTo;

  /// Minutes to move the time by: −5 or +5.
  final ValueChanged<int> onShift;
  final ValueChanged<Repeat> onRepeat;

  /// Why "Every workday" is off, said in words under the pills; null = allowed.
  final String? dailyBlockedReason;

  static const _step = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final day = MarketDay.nextWorkday(departure, now);
    Widget label(String text) => Padding(
          padding: const EdgeInsetsDirectional.only(top: AppSpacing.md, bottom: AppSpacing.sm),
          child: Text(text, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
        );
    Widget areas(Area selected, ValueChanged<Area> on, String prefix) => Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final a in Area.values)
              GooraPill(key: Key('$prefix-${a.name}'), label: l10n.area(a), selected: selected == a, onTap: () => on(a)),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        label(l10n.offerFromLabel),
        areas(from, onFrom, 'from'),
        label(l10n.offerToLabel),
        areas(to, onTo, 'to'),
        label(l10n.offerTimeLabel),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: GooraStepper(
            key: const Key('time-stepper'),
            valueLabel: l10n.time(departure),
            decreaseLabel: l10n.earlier,
            increaseLabel: l10n.later,
            onDecrease: () => onShift(-_step),
            onIncrease: () => onShift(_step),
            valueTapLabel: l10n.pickTime,
            onValueTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: departure.hour, minute: departure.minute),
              );
              if (picked == null) return;
              final delta = (picked.hour * 60 + picked.minute) - departure.minutes;
              if (delta != 0) onShift(delta);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${l10n.heroWhen(day, now.date)} · ${l10n.time(departure)}',
          key: const Key('resolved-day'),
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            GooraPill(
              key: const Key('repeat-once'),
              label: l10n.justOnce,
              selected: repeat == Repeat.once,
              onTap: () => onRepeat(Repeat.once),
            ),
            GooraPill(
              key: const Key('repeat-daily'),
              label: l10n.everyWorkday,
              selected: repeat == Repeat.daily,
              onTap: dailyBlockedReason == null ? () => onRepeat(Repeat.daily) : null,
            ),
          ],
        ),
        if (dailyBlockedReason != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
            child: Text(
              dailyBlockedReason!,
              key: const Key('daily-blocked'),
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}
