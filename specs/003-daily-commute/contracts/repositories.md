# Contract: app repositories and device interfaces

All in `lib/features/daily/domain/`. Fakes in `daily/data/` over shared_preferences; Supabase
implementations later call the Edge Functions in [edge-functions.md](edge-functions.md).

## DailyCommuteRepository

```dart
abstract interface class DailyCommuteRepository {
  /// The person's group with them included as a member; null when not in a group (removed).
  Future<CommuteGroup?> myGroup();

  /// Schedule for [from]..[to] inclusive (rotation + absences + backups applied).
  Future<List<ScheduleDay>> schedule(CalendarDate from, CalendarDate to);

  Future<Ride?> ride(CalendarDate date, Leg leg);

  // Rider actions (also used by off-duty drivers)
  Future<List<Charge>> cancel(CalendarDate date, Set<Leg> legs, WallTime madeAt); // may be empty
  Future<UndoResult> undoCancel(CalendarDate date, WallTime now); // ok | refusedSeatTaken | refusedAfterCutoff
  Future<List<Charge>> notComingNextWeek(WallTime madeAt);

  // Driver actions
  Future<void> setConfirmed(String rideId, bool confirmed);
  Future<void> reportDelay(String rideId, int minutes); // 5 | 10 | 15
  Future<BackupResult> cantDrive(CalendarDate date, Set<Leg> legs, WallTime madeAt);
  Future<void> arrivedAt(String rideId, String stopId, WallTime at);
  Future<void> mark(String rideId, String personId, Outcome outcome, WallTime at); // noShow < 5 min → AttendanceRefused
  Future<void> startTrip(String rideId, WallTime at);
  Future<void> endTrip(String rideId, WallTime at);

  // Results
  Future<List<Charge>> chargesOwed(); // shown and collected in 004
  Future<int> noShowsInMonth(String monthKey);
  Future<List<ReliabilityEvent>> events(CalendarDate from, CalendarDate to);

  // Notices
  Stream<List<Notice>> notices();
  Future<void> markRead(String noticeId);
  Future<void> chooseNoCoverOption(CalendarDate date, Leg leg, NoCoverOption option); // dayOff → free absence
}
```

Refusals are typed (`AttendanceRefused.reason`) so the UI shows calm copy, never a raw message.

## TrustRepository

```dart
abstract interface class TrustRepository {
  Future<TrustProfile> profile();
  Future<void> setPrivacy(PrivacyPreference p); // refused when not available (research R7)
  Future<List<TrustedContact>> contacts();
  Future<void> addContact(String name, PhoneNumber phone); // max 3
  Future<void> removeContact(String id);
  Future<SosAlert> sendSos({String? rideId}); // fake: recorded only
}
```

## Device interfaces

```dart
abstract interface class PhoneDialer { Future<bool> dial(String number); } // E.164 or "122"
abstract interface class TripSharer { Future<void> share(String text); }
abstract interface class LocationSource { Stream<TripPosition> watch(String rideId); }
```

Implementations: `UrlPhoneDialer` (url_launcher `tel:`), `SharePlusSharer` (share_plus),
`SimulatedLocationSource` (5 s ticks). Tests use recording fakes.

## Pure rule modules (no Flutter imports)

```dart
abstract final class AttendanceRules { /* research R3 table */ }
abstract final class ReliabilityRules {
  static Reliability compute(List<ReliabilityEvent> events, CalendarDate today);
}
abstract final class RotationPlanner {
  static List<ScheduleDay> plan(CommuteGroup g, CalendarDate from, CalendarDate to,
      {Set<(String memberId, CalendarDate date, Leg leg)> unavailable});
}
abstract final class BackupService {
  static BackupResult findCover(Ride ride, CommuteGroup g, List<BackupCandidate> candidates,
      {MatchingLimits limits});
}
abstract final class PrivacyRules {
  static bool accepts(PrivacyPreference p, PersonFacts owner, PersonFacts other);
  static bool available(PrivacyPreference p, PersonFacts me);
}
```
