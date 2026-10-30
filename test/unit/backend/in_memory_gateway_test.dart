import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/backend/backend_failure.dart';
import 'package:goora/core/backend/backend_gateway.dart';

import '../../contract/support/in_memory_gateway.dart';

void main() {
  test('keys clash on insert and replace on upsert; filters, order and limit read like PostgREST', () async {
    final db = InMemoryGateway(keys: {'t': ['id']});
    await db.insert('t', [{'id': 'a', 'n': 2}, {'id': 'b', 'n': 1}]);
    expect(() => db.insert('t', [{'id': 'a', 'n': 9}]), throwsA(isA<BackendConflict>()));
    await db.upsert('t', [{'id': 'a', 'n': 3}]);
    expect(await db.select('t', where: [const Filter.gte('n', 2)]), [{'id': 'a', 'n': 3}]);
    expect((await db.select('t', orderBy: 'n')).map((r) => r['id']), ['b', 'a']);
    expect((await db.select('t', orderBy: 'n', descending: true, limit: 1)).single['id'], 'a');
    await db.update('t', {'n': 0}, where: [const Filter.eq('id', 'b')]);
    await db.delete('t', where: [const Filter.inList('id', ['a'])]);
    expect(await db.select('t'), [{'id': 'b', 'n': 0}]);
  });

  test('auth: sign up, sign out, wrong password is unauthorized', () async {
    final db = InMemoryGateway();
    await db.auth.signUp('p@x.test', 'pw');
    final id = db.userId;
    expect(id, isNotNull);
    await db.auth.signOut();
    expect(db.userId, isNull);
    expect(() => db.auth.signInWithPassword('p@x.test', 'no'), throwsA(isA<BackendUnauthorized>()));
    await db.auth.signInWithPassword('p@x.test', 'pw');
    expect(db.userId, id);
  });

  test('rpc calls a registered handler and records the call', () async {
    final db = InMemoryGateway()..rpcs['f'] = (p, _) => (p['x']! as int) + 1;
    expect(await db.rpc('f', {'x': 1}), 2);
    expect(db.calls.single.$1, 'f');
    expect(() => db.rpc('missing'), throwsA(isA<BackendError>()));
  });
}
