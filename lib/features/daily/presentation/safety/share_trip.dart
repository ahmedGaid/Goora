import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../commute/domain/commute_profile.dart';
import '../../../commute/presentation/labels.dart';
import '../../data/providers.dart';
import '../../domain/schedule.dart';
import '../labels.dart';
import '../today/today_controller.dart';

/// Shares the next trip: areas, driver first name, car, expected arrival and
/// a trip link. Never a home location (FR-031). The live link page arrives
/// with US7; the token is stable per ride until then.
Future<void> shareTrip(BuildContext context, WidgetRef ref, TodayView v) async {
  final l10n = AppLocalizations.of(context);
  final g = v.group;
  final leg = v.display?.legs.where((l) => l.duty != Duty.off && !l.overAt(v.now)).firstOrNull;
  if (g == null || leg == null || leg.ride == null) return;
  final driver = leg.driver;
  final vehicle = driver?.vehicle;
  final going = leg.leg == Leg.going;
  final text = l10n.shareMessage(
    driver?.firstName ?? '',
    vehicle == null ? '' : l10n.carColour(vehicle.make, l10n.colour(vehicle.colour)),
    l10n.area(going ? g.origin : g.destination),
    l10n.area(going ? g.destination : g.origin),
    l10n.time(leg.end.time),
    '${Env.shareBaseUrl}/t/${leg.ride!.shareToken ?? _token(leg.ride!.id)}',
  );
  await ref.read(tripSharerProvider).share(text);
}

/// 16 hex characters derived from the ride id (FNV-1a), so the link names
/// no group, date or person.
String _token(String rideId) {
  var h = 0xcbf29ce484222325;
  for (final c in rideId.codeUnits) {
    h = (h ^ c) * 0x100000001b3;
  }
  return h.toUnsigned(64).toRadixString(16).padLeft(16, '0');
}
