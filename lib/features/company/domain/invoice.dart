import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/clock.dart';
import '../../wallet/domain/direct_pay.dart';
import 'company.dart';
import 'company_rules.dart';

/// `overdue` is derived: unpaid after the due day (data-model.md).
enum InvoiceStatus { issued, paid, overdue }

/// One company's bill for one calendar month (FR-011). A record only: the
/// company pays by bank transfer outside the app and Goora staff mark it paid
/// (FR-012); real issuing waits behind `CompanyFlags.companyInvoicesLive`.
final class Invoice {
  const Invoice({
    required this.id,
    required this.companyId,
    required this.month,
    required this.peakEnrolled,
    required this.billedSeats,
    required this.pricePerSeat,
    required this.total,
    required this.issuedOn,
    required this.dueOn,
    required this.reference,
    this.paidAt,
    this.bankRef,
  });

  /// The invoice for [month] (any day in it), issued at 00:00 on the 1st of
  /// the month after, from that month's peak enrolled (no pro-rating).
  factory Invoice.issue({required Company company, required CalendarDate month, required int peakEnrolled}) {
    final first = CalendarDate(month.year, month.month, 1);
    final issuedOn = first.addMonths(1);
    final seats = CompanyRules.billedSeats(peakEnrolled, company.minimumSeats);
    return Invoice(
      id: idFor(company.id, first.monthKey),
      companyId: company.id,
      month: first.monthKey,
      peakEnrolled: peakEnrolled,
      billedSeats: seats,
      pricePerSeat: company.pricePerSeat,
      total: CompanyRules.invoiceTotal(seats, company.pricePerSeat),
      issuedOn: issuedOn,
      dueOn: _date(CompanyRules.dueDay(SharePolicy.dayOf(issuedOn))),
      reference: 'GR-${company.shortId}-${first.monthKey.replaceAll('-', '')}',
    );
  }

  static String idFor(String companyId, String monthKey) => 'inv-$companyId-$monthKey';

  /// `inv-<companyId>-<yyyy-mm>`.
  final String id;
  final String companyId;

  /// `yyyy-mm` of the month billed.
  final String month;
  final int peakEnrolled;

  /// max(minimum seats, [peakEnrolled]).
  final int billedSeats;
  final int pricePerSeat;

  /// Whole EGP, [billedSeats] × [pricePerSeat]; VAT pending (research R0 c).
  final int total;
  final CalendarDate issuedOn;
  final CalendarDate dueOn;

  /// `GR-<companyShortId>-<yyyymm>`: what the company writes on the transfer.
  final String reference;

  /// The moment Goora staff marked it paid; coverage returns from here.
  final WallTime? paidAt;
  final String? bankRef;

  CalendarDate? get paidOn => paidAt?.date;

  /// 00:00 on the first day with no coverage if still unpaid (Q10 default).
  WallTime get suspendFrom =>
      WallTime(_date(CompanyRules.suspendFromDay(SharePolicy.dayOf(dueOn))), const Clock.hm(0, 0));

  InvoiceStatus statusAt(WallTime now) {
    if (paidAt != null && !now.isBefore(paidAt!)) return InvoiceStatus.paid;
    return now.date.isAfter(dueOn) ? InvoiceStatus.overdue : InvoiceStatus.issued;
  }

  Invoice markPaid({required WallTime at, required String bankRef}) => Invoice(
        id: id,
        companyId: companyId,
        month: month,
        peakEnrolled: peakEnrolled,
        billedSeats: billedSeats,
        pricePerSeat: pricePerSeat,
        total: total,
        issuedOn: issuedOn,
        dueOn: dueOn,
        reference: reference,
        paidAt: at,
        bankRef: bankRef,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'companyId': companyId,
        'month': month,
        'peakEnrolled': peakEnrolled,
        'billedSeats': billedSeats,
        'pricePerSeat': pricePerSeat,
        'total': total,
        'issuedOn': issuedOn.toIso(),
        'dueOn': dueOn.toIso(),
        'reference': reference,
        'paidAt': paidAt?.toJson(),
        'bankRef': bankRef,
      };

  static Invoice fromJson(Map<String, Object?> j) => Invoice(
        id: j['id']! as String,
        companyId: j['companyId']! as String,
        month: j['month']! as String,
        peakEnrolled: j['peakEnrolled']! as int,
        billedSeats: j['billedSeats']! as int,
        pricePerSeat: j['pricePerSeat']! as int,
        total: j['total']! as int,
        issuedOn: CalendarDate.parse(j['issuedOn']! as String),
        dueOn: CalendarDate.parse(j['dueOn']! as String),
        reference: j['reference']! as String,
        paidAt: j['paidAt'] == null ? null : WallTime.fromJson(j['paidAt']! as String),
        bankRef: j['bankRef'] as String?,
      );

  static final _epoch = CalendarDate(2000, 1, 1);

  /// Back from the shared day scale.
  static CalendarDate _date(int day) => _epoch.addDays(day);

  @override
  bool operator ==(Object other) =>
      other is Invoice &&
      other.id == id &&
      other.companyId == companyId &&
      other.month == month &&
      other.peakEnrolled == peakEnrolled &&
      other.billedSeats == billedSeats &&
      other.pricePerSeat == pricePerSeat &&
      other.total == total &&
      other.issuedOn == issuedOn &&
      other.dueOn == dueOn &&
      other.reference == reference &&
      other.paidAt == paidAt &&
      other.bankRef == bankRef;

  @override
  int get hashCode => Object.hash(
      id, companyId, month, peakEnrolled, billedSeats, pricePerSeat, total, issuedOn, dueOn, reference, paidAt, bankRef);

  @override
  String toString() => 'Invoice($id, $billedSeats × $pricePerSeat = $total)';
}
