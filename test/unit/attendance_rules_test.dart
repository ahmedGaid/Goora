import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/daily/domain/absence.dart';
import 'package:goora/features/daily/domain/attendance_rules.dart';

/// Brief §6.5 numbers at their exact boundaries (SC-003).
void main() {
  final tue = CalendarDate(2026, 10, 6);
  final mon = tue.addDays(-1);
  WallTime at(CalendarDate d, int h, int m, [int s = 0]) => WallTime(d, Clock.hm(h, m), s);
  final pickup = at(tue, 7, 25);

  group('cancellation', () {
    test('cut-off is 9 PM the calendar day before', () {
      expect(AttendanceRules.cutoffFor(tue), at(mon, 21, 0));
    });

    test('8:59 PM free · 9:00 PM late = half share (20 of 40)', () {
      expect(AttendanceRules.cancelCharge(tue, at(mon, 20, 59), 40), 0);
      expect(AttendanceRules.cancelCharge(tue, at(mon, 20, 59, 59), 40), 0);
      expect(AttendanceRules.cancelCharge(tue, at(mon, 21, 0), 40), 20);
      expect(AttendanceRules.cancelKind(tue, at(mon, 21, 0)), AbsenceKind.lateCancel);
      expect(AttendanceRules.cancelKind(tue, at(mon, 20, 59)), AbsenceKind.freeCancel);
    });

    test('both legs late = 20 + 20 = 40', () {
      final total = [for (final _ in Leg.values) AttendanceRules.cancelCharge(tue, at(mon, 22, 0), 40)]
          .reduce((a, b) => a + b);
      expect(total, 40);
    });

    test('Sunday ride → Saturday 9 PM cut-off (not a working day)', () {
      final sunday = CalendarDate(2026, 10, 11);
      final saturday = CalendarDate(2026, 10, 10);
      expect(sunday.weekday, Day.sun);
      expect(AttendanceRules.cutoffFor(sunday), at(saturday, 21, 0));
      expect(AttendanceRules.cancelCharge(sunday, at(saturday, 20, 59), 40), 0);
      expect(AttendanceRules.cancelCharge(sunday, at(saturday, 21, 0), 40), 20);
    });

    test('cancel at or after pickup time is refused', () {
      expect(AttendanceRules.canCancel(pickup, at(tue, 7, 24, 59)), isTrue);
      expect(AttendanceRules.canCancel(pickup, at(tue, 7, 25)), isFalse);
    });

    test('price even → exact half', () {
      for (final price in [30, 32, 40, 48]) {
        expect(AttendanceRules.cancelCharge(tue, at(mon, 21, 0), price) * 2, price);
      }
    });
  });

  group('undo', () {
    Absence absence(AbsenceKind kind) =>
        Absence(personId: 'me', date: tue, leg: Leg.going, madeAt: at(mon, 18, 0), kind: kind);

    test('free cancel: undo before the cut-off ok, at the cut-off the seat is taken', () {
      final a = absence(AbsenceKind.freeCancel);
      expect(AttendanceRules.canUndo(a, at(mon, 20, 59), pickup: pickup, waitlistWaiting: true), UndoResult.ok);
      expect(AttendanceRules.canUndo(a, at(mon, 21, 0), pickup: pickup, waitlistWaiting: true),
          UndoResult.refusedSeatTaken);
    });

    test('free cancel with an empty waitlist: the seat stays free until pickup', () {
      final a = absence(AbsenceKind.freeCancel);
      expect(AttendanceRules.canUndo(a, at(mon, 22, 0), pickup: pickup, waitlistWaiting: false), UndoResult.ok);
    });

    test('late cancel: undo allowed until pickup (founder 2026-10-06), refused at pickup', () {
      final a = absence(AbsenceKind.lateCancel);
      expect(AttendanceRules.canUndo(a, at(mon, 23, 0), pickup: pickup, waitlistWaiting: true), UndoResult.ok);
      expect(AttendanceRules.canUndo(a, at(tue, 7, 24, 59), pickup: pickup, waitlistWaiting: true), UndoResult.ok);
      expect(AttendanceRules.canUndo(a, at(tue, 7, 25), pickup: pickup, waitlistWaiting: true),
          UndoResult.refusedTooLate);
    });
  });

  group('no-show', () {
    final arrived = at(tue, 7, 20);

    test('4:59 after arrival: not yet · 5:00: allowed', () {
      expect(AttendanceRules.noShowAvailableAt(arrived), at(tue, 7, 25));
      expect(AttendanceRules.canMarkNoShow(arrived, arrived.plusSeconds(4 * 60 + 59)), isFalse);
      expect(AttendanceRules.canMarkNoShow(arrived, arrived.plusSeconds(5 * 60)), isTrue);
    });

    test('full share 40', () => expect(AttendanceRules.noShowCharge(40), 40));

    test('standing: 1 ok · 2 warning · 3 removal', () {
      expect(AttendanceRules.standing(0), NoShowStanding.ok);
      expect(AttendanceRules.standing(1), NoShowStanding.ok);
      expect(AttendanceRules.standing(2), NoShowStanding.warning);
      expect(AttendanceRules.standing(3), NoShowStanding.removal);
      expect(AttendanceRules.standing(4), NoShowStanding.removal);
    });

    test('going + return no-shows on one day count as 2 → warning', () {
      const sameDay = [Leg.going, Leg.ret];
      expect(AttendanceRules.standing(sameDay.length), NoShowStanding.warning);
    });

    test('month boundary resets the count (counted per ride-date month key)', () {
      final oct31 = CalendarDate(2026, 10, 31);
      final nov1 = oct31.addDays(1);
      expect(oct31.monthKey, isNot(nov1.monthKey));
    });
  });

  group('drivers', () {
    test('driver no-show at first pickup + 5 min without check-in or cancel', () {
      expect(
        AttendanceRules.driverNoShow(
            firstPickup: at(tue, 7, 20), now: at(tue, 7, 24, 59), checkedIn: false, cancelled: false),
        isFalse,
      );
      expect(
        AttendanceRules.driverNoShow(firstPickup: at(tue, 7, 20), now: at(tue, 7, 25), checkedIn: false, cancelled: false),
        isTrue,
      );
      expect(
        AttendanceRules.driverNoShow(firstPickup: at(tue, 7, 20), now: at(tue, 7, 30), checkedIn: true, cancelled: false),
        isFalse,
      );
    });

    test("can't drive follows the 9 PM rule", () {
      expect(AttendanceRules.driverCantDriveLate(tue, at(mon, 20, 59)), isFalse);
      expect(AttendanceRules.driverCantDriveLate(tue, at(mon, 21, 0)), isTrue);
    });
  });
}
