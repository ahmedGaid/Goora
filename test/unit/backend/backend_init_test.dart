import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/backend/backend.dart';
import 'package:goora/core/backend/backend_gateway.dart';

final class _NoGateway implements BackendGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  tearDown(Backend.reset);

  Future<bool> up(String url, String key) async => true;
  Future<bool> down(String url, String key) async => false;
  Future<BackendGateway> connect(String url, String key) async => _NoGateway();

  test('off: fake, nothing probed (011 FR-001)', () async {
    var probed = false;
    final mode = await Backend.init(url: 'http://127.0.0.1:54321', anonKey: 'k', probe: (u, k) async => probed = true);
    expect(mode, BackendMode.fake);
    expect(probed, isFalse);
    expect(() => Backend.gateway, throwsStateError);
  });

  test('on without a URL or key: fake (US1/AC3)', () async {
    expect(await Backend.init(live: true, url: '', anonKey: 'k', probe: up, connect: connect), BackendMode.fake);
    expect(await Backend.init(live: true, url: 'http://x', anonKey: '', probe: up, connect: connect), BackendMode.fake);
  });

  test('on but unreachable: fake for this run (US5/AC1)', () async {
    expect(await Backend.init(live: true, url: 'http://x', anonKey: 'k', probe: down, connect: connect), BackendMode.fake);
  });

  test('on and reachable: live with a gateway', () async {
    expect(await Backend.init(live: true, url: 'http://x', anonKey: 'k', probe: up, connect: connect), BackendMode.live);
    expect(Backend.gateway, isA<_NoGateway>());
  });

  test('the real probe says no to a closed port', () async {
    expect(await Backend.healthy('http://127.0.0.1:9', 'k'), isFalse);
  });
}
