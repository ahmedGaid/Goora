import 'package:intl/intl.dart';

/// Numbers always use Western digits (brief §3.2), in both locales.
abstract final class AppFormat {
  static final _int = NumberFormat.decimalPattern('en');

  static String number(num value) => _int.format(value);
}
