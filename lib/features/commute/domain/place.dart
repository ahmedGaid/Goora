import 'geo.dart';

/// Launch-corridor areas. Shown to people by name only (l10n), never as points.
enum Area { sheikhZayed, october, smartVillage }

final class Place {
  const Place({required this.id, required this.area, required this.point});

  final String id;
  final Area area;

  /// Private: never displayed, never shared with other people.
  final GeoPoint point;

  Map<String, Object?> toJson() => {'id': id, 'area': area.name, 'point': point.toJson()};

  static Place fromJson(Map<String, Object?> json) => Place(
        id: json['id']! as String,
        area: Area.values.byName(json['area']! as String),
        point: GeoPoint.fromJson((json['point']! as Map).cast<String, Object?>()),
      );
}
