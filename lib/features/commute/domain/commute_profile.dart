import 'clock.dart';
import 'place.dart';

/// Sunday-first, as Egyptian working weeks are written.
enum Day { sun, mon, tue, wed, thu, fri, sat }

enum Leg { going, ret }

enum DrivenTrips {
  both({Leg.going, Leg.ret}),
  going({Leg.going}),
  ret({Leg.ret});

  const DrivenTrips(this.legs);
  final Set<Leg> legs;

  int get tripsPerDay => legs.length;
}

final class DriverOffer {
  const DriverOffer({required this.seats, required this.trips, required this.contribution});

  static const minSeats = 1;
  static const maxSeats = 4;
  static const defaultSeats = 3;

  final int seats;
  final DrivenTrips trips;

  /// EGP per rider per trip.
  final int contribution;

  DriverOffer copyWith({int? seats, DrivenTrips? trips, int? contribution}) => DriverOffer(
        seats: seats ?? this.seats,
        trips: trips ?? this.trips,
        contribution: contribution ?? this.contribution,
      );

  Map<String, Object?> toJson() => {'seats': seats, 'trips': trips.name, 'contribution': contribution};

  static DriverOffer fromJson(Map<String, Object?> j) => DriverOffer(
        seats: j['seats']! as int,
        trips: DrivenTrips.values.byName(j['trips']! as String),
        contribution: j['contribution']! as int,
      );
}

enum CommuteProblem { missingPlace, sameArea, noDays, returnBeforeDeparture }

final class CommuteProfile {
  const CommuteProfile({
    required this.home,
    required this.work,
    required this.departure,
    required this.ret,
    required this.days,
    this.driver,
  });

  static const defaultDeparture = Clock.hm(7, 30);
  static const defaultReturn = Clock.hm(17, 0);
  static const defaultDays = {Day.sun, Day.mon, Day.tue, Day.wed, Day.thu};

  /// Home and work must be farther apart than the destination match radius.
  static const minHomeWorkMeters = 1500.0;

  final Place? home;
  final Place? work;
  final Clock departure;
  final Clock ret;
  final Set<Day> days;
  final DriverOffer? driver;

  CommuteProblem? get problem {
    if (home == null || work == null) return CommuteProblem.missingPlace;
    if (home!.point.distanceTo(work!.point) <= minHomeWorkMeters) return CommuteProblem.sameArea;
    if (days.isEmpty) return CommuteProblem.noDays;
    if (ret.compareTo(departure) <= 0) return CommuteProblem.returnBeforeDeparture;
    return null;
  }

  CommuteProfile copyWith({
    Place? home,
    Place? work,
    Clock? departure,
    Clock? ret,
    Set<Day>? days,
    DriverOffer? driver,
    bool clearDriver = false,
  }) =>
      CommuteProfile(
        home: home ?? this.home,
        work: work ?? this.work,
        departure: departure ?? this.departure,
        ret: ret ?? this.ret,
        days: days ?? this.days,
        driver: clearDriver ? null : driver ?? this.driver,
      );

  Map<String, Object?> toJson() => {
        'home': home?.toJson(),
        'work': work?.toJson(),
        'departure': departure.minutes,
        'ret': ret.minutes,
        'days': [for (final d in Day.values) if (days.contains(d)) d.name],
        'driver': driver?.toJson(),
      };

  static CommuteProfile fromJson(Map<String, Object?> j) {
    Map<String, Object?>? map(Object? o) => o == null ? null : (o as Map).cast<String, Object?>();
    final home = map(j['home']);
    final work = map(j['work']);
    final driver = map(j['driver']);
    return CommuteProfile(
      home: home == null ? null : Place.fromJson(home),
      work: work == null ? null : Place.fromJson(work),
      departure: Clock(j['departure']! as int),
      ret: Clock(j['ret']! as int),
      days: {for (final d in (j['days']! as List).cast<String>()) Day.values.byName(d)},
      driver: driver == null ? null : DriverOffer.fromJson(driver),
    );
  }
}
