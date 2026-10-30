import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../config/env.dart';
import 'backend_gateway.dart';
import 'supabase_gateway.dart';

/// Which repositories the app runs on (011 research D1, D2).
enum BackendMode { fake, live }

typedef BackendProbe = Future<bool> Function(String url, String anonKey);
typedef BackendConnect = Future<BackendGateway> Function(String url, String anonKey);

/// Chooses the mode once, before the first frame (research D6, D21).
abstract final class Backend {
  static BackendMode _mode = BackendMode.fake;
  static BackendGateway? _gateway;

  static BackendMode get mode => _mode;

  /// The live gateway; only valid in [BackendMode.live].
  static BackendGateway get gateway => _gateway ?? (throw StateError('Backend is not live'));

  /// Off (no flag, or no URL/key) → fake, nothing touched. On → connect and
  /// probe the server; unreachable → fake for this run, as before 011.
  static Future<BackendMode> init({
    bool live = false,
    String url = Env.supabaseUrl,
    String anonKey = Env.supabaseAnonKey,
    BackendProbe probe = healthy,
    BackendConnect connect = _connect,
  }) async {
    _mode = BackendMode.fake;
    _gateway = null;
    if (!live || url.isEmpty || anonKey.isEmpty) return _mode;
    if (!await probe(url, anonKey)) {
      debugPrint('Goora backend: $url unreachable, running on the on-device data this time');
      return _mode;
    }
    _gateway = await connect(url, anonKey);
    return _mode = BackendMode.live;
  }

  /// `init` with the build's settings (`Env.backendLive`).
  static Future<BackendMode> initFromEnv() => init(live: Env.backendLive);

  /// Test hook: back to the default.
  @visibleForTesting
  static void reset() {
    _mode = BackendMode.fake;
    _gateway = null;
  }

  static Future<BackendGateway> _connect(String url, String anonKey) async {
    // The env key is the local anon (publishable) key; the parameter name moved, the value did not.
    await Supabase.initialize(url: url, publishableKey: anonKey);
    return SupabaseGateway(Supabase.instance.client);
  }

  /// GET `<url>/auth/v1/health`, 3 s at most.
  static Future<bool> healthy(String url, String anonKey) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final request = await client.getUrl(Uri.parse('$url/auth/v1/health')).timeout(const Duration(seconds: 3));
      request.headers.set('apikey', anonKey);
      final response = await request.close().timeout(const Duration(seconds: 3));
      await response.drain<void>();
      return response.statusCode == 200;
    } on Object {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
