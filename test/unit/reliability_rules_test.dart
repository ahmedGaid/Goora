import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/daily/domain/reliability_rules.dart';
import 'package:goora/features/daily/domain/trust.dart';

final today = CalendarDate(2026, 10, 20);

ReliabilityEvent ev(ReliabilityEventKind kind, {int daysAgo = 1, CalendarDate? on}) {
  final date = on ?? today.addDays(-daysAgo);
  return ReliabilityEvent(personId: 'me', rideId: 'r-${date.toIso()}-${kind.name}', date: date, kind: kind);
}

List<ReliabilityEvent> times(int n, ReliabilityEventKind kind) => [for (var i = 0; i < n; i++) ev(kind, daysAgo: i + 1)];

int pct(List<ReliabilityEvent> events) => ReliabilityRules.compute(events, today).percent;

void main() {
  const kept = ReliabilityEventKind.kept;
  const noShow = ReliabilityEventKind.noShow;
  const late = ReliabilityEventKind.lateCancel;

  test('12.5 kept of 13 booked → 96 %', () {
    expect(pct([...times(12, kept), ev(late)]), 96);
  });

  test('no booked trips → 100 %', () {
    expect(pct(const []), 100);
  });

  test('1 no-show of 4 → 75 %; 1 late cancel of 2 → 75 %', () {
    expect(pct([...times(3, kept), ev(noShow)]), 75);
    expect(pct([ev(kept), ev(late)]), 75);
  });

  test('a late "can\'t drive" counts like a late cancel', () {
    expect(pct([ev(kept), ev(ReliabilityEventKind.lateCantDrive)]), 75);
  });

  test('a free cancel is not booked (it leaves no event)', () {
    expect(pct(times(4, kept)), 100);
  });

  test('x.5 rounds up, exactly', () {
    expect(ReliabilityRules.percent(booked: 100, missedHalves: 1), 100, reason: '99.5');
    expect(ReliabilityRules.percent(booked: 100, missedHalves: 3), 99, reason: '98.5');
    expect(ReliabilityRules.percent(booked: 8, missedHalves: 1), 94, reason: '93.75');
    expect(ReliabilityRules.percent(booked: 1, missedHalves: 2), 0);
  });

  test('window: 30 days ago counts, 31 does not; today does not yet', () {
    expect(pct([ev(noShow, daysAgo: 30), ev(kept)]), 50);
    expect(pct([ev(noShow, daysAgo: 31), ev(kept)]), 100);
    expect(pct([ev(noShow, daysAgo: 0), ev(kept)]), 100);
  });

  test('month counts reset on the 1st; the % does not', () {
    final first = CalendarDate(2026, 11, 1);
    final events = [
      ev(late, on: CalendarDate(2026, 10, 28)),
      ev(noShow, on: CalendarDate(2026, 10, 29)),
      ev(kept, on: CalendarDate(2026, 10, 30)),
    ];
    final october = ReliabilityRules.compute(events, CalendarDate(2026, 10, 31));
    expect((october.monthLateCancels, october.monthNoShows), (1, 1));
    final november = ReliabilityRules.compute(events, first);
    expect((november.monthLateCancels, november.monthNoShows), (0, 0));
    expect(november.percent, october.percent);
    expect(november.percent, 50, reason: '1.5 kept of 3');
  });
}
