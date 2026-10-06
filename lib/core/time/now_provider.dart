import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/preferences.dart';
import 'wall_time.dart';

part 'now_provider.g.dart';

typedef Now = WallTime Function();

/// The current Cairo wall-clock time (device local time). Tests override it
/// with a fixed value; debug builds may run on a demo clock (research R11).
@Riverpod(keepAlive: true)
Now now(Ref ref) {
  final demo = kDebugMode ? DemoClock.read(ref.watch(sharedPreferencesProvider)) : null;
  if (demo == null) return () => WallTime.of(DateTime.now());
  return () => demo.at.plusSeconds(DateTime.now().difference(demo.setAt).inSeconds);
}

/// Debug-only demo time: starts at [at] and runs forward from [setAt].
final class DemoClock {
  const DemoClock(this.at, this.setAt);

  static const storageKey = 'debug.demoNow';

  final WallTime at;
  final DateTime setAt;

  static DemoClock? read(SharedPreferences prefs) {
    final raw = prefs.getString(storageKey);
    if (raw == null) return null;
    final j = (jsonDecode(raw) as Map).cast<String, Object?>();
    return DemoClock(
      WallTime.fromJson(j['at']! as String),
      DateTime.fromMillisecondsSinceEpoch(j['setAt']! as int),
    );
  }

  static Future<void> write(SharedPreferences prefs, WallTime? at) => at == null
      ? prefs.remove(storageKey)
      : prefs.setString(
          storageKey,
          jsonEncode({'at': at.toJson(), 'setAt': DateTime.now().millisecondsSinceEpoch}),
        );
}
