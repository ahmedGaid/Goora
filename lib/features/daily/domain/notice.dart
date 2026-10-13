import '../../../core/time/wall_time.dart';
import 'trust.dart';

enum NoticeKind {
  driverConfirmed,
  driverUnconfirmed,
  delay,
  backupCover,
  noCover,
  driverArrived,
  lateCancelCharged,
  noShowCharged,
  noShowWarning,
  removed,
  seatOffered,
  sosSent,
  driverNoShow,
  seatBooked,
  seatReclaimed,
  requestAccepted,
  requestExpired,
  tripCancelledByDriver,
}

/// An in-app notification (research R11). [toMe] is false for notices the
/// person's own driver actions sent to their riders; the fake inbox shows
/// both so the demo can see what riders were told.
final class Notice {
  const Notice({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.params = const {},
    this.read = false,
    this.toMe = true,
  });

  final String id;
  final NoticeKind kind;
  final WallTime createdAt;

  /// Values for the localized text: `driver`, `day` (ISO date), `time`
  /// (minutes since midnight), `minutes`, `amount`, `stop`, `leg`.
  final Map<String, String> params;
  final bool read;
  final bool toMe;

  Notice markedRead() =>
      Notice(id: id, kind: kind, createdAt: createdAt, params: params, read: true, toMe: toMe);

  Map<String, Object?> toJson() => {
        'id': id,
        'kind': kind.name,
        'createdAt': createdAt.toJson(),
        'params': params,
        'read': read,
        'toMe': toMe,
      };

  static Notice fromJson(Map<String, Object?> j) => Notice(
        id: j['id']! as String,
        kind: NoticeKind.values.byName(j['kind']! as String),
        createdAt: WallTime.fromJson(j['createdAt']! as String),
        params: (j['params']! as Map).cast<String, String>(),
        read: j['read']! as bool,
        toMe: j['toMe'] as bool? ?? true,
      );
}

/// What a rider can do when no backup driver was found (FR-020).
enum NoCoverOption { emptySeat, postTrip, dayOff }

/// What the marketplace may do to 003's inbox and reliability record without
/// importing the daily feature (research R9, FR-017). `FakeDailyCommuteRepository`
/// implements it; posted notices reach the bell/inbox stream unchanged.
abstract interface class NoticeSink {
  /// Params: `day` (ISO date), `driver`, `amount`.
  Future<void> post(NoticeKind kind, Map<String, String> params);

  /// Appends to 003's reliability events. The marketplace calls it with
  /// [ReliabilityEventKind.lateCantDrive], rideId `offer:<tripId>`, only for a
  /// driver cancel after the 9 PM cut-off on a trip with at least one booking
  /// (R9); this seam does not check that.
  Future<void> recordReliability(ReliabilityEvent event);
}
