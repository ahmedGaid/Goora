import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_ghost_button.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../../commute/domain/commute_profile.dart';
import '../../../commute/presentation/labels.dart';
import '../../domain/absence.dart';
import '../../domain/attendance_rules.dart';
import '../labels.dart';
import 'today_controller.dart';

/// "I can't come tomorrow": legs to cancel (both by default) and the exact
/// charge before confirming — 2 taps from Today (SC-002, US2).
Future<void> showCantComeSheet(BuildContext context, DayPlan day) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => CantComeSheet(day: day),
    );

class CantComeSheet extends ConsumerStatefulWidget {
  const CantComeSheet({super.key, required this.day});

  final DayPlan day;

  @override
  ConsumerState<CantComeSheet> createState() => _CantComeSheetState();
}

class _CantComeSheetState extends ConsumerState<CantComeSheet> {
  late final Set<Leg> _legs = {for (final l in widget.day.riding) l.leg};
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(todayControllerProvider).value;
    if (view == null || view.group == null) return const SizedBox.shrink();
    final now = view.now;
    final share = view.group!.price;
    final late = AttendanceRules.isLate(widget.day.date, now);
    final total = _legs.length * AttendanceRules.cancelCharge(widget.day.date, now, share);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.tabH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.cantComeTitle, style: AppTypography.title.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              l10n.when(widget.day.date, now.date),
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final l in widget.day.riding)
              CheckboxListTile(
                key: Key('cancel-leg-${l.leg.name}'),
                contentPadding: EdgeInsetsDirectional.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.greenText,
                value: _legs.contains(l.leg),
                onChanged: (on) => setState(() => on! ? _legs.add(l.leg) : _legs.remove(l.leg)),
                title: Text(
                  l10n.legAt(l10n.legName(l.leg), l10n.time(l.stop.time)),
                  style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              key: const Key('cancel-charge'),
              late ? l10n.lateCancelPreview(total) : l10n.freeCancelPreview,
              style: AppTypography.bodyStrong.copyWith(color: late ? AppColors.warningTitle : AppColors.greenText),
            ),
            const SizedBox(height: AppSpacing.gap),
            GooraPrimaryButton(
              key: const Key('confirm-cancel'),
              label: _legs.isEmpty ? l10n.pickOneTrip : l10n.confirmCancel,
              onPressed: _legs.isEmpty || _busy ? null : _confirm,
            ),
            const SizedBox(height: AppSpacing.md),
            GooraGhostButton(
              key: const Key('not-next-week'),
              label: l10n.notNextWeek,
              onPressed: _busy ? null : _notNextWeek,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(todayControllerProvider.notifier).cancel(widget.day.date, _legs);
      navigator.pop();
    } on AttendanceRefused {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.cancelAfterPickup)));
    }
  }

  Future<void> _notNextWeek() async {
    final navigator = Navigator.of(context);
    if (await confirmNotNextWeek(context, ref, onConfirmed: () => setState(() => _busy = true))) navigator.pop();
  }
}

/// "Not coming next week" after a confirmation (US2/AC4); from the cancel
/// sheet and the Week tab. True when done.
Future<bool> confirmNotNextWeek(BuildContext context, WidgetRef ref, {VoidCallback? onConfirmed}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(l10n.notNextWeekConfirm),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.keepIt)),
        TextButton(
          key: const Key('confirm-not-next-week'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.notNextWeek),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  onConfirmed?.call();
  await ref.read(todayControllerProvider.notifier).notComingNextWeek();
  messenger.showSnackBar(SnackBar(content: Text(l10n.notNextWeekDone)));
  return true;
}
