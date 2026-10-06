import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/calendar_date.dart';
import '../../../../core/time/now_provider.dart';
import '../../../commute/domain/commute_profile.dart';
import '../../../commute/domain/group.dart';
import '../../data/providers.dart';
import '../../domain/schedule.dart';

part 'week_controller.g.dart';

/// Everything the Week tab shows (US5).
final class WeekView {
  const WeekView({required this.today, required this.group, required this.me, required this.days, this.riders = const {}});

  const WeekView.removed(this.today)
      : group = null,
        me = null,
        days = const [],
        riders = const {};

  final CalendarDate today;
  final CommuteGroup? group;
  final Member? me;

  /// My working days in the coming week, today first, with backups and
  /// absences applied.
  final List<ScheduleDay> days;

  /// Drivers: passengers in my car on the legs I drive, by date and leg.
  final Map<(CalendarDate, Leg), int> riders;

  bool get removed => group == null;
  bool get isDriver => me?.role == MemberRole.driver;

  /// Whoever drives [a]: a group member or an outside backup.
  Member? driverOf(LegAssignment? a) {
    final id = a?.actual;
    if (id == null) return null;
    return a!.cover ?? group?.member(id);
  }
}

@riverpod
class WeekController extends _$WeekController {
  static const days = 7;

  @override
  Future<WeekView> build() async {
    final today = ref.watch(nowProvider)().date;
    final repo = ref.watch(dailyCommuteRepositoryProvider);
    final g = await repo.myGroup();
    if (g == null) return WeekView.removed(today);
    final me = g.member(repo.meId)!;
    final schedule = [
      for (final d in await repo.schedule(today, today.addDays(days - 1)))
        if (me.daysIn(g).contains(d.date.weekday)) d,
    ];
    final riders = <(CalendarDate, Leg), int>{};
    for (final d in schedule) {
      for (final leg in Leg.values) {
        if (d.assignment(leg)?.actual != me.id) continue;
        riders[(d.date, leg)] = (await repo.ride(d.date, leg))?.passengers.length ?? 0;
      }
    }
    return WeekView(today: today, group: g, me: me, days: schedule, riders: riders);
  }
}
