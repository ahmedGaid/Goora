import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/group.dart';
import 'absence.dart';
import 'backup_service.dart';
import 'charge.dart';
import 'check_in.dart';
import 'notice.dart';
import 'ride.dart';
import 'schedule.dart';
import 'trust.dart';

export 'backup_service.dart' show BackupResult;

/// Everything after joining a group (contracts/repositories.md). Fakes run
/// on shared_preferences; Supabase implementations call the Edge Functions.
abstract interface class DailyCommuteRepository {
  /// Member id of the person using the app.
  String get meId;

  /// The person's group with them included as a member; null when not in a
  /// group (e.g. removed after 3 no-shows).
  Future<CommuteGroup?> myGroup();

  /// Schedule for [from]..[to] inclusive (rotation + absences + backups).
  Future<List<ScheduleDay>> schedule(CalendarDate from, CalendarDate to);

  Future<Ride?> ride(CalendarDate date, Leg leg);

  Future<List<Absence>> absences(CalendarDate from, CalendarDate to);

  Future<List<StopCheckIn>> checkIns(String rideId);

  Future<List<PassengerOutcome>> outcomes(String rideId);

  // Rider actions (also used by off-duty drivers).

  /// Charges created; empty when the cancellation was free.
  Future<List<Charge>> cancel(CalendarDate date, Set<Leg> legs, WallTime madeAt);
  Future<UndoResult> undoCancel(CalendarDate date, WallTime now);
  Future<List<Charge>> notComingNextWeek(WallTime madeAt);

  // Driver actions.
  Future<void> setConfirmed(String rideId, bool confirmed);

  /// 5, 10 or 15 minutes; shifts every stop time of the ride.
  Future<void> reportDelay(String rideId, int minutes);
  Future<BackupResult> cantDrive(CalendarDate date, Set<Leg> legs, WallTime madeAt);
  Future<void> arrivedAt(String rideId, String stopId, WallTime at);

  /// Throws [AttendanceRefused] for a no-show before the 5-minute wait or
  /// any mark after the trip started.
  Future<void> mark(String rideId, String personId, Outcome outcome, WallTime at);
  Future<void> startTrip(String rideId, WallTime at);
  Future<void> endTrip(String rideId, WallTime at);

  // Results.
  /// Charges the person owes; shown and collected in 004.
  Future<List<Charge>> chargesOwed();
  Future<int> noShowsInMonth(String monthKey);
  Future<List<ReliabilityEvent>> events(CalendarDate from, CalendarDate to);

  // Notices.
  Stream<List<Notice>> notices();
  Future<void> markRead(String noticeId);
  Future<void> chooseNoCoverOption(CalendarDate date, Leg leg, NoCoverOption option);
}
