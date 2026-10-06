import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/time/calendar_date.dart';
import '../../../../core/widgets/goora_banner.dart';
import '../../../../core/widgets/goora_ghost_button.dart';
import '../../../../core/widgets/goora_icons.dart';
import '../../domain/absence.dart';
import '../../domain/attendance_rules.dart';
import '../inbox/inbox_sheet.dart';
import '../labels.dart';
import '../safety/share_trip.dart';
import '../safety/sos_sheet.dart';
import 'today_controller.dart';

/// Bell (with unread count as text) and settings, on the Today header.
class TodayHeaderActions extends ConsumerWidget {
  const TodayHeaderActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final unread = ref.watch(noticesProvider).value?.where((n) => !n.read).length ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('inbox'),
          tooltip: l10n.inboxAria(unread),
          constraints: const BoxConstraints(minWidth: AppSizes.minTouch, minHeight: AppSizes.minTouch),
          onPressed: () => showInboxSheet(context),
          icon: Badge(
            isLabelVisible: unread > 0,
            backgroundColor: AppColors.greenText,
            textColor: AppColors.white,
            label: Text(unread.toString()),
            child: const Icon(GooraIcons.bell, color: AppColors.textPrimary),
          ),
        ),
        IconButton(
          key: const Key('open-settings'),
          tooltip: l10n.openSettings,
          constraints: const BoxConstraints(minWidth: AppSizes.minTouch, minHeight: AppSizes.minTouch),
          onPressed: () => context.push(Routes.settings),
          icon: const Icon(GooraIcons.settings, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

/// Standing warning, the "you're off" banner with Undo, and the driver's
/// "can't drive" confirmation (US2, US3).
class TodayBanners extends ConsumerWidget {
  const TodayBanners({super.key, required this.view});

  final TodayView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final target = view.target;
    final banners = <Widget>[
      if (view.standing == NoShowStanding.warning)
        GooraBanner(kind: GooraBannerKind.warning, title: l10n.headsUp, body: l10n.noShowWarning),
    ];
    if (target != null) {
      final when = l10n.when(target.date, view.now.date);
      final riderOff = [for (final l in target.off) if (l.absence != null && !l.absence!.driving) l];
      if (riderOff.isNotEmpty) {
        final late = riderOff.where((l) => l.absence!.kind == AbsenceKind.lateCancel).length;
        final travelling = target.legs.where((l) => !(l.absence?.driving ?? false)).length;
        banners.add(GooraBanner(
          key: const Key('off-banner'),
          kind: GooraBannerKind.info,
          title: riderOff.length == travelling ? l10n.offTitle(when) : l10n.offLegTitle(l10n.tripName(riderOff.single.leg), when),
          body: late > 0 ? l10n.lateOffBody(late * (view.group!.price ~/ 2)) : l10n.offBody,
          actionLabel: l10n.undo,
          onAction: () => _undo(context, ref, target.date),
        ));
      }
      if (target.off.any((l) => l.absence?.driving ?? false)) {
        banners.add(GooraBanner(kind: GooraBannerKind.info, title: l10n.cantDrive, body: l10n.cantDriveDone(when)));
      }
    }
    return Column(
      children: [
        for (final b in banners) ...[b, const SizedBox(height: AppSpacing.gap)],
      ],
    );
  }

  Future<void> _undo(BuildContext context, WidgetRef ref, CalendarDate date) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(todayControllerProvider.notifier).undo(date);
    final message = switch (result) {
      UndoResult.ok => null,
      UndoResult.refusedSeatTaken => l10n.undoRefused,
      UndoResult.refusedTooLate => l10n.undoTooLate,
    };
    if (message != null) messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Share trip + SOS: one tap away on Today at all times (FR-029).
class SafetyRow extends ConsumerWidget {
  const SafetyRow({super.key, required this.view});

  final TodayView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: GooraGhostButton(
            key: const Key('share-trip'),
            label: l10n.shareTrip,
            icon: GooraIcons.share,
            onPressed: () => shareTrip(context, ref, view),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: GooraGhostButton(
            key: const Key('sos'),
            label: l10n.sos,
            icon: GooraIcons.sos,
            danger: true,
            onPressed: () => showSosSheet(context),
          ),
        ),
      ],
    );
  }
}

/// Section heading inside a tab.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
        child: Text(text, style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
      );
}

/// Small secondary line under a control.
class Caption extends StatelessWidget {
  const Caption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
        child: Text(text, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
      );
}

/// First name of a member as seen by the person ("You" for themselves).
String nameFor(AppLocalizations l10n, TodayView v, String? memberId) {
  if (memberId == null) return '';
  if (memberId == v.me?.id) return l10n.youWord;
  return v.group?.member(memberId)?.firstName ?? '';
}

/// Avatar colour by position in the group, stable across screens.
int paletteFor(TodayView v, String memberId) {
  final i = v.group?.members.indexWhere((m) => m.id == memberId) ?? 0;
  return i < 0 ? 0 : i;
}
