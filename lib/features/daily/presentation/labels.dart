import '../../../core/l10n/app_localizations.dart';
import '../../../core/time/calendar_date.dart';
import '../../commute/domain/clock.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/group.dart';
import '../../commute/presentation/labels.dart';
import '../domain/notice.dart';
import '../domain/privacy.dart';
import '../domain/trust.dart';

/// Turns daily-commute domain values into localized text. Digits stay Western.
extension DailyLabels on AppLocalizations {
  String stopName(StopName s) => switch (s) {
        StopName.mainGate => stopMainGate,
        StopName.centralSt => stopCentralSt,
        StopName.gasStation => stopGasStation,
        StopName.smartVillageGate2 => stopSmartVillageGate2,
      };

  String legName(Leg leg) => leg == Leg.going ? legGoing : legReturn;

  /// "the going trip" / "the return trip", used inside sentences.
  String tripName(Leg leg) => leg == Leg.going ? tripGoing : tripReturn;

  String checkLabel(VerificationKind k) => switch (k) {
        VerificationKind.phone => checkPhone,
        VerificationKind.nationalId => checkNationalId,
        VerificationKind.workEmail => checkWorkEmail,
        VerificationKind.license => checkLicense,
        VerificationKind.vehicle => checkVehicle,
      };

  String privacyLabel(PrivacyPreference p) => switch (p) {
        PrivacyPreference.verifiedUsers => privacyVerified,
        PrivacyPreference.sameCompany => privacyCompany,
        PrivacyPreference.sameCompound => privacyCompound,
        PrivacyPreference.womenOnly => privacyWomen,
      };

  /// Why a preference is unavailable (research R7); null when it always is.
  String? privacyHint(PrivacyPreference p) => switch (p) {
        PrivacyPreference.sameCompany => needWorkEmail,
        PrivacyPreference.sameCompound => needCompound,
        PrivacyPreference.verifiedUsers || PrivacyPreference.womenOnly => null,
      };

  String colour(VehicleColour c) => switch (c) {
        VehicleColour.white => colourWhite,
        VehicleColour.silver => colourSilver,
        VehicleColour.black => colourBlack,
        VehicleColour.grey => colourGrey,
        VehicleColour.red => colourRed,
        VehicleColour.blue => colourBlue,
      };

  String dayOf(CalendarDate d) => day(d.weekday);

  /// Inside a sentence: "today" · "tomorrow (Tue)" · "on Sun".
  String when(CalendarDate date, CalendarDate today) {
    final gap = today.daysUntil(date);
    if (gap == 0) return relToday;
    if (gap == 1) return relTomorrowDay(dayOf(date));
    return relOn(dayOf(date));
  }

  /// At the start of a line: "Today" · "Tomorrow" · "Sun".
  String heroWhen(CalendarDate date, CalendarDate today) {
    final gap = today.daysUntil(date);
    if (gap == 0) return heroToday;
    if (gap == 1) return heroTomorrow;
    return dayOf(date);
  }

  /// Delay and countdowns: minutes:seconds, Western digits.
  String mmss(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  String direction(Set<Leg> legs) => legs.length == 2 ? dirBoth : legName(legs.single);

  String rating(double r) => ratingStars(r.toStringAsFixed(1));

  String noticeText(Notice n, CommuteGroup? g) {
    String dayParam() {
      final iso = n.params['day'];
      return iso == null ? '' : dayOf(CalendarDate.parse(iso));
    }

    String stopParam() {
      final id = n.params['stop'];
      final stops = g == null ? const <Stop>[] : [...g.goingStops, g.workStop];
      final stop = stops.where((s) => s.id == id).firstOrNull;
      return stop == null ? '' : stopName(stop.name);
    }

    int amount() => int.tryParse(n.params['amount'] ?? '') ?? 0;

    return switch (n.kind) {
      NoticeKind.driverConfirmed => nDriverConfirmed(dayParam()),
      NoticeKind.driverUnconfirmed => nDriverUnconfirmed(dayParam()),
      NoticeKind.delay => nDelay(
          int.tryParse(n.params['minutes'] ?? '') ?? 0,
          n.params['time'] == null ? '' : time(Clock(int.parse(n.params['time']!))),
        ),
      NoticeKind.driverArrived => nDriverArrived(stopParam()),
      NoticeKind.lateCancelCharged => nLateCancel(dayParam(), amount()),
      NoticeKind.noShowCharged => nNoShow(dayParam(), amount()),
      NoticeKind.noShowWarning => noShowWarning,
      NoticeKind.removed => removedNotice,
      NoticeKind.seatOffered => nSeatOffered(dayParam()),
      NoticeKind.noCover => noCoverTitle(relOn(dayParam())),
      NoticeKind.backupCover => backupBodyFor(n.params['cover'] ?? ''),
      NoticeKind.sosSent => sosAlertSent,
      NoticeKind.driverNoShow => nDriverNoShow(dayParam()),
    };
  }
}
