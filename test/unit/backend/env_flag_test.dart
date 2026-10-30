import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/config/env.dart';

void main() {
  test('backendLive is off by default and needs both Supabase settings (011 FR-001, FR-003)', () {
    expect(Env.backendLiveRequested, isFalse);
    expect(Env.backendLive, isFalse);
  });
}
