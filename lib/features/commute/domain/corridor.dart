import 'commute_profile.dart';
import 'place.dart';

/// Minutes a trip takes between two areas of one corridor.
typedef TripMinutes = int Function(Area from, Area to);

/// One commute corridor: its areas, the places people pick, the demo trip
/// cost and how long its trips take (006 research R4). Exactly one corridor
/// is active; screens read it instead of a fixed area list.
final class Corridor {
  const Corridor({
    required this.id,
    required this.areas,
    required this.homePlaces,
    required this.workPlaces,
    required this.defaultFrom,
    required this.defaultTo,
    required this.tripCost,
    required this.riderSeats,
    required this.minutes,
  });

  /// Saved as the active-corridor setting.
  final String id;

  /// Shown in filters and route forms, in this order.
  final List<Area> areas;
  final List<Place> homePlaces;
  final List<Place> workPlaces;

  /// Post your trip / Offer a trip start here.
  final Area defaultFrom;
  final Area defaultTo;

  /// Demo trip cost per leg in EGP and the rider seats sharing it
  /// (unverified placeholder for Cairo ↔ Ismailia, research R2).
  final int tripCost;
  final int riderSeats;

  /// Trip length between two of [areas]; same both ways (research R6).
  final TripMinutes minutes;

  int tripMinutes(Area from, Area to) => minutes(from, to);

  /// Which leg a trip from [from] to [to] is (research R5): going when it
  /// leaves the person's [home], return when it ends there. When neither end
  /// is home (or there is no saved commute), only leaving the work end —
  /// [work], else [defaultTo] — is return, so a Cairo area other than home
  /// heading to Ismailia is still going.
  Leg legOf(Area from, Area to, {Area? home, Area? work}) {
    if (home != null && from == home) return Leg.going;
    if (home != null && to == home) return Leg.ret;
    return from == (work ?? defaultTo) ? Leg.ret : Leg.going;
  }
}
