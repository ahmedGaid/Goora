import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/data/fake_commute_repository.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/domain/absence.dart';
import 'package:goora/features/daily/domain/charge.dart';
import 'package:goora/features/daily/domain/check_in.dart';
import 'package:goora/features/daily/domain/notice.dart';
import 'package:goora/features/daily/domain/ride.dart';
import 'package:goora/features/daily/domain/trust.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/daily_fakes.dart';

final class _Setup {
  _Setup(this.repo, this.prefs, this.clock);

  final FakeDailyCommuteRepository repo;
  final SharedPreferences prefs;
  final TestClock clock;
}

Future<_Setup> _make(Role role, {required WallTime start}) async {
  SharedPreferences.setMockInitialValues(memberPrefs(role: role));
  final prefs = await SharedPreferences.getInstance();
  final clock = TestClock(start);
  final person = Profile(phone: testPhone, firstName: 'Omar', lastName: 'Khaled', gender: Gender.male, role: role);
  final repo = FakeDailyCommuteRepository(
    prefs,
    commute: FakeCommuteRepository(prefs),
    person: () => person,
    now: clock.call,
  );
  return _Setup(repo, prefs, clock);
}

String _id(CalendarDate d, Leg leg) => Ride.idFor('sz-0725', d, leg);

void main() {
  final tue = rideTuesday;
  final mon = tue.addDays(-1);
  final wed = tue.addDays(1);

  group('rider: cancel', () {
    test('before 9 PM: free, seat offered, no charge, no reliability event', () async {
      final s = await _make(Role.rider, start: at(mon, 20, 59));
      final charges = await s.repo.cancel(tue, {Leg.going, Leg.ret}, at(mon, 20, 59));
      expect(charges, isEmpty);
      final absences = await s.repo.absences(tue, tue);
      expect(absences.map((a) => a.kind), [AbsenceKind.freeCancel, AbsenceKind.freeCancel]);
      expect(await s.repo.chargesOwed(), isEmpty);
      final events = await s.repo.events(tue, tue);
      expect(events, isEmpty);
      final notices = await s.repo.notices().first;
      expect(notices.where((n) => n.kind == NoticeKind.seatOffered), hasLength(2));
    });

    test('at 9 PM both legs: 20 + 20 owed to that day\'s driver, no Goora fee', () async {
      final s = await _make(Role.rider, start: at(tue, 21, 0));
      final charges = await s.repo.cancel(wed, {Leg.going, Leg.ret}, at(tue, 21, 0));
      expect(charges.map((c) => c.amount), [20, 20]);
      expect(charges.every((c) => c.owedTo == 'mohamed' && c.reason == ChargeReason.lateCancel), isTrue);
      expect((await s.repo.chargesOwed()).fold<int>(0, (a, c) => a + c.amount), 40);
      final events = await s.repo.events(wed, wed);
      expect(events.map((e) => e.kind), everyElement(ReliabilityEventKind.lateCancel));
    });

    test('at or after pickup the cancel is refused', () async {
      final s = await _make(Role.rider, start: at(tue, 7, 25));
      expect(
        () => s.repo.cancel(tue, {Leg.going}, at(tue, 7, 25)),
        throwsA(isA<AttendanceRefused>().having((e) => e.reason, 'reason', RefusalReason.afterPickup)),
      );
    });

    test('undo: free before 9 PM ok; at 9 PM the waitlist took the seat', () async {
      final s = await _make(Role.rider, start: at(mon, 18, 0));
      await s.repo.cancel(tue, {Leg.going}, at(mon, 18, 0));
      expect(await s.repo.undoCancel(tue, at(mon, 21, 0)), UndoResult.refusedSeatTaken);
      expect(await s.repo.absences(tue, tue), hasLength(1));
      expect(await s.repo.undoCancel(tue, at(mon, 20, 59)), UndoResult.ok);
      expect(await s.repo.absences(tue, tue), isEmpty);
    });

    test('undo a late cancel until pickup removes the charge and event (founder 2026-10-06)', () async {
      final s = await _make(Role.rider, start: at(mon, 22, 0));
      await s.repo.cancel(tue, {Leg.going, Leg.ret}, at(mon, 22, 0));
      expect(await s.repo.chargesOwed(), hasLength(2));
      expect(await s.repo.undoCancel(tue, at(tue, 7, 25)), UndoResult.refusedTooLate);
      expect(await s.repo.undoCancel(tue, at(tue, 7, 0)), UndoResult.ok);
      expect(await s.repo.chargesOwed(), isEmpty);
      expect(await s.repo.events(tue, tue), isEmpty);
      expect(await s.repo.absences(tue, tue), isEmpty);
    });

    test('not coming next week: every ride day Sun–Thu, both legs, free', () async {
      final s = await _make(Role.rider, start: at(tue, 12, 0));
      final charges = await s.repo.notComingNextWeek(at(tue, 12, 0));
      expect(charges, isEmpty);
      final sun = CalendarDate(2026, 10, 11);
      final absences = await s.repo.absences(sun, sun.addDays(6));
      expect(absences, hasLength(10));
      expect({for (final a in absences) a.date.weekday}, {Day.sun, Day.mon, Day.tue, Day.wed, Day.thu});
    });
  });

  group('no-shows', () {
    Future<void> noShow(_Setup s, CalendarDate date, Leg leg) async {
      final id = _id(date, leg);
      final stop = leg == Leg.going ? 'central-st' : 'work';
      final arrived = leg == Leg.going ? at(date, 7, 25) : at(date, 17, 0);
      await s.repo.arrivedAt(id, stop, arrived);
      await s.repo.mark(id, 'me', Outcome.noShow, arrived.plusSeconds(5 * 60));
      await s.repo.startTrip(id, arrived.plusSeconds(6 * 60));
    }

    test('4:59 refused, 5:00 allowed; full share 40 owed to the driver', () async {
      final s = await _make(Role.rider, start: at(tue, 7, 20));
      final id = _id(tue, Leg.going);
      await s.repo.arrivedAt(id, 'central-st', at(tue, 7, 25));
      expect(
        () => s.repo.mark(id, 'me', Outcome.noShow, at(tue, 7, 29, 59)),
        throwsA(isA<AttendanceRefused>().having((e) => e.reason, 'reason', RefusalReason.noShowTooEarly)),
      );
      await s.repo.mark(id, 'me', Outcome.noShow, at(tue, 7, 30));
      await s.repo.startTrip(id, at(tue, 7, 31));
      final charges = await s.repo.chargesOwed();
      expect(charges.single.amount, 40);
      expect(charges.single.owedTo, 'ahmed');
      expect(await s.repo.noShowsInMonth('2026-10'), 1);
    });

    test('picked up by mistake can switch to no-show until start; the last mark counts', () async {
      final s = await _make(Role.rider, start: at(tue, 7, 20));
      final id = _id(tue, Leg.going);
      await s.repo.arrivedAt(id, 'central-st', at(tue, 7, 25));
      await s.repo.mark(id, 'me', Outcome.pickedUp, at(tue, 7, 26));
      await s.repo.mark(id, 'me', Outcome.noShow, at(tue, 7, 30));
      expect((await s.repo.outcomes(id)).single.outcome, Outcome.noShow);
      await s.repo.startTrip(id, at(tue, 7, 31));
      expect(
        () => s.repo.mark(id, 'me', Outcome.pickedUp, at(tue, 7, 32)),
        throwsA(isA<AttendanceRefused>().having((e) => e.reason, 'reason', RefusalReason.tripStarted)),
      );
    });

    test('going + return the same day = 2 → warning; a third removes, profile kept', () async {
      final s = await _make(Role.rider, start: at(tue, 7, 0));
      await noShow(s, tue, Leg.going);
      await noShow(s, tue, Leg.ret);
      expect(await s.repo.noShowsInMonth('2026-10'), 2);
      var notices = await s.repo.notices().first;
      expect(notices.where((n) => n.kind == NoticeKind.noShowWarning), hasLength(1));
      expect(s.prefs.getString(FakeCommuteRepository.membershipKey), 'sz-0725');

      await noShow(s, wed, Leg.going);
      notices = await s.repo.notices().first;
      expect(notices.where((n) => n.kind == NoticeKind.removed), hasLength(1));
      expect(s.prefs.containsKey(FakeCommuteRepository.membershipKey), isFalse);
      expect(await s.repo.myGroup(), isNull);
      expect(await FakeCommuteRepository(s.prefs).loadProfile(), isNotNull, reason: 'commute profile is kept');
    });

    test('the count is per calendar month', () async {
      final s = await _make(Role.rider, start: at(tue, 7, 0));
      await noShow(s, tue, Leg.going);
      expect(await s.repo.noShowsInMonth('2026-10'), 1);
      expect(await s.repo.noShowsInMonth('2026-11'), 0);
    });
  });

  group('driver', () {
    // Three drivers (ahmed, me, mohamed): Thursday 8 Oct is mine.
    final thu = tue.addDays(2);

    test("can't drive after 9 PM: reliability event, no money, riders told, no cover yet", () async {
      final s = await _make(Role.driver, start: at(wed, 21, 30));
      expect((await s.repo.ride(thu, Leg.going))!.driverId, 'me');
      final result = await s.repo.cantDrive(thu, {Leg.going, Leg.ret}, at(wed, 21, 30));
      expect(result.found, isFalse);
      expect((await s.repo.ride(thu, Leg.going))!.driverId, isNull);
      expect(await s.repo.chargesOwed(), isEmpty);
      final events = await s.repo.events(thu, thu);
      expect(events.map((e) => e.kind), everyElement(ReliabilityEventKind.lateCantDrive));
      final notices = await s.repo.notices().first;
      expect(notices.where((n) => n.kind == NoticeKind.noCover && !n.toMe), hasLength(2));
    });

    test("can't drive before 9 PM: no reliability event", () async {
      final s = await _make(Role.driver, start: at(wed, 20, 0));
      await s.repo.cantDrive(thu, {Leg.going}, at(wed, 20, 0));
      expect(await s.repo.events(thu, thu), isEmpty);
    });

    test('confirm, delay and arrival notify riders; delay shifts every stop', () async {
      final s = await _make(Role.driver, start: at(wed, 20, 0));
      final id = _id(thu, Leg.going);
      await s.repo.setConfirmed(id, true);
      await s.repo.reportDelay(id, 10);
      final ride = (await s.repo.ride(thu, Leg.going))!;
      expect(ride.confirmed, isTrue);
      expect([for (final st in ride.stops) st.time.h12], ['7:30', '7:35']);
      await s.repo.arrivedAt(id, 'main-gate', at(thu, 7, 30));
      final kinds = [for (final n in await s.repo.notices().first) if (!n.toMe) n.kind];
      expect(kinds, [NoticeKind.driverConfirmed, NoticeKind.delay, NoticeKind.driverArrived]);
    });

    test('off-duty drivers ride on the on-duty car (FR-022a)', () async {
      final s = await _make(Role.driver, start: at(wed, 20, 0));
      final ride = (await s.repo.ride(thu, Leg.going))!;
      expect({for (final p in ride.passengers) p.memberId}, {'ahmed', 'mohamed', 'sara', 'youssef'});
      final tuesday = (await s.repo.ride(tue, Leg.going))!;
      expect(tuesday.carries('me'), isTrue);
    });
  });
}
