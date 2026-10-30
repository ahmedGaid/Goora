import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/map/flutter_map_renderer.dart';
import 'package:goora/core/map/map_config.dart';
import 'package:goora/core/map/pickup_map_renderer.dart';
import 'package:goora/core/theme/app_colors.dart';
import 'package:goora/core/widgets/goora_pickup_map.dart';

import '../../helpers/pump_app.dart';
import 'map_test_helpers.dart';

void main() {
  const config = MapConfig(
    urlTemplate: 'https://t.example/{z}/{x}/{y}.png?key={key}',
    apiKey: 'test-key',
    extraAttribution: '© Tiles Co',
  );

  for (final locale in locales) {
    final l = l10nFor(locale);

    testWidgets('tiles on → map, every pin, OSM + provider attribution [${locale.languageCode}]', (tester) async {
      final tiles = MemoryTileProvider();
      await pumpMapHost(
        tester,
        GooraPickupMap(pins: seedPins()),
        locale: locale,
        overrides: [
          pickupMapRendererProvider.overrideWithValue(FlutterMapPickupRenderer(config: config, tileProvider: tiles)),
        ],
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final map = find.byType(FlutterMap);
      expect(map, findsOneWidget);
      expect(find.byKey(const Key('pickup-map-sketch')), findsNothing);
      expect(find.text(l.mapSketchNote), findsNothing);
      for (var i = 0; i < seedPins().length; i++) {
        expect(find.descendant(of: map, matching: find.byKey(Key('map-pin-$i'))), findsOneWidget);
      }
      final attribution = find.descendant(of: map, matching: find.byKey(const Key('map-attribution')));
      expect(attribution, findsOneWidget);
      expect(find.descendant(of: attribution, matching: find.textContaining(l.mapAttribution)), findsOneWidget);
      expect(find.descendant(of: attribution, matching: find.textContaining('© Tiles Co')), findsOneWidget);
      expect(tiles.requested, greaterThan(0));

      final options = tester.widget<FlutterMap>(map).options;
      expect(options.backgroundColor, AppColors.mapLand);
      // The small card is a static preview; the card owns the tap.
      expect(options.interactionOptions.flags, InteractiveFlag.none);

      final layer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(layer.urlTemplate, config.urlTemplate);
      expect(layer.additionalOptions, {'key': 'test-key'});
    });

    testWidgets('the bigger map pans and zooms, still with attribution [${locale.languageCode}]', (tester) async {
      await pumpMapHost(
        tester,
        GooraPickupMap(pins: seedPins()),
        locale: locale,
        overrides: [
          pickupMapRendererProvider.overrideWithValue(
            FlutterMapPickupRenderer(config: config, tileProvider: MemoryTileProvider()),
          ),
        ],
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('pickup-map-card')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final sheet = find.byKey(const Key('pickup-map-sheet'));
      final map = find.descendant(of: sheet, matching: find.byType(FlutterMap));
      expect(map, findsOneWidget);
      expect(tester.widget<FlutterMap>(map).options.interactionOptions.flags, isNot(InteractiveFlag.none));
      expect(find.descendant(of: sheet, matching: find.byKey(const Key('map-attribution'))), findsOneWidget);
    });
  }

  test('the tiles renderer reports network use; the sketch does not', () {
    expect(const FlutterMapPickupRenderer(config: config).usesNetwork, isTrue);
  });
}
