import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_failure.dart';
import 'backend_gateway.dart';

/// `BackendGateway` over Supabase — the only file that imports
/// supabase_flutter (011 research D3).
final class SupabaseGateway implements BackendGateway {
  SupabaseGateway(this._client) : auth = _SupabaseAuth(_client);

  final SupabaseClient _client;

  @override
  final BackendAuth auth;

  @override
  String? get userId => _client.auth.currentUser?.id;

  @override
  Future<List<Row>> select(String table,
      {List<Filter> where = const [], String? orderBy, bool descending = false, int? limit}) {
    return guard(() async {
      PostgrestTransformBuilder<List<Map<String, dynamic>>> q = _filtered(_client.from(table).select(), where);
      if (orderBy != null) q = q.order(orderBy, ascending: !descending);
      if (limit != null) q = q.limit(limit);
      return _rows(await q);
    });
  }

  @override
  Future<List<Row>> insert(String table, List<Row> rows) =>
      guard(() async => _rows(await _client.from(table).insert(rows).select()));

  @override
  Future<List<Row>> upsert(String table, List<Row> rows, {String? onConflict}) =>
      guard(() async => _rows(await _client.from(table).upsert(rows, onConflict: onConflict).select()));

  @override
  Future<List<Row>> update(String table, Row values, {required List<Filter> where}) =>
      guard(() async => _rows(await _filtered(_client.from(table).update(values), where).select()));

  @override
  Future<void> delete(String table, {required List<Filter> where}) =>
      guard(() async => await _filtered(_client.from(table).delete(), where));

  @override
  Future<Object?> rpc(String function, [Row params = const {}]) =>
      guard(() async => await _client.rpc<Object?>(function, params: params));

  @override
  Future<Object?> invoke(String function, Row body) =>
      guard(() async => (await _client.functions.invoke(function, body: body)).data as Object?);

  static PostgrestFilterBuilder<T> _filtered<T>(PostgrestFilterBuilder<T> q, List<Filter> where) {
    for (final f in where) {
      q = switch (f) {
        EqFilter(:final column, :final value) => value == null ? q.isFilter(column, null) : q.eq(column, value),
        GteFilter(:final column, :final value) => q.gte(column, value),
        LteFilter(:final column, :final value) => q.lte(column, value),
        InFilter(:final column, :final values) => q.inFilter(column, values),
        IsNullFilter(:final column) => q.isFilter(column, null),
      };
    }
    return q;
  }

  static List<Row> _rows(Object? data) =>
      [for (final r in (data as List? ?? const [])) (r as Map).cast<String, Object?>()];
}

final class _SupabaseAuth implements BackendAuth {
  _SupabaseAuth(this._client);

  final SupabaseClient _client;

  @override
  String? get email => _client.auth.currentUser?.email;

  @override
  Future<void> signInWithPassword(String email, String password) =>
      guard(() => _client.auth.signInWithPassword(email: email, password: password));

  @override
  Future<void> signUp(String email, String password) =>
      guard(() => _client.auth.signUp(email: email, password: password));

  @override
  Future<void> signOut() => guard(() => _client.auth.signOut());
}

/// Runs [body] and turns whatever it throws into a `BackendFailure`.
Future<T> guard<T>(Future<T> Function() body) async {
  try {
    return await body();
  } catch (e) {
    throw mapBackendError(e);
  }
}

/// The table in contracts/backend-gateway.md.
BackendFailure mapBackendError(Object e) {
  if (e is BackendFailure) return e;
  if (e is SocketException || e is TimeoutException || e is AuthRetryableFetchException) {
    return const BackendOffline();
  }
  // package:http's ClientException is not a direct dependency; match its name.
  if (e.runtimeType.toString() == 'ClientException') return const BackendOffline();
  if (e is PostgrestException) {
    final refused = BackendRefused.parse(e.message);
    if (refused != null) return refused;
    return switch (e.code) {
      '23505' || '23514' || '23P01' || '23503' => BackendConflict(e.code!, e.message),
      '42501' || 'PGRST301' || 'PGRST302' => BackendUnauthorized(e.message),
      _ => BackendError(e.message),
    };
  }
  if (e is AuthException) {
    final status = int.tryParse(e.statusCode ?? '');
    if (status == null || status >= 500) return BackendError(e.message);
    return BackendUnauthorized(e.message);
  }
  if (e is FunctionException) {
    final details = e.details;
    if (e.status == 409 && details is Map && details['refused'] is String) {
      return BackendRefused(details['refused'] as String, details['secondsLeft']?.toString());
    }
    if (e.status == 401 || e.status == 403) return BackendUnauthorized(e.reasonPhrase);
    return BackendError('function ${e.status}: ${e.reasonPhrase ?? details}');
  }
  return BackendError(e.toString());
}
