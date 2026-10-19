import '../domain/corridor.dart';
import '../domain/place.dart';
import 'cairo_ismailia_seed.dart';
import 'corridor_seed.dart';

/// The corridors the fakes know (006 research R4).
abstract final class Corridors {
  /// The launch corridor and the app default (founder, 2026-10-16).
  static const cairoIsmailia = Corridor(
    id: 'cairo-ismailia',
    areas: [Area.newCairo, Area.nasrCity, Area.heliopolis, Area.obour, Area.tenthOfRamadan, Area.ismailia],
    homePlaces: CairoIsmailiaSeed.homePlaces,
    workPlaces: CairoIsmailiaSeed.workPlaces,
    defaultFrom: Area.newCairo,
    defaultTo: Area.ismailia,
    tripCost: 300,
    riderSeats: 3,
    minutes: CairoIsmailiaSeed.tripMinutes,
  );

  /// The first demo corridor, data unchanged; existing tests pin it.
  static const sheikhZayedSmartVillage = Corridor(
    id: 'sheikh-zayed-smart-village',
    areas: [Area.sheikhZayed, Area.october, Area.smartVillage],
    homePlaces: CorridorSeed.homePlaces,
    workPlaces: CorridorSeed.workPlaces,
    defaultFrom: Area.sheikhZayed,
    defaultTo: Area.smartVillage,
    tripCost: 160,
    riderSeats: 3,
    minutes: _oldMinutes,
  );

  static const all = [cairoIsmailia, sheikhZayedSmartVillage];

  static Corridor? byId(String id) => all.where((c) => c.id == id).firstOrNull;

  static int _oldMinutes(Area from, Area to) => from == to ? 0 : 40;
}
