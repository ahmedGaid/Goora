import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/domain/geo.dart';
import 'package:goora/features/commute/domain/group.dart';

/// Field-by-field equality for groups (the model has no `==`).
void expectSameGroup(CommuteGroup actual, CommuteGroup expected) {
  final why = expected.id;
  expect(actual.id, expected.id);
  expect(actual.origin, expected.origin, reason: why);
  expect(actual.destination, expected.destination, reason: why);
  _point(actual.destinationPoint, expected.destinationPoint, why);
  expect(actual.pickupPoints, hasLength(expected.pickupPoints.length), reason: why);
  for (var i = 0; i < expected.pickupPoints.length; i++) {
    _point(actual.pickupPoints[i], expected.pickupPoints[i], why);
  }
  expect(actual.going, expected.going, reason: why);
  expect(actual.ret, expected.ret, reason: why);
  expect(actual.days, expected.days, reason: why);
  expect(actual.price, expected.price, reason: why);
  expect(actual.freeSeatsGoing, expected.freeSeatsGoing, reason: why);
  expect(actual.freeSeatsReturn, expected.freeSeatsReturn, reason: why);
  expect(actual.tripCost, expected.tripCost, reason: why);
  expect(actual.riderSeats, expected.riderSeats, reason: why);
  expect(actual.detourMinutes, expected.detourMinutes, reason: why);
  expect(actual.womenOnly, expected.womenOnly, reason: why);
  expect(actual.sameCompanyOnly, expected.sameCompanyOnly, reason: why);
  expect(actual.sameCompoundOnly, expected.sameCompoundOnly, reason: why);
  expect(actual.stops, hasLength(expected.stops.length), reason: why);
  for (var i = 0; i < expected.stops.length; i++) {
    expectSameStop(actual.stops[i], expected.stops[i]);
  }
  expect(actual.arrival, expected.arrival, reason: why);
  expect(actual.arrivalName, expected.arrivalName, reason: why);
  expect(actual.rotationStart, expected.rotationStart, reason: why);
  expect(actual.members.map((m) => m.id), expected.members.map((m) => m.id), reason: why);
  for (var i = 0; i < expected.members.length; i++) {
    expectSameMember(actual.members[i], expected.members[i]);
  }
}

void expectSameMember(Member actual, Member expected) {
  final why = expected.id;
  expect(actual.id, expected.id);
  expect(actual.firstName, expected.firstName, reason: why);
  expect(actual.initials, expected.initials, reason: why);
  expect(actual.role, expected.role, reason: why);
  expect(actual.isWoman, expected.isWoman, reason: why);
  expect(actual.company, expected.company, reason: why);
  expect(actual.compound, expected.compound, reason: why);
  expect(actual.rating, expected.rating, reason: why);
  expect(actual.reliability, expected.reliability, reason: why);
  expect(actual.legs, expected.legs, reason: why);
  expect(actual.seats, expected.seats, reason: why);
  expect(actual.vehicle?.make, expected.vehicle?.make, reason: why);
  expect(actual.vehicle?.colour, expected.vehicle?.colour, reason: why);
  expect(actual.phone, expected.phone, reason: why);
  expect(actual.privacy, expected.privacy, reason: why);
  expect(actual.days, expected.days, reason: why);
}

void expectSameStop(Stop actual, Stop expected) {
  expect(actual.id, expected.id);
  expect(actual.name, expected.name, reason: expected.id);
  _point(actual.point, expected.point, expected.id);
  expect(actual.time, expected.time, reason: expected.id);
}

void _point(GeoPoint actual, GeoPoint expected, String why) {
  expect(actual.lat, expected.lat, reason: why);
  expect(actual.lng, expected.lng, reason: why);
}
