import 'clock.dart';
import 'commute_profile.dart';
import 'geo.dart';
import 'group.dart';
import 'place.dart';

/// Hard limits from brief §6.3 (configurable).
final class MatchingLimits {
  const MatchingLimits({
    this.pickupMeters = 1000,
    this.detourMinutes = 10,
    this.timeMinutes = 20,
    this.destinationMeters = 1500,
  });

  final double pickupMeters;
  final int detourMinutes;
  final int timeMinutes;
  final double destinationMeters;
}

/// Score weights from brief §6.3 (sum 100).
abstract final class MatchWeights {
  static const destination = 25.0;
  static const departure = 20.0;
  static const pickup = 15.0;
  static const ret = 10.0;
  static const days = 10.0;
  static const community = 10.0;
  static const rating = 10.0;
}

final class Seeker {
  const Seeker({
    required this.role,
    required this.home,
    required this.work,
    required this.departure,
    required this.ret,
    required this.days,
    required this.legs,
    this.isWoman = false,
    this.company,
    this.compound,
    this.womenOnly = false,
    this.sameCompanyOnly = false,
    this.sameCompoundOnly = false,
  });

  final MemberRole role;
  final GeoPoint home;
  final GeoPoint work;
  final Clock departure;
  final Clock ret;
  final Set<Day> days;
  final Set<Leg> legs;
  final bool isWoman;
  final String? company;
  final String? compound;
  final bool womenOnly;
  final bool sameCompanyOnly;
  final bool sameCompoundOnly;
}

enum ReasonKind { destination, departure, pickup, companyReturn, company, compound, ret, days, rating }

final class Reason {
  const Reason(this.kind, {this.value, this.area, this.rating});

  final ReasonKind kind;
  final int? value;
  final Area? area;
  final double? rating;
}

final class FactorScores {
  const FactorScores({
    required this.destination,
    required this.departure,
    required this.pickup,
    required this.ret,
    required this.days,
    required this.community,
    required this.rating,
  });

  final double destination;
  final double departure;
  final double pickup;
  final double ret;
  final double days;
  final double community;
  final double rating;

  int get total => (destination + departure + pickup + ret + days + community + rating).round();
}

final class GroupMatch {
  const GroupMatch({
    required this.group,
    required this.legs,
    required this.factors,
    required this.reasons,
    required this.pickupMeters,
    required this.departureDiff,
  });

  final CommuteGroup group;
  final Set<Leg> legs;
  final FactorScores factors;
  final List<Reason> reasons;
  final double pickupMeters;
  final int departureDiff;

  int get score => factors.total;
}

final class MatchResult {
  const MatchResult({this.main, this.returnMatch, this.alternatives = const []});

  static const none = MatchResult();

  /// Best group; covers every needed leg unless [returnMatch] is set.
  final GroupMatch? main;

  /// Set only when the return leg comes from a different group.
  final GroupMatch? returnMatch;
  final List<GroupMatch> alternatives;

  bool get found => main != null;
}

/// Pure matching rules (brief §6.3, founder decisions 2026-10-05).
/// Mirrored in `supabase/functions/_shared/matching.ts`; both run
/// `test/fixtures/matching_vectors.json`.
abstract final class MatchingService {
  static MatchResult match(
    Seeker seeker,
    List<CommuteGroup> groups, {
    MatchingLimits limits = const MatchingLimits(),
  }) {
    final candidates = <GroupMatch>[];
    for (final g in groups) {
      final m = evaluate(seeker, g, limits: limits);
      if (m != null) candidates.add(m);
    }
    int byScore(GroupMatch a, GroupMatch b) => b.score.compareTo(a.score);

    final full = candidates.where((m) => m.legs.containsAll(seeker.legs)).toList()..sort(byScore);
    if (full.isNotEmpty) {
      return MatchResult(main: full.first, alternatives: full.skip(1).toList());
    }

    // Going and return matched independently.
    GroupMatch? bestFor(Leg leg) {
      final serving = candidates.where((m) => m.legs.contains(leg)).toList()..sort(byScore);
      return serving.isEmpty ? null : serving.first;
    }

    final perLeg = {for (final leg in seeker.legs) leg: bestFor(leg)};
    if (perLeg.values.any((m) => m == null)) return MatchResult.none;
    final going = perLeg[Leg.going];
    final ret = perLeg[Leg.ret];
    final main = going ?? ret!;
    return MatchResult(main: main, returnMatch: ret != null && ret != main ? ret : null);
  }

