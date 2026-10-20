import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/wallet/domain/activity_entry.dart';
import 'package:goora/features/wallet/presentation/labels.dart';

import '../helpers/pump_app.dart';

/// 005 T039: a one-off seat row reads "Seat" with its 40 + 4 fee breakdown;
/// its refund reads "Refund" with no caption.
void main() {
  final seat = ActivityEntry(
    id: 'seat:bk-1',
    kind: ActivityKind.seatBooked,
    amount: 44,
    fee: 4,
    date: CalendarDate(2026, 10, 22),
    rideId: 'offer:t1',
  );
  final refund = ActivityEntry(
    id: 'refund:bk-1',
    kind: ActivityKind.seatRefund,
    amount: 44,
    date: CalendarDate(2026, 10, 22),
    rideId: 'offer:t1',
  );

  for (final locale in const [Locale('en'), Locale('ar')]) {
    test('seat and refund rows (${locale.languageCode})', () {
      final l10n = l10nFor(locale);
      expect(l10n.activityLabel(seat), l10n.actSeatBooked);
      expect(l10n.activityCaption(seat, contribution: 40), l10n.priceWithFee(40, 4));
      expect(l10n.activityLabel(refund), l10n.actSeatRefund);
      expect(l10n.activityCaption(refund, contribution: 40), isNull);
    });
  }

  test('S-2: a fee-free seat (subscriber) still names the driver share', () {
    final l10n = l10nFor(const Locale('en'));
    final free = ActivityEntry(id: 'seat:bk-2', kind: ActivityKind.seatBooked, amount: 40, date: CalendarDate(2026, 10, 22));
    expect(l10n.activityCaption(free, contribution: 40), l10n.priceNoFee(40));
    
    expect(l10n.priceNoFee(40), startsWith('40 EGP to the driver'));
  });
}
