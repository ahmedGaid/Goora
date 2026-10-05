import 'dart:math' as math;

final class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;

  static const _earthRadiusMeters = 6371000.0;

  /// Great-circle (haversine) distance in metres.
  double distanceTo(GeoPoint other) {
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(other.lat - lat);
    final dLng = rad(other.lng - lng);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat)) * math.cos(rad(other.lat)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadiusMeters * math.asin(math.sqrt(a));
  }

  Map<String, Object?> toJson() => {'lat': lat, 'lng': lng};

  static GeoPoint fromJson(Map<String, Object?> json) =>
      GeoPoint((json['lat']! as num).toDouble(), (json['lng']! as num).toDouble());
}
