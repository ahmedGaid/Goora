import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_avatar.dart';
import '../../../../core/widgets/goora_banner.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_ghost_button.dart';
import '../../../commute/domain/commute_profile.dart';
import '../../../commute/domain/group.dart';
import '../../../commute/presentation/labels.dart';
import '../../domain/absence.dart';
import '../../domain/schedule.dart';
import '../labels.dart';
import '../shell/tab_page.dart';
import '../today/cant_come_sheet.dart';
import 'week_controller.dart';

/// Week tab: who drives each of my working days, backups and days off (US5).
class WeekScreen extends ConsumerWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(weekControllerProvider);
    final view = state.value;
    if (view == null) {
      return TabPage(
        title: l10n.scheduleTitle,
        children: [TabLoadState(failed: state.hasError, onRetry: () => ref.invalidate(weekControllerProvider))],
      );
    }
    if (view.removed) {
      return TabPage(
        title: l10n.scheduleTitle,
        children: [GooraBanner(kind: GooraBannerKind.warning, title: l10n.removedTitle, body: l10n.removedNotice)],
      );
    }
    final g = view.group!;
    return TabPage(
      title: l10n.scheduleTitle,
      subtitle: l10n.routeLine(l10n.area(g.origin), l10n.area(g.destination)),
      children: [
        Text(
          l10n.weekRiderLine(l10n.time(g.going), l10n.time(g.ret)),
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.gap),
        if (view.days.isEmpty)
          GooraCard(child: Text(l10n.weekEmpty, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)))
        else
          GooraCard.rows(rows: [for (final d in view.days) _DayRow(view: view, day: d)]),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.rotateNote, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.gap),
        GooraGhostButton(
          key: const Key('week-not-next-week'),
          label: l10n.notNextWeek,
          onPressed: () => confirmNotNextWeek(context, ref),
        ),
      ],
    );
  }
}

/// One working day: the driving person, then each trip's driver with
/// backups marked, or my day off and why (US5/AC1–AC3).
class _DayRow extends StatelessWidget {
  const _DayRow({required this.view, required this.day});

  final WeekView view;
  final ScheduleDay day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final g = view.group!;
    final me = view.me!;
    final legs = [
      for (final leg in Leg.values)
        if (day.assignment(leg) != null && travelsOn(g, me, day.date, leg)) leg,
    ];
    final driving = [for (final leg in legs) if (day.assignment(leg)!.actual == me.id) leg];
    final off = [for (final leg in legs) if (day.absenceOf(me.id, leg) != null) leg];
    final allOff = legs.isNotEmpty && off.length == legs.length;
    final main = legs.isEmpty ? null : view.driverOf(day.assignment(legs.first));

    String name(Leg leg) {
      if (off.contains(leg)) return l10n.youOff;
      final a = day.assignment(leg);
      final driver = view.driverOf(a);
      if (driver == null) return l10n.noDriverYet;
      final first = driver.id == me.id ? l10n.youWord : driver.firstName;
      return a!.isBackup ? l10n.backupName(first) : first;
    }

    final String title;
    final String detail;
    if (driving.isNotEmpty) {
      title = l10n.youDrive;
      final riders = driving.map((leg) => view.riders[(day.date, leg)] ?? 0).reduce((a, b) => a > b ? a : b);
      detail = l10n.weekDriveLine(l10n.direction(driving.toSet()), riders);
    } else if (allOff) {
      title = l10n.youOff;
      final absences = [for (final leg in off) day.absenceOf(me.id, leg)!];
      final late = absences.where((a) => a.kind == AbsenceKind.lateCancel).length;
      detail = absences.every((a) => a.kind == AbsenceKind.noCover)
          ? l10n.noCoverNote
          : late > 0
              ? l10n.lateOffNote(late * (g.price ~/ 2))
              : l10n.offNote;
    } else {
      title = main == null ? l10n.noDriverYet : l10n.drivesName(main.firstName);
      detail = me.role == MemberRole.driver
          ? l10n.youRide
          : legs.length == 2
              ? l10n.weekRiderLine(name(Leg.going), name(Leg.ret))
              : l10n.legRow(l10n.legName(legs.single), name(legs.single), l10n.time(g.timeFor(legs.single)));
    }
    final face = driving.isNotEmpty ? me : main;

    return Row(
      key: Key('week-${day.date.toIso()}'),
      children: [
        if (face != null)
          GooraAvatar(
            initials: face.initials,
            size: GooraAvatarSize.s40,
            paletteIndex: g.members.indexWhere((m) => m.id == face.id).clamp(0, g.members.length),
          )
        else
          SizedBox(width: GooraAvatarSize.s40.value),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.heroWhen(day.date, view.today), style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              Text(title, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
              Text(detail, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
