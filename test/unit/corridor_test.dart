import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/l10n/app_localizations.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/features/commute/data/cairo_ismailia_seed.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';
import 'package:goora/features/commute/data/corridors.dart';
import 'package:goora/features/commute/data/providers.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/geo.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/commute/presentation/labels.dart';
import 'package:goora/features/daily/presentation/labels.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Area (saved data)', () {
    test('old area names still load', () {
      for (final name in ['sheikhZayed', 'october', 'smartVillage']) {
        final place = Place.fromJson({
          'id': 'p',
          'area': name,
          'point': const GeoPoint(30, 31).toJson(),
        });
        expect(place.area.name, name);
      }
    });

    test('a new area round-trips', () {
      final back = Place.fromJson(CairoIsmailiaSeed.homeIsmailia.toJson());
      expect(back.area, Area.ismailia);
      expect(back.id, 'home-ism');
    });
  });

  group('Corridor', () {
    const ci = Corridors.cairoIsmailia;
    const old = Corridors.sheikhZayedSmartVillage;

    test('no area belongs to two corridors', () {
      expect(ci.areas.toSet().intersection(old.areas.toSet()), isEmpty);
    });

    test('places and defaults stay inside the corridor', () {
      for (final c in Corridors.all) {
        expect(c.areas, contains(c.defaultFrom));
        expect(c.areas, contains(c.defaultTo));
        for (final p in [...c.homePlaces, ...c.workPlaces]) {
          expect(c.areas, contains(p.area), reason: '${c.id} ${p.id}');
        }
      }
    });

    test('Cairo ↔ Ismailia: 300 EGP over 3 rider seats (R2 placeholder)', () {
      expect(ci.tripCost, 300);
      expect(ci.riderSeats, 3);
      expect(ci.defaultFrom, Area.newCairo);
      expect(ci.defaultTo, Area.ismailia);
    });

    test('old corridor keeps its data: 160 EGP, 3 seats, 40 min', () {
      expect(old.tripCost, 160);
      expect(old.riderSeats, 3);
      expect(old.tripMinutes(Area.sheikhZayed, Area.smartVillage), 40);
      expect(old.homePlaces.map((p) => p.id), ['home-sz', 'home-oct']);
      expect(old.workPlaces.map((p) => p.id), ['work-sv']);
    });

    test('trip minutes: Cairo district ↔ Ismailia 105, road town ↔ Ismailia 90', () {
      expect(ci.tripMinutes(Area.newCairo, Area.ismailia), 105);
      expect(ci.tripMinutes(Area.nasrCity, Area.ismailia), 105);
      expect(ci.tripMinutes(Area.heliopolis, Area.ismailia), 105);
      expect(ci.tripMinutes(Area.obour, Area.ismailia), 90);
      expect(ci.tripMinutes(Area.tenthOfRamadan, Area.ismailia), 90);
    });

    test('trip minutes are the same both ways', () {
      for (final c in Corridors.all) {
        for (final a in c.areas) {
          for (final b in c.areas) {
            expect(c.tripMinutes(a, b), c.tripMinutes(b, a), reason: '${c.id} $a $b');
          }
        }
      }
    });

    test('byId finds each corridor; unknown id is null', () {
      for (final c in Corridors.all) {
        expect(Corridors.byId(c.id), same(c));
      }
      expect(Corridors.byId('nowhere'), isNull);
    });
  });

  group('Stops', () {
    test('each new-corridor area has its own meeting point', () {
      for (final a in Corridors.cairoIsmailia.areas) {
        final stop = CairoIsmailiaSeed.stopIn(a, 's', const Clock.hm(6, 30));
        expect(stop.name, StopName.meetingPointOf(a));
        expect(stop.point, CairoIsmailiaSeed.meetingPoints[a]);
      }
    });

    test('a group with no named arrival ends at its own area, never Smart Village', () {
      final g = CommuteGroup(
        id: 'ci-test',
        origin: Area.newCairo,
        destination: Area.ismailia,
        destinationPoint: CairoIsmailiaSeed.meetingPoints[Area.ismailia]!,
        pickupPoints: [CairoIsmailiaSeed.meetingPoints[Area.newCairo]!],
        going: const Clock.hm(6, 30),
        ret: const Clock.hm(16, 30),
        days: const {},
        members: const [],
        price: 76,
        freeSeatsGoing: 1,
        freeSeatsReturn: 1,
        tripCost: 300,
        riderSeats: 3,
        detourMinutes: 4,
      );
      expect(g.workStop.name, StopName.ismailiaMeet);
    });
  });

  group('Labels', () {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      test('every area and stop has a ${locale.languageCode} name', () {
        final l10n = lookupAppLocalizations(locale);
        for (final a in Area.values) {
          expect(l10n.area(a).trim(), isNotEmpty, reason: '$a');
        }
        for (final s in StopName.values) {
          expect(l10n.stopName(s).trim(), isNotEmpty, reason: '$s');
        }
      });
    }

    test('new names differ between Arabic and English', () {
      final ar = lookupAppLocalizations(const Locale('ar'));
      final en = lookupAppLocalizations(const Locale('en'));
      for (final a in Corridors.cairoIsmailia.areas) {
        expect(ar.area(a), isNot(en.area(a)), reason: '$a');
      }
    });
  });

  group('activeCorridor', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    ProviderContainer container() {
      final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(c.dispose);
      return c;
    }

    test('defaults to Cairo ↔ Ismailia', () {
      expect(container().read(activeCorridorProvider), same(Corridors.cairoIsmailia));
    });

    test('a switch is saved and survives a restart', () async {
      await container().read(activeCorridorProvider.notifier).select(Corridors.sheikhZayedSmartVillage);
      expect(container().read(activeCorridorProvider), same(Corridors.sheikhZayedSmartVillage));
    });

    test('reset (key removed) brings the default back', () async {
      final c = container();
      await c.read(activeCorridorProvider.notifier).select(Corridors.sheikhZayedSmartVillage);
      await prefs.remove(ActiveCorridor.storageKey);
      c.invalidate(activeCorridorProvider);
      expect(c.read(activeCorridorProvider), same(Corridors.cairoIsmailia));
    });

    test('an unknown saved id falls back to the default', () async {
      await prefs.setString(ActiveCorridor.storageKey, 'gone');
      expect(container().read(activeCorridorProvider), same(Corridors.cairoIsmailia));
    });

    // 006 P5 wiring: the group catalog seeds the active corridor's groups.
    test('the group catalog holds the active corridor\'s seeded groups', () async {
      expect(container().read(groupCatalogProvider).all().map((g) => g.id), CairoIsmailiaSeed.groups.map((g) => g.id));
      await prefs.setString(ActiveCorridor.storageKey, Corridors.sheikhZayedSmartVillage.id);
      expect(container().read(groupCatalogProvider).all().map((g) => g.id), CorridorSeed.groups.map((g) => g.id));
    });
  });

  group('leg rule (R5)', () {
    const ci = Corridors.cairoIsmailia;
    const old = Corridors.sheikhZayedSmartVillage;

    test('leaving home is going, coming home is return', () {
      expect(ci.legOf(Area.newCairo, Area.ismailia, home: Area.newCairo, work: Area.ismailia), Leg.going);
      expect(ci.legOf(Area.ismailia, Area.newCairo, home: Area.newCairo, work: Area.ismailia), Leg.ret);
    });

    test('someone who lives in Ismailia goes to Cairo in the morning', () {
      expect(ci.legOf(Area.ismailia, Area.nasrCity, home: Area.ismailia, work: Area.nasrCity), Leg.going);
      expect(ci.legOf(Area.nasrCity, Area.ismailia, home: Area.ismailia, work: Area.nasrCity), Leg.ret);
    });

    test('no saved commute: from the default origin is going, back is return', () {
      expect(ci.legOf(ci.defaultFrom, ci.defaultTo), Leg.going);
      expect(ci.legOf(ci.defaultTo, ci.defaultFrom), Leg.ret);
    });

    test('no saved commute: another Cairo area towards Ismailia is still going', () {
      expect(ci.legOf(Area.heliopolis, Area.ismailia), Leg.going);
      expect(ci.legOf(Area.ismailia, Area.heliopolis), Leg.ret);
    });

    test('neither end is home: leaving the work end is return', () {
      expect(ci.legOf(Area.heliopolis, Area.ismailia, home: Area.nasrCity, work: Area.ismailia), Leg.going);
      expect(ci.legOf(Area.ismailia, Area.heliopolis, home: Area.nasrCity, work: Area.ismailia), Leg.ret);
    });

    test('old corridor keeps its rule: only leaving Smart Village is return', () {
      expect(old.legOf(Area.sheikhZayed, Area.smartVillage), Leg.going);
      expect(old.legOf(Area.october, Area.smartVillage), Leg.going);
      expect(old.legOf(Area.smartVillage, Area.sheikhZayed), Leg.ret);
      expect(old.legOf(Area.october, Area.smartVillage, home: Area.sheikhZayed, work: Area.smartVillage), Leg.going);
      expect(old.legOf(Area.smartVillage, Area.october, home: Area.october, work: Area.smartVillage), Leg.ret);
    });
  });
}
