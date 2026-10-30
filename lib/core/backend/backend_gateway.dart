/// The one door between repositories and the backend (011 contracts/
/// backend-gateway.md). `SupabaseGateway` is the real one; tests use an
/// in-memory one, so no repository imports supabase_flutter. Every method
/// throws only `BackendFailure`.
typedef Row = Map<String, Object?>;

/// One condition on a column; a list of them is ANDed.
sealed class Filter {
  const Filter(this.column);

  final String column;

  const factory Filter.eq(String column, Object? value) = EqFilter;
  const factory Filter.gte(String column, Object value) = GteFilter;
  const factory Filter.lte(String column, Object value) = LteFilter;
  const factory Filter.inList(String column, List<Object> values) = InFilter;
  const factory Filter.isNull(String column) = IsNullFilter;

  /// Whether [row] passes (the in-memory gateway's reading).
  bool matches(Row row);
}

int _compare(Object? a, Object b) => (a as Comparable<Object>).compareTo(b);

final class EqFilter extends Filter {
  const EqFilter(super.column, this.value);
  final Object? value;

  @override
  bool matches(Row row) => row[column] == value;
}

final class GteFilter extends Filter {
  const GteFilter(super.column, this.value);
  final Object value;

  @override
  bool matches(Row row) => row[column] != null && _compare(row[column], value) >= 0;
}

final class LteFilter extends Filter {
  const LteFilter(super.column, this.value);
  final Object value;

  @override
  bool matches(Row row) => row[column] != null && _compare(row[column], value) <= 0;
}

final class InFilter extends Filter {
  const InFilter(super.column, this.values);
  final List<Object> values;

  @override
  bool matches(Row row) => values.contains(row[column]);
}

final class IsNullFilter extends Filter {
  const IsNullFilter(super.column);

  @override
  bool matches(Row row) => row[column] == null;
}

abstract interface class BackendAuth {
  /// The signed-in account's email; null when signed out.
  String? get email;

  /// Throws `BackendUnauthorized` on wrong credentials.
  Future<void> signInWithPassword(String email, String password);

  Future<void> signUp(String email, String password);

  Future<void> signOut();
}

abstract interface class BackendGateway {
  /// `auth.uid()` of the session; null when signed out.
  String? get userId;

  BackendAuth get auth;

  Future<List<Row>> select(
    String table, {
    List<Filter> where = const [],
    String? orderBy,
    bool descending = false,
    int? limit,
  });

  Future<List<Row>> insert(String table, List<Row> rows);

  Future<List<Row>> upsert(String table, List<Row> rows, {String? onConflict});

  Future<List<Row>> update(String table, Row values, {required List<Filter> where});

  Future<void> delete(String table, {required List<Filter> where});

  /// A SQL function (`security definer`, contracts/server-functions.md).
  Future<Object?> rpc(String function, [Row params = const {}]);

  /// An Edge Function, e.g. `commute-day` (003 contracts/edge-functions.md).
  Future<Object?> invoke(String function, Row body);
}
