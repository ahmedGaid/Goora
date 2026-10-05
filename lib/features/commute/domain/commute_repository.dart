import 'commute_profile.dart';
import 'group.dart';
import 'place.dart';

abstract interface class CommuteRepository {
  List<Place> homePlaces();

  List<Place> workPlaces();

  Future<CommuteProfile?> loadProfile();

  Future<void> saveProfile(CommuteProfile profile);

  Future<List<CommuteGroup>> groupsFor(Area origin, Area destination);

  /// Adds the person to the corridor waitlist and returns their position.
  Future<int> joinWaitlist(Area origin, Area destination);

  Future<void> join(String groupId);

  Future<String?> joinedGroupId();
}
