import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../commute/domain/commute_profile.dart';
import '../../../commute/presentation/labels.dart';
import '../../data/providers.dart';
import '../labels.dart';
import '../today/today_controller.dart';

/// Shares the next trip: areas, driver first name, car, expected arrival and
/// a trip link. Never a home location (FR-031). The token is random,
/// stored with the ride, and names no group, date or person. With no
/// current trip it says there is nothing to share.
Future<void> shareTrip(BuildContext context, WidgetRef ref, TodayView v) async {
  final l10n = AppLocalizations.of(context);
  final g = v.group;
  final leg = v.currentTrip;
  if (g == null || leg == null || leg.ride?.shareToken == null) {
    // Nothing to share yet: say so instead of a dead button (FR-029).
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.shareNoTrip)));
    return;
  }
  final driver = leg.driver;
  final vehicle = driver?.vehicle;
  final going = leg.leg == Leg.going;
  final text = l10n.shareMessage(
    driver?.firstName ?? '',
    vehicle == null ? '' : l10n.carColour(vehicle.make, l10n.colour(vehicle.colour)),
    l10n.area(going ? g.origin : g.destination),
    l10n.area(going ? g.destination : g.origin),
    l10n.time(leg.end.time),
    '${Env.shareBaseUrl}/t/${leg.ride!.shareToken}',
  );
  await ref.read(tripSharerProvider).share(text);
}
