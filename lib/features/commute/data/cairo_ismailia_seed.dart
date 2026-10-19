import '../domain/clock.dart';
import '../domain/geo.dart';
import '../domain/group.dart';
import '../domain/place.dart';

/// Cairo ↔ Ismailia launch corridor (006): one place and one named meeting
/// point per area. Points are approximate area centres, recalled (not
/// map-checked, research R7), used only for matching distances and never
/// shown. Groups come in P5.
abstract final class CairoIsmailiaSeed {
  static const _newCairo = GeoPoint(30.03, 31.47); // recalled
  static const _nasrCity = GeoPoint(30.06, 31.34); // recalled
  static const _heliopolis = GeoPoint(30.09, 31.32); // recalled
  static const _obour = GeoPoint(30.23, 31.48); // recalled
  static const _tenthOfRamadan = GeoPoint(30.29, 31.75); // recalled
  static const _ismailia = GeoPoint(30.60, 32.27); // recalled

  static const homeNewCairo = Place(id: 'home-nc', area: Area.newCairo, point: _newCairo);
  static const homeNasrCity = Place(id: 'home-nasr', area: Area.nasrCity, point: _nasrCity);
  static const homeHeliopolis = Place(id: 'home-heli', area: Area.heliopolis, point: _heliopolis);
  static const homeObour = Place(id: 'home-obour', area: Area.obour, point: _obour);
  static const homeTenthOfRamadan = Place(id: 'home-10r', area: Area.tenthOfRamadan, point: _tenthOfRamadan);
  static const homeIsmailia = Place(id: 'home-ism', area: Area.ismailia, point: _ismailia);

  static const workNewCairo = Place(id: 'work-nc', area: Area.newCairo, point: _newCairo);
  static const workNasrCity = Place(id: 'work-nasr', area: Area.nasrCity, point: _nasrCity);
  static const workHeliopolis = Place(id: 'work-heli', area: Area.heliopolis, point: _heliopolis);
  static const workIsmailia = Place(id: 'work-ism', area: Area.ismailia, point: _ismailia);

  static const homePlaces = [homeNewCairo, homeNasrCity, homeHeliopolis, homeObour, homeTenthOfRamadan, homeIsmailia];

  /// Obour and 10th of Ramadan are road towns: homes, not workplaces.
  static const workPlaces = [workNewCairo, workNasrCity, workHeliopolis, workIsmailia];

  /// The public meeting point of each area (never a home); its name is
  /// [StopName.meetingPointOf].
  static const meetingPoints = <Area, GeoPoint>{
    Area.newCairo: _newCairo,
    Area.nasrCity: _nasrCity,
    Area.heliopolis: _heliopolis,
    Area.obour: _obour,
    Area.tenthOfRamadan: _tenthOfRamadan,
    Area.ismailia: _ismailia,
  };

  /// The meeting point in [area] as a stop at [time].
  static Stop stopIn(Area area, String id, Clock time) =>
      Stop(id: id, name: StopName.meetingPointOf(area), point: meetingPoints[area]!, time: time);

  /// Cairo district ↔ Ismailia 105 min (middle of the verified 1h30–2h band,
  /// R1); road town ↔ Ismailia 90; anywhere on the Cairo side 30.
  static int tripMinutes(Area from, Area to) {
    if (from == to) return 0;
    if (from != Area.ismailia && to != Area.ismailia) return 30;
    final other = from == Area.ismailia ? to : from;
    return other == Area.obour || other == Area.tenthOfRamadan ? 90 : 105;
  }
}
