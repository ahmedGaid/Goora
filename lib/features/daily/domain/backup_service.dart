import '../../commute/domain/group.dart';
import '../../commute/domain/matching_service.dart';
import 'privacy.dart';
import 'ride.dart';
import 'schedule.dart';

/// Result of a backup search (§6.6).
final class BackupResult {
  const BackupResult.covered(String this.coverId, BackupStep this.step);

  const BackupResult.none()
      : coverId = null,
        step = null;

  final String? coverId;
  final BackupStep? step;

  bool get found => coverId != null;
}

/// A driver who might cover a leg, offered by one search [step].
final class BackupCandidate {
  const BackupCandidate({
    required this.member,
    required this.step,
    required this.seeker,
    required this.freeSeats,
    this.available = true,
  });

  final Member member;
  final BackupStep step;

  /// Their own commute as a driver (home, work, times, days). The search
  /// limits it to the ride's leg and day.
  final Seeker seeker;

  /// Seats free in their car on that leg and day.
  final int freeSeats;

  /// Not away themselves that day.
  final bool available;
}

/// Backup driver search (brief §6.6, FR-017 – FR-019, research R6).
///
/// Steps in order: same group → nearby group → same company → same
/// community. A candidate passes when available, with enough free seats for
/// every passenger, passing the 002 hard constraints for that leg and day
/// ([MatchingService.evaluate]), and accepted by every passenger's privacy
/// preference. Within a step: least detour (distance from their home to the
/// group's pickup) → highest rating → lowest id. One cover carries the whole
/// leg; the group price never changes. Mirrored in
/// `supabase/functions/_shared/backup.ts`.
abstract final class BackupService {
  static BackupResult findCover(
    Ride ride,
    CommuteGroup g,
    List<BackupCandidate> candidates, {
    MatchingLimits limits = const MatchingLimits(),
  }) {
    for (final step in BackupStep.values) {
      final passing = <(BackupCandidate, double)>[
        for (final c in candidates.where((c) => c.step == step))
          if (_detour(c, ride, g, limits) case final detour?) (c, detour),
      ]..sort((a, b) {
          final byDetour = a.$2.compareTo(b.$2);
          if (byDetour != 0) return byDetour;
          final byRating = b.$1.member.rating.compareTo(a.$1.member.rating);
          if (byRating != 0) return byRating;
          return a.$1.member.id.compareTo(b.$1.member.id);
        });
      if (passing.isNotEmpty) return BackupResult.covered(passing.first.$1.member.id, step);
    }
    return const BackupResult.none();
  }

  /// Metres from the candidate's home to the group's pickup, or null when
  /// they cannot cover this ride.
  static double? _detour(BackupCandidate c, Ride ride, CommuteGroup g, MatchingLimits limits) {
    final cover = c.member;
    if (!c.available) return null;
    final riders = ride.passengers.where((p) => p.memberId != cover.id).toList();
    if (c.freeSeats < riders.length) return null;

    final s = c.seeker;
    final match = MatchingService.evaluate(
      Seeker(
        role: MemberRole.driver,
        home: s.home,
        work: s.work,
        departure: s.departure,
        ret: s.ret,
        days: s.days.intersection({ride.date.weekday}),
        legs: {ride.leg},
        isWoman: cover.isWoman,
        company: cover.company,
        compound: cover.compound,
        womenOnly: cover.privacy.wantsWomenOnly,
        sameCompanyOnly: cover.privacy.wantsSameCompany,
        sameCompoundOnly: cover.privacy.wantsSameCompound,
      ),
      g,
      limits: limits,
    );
    if (match == null) return null;

    final coverFacts = cover.facts;
    for (final p in riders) {
      final rider = g.member(p.memberId);
      if (rider != null && !PrivacyRules.accepts(rider.privacy, rider.facts, coverFacts)) return null;
    }
    return match.pickupMeters;
  }
}
