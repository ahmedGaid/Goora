import 'package:intl/intl.dart';

final _grouped = NumberFormat('#,##0', 'en');

/// 15840 → "15,840". Digits stay Western and the separator stays "," in both
/// languages, as in every other money line.
String groupedInt(int value) => _grouped.format(value);
