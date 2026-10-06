import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Constitution III + VI: feature and app code use tokens and ARB strings only.
/// Raw values may live only in lib/core/theme and the ARB files.
void main() {
  final rules = <String, RegExp>{
    'raw Color(...)': RegExp(r'\bColor\(0x'),
    'Colors.* (use AppColors)': RegExp(r'\bColors\.(?!transparent\b)\w+'),
    'raw fontSize': RegExp(r'fontSize:\s*\d'),
    'raw radius': RegExp(r'(BorderRadius|Radius)\.circular\(\s*\d'),
    'physical left/right insets': RegExp(r'EdgeInsets\.(only|fromLTRB)\('),
    'physical alignment': RegExp(r'Alignment\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)\b'),
    'Positioned left/right': RegExp(r'\b(left|right):\s*[\d.]'),
    'hard-coded Text string': RegExp(r'''\bText\(\s*['"]'''),
  };

  // lib/features includes lib/features/daily (003).
  final roots = ['lib/app', 'lib/features', 'lib/core/widgets', 'lib/core/time'];
  final files = [
    for (final root in roots)
      ...Directory(root)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart')),
  ];

  test('scans a non-empty source tree', () => expect(files, isNotEmpty));

  for (final entry in rules.entries) {
    test('no ${entry.key}', () {
      final hits = <String>[];
      for (final f in files) {
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trimLeft();
          if (line.startsWith('//')) continue;
          if (entry.value.hasMatch(line)) hits.add('${f.path}:${i + 1}: $line');
        }
      }
      expect(hits, isEmpty, reason: hits.join('\n'));
    });
  }
}
