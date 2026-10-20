import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/now_provider.dart';
import '../../../commute/data/providers.dart';
import '../../../commute/domain/clock.dart';
import '../../../commute/domain/commute_profile.dart';
import '../../../commute/domain/corridor.dart';
import '../../../commute/domain/place.dart';
import '../../../daily/data/providers.dart';
import '../../data/providers.dart';
import '../../domain/marketplace_repository.dart';
import '../../domain/offered_trip.dart';
import '../../domain/trip_request.dart';

part 'post_trip_controller.g.dart';

/// Where the form starts: the rider's saved commute, and whether they already
/// ride in a daily group (which turns Every workday off, R10).
final class PostStart {
  const PostStart({
    required this.corridor,
    required this.from,
    required this.to,
    this.home,
    this.work,
    required this.departure,
    required this.inGroup,
  });

  /// The active corridor: its areas, defaults and trip cost (006 R4).
  final Corridor corridor;
  final Area from;
  final Area to;

  /// The rider's saved home and work areas, which decide the leg (R5).
  final Area? home;
  final Area? work;
  final Clock departure;
  final bool inGroup;

  /// Leaving home is the way there, coming home the way back (research R5).
  Leg legOf(Area from, Area to) => corridor.legOf(from, to, home: home, work: work);
}

/// The rider's edits, carried in the URL across the payment-method detour.
final class PostTripDraft {
  const PostTripDraft({required this.from, required this.to, required this.departure, required this.repeat});

  final Area from;
  final Area to;
  final Clock departure;
  final Repeat repeat;

  /// Null unless every part is present and valid (a bare `/post-trip` starts fresh).
  static PostTripDraft? parse({String? from, String? to, String? at, String? repeat}) {
    final a = Area.values.asNameMap()[from];
    final b = Area.values.asNameMap()[to];
    final r = Repeat.values.asNameMap()[repeat];
    final minutes = int.tryParse(at ?? '');
    if (a == null || b == null || r == null || minutes == null || minutes < 0 || minutes >= Clock.minutesPerDay) return null;
    return PostTripDraft(from: a, to: b, departure: Clock(minutes), repeat: r);
  }
}

@riverpod
Future<PostStart> postStart(Ref ref) async {
  final corridor = ref.watch(activeCorridorProvider);
  final profile = await ref.watch(commuteRepositoryProvider).loadProfile();
  final group = await ref.watch(dailyCommuteRepositoryProvider).myGroup();
  return PostStart(
    corridor: corridor,
    from: profile?.home?.area ?? corridor.defaultFrom,
    to: profile?.work?.area ?? corridor.defaultTo,
    home: profile?.home?.area,
    work: profile?.work?.area,
    departure: profile?.departure ?? const Clock.hm(7, 30),
    inGroup: group != null,
  );
}

/// One posted request, read fresh: it expires on read at date + time (R13).
@riverpod
Future<TripRequest?> postedRequest(Ref ref, String id) =>
    ref.watch(marketplaceRepositoryProvider).request(id, now: ref.read(nowProvider)());

/// "Sent to N drivers on your route".
@riverpod
Future<int> sentTo(Ref ref, String requestId) async {
  final market = ref.watch(marketplaceRepositoryProvider);
  final r = await market.request(requestId, now: ref.read(nowProvider)());
  if (r == null) return 0;
  return market.driversOnRoute(TripDraft(leg: r.leg, from: r.from, to: r.to, departure: r.departure, repeat: r.repeat));
}

/// The rider's requests still waiting for a driver, for Today.
@riverpod
Future<List<TripRequest>> myPostedRequests(Ref ref) =>
    ref.watch(marketplaceRepositoryProvider).myRequests(now: ref.read(nowProvider)());
