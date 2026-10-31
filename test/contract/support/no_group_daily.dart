import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/daily/domain/daily_commute_repository.dart';

/// A person in no group: the marketplace only asks the daily seam for the group.
final class NoGroupDaily implements DailyCommuteRepository {
  @override
  String get meId => 'me';
  @override
  Future<CommuteGroup?> myGroup() async => null;
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}
