import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/map/map_config.dart';

void main() {
  test('the build default has no tile URL, so tiles are off', () {
    // Tests never pass --dart-define=MAP_TILE_URL_TEMPLATE (research R8).
    expect(MapConfig.fromEnvironment().hasTiles, isFalse);
  });

  test('a blank template is still "no tiles"', () {
    expect(const MapConfig(urlTemplate: '   ').hasTiles, isFalse);
  });

  test('a template turns tiles on and passes the key as the {key} option', () {
    const c = MapConfig(urlTemplate: 'https://t.example/{z}/{x}/{y}.png?key={key}', apiKey: 'k1');
    expect(c.hasTiles, isTrue);
    expect(c.tileOptions, {'key': 'k1'});
  });

  test('no key → no {key} option', () {
    expect(const MapConfig(urlTemplate: 'https://t.example/{z}/{x}/{y}.png').tileOptions, isEmpty);
  });

  test('extra attribution is trimmed and optional', () {
    expect(const MapConfig(urlTemplate: 'u', extraAttribution: '  © Tiles Co  ').attributionExtra, '© Tiles Co');
    expect(const MapConfig(urlTemplate: 'u').attributionExtra, isNull);
  });
}
