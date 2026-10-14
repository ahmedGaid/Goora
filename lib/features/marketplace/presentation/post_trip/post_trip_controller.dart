import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/now_provider.dart';
import '../../../commute/data/providers.dart';
import '../../../commute/domain/clock.dart';
import '../../../commute/domain/place.dart';
import '../../../daily/data/providers.dart';
import '../../data/providers.dart';
import '../../domain/marketplace_repository.dart';
import '../../domain/trip_request.dart';

part 'post_trip_controller.g.dart';

/// Where the form starts: the rider's saved commute, and whether they already
/// ride in a daily group (which turns Every workday off, R10).
final class PostStart {
  const PostStart({required this.from, required this.to, required this.departure, required this.inGroup});

  final Area from;
  final Area to;
  final Clock departure;
  final bool inGroup;
}

@riverpod
Future<PostStart> postStart(Ref ref) async {
  final profile = await ref.watch(commuteRepositoryProvider).loadProfile();
  final group = await ref.watch(dailyCommuteRepositoryProvider).myGroup();
  return PostStart(
    from: profile?.home?.area ?? Area.sheikhZayed,
    to: profile?.work?.area ?? Area.smartVillage,
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
