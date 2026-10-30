import '../../features/commute/domain/group.dart';

enum PickupPinKind { pickup, arrival }

/// One point on the pickup map. It can only be made from a group [Stop] — a
/// public meeting point — so a home location can never reach the map
/// (Constitution IV, 012 FR-002). Labels are stop names and times, never
/// people.
final class PickupPin {
  const PickupPin._({
    required this.kind,
    required this.lat,
    required this.lng,
    required this.title,
    required this.place,
    this.number,
  });

  /// [number] is the 1-based driving order.
  factory PickupPin.pickup(Stop stop, {required int number, required String title, required String place}) {
    assert(number >= 1, 'pickup numbers start at 1');
    return PickupPin._(
      kind: PickupPinKind.pickup,
      lat: stop.point.lat,
      lng: stop.point.lng,
      number: number,
      title: title,
      place: place,
    );
  }

  factory PickupPin.arrival(Stop stop, {required String title, required String place}) => PickupPin._(
        kind: PickupPinKind.arrival,
        lat: stop.point.lat,
        lng: stop.point.lng,
        title: title,
        place: place,
      );

  final PickupPinKind kind;
  final double lat;
  final double lng;
  final int? number;

  /// e.g. "التجمع · 7:20".
  final String title;

  /// The stop name.
  final String place;

  /// One legend line read aloud; [sep] is the locale's list separator.
  String spoken(String sep) => '$title$sep$place';
}
