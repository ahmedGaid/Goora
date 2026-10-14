import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/calendar_date.dart';
import '../../../../core/time/now_provider.dart';
import '../../../commute/domain/place.dart';
import '../../../daily/presentation/today/today_controller.dart';
import '../../data/providers.dart';
import '../../domain/marketplace_repository.dart';
import '../today/one_off_section.dart';

part 'find_riders_controller.g.dart';

/// Requests on the driver's route (D): only those within a 10-minute detour,
/// for their own privacy choice, each with what accepting would do (FR-018).
@riverpod
Future<List<RequestCard>> requestCards(Ref ref, Area? leavingFrom, PartOfDay part) =>
    ref.watch(marketplaceRepositoryProvider).requestsForMe(
          leavingFrom: leavingFrom,
          part: part,
          now: ref.read(nowProvider)(),
        );

/// Trips the driver still has on [date] (Constitution II: two a day).
@riverpod
Future<int> tripsLeft(Ref ref, CalendarDate date) async =>
    (await ref.watch(marketplaceRepositoryProvider).driverDay(date)).tripsLeft;

/// Accepts [requestId] and re-reads everything that moved: the list, trips
/// left, the driver's offers and Today (a daily request joins a group).
Future<AcceptResult> acceptRequest(WidgetRef ref, String requestId) async {
  final result = await ref.read(marketplaceRepositoryProvider).accept(requestId, now: ref.read(nowProvider)());
  ref
    ..invalidate(requestCardsProvider)
    ..invalidate(tripsLeftProvider)
    ..invalidate(driverOffersProvider)
    ..invalidate(todayControllerProvider);
  return result;
}
