# Contract: `BackendGateway` (lib/core/backend/)

```dart
typedef Row = Map<String, Object?>;

/// One filter on a column; the gateway ANDs them.
sealed class Filter { eq(col, v) · gte(col, v) · lte(col, v) · inList(col, values) · isNull(col) }

abstract interface class BackendGateway {
  /// auth.uid() of the session; null when signed out.
  String? get userId;
  BackendAuth get auth;

  Future<List<Row>> select(String table, {List<Filter> where, String? orderBy,
      bool descending = false, int? limit});
  Future<List<Row>> insert(String table, List<Row> rows);           // returns inserted rows
  Future<List<Row>> upsert(String table, List<Row> rows, {String? onConflict});
  Future<List<Row>> update(String table, Row values, {required List<Filter> where});
  Future<void> delete(String table, {required List<Filter> where});
  Future<Object?> rpc(String function, [Row params]);               // SQL function
  Future<Object?> invoke(String function, Row body);                // Edge Function
}

abstract interface class BackendAuth {
  String? get email;
  Future<void> signInWithPassword(String email, String password);   // throws BackendUnauthorized on bad credentials
  Future<void> signUp(String email, String password);
  Future<void> signOut();
}
```

Every method throws only `BackendFailure` (research D7):

| Source | Becomes |
|---|---|
| `SocketException`, `http.ClientException`, `TimeoutException`, `AuthRetryableFetchException` | `BackendOffline` |
| `AuthException` 400 "Invalid login credentials", PostgREST `PGRST301`/`42501`, HTTP 401/403 | `BackendUnauthorized` |
| PostgREST `23505` (unique), `23P01` | `BackendConflict(code, detail)` |
| PostgREST `P0001` with message `refused:<reason>[:<detail>]`, Edge Function 409 `{refused}` | `BackendRefused(reason, detail)` |
| anything else | `BackendError(message)` |

`SupabaseGateway(SupabaseClient)` is the only file that imports `supabase_flutter`.
`InMemoryGateway` (test only) implements the same interface: tables keyed by a declared primary key,
optional unique keys (a clash throws `BackendConflict('23505')`), registered `rpc`/`invoke` handlers
(`(Row params, InMemoryGateway db) → Object?`, a handler may throw `BackendRefused`), and a settable
`userId` per test.

## Selection (`backend_providers.dart`)

```dart
enum BackendMode { fake, live }
@Riverpod(keepAlive: true) BackendMode backendMode(Ref ref);          // Backend.mode, overridable
@Riverpod(keepAlive: true) BackendGateway backendGateway(Ref ref);    // throws StateError in fake mode
```

`Backend.init()` (main.dart, before `runApp`): no-op unless `Env.backendLive`; else
`Supabase.initialize(url, anonKey)` + health probe (3 s) → `mode = live`, or `fake` on failure.
