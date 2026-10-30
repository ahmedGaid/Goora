import 'package:goora/core/backend/backend_failure.dart';
import 'package:goora/core/backend/backend_gateway.dart';

/// A server-function stand-in: gets the call's params and the gateway, may
/// throw `BackendRefused`, returns what the SQL function would.
typedef Handler = Object? Function(Row params, InMemoryGateway db);

/// The mocked client for contract tests (011 research D3). Tables are lists of
/// rows; [keys] names each table's primary key columns so inserts clash and
/// upserts replace like Postgres. RPCs and Edge Functions are handlers a
/// harness registers — they stand in for the SQL in supabase/migrations,
/// which the pgTAP tests check against a real database.
final class InMemoryGateway implements BackendGateway {
  InMemoryGateway({this.keys = const {}}) {
    auth = _MemoryAuth(this);
  }

  /// Primary key columns per table.
  final Map<String, List<String>> keys;
  final Map<String, List<Row>> tables = {};
  final Map<String, Handler> rpcs = {};
  final Map<String, Handler> functions = {};

  /// Every rpc/invoke call, in order: (name, params).
  final List<(String, Row)> calls = [];

  @override
  String? userId;

  @override
  late final BackendAuth auth;

  int _seq = 0;

  /// A fresh id, unique within this gateway.
  String newId([String prefix = 'id']) => '$prefix-${++_seq}';

  List<Row> table(String name) => tables.putIfAbsent(name, () => []);

  bool _sameKey(String table, Row a, Row b) {
    final key = keys[table];
    if (key == null) return false;
    return key.every((c) => a[c] == b[c]);
  }

  @override
  Future<List<Row>> select(String table,
      {List<Filter> where = const [], String? orderBy, bool descending = false, int? limit}) async {
    var rows = [for (final r in this.table(table)) if (where.every((f) => f.matches(r))) Map<String, Object?>.of(r)];
    if (orderBy != null) {
      rows.sort((a, b) {
        final c = _cmp(a[orderBy], b[orderBy]);
        return descending ? -c : c;
      });
    }
    if (limit != null && rows.length > limit) rows = rows.sublist(0, limit);
    return rows;
  }

  static int _cmp(Object? a, Object? b) {
    if (a == null) return b == null ? 0 : -1;
    if (b == null) return 1;
    return (a as Comparable<Object>).compareTo(b);
  }

  @override
  Future<List<Row>> insert(String table, List<Row> rows) async {
    final t = this.table(table);
    for (final r in rows) {
      if (t.any((e) => _sameKey(table, e, r))) throw BackendConflict('23505', '$table key');
    }
    final copies = [for (final r in rows) Map<String, Object?>.of(r)];
    t.addAll(copies);
    return [for (final r in copies) Map.of(r)];
  }

  @override
  Future<List<Row>> upsert(String table, List<Row> rows, {String? onConflict}) async {
    final t = this.table(table);
    final cols = onConflict?.split(',').map((s) => s.trim()).toList();
    for (final r in rows) {
      final i = t.indexWhere((e) => cols == null ? _sameKey(table, e, r) : cols.every((c) => e[c] == r[c]));
      if (i < 0) {
        t.add(Map.of(r));
      } else {
        t[i] = {...t[i], ...r};
      }
    }
    return [for (final r in rows) Map.of(r)];
  }

  @override
  Future<List<Row>> update(String table, Row values, {required List<Filter> where}) async {
    final out = <Row>[];
    final t = this.table(table);
    for (var i = 0; i < t.length; i++) {
      if (where.every((f) => f.matches(t[i]))) {
        t[i] = {...t[i], ...values};
        out.add(Map.of(t[i]));
      }
    }
    return out;
  }

  @override
  Future<void> delete(String table, {required List<Filter> where}) async =>
      this.table(table).removeWhere((r) => where.every((f) => f.matches(r)));

  @override
  Future<Object?> rpc(String function, [Row params = const {}]) async {
    calls.add((function, params));
    final h = rpcs[function] ?? (throw BackendError('no rpc handler: $function'));
    return h(params, this);
  }

  @override
  Future<Object?> invoke(String function, Row body) async {
    calls.add((function, body));
    final h = functions[function] ?? (throw BackendError('no function handler: $function'));
    return h(body, this);
  }

  /// Throws `BackendRefused` when signed out, like `wallet_me()`.
  String me() => userId ?? (throw const BackendRefused('signedOut'));
}

final class _MemoryAuth implements BackendAuth {
  _MemoryAuth(this._db);

  final InMemoryGateway _db;
  final Map<String, ({String password, String id})> _accounts = {};

  @override
  String? email;

  @override
  Future<void> signInWithPassword(String email, String password) async {
    final a = _accounts[email];
    if (a == null || a.password != password) throw const BackendUnauthorized('Invalid login credentials');
    this.email = email;
    _db.userId = a.id;
  }

  @override
  Future<void> signUp(String email, String password) async {
    if (_accounts.containsKey(email)) throw const BackendConflict('23505', 'user exists');
    final id = _db.newId('user');
    _accounts[email] = (password: password, id: id);
    this.email = email;
    _db.userId = id;
  }

  @override
  Future<void> signOut() async {
    email = null;
    _db.userId = null;
  }
}
