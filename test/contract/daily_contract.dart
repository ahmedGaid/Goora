import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/daily/domain/daily_commute_repository.dart';
import 'package:goora/features/daily/domain/notice.dart';

/// [postNotice] stands for whoever writes a notice (the fake itself, the
/// server's service role on Supabase).
typedef DailySetup = ({DailyCommuteRepository repo, Future<void> Function(NoticeKind kind) postNotice});

/// 011 contracts/seam-contracts.md — Daily commute. The cut-off cases (D3/D4
/// of the plan) are the commute-day Edge Function's, run on the TS twins by
/// `node --test`; here D3 is the read side only (research "Daily gaps").
void dailyContract(String label, Future<DailySetup> Function({required bool member}) make) {
  final week = (CalendarDate(2026, 11, 1), CalendarDate(2026, 11, 7));

  group('daily contract [$label]', () {
    test('D1 not in a group: no group, no schedule', () async {
      final s = await make(member: false);
      expect(await s.repo.myGroup(), isNull);
      expect(await s.repo.schedule(week.$1, week.$2), isEmpty);
    });

    test('D2 a member: the group holds me and the week has days', () async {
      final s = await make(member: true);
      final g = await s.repo.myGroup();
      expect(g?.member(s.repo.meId), isNotNull);
      expect(await s.repo.schedule(week.$1, week.$2), isNotEmpty);
    });

    test('D3 nothing cancelled: no absences, no charges owed', () async {
      final s = await make(member: true);
      expect(await s.repo.absences(week.$1, week.$2), isEmpty);
      expect(await s.repo.chargesOwed(), isEmpty);
    });

    test('D5 a new notice arrives unread and reads as read after markRead', () async {
      final s = await make(member: true);
      await s.postNotice(NoticeKind.driverConfirmed);
      final first = await s.repo.notices().first;
      final n = first.firstWhere((n) => n.kind == NoticeKind.driverConfirmed && !n.read);
      await s.repo.markRead(n.id);
      expect((await s.repo.notices().first).firstWhere((x) => x.id == n.id).read, isTrue);
    });

    test('D6 a month with no trips has no no-shows', () async {
      final s = await make(member: true);
      expect(await s.repo.noShowsInMonth('2026-11'), 0);
    });
  });
}
