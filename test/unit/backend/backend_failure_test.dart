import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/backend/backend_failure.dart';
import 'package:goora/core/backend/supabase_gateway.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapBackendError (011 contracts/backend-gateway.md)', () {
    test('network failures are offline', () {
      expect(mapBackendError(const SocketException('down')), isA<BackendOffline>());
      expect(mapBackendError(TimeoutException('slow')), isA<BackendOffline>());
      expect(mapBackendError(AuthRetryableFetchException()), isA<BackendOffline>());
    });

    test('a server refusal keeps its reason and detail', () {
      final f = mapBackendError(const PostgrestException(message: 'refused:domainTaken:acme.com', code: 'P0001'));
      expect(f, isA<BackendRefused>().having((r) => r.reason, 'reason', 'domainTaken').having((r) => r.detail, 'detail', 'acme.com'));
      final g = mapBackendError(const PostgrestException(message: 'refused:overLimit', code: 'P0001'));
      expect(g, isA<BackendRefused>().having((r) => r.reason, 'reason', 'overLimit').having((r) => r.detail, 'detail', null));
    });

    test('constraints are conflicts, row rules are unauthorized', () {
      expect(mapBackendError(const PostgrestException(message: 'contactsFull', code: '23514')),
          isA<BackendConflict>().having((c) => c.detail, 'detail', 'contactsFull'));
      expect(mapBackendError(const PostgrestException(message: 'dup', code: '23505')), isA<BackendConflict>());
      expect(mapBackendError(const PostgrestException(message: 'rls', code: '42501')), isA<BackendUnauthorized>());
    });

    test('auth: bad credentials are unauthorized, server errors are errors', () {
      expect(mapBackendError(const AuthApiException('Invalid login credentials', statusCode: '400')), isA<BackendUnauthorized>());
      expect(mapBackendError(const AuthApiException('boom', statusCode: '500')), isA<BackendError>());
    });

    test('an Edge Function 409 is a refusal (003 contract)', () {
      final f = mapBackendError(const FunctionException(status: 409, details: {'refused': 'tooEarly', 'secondsLeft': 40}));
      expect(f, isA<BackendRefused>().having((r) => r.reason, 'reason', 'tooEarly').having((r) => r.detail, 'detail', '40'));
    });

    test('anything else is a plain error; failures pass through', () {
      expect(mapBackendError(StateError('x')), isA<BackendError>());
      const offline = BackendOffline();
      expect(mapBackendError(offline), same(offline));
    });
  });
}
