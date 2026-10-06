import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/now_provider.dart';
import '../../../core/time/wall_time.dart';

/// Rebuilds only its own subtree with the current time, once a second and
/// only when the time changed (research R2: countdowns tick without
/// rebuilding the tab).
class NowTicker extends ConsumerStatefulWidget {
  const NowTicker({super.key, required this.builder});

  final Widget Function(BuildContext context, WallTime now) builder;

  @override
  ConsumerState<NowTicker> createState() => _NowTickerState();
}

class _NowTickerState extends ConsumerState<NowTicker> {
  late WallTime _now = ref.read(nowProvider)();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = ref.read(nowProvider)();
      if (now != _now) setState(() => _now = now);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}
