import '../../../core/l10n/app_localizations.dart';
import '../domain/clock.dart';
import '../domain/commute_profile.dart';
import '../domain/matching_service.dart';
import '../domain/place.dart';

/// Turns commute domain values into localized text. Digits stay Western.
extension CommuteLabels on AppLocalizations {
  String area(Area a) => switch (a) {
        Area.sheikhZayed => areaSheikhZayed,
        Area.october => areaOctober,
        Area.smartVillage => areaSmartVillage,
      };

  String day(Day d) => switch (d) {
        Day.sun => daySun,
        Day.mon => dayMon,
        Day.tue => dayTue,
        Day.wed => dayWed,
        Day.thu => dayThu,
        Day.fri => dayFri,
        Day.sat => daySat,
      };

  String time(Clock c) => c.isAm ? timeAm(c.h12) : timePm(c.h12);

  String daysSummary(Set<Day> days) {
    if (days.length == CommuteProfile.defaultDays.length && days.containsAll(CommuteProfile.defaultDays)) {
      return sunThu;
    }
    return [for (final d in Day.values) if (days.contains(d)) day(d)].join(' · ');
  }

  String trips(DrivenTrips t) => switch (t) {
        DrivenTrips.both => dirBoth,
        DrivenTrips.going => dirGoing,
        DrivenTrips.ret => dirRet,
      };

  String reason(Reason r) => switch (r.kind) {
        ReasonKind.destination => reasonDestination(area(r.area!)),
        ReasonKind.departure => r.value == 0 ? reasonSameDeparture : reasonDeparture(r.value!),
        ReasonKind.pickup => reasonPickup(r.value!),
        ReasonKind.companyReturn => reasonCompanyReturn,
        ReasonKind.company => reasonCompany,
        ReasonKind.compound => reasonCompound,
        ReasonKind.ret => reasonReturn,
        ReasonKind.days => reasonDays(r.value!),
        ReasonKind.rating => reasonRating(r.rating!.toStringAsFixed(1)),
      };

  String commuteProblem(CommuteProblem p) => switch (p) {
        CommuteProblem.missingPlace => choosePlace,
        CommuteProblem.sameArea => sameAreaHint,
        CommuteProblem.noDays => noDaysHint,
        CommuteProblem.returnBeforeDeparture => returnHint,
      };
}
