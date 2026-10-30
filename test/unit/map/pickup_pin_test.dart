import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/map/pickup_pin.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';

void main() {
  test('a pickup pin copies only the stop\'s public point', () {
    const stop = CorridorSeed.mainGate;
    final pin = PickupPin.pickup(stop, number: 1, title: 'Pickup · 7:20', place: 'Main gate');
    expect(pin.kind, PickupPinKind.pickup);
    expect((pin.lat, pin.lng), (stop.point.lat, stop.point.lng));
    expect(pin.number, 1);
    expect(pin.spoken(', '), 'Pickup · 7:20, Main gate');
  });

  test('an arrival pin has no number', () {
    final g = CorridorSeed.groups.first;
    final pin = PickupPin.arrival(g.workStop, title: 'Arrival · 8:05', place: 'Gate 2');
    expect(pin.kind, PickupPinKind.arrival);
    expect(pin.number, isNull);
    expect((pin.lat, pin.lng), (g.destinationPoint.lat, g.destinationPoint.lng));
  });

  test('pickup numbers start at 1', () {
    expect(
      () => PickupPin.pickup(CorridorSeed.mainGate, number: 0, title: 't', place: 'p'),
      throwsA(isA<AssertionError>()),
    );
  });
}
