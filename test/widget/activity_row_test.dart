import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/commute/domain/commute_profile.dart' show Leg;
import 'package:goora/features/wallet/domain/activity_entry.dart';
import 'package:goora/features/wallet/presentation/wallet/activity_row.dart';

import '../helpers/pump_app.dart';

/// Walk nit N-10: a day with a going and a return trip showed two identical
/// rows. The date line now names the leg, so the two rows tell themselves apart.
ActivityEntry _trip(Leg? leg, {String id = 'a'}) => ActivityEntry(
      id: id,
      kind: ActivityKind.cashTrip,
      amount: 0,
      date: CalendarDate(2026, 10, 5),
      rideId: 'g:2026-10-05:${leg == Leg.ret ? 'return' : 'going'}',
      shareToDriver: 40,
      leg: leg,
    );

void main() {
  final lines = {
    ar: (going: '5 أكتوبر · الذهاب', ret: '5 أكتوبر · الرجوع', plain: '5 أكتوبر'),
    en: (going: '5 Oct · Going', ret: '5 Oct · Return', plain: '5 Oct'),
  };

  for (final locale in locales) {
    final code = locale.languageCode;
    final expected = lines[locale]!;

    testWidgets('[$code] the date line names the leg', (tester) async {
      await pumpScreen(
        tester,
        Column(children: [
          ActivityRow(entry: _trip(Leg.going, id: 'g'), contribution: 40),
          ActivityRow(entry: _trip(Leg.ret, id: 'r'), contribution: 40),
        ]),
        locale: locale,
      );
      expect(find.text(expected.going), findsOneWidget);
      expect(find.text(expected.ret), findsOneWidget);
    });

    testWidgets('[$code] a row with no leg shows the date alone', (tester) async {
      await pumpScreen(tester, ActivityRow(entry: _trip(null), contribution: 40), locale: locale);
      expect(find.text(expected.plain), findsOneWidget);
    });
  }

  test('a leg survives the JSON round trip; a missing one stays null', () {
    final withLeg = ActivityEntry.fromJson(_trip(Leg.ret).toJson());
    expect(withLeg.leg, Leg.ret);
    final without = ActivityEntry.fromJson(_trip(null).toJson());
    expect(without.leg, isNull);
    expect(ActivityEntry.fromJson({
      'id': 'old',
      'kind': 'topUp',
      'amount': 200,
      'date': '2026-10-05',
    }).leg, isNull, reason: 'rows stored before this field existed');
  });
}
