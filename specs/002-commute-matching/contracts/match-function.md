# Contract: `match` Edge Function and repository

## Edge Function `POST /functions/v1/match` (deployed later)

Auth: Supabase JWT (the caller). Body: none — the function reads the caller's own commute profile.

1. Load caller profile + commute profile (service role, server-side only).
2. Pre-filter groups with PostGIS: `ST_DWithin(destination, caller.work, 1500)` and any pickup point
   `ST_DWithin(point, caller.home, 1000)`.
3. Run `_shared/matching.ts` `matchGroups(seeker, groups)`.
4. Respond:

```json
{
  "main": { "groupId": "g1", "score": 92, "legs": ["going", "return"],
            "reasons": [{ "kind": "destination", "value": "smartVillage" }] },
  "returnMatch": null,
  "alternatives": [{ "groupId": "g2", "score": 88 }],
  "waitlistPosition": null
}
```

No match → `main: null`, `waitlistPosition: <int>` (caller added to the corridor waitlist).
Home points never appear in responses.

## CommuteRepository (app)

```dart
abstract interface class CommuteRepository {
  List<Place> homePlaces();
  List<Place> workPlaces();
  Future<CommuteProfile?> loadProfile();
  Future<void> saveProfile(CommuteProfile profile);
  Future<List<CommuteGroup>> groupsFor(Area origin, Area destination);
  Future<int> joinWaitlist(Area origin, Area destination);   // returns position
  Future<void> join(String groupId);
}
```

`FakeCommuteRepository`: corridor seed + shared_preferences. `SupabaseCommuteRepository` later calls
the function above.
