import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/map/map_config.dart';
import 'package:goora/core/map/pickup_map_renderer.dart';
import 'package:goora/core/theme/app_sizes.dart';
import 'package:goora/core/widgets/goora_pickup_map.dart';

import '../../helpers/pump_app.dart';
import 'map_test_helpers.dart';

void main() {
  late HttpOverrides? previous;
  late CountingHttpOverrides http;

  setUp(() {
    previous = HttpOverrides.current;
    http = CountingHttpOverrides();
    HttpOverrides.global = http;
  });
  tearDown(() => HttpOverrides.global = previous);

  for (final locale in locales) {
    final l = l10nFor(locale);

    testWidgets('no tile URL → offline sketch, legend, note, zero network [${locale.languageCode}]', (tester) async {
      await pumpMapHost(tester, GooraPickupMap(pins: seedPins()), locale: locale);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pickup-map-sketch')), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text(l.mapCardTitle), findsOneWidget);
      expect(find.text(l.mapSketchNote), findsOneWidget);
      expect(find.text(l.mapAttribution), findsNothing);
      for (final p in seedPins()) {
        expect(find.text(p.title), findsOneWidget);
        expect(find.text(p.place), findsOneWidget);
      }
      final images = tester.widgetList<Image>(find.byType(Image));
      expect(images.where((i) => i.image is NetworkImage), isEmpty);
      expect(http.created, 0);
    });

    testWidgets('pin 1 sits on the start side [${locale.languageCode}]', (tester) async {
      await pumpMapHost(tester, GooraPickupMap(pins: seedPins()), locale: locale);
      await tester.pumpAndSettle();
      final sketch = find.byKey(const Key('pickup-map-sketch'));
      final first = tester.getCenter(find.descendant(of: sketch, matching: find.byKey(const Key('map-pin-0'))));
      final arrival = tester.getCenter(find.descendant(of: sketch, matching: find.byKey(const Key('map-pin-2'))));
      if (locale == ar) {
        expect(first.dx, greaterThan(arrival.dx));
      } else {
        expect(first.dx, lessThan(arrival.dx));
      }
    });

    testWidgets('the card is one ≥ 44 px button that reads the legend [${locale.languageCode}]', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpMapHost(tester, GooraPickupMap(pins: seedPins()), locale: locale);
      await tester.pumpAndSettle();
      final card = find.byKey(const Key('pickup-map-card'));
      final size = tester.getSize(card);
      expect(size.height, greaterThanOrEqualTo(AppSizes.minTouch));
      final points = [for (final p in seedPins()) p.spoken(l.listSep)].join(l.listSep);
      expect(
        tester.getSemantics(card),
        matchesSemantics(label: l.mapPointsAria(points), isButton: true, hasTapAction: true, onTapHint: l.mapOpen),
      );
      handle.dispose();
    });

    testWidgets('tap opens the bigger map; close shuts it [${locale.languageCode}]', (tester) async {
      await pumpMapHost(tester, GooraPickupMap(pins: seedPins()), locale: locale);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pickup-map-card')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pickup-map-sheet')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('pickup-map-sheet')), matching: find.text(l.mapSketchNote)), findsOneWidget);
      await tester.tap(find.byKey(const Key('pickup-map-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pickup-map-sheet')), findsNothing);
    });
  }

  testWidgets('pins are not tappable — no free-point picking (FR-001)', (tester) async {
    await pumpMapHost(tester, GooraPickupMap(pins: seedPins()));
    await tester.pumpAndSettle();
    final sketch = find.byKey(const Key('pickup-map-sketch'));
    expect(find.descendant(of: sketch, matching: find.byType(GestureDetector)), findsNothing);
    expect(find.descendant(of: sketch, matching: find.byType(InkWell)), findsNothing);
  });

  testWidgets('one provider swaps the renderer for every map (FR-012)', (tester) async {
    await pumpMapHost(
      tester,
      GooraPickupMap(pins: seedPins()),
      overrides: [pickupMapRendererProvider.overrideWithValue(const _FakeRenderer())],
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fake-renderer')), findsOneWidget);
    expect(find.byKey(const Key('pickup-map-sketch')), findsNothing);
  });

  test('the default config picks the sketch; a tile URL picks the tiles renderer', () {
    final offline = ProviderContainer();
    addTearDown(offline.dispose);
    expect(offline.read(pickupMapRendererProvider).usesNetwork, isFalse);

    final tiles = ProviderContainer(
      overrides: [mapConfigProvider.overrideWithValue(const MapConfig(urlTemplate: 'https://t.example/{z}/{x}/{y}.png'))],
    );
    addTearDown(tiles.dispose);
    expect(tiles.read(pickupMapRendererProvider).usesNetwork, isTrue);
  });

  testWidgets('one point only is centred, at 1.3× text with no overflow', (tester) async {
    await pumpMapHost(tester, GooraPickupMap(pins: [seedPins().last]), locale: ar, textScale: 1.3);
    await tester.pumpAndSettle();
    final sketch = tester.getRect(find.byKey(const Key('pickup-map-sketch')));
    final pin = tester.getCenter(find.byKey(const Key('map-pin-0')));
    expect((pin.dx - sketch.center.dx).abs(), lessThan(1));
    expect(tester.takeException(), isNull);
  });
}

final class _FakeRenderer implements PickupMapRenderer {
  const _FakeRenderer();

  @override
  bool get usesNetwork => false;

  @override
  Widget render(BuildContext context, PickupMapScene scene) => const SizedBox.expand(key: Key('fake-renderer'));
}
