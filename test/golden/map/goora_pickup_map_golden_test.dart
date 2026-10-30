import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/widgets/goora_pickup_map.dart';

import '../../helpers/pump_app.dart';
import '../../widget/map/map_test_helpers.dart';

/// 012: the pickup map card and the bigger sheet, offline sketch only (no
/// tile URL in tests → no network), ar + en at 1.3× text. Rendered on
/// Windows; regenerate with `flutter test --update-goldens test/golden/map`.
void main() {
  for (final locale in locales) {
    final dir = locale == ar ? 'rtl' : 'ltr';

    testWidgets('pickup map card 1.3× [$dir]', (tester) async {
      await pumpMapHost(tester, GooraPickupMap(pins: seedPins()), locale: locale, textScale: 1.3);
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/pickup_map_card_$dir.png'));
    });

    testWidgets('pickup map sheet 1.3× [$dir]', (tester) async {
      await pumpMapHost(tester, GooraPickupMap(pins: seedPins()), locale: locale, textScale: 1.3);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pickup-map-card')));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/pickup_map_sheet_$dir.png'));
    });
  }
}
