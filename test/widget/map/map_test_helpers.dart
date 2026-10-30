import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/l10n/app_localizations.dart';
import 'package:goora/core/map/pickup_pin.dart';
import 'package:goora/core/theme/app_spacing.dart';
import 'package:goora/core/theme/app_theme.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';

import '../../helpers/pump_app.dart';

/// Two pickups and the arrival of the seeded sz-0725 group — public stops only.
List<PickupPin> seedPins() {
  final g = CorridorSeed.groups.first;
  return [
    PickupPin.pickup(CorridorSeed.mainGate, number: 1, title: 'Pickup · 7:20', place: 'Main gate'),
    PickupPin.pickup(CorridorSeed.centralSt, number: 2, title: 'Pickup · 7:25', place: 'Central St.'),
    PickupPin.arrival(g.workStop, title: 'Arrival · 8:05', place: 'Smart Village gate 2'),
  ];
}

Future<void> pumpMapHost(
  WidgetTester tester,
  Widget child, {
  Locale locale = en,
  List<Override> overrides = const [],
  double textScale = 1,
}) async {
  await loadAppFonts();
  usePhoneSize(tester, textScale: textScale);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: locales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light(locale),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(AppSpacing.tabH),
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// Counts every HttpClient the code under test asks for.
final class CountingHttpOverrides extends HttpOverrides {
  int created = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    created++;
    return super.createHttpClient(context);
  }
}

/// Tiles from memory: the tiles path is tested with zero network (R8).
final class MemoryTileProvider extends TileProvider {
  MemoryTileProvider();

  int requested = 0;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    requested++;
    return MemoryImage(transparentPng);
  }
}

final transparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);