  /// Null when the group fails a hard constraint common to every leg, or
  /// serves none of the seeker's legs.
  static GroupMatch? evaluate(
    Seeker s,
    CommuteGroup g, {
    MatchingLimits limits = const MatchingLimits(),
  }) {
    final destinationMeters = s.work.distanceTo(g.destinationPoint);
    if (destinationMeters > limits.destinationMeters) return null;

    var pickupMeters = double.infinity;
    for (final p in g.pickupPoints) {
      final d = s.home.distanceTo(p);
      if (d < pickupMeters) pickupMeters = d;
    }
    if (pickupMeters > limits.pickupMeters) return null;
    if (g.detourMinutes > limits.detourMinutes) return null;

    final shared = s.days.intersection(g.days).length;
    if (shared == 0) return null;
    if (!_privacyCompatible(s, g)) return null;

    final departureDiff = s.departure.diff(g.going);
    final returnDiff = s.ret.diff(g.ret);
    final legs = <Leg>{
      for (final leg in s.legs)
        if ((leg == Leg.going ? departureDiff : returnDiff) <= limits.timeMinutes &&
            (s.role == MemberRole.rider ? g.freeSeats(leg) > 0 : g.hasRidersOn(leg)))
          leg,
    };
    if (legs.isEmpty) return null;

    double linear(double weight, double value, double limit) =>
        weight * (1 - value / limit).clamp(0.0, 1.0);

    final community = g.members.any((m) =>
            (s.company != null && m.company == s.company) ||
            (s.compound != null && m.compound == s.compound))
        ? MatchWeights.community
        : 0.0;

    final avgRating = g.members.isEmpty
        ? 0.0
        : g.members.map((m) => m.rating).reduce((a, b) => a + b) / g.members.length;
    final avgReliability = g.members.isEmpty
        ? 0.0
        : g.members.map((m) => m.reliability).reduce((a, b) => a + b) / g.members.length;

    final factors = FactorScores(
      destination: linear(MatchWeights.destination, destinationMeters, limits.destinationMeters),
      departure: linear(MatchWeights.departure, departureDiff.toDouble(), limits.timeMinutes.toDouble()),
      pickup: linear(MatchWeights.pickup, pickupMeters, limits.pickupMeters),
      ret: linear(MatchWeights.ret, returnDiff.toDouble(), limits.timeMinutes.toDouble()),
      days: MatchWeights.days * shared / s.days.length,
      community: community,
      rating: MatchWeights.rating * ((avgRating / 5) + (avgReliability / 100)) / 2,
    );

    return GroupMatch(
      group: g,
      legs: legs,
      factors: factors,
      reasons: _reasons(s, g, factors, departureDiff, pickupMeters, shared, avgRating),
      pickupMeters: pickupMeters,
      departureDiff: departureDiff,
    );
  }

  static bool _privacyCompatible(Seeker s, CommuteGroup g) {
    if (g.womenOnly && !s.isWoman) return false;
    if (s.womenOnly && g.members.any((m) => !m.isWoman)) return false;
    if (g.sameCompanyOnly != null && g.sameCompanyOnly != s.company) return false;
    if (g.sameCompoundOnly != null && g.sameCompoundOnly != s.compound) return false;
    if (s.sameCompanyOnly && (s.company == null || g.members.any((m) => m.company != s.company))) {
      return false;
    }
    if (s.sameCompoundOnly && (s.compound == null || g.members.any((m) => m.compound != s.compound))) {
      return false;
    }
    return true;
  }

  static const maxReasons = 4;
  static const _pickupRounding = 50;

  static List<Reason> _reasons(
    Seeker s,
    CommuteGroup g,
    FactorScores f,
    int departureDiff,
    double pickupMeters,
    int sharedDays,
    double avgRating,
  ) {
    final sameCompany = s.company != null && g.members.any((m) => m.company == s.company);
    final ranked = <(double, Reason)>[
      (f.destination, Reason(ReasonKind.destination, area: g.destination)),
      (f.departure, Reason(ReasonKind.departure, value: departureDiff)),
      (
        f.pickup,
        Reason(
          ReasonKind.pickup,
          value: (pickupMeters / _pickupRounding).round() * _pickupRounding,
        ),
      ),
      if (f.community > 0 && f.ret > 0)
        (f.community + f.ret, Reason(sameCompany ? ReasonKind.companyReturn : ReasonKind.compound))
      else ...[
        if (f.community > 0) (f.community, Reason(sameCompany ? ReasonKind.company : ReasonKind.compound)),
        (f.ret, const Reason(ReasonKind.ret)),
      ],
      (f.days, Reason(ReasonKind.days, value: sharedDays)),
      (f.rating, Reason(ReasonKind.rating, rating: (avgRating * 10).round() / 10)),
    ];
    final positive = ranked.where((r) => r.$1 > 0).toList();
    // Stable sort: equal points keep the listing order above.
    final indexed = positive.indexed.toList()
      ..sort((a, b) {
        final byPoints = b.$2.$1.compareTo(a.$2.$1);
        return byPoints != 0 ? byPoints : a.$1.compareTo(b.$1);
      });
    return [for (final e in indexed.take(maxReasons)) e.$2.$2];
  }
}
