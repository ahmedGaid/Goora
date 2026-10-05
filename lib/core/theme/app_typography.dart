import 'package:flutter/painting.dart';

/// Sizes and weights from brief §3.2. The font family comes from the theme
/// per locale (Cairo for ar, Plus Jakarta Sans for en); only [wordmark]
/// pins a family because the logo is always Plus Jakarta Sans.
abstract final class AppTypography {
  static const arabicFamily = 'Cairo';
  static const englishFamily = 'PlusJakartaSans';

  static String familyFor(String languageCode) =>
      languageCode == 'ar' ? arabicFamily : englishFamily;

  /// Cairo has no arrows (← →) or ★; Plus Jakarta Sans fills them in, offline.
  static List<String>? fallbackFor(String languageCode) => languageCode == 'ar' ? const [englishFamily] : null;

  static String otherFamilyFor(String languageCode) =>
      languageCode == 'ar' ? englishFamily : arabicFamily;

  static const _heading = 1.2;
  static const _body = 1.5;

  static const wordmark = TextStyle(
    fontFamily: englishFamily,
    fontSize: 56,
    fontWeight: FontWeight.w800,
    letterSpacing: -2,
    height: _heading,
  );
  static const display = TextStyle(fontSize: 38, fontWeight: FontWeight.w800, height: _heading);
  static const h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: _heading);
  static const h2 = TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: _heading);
  static const title = TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: _heading);
  static const heroTime = TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: _heading);
  static const section = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: _body);
  static const bodyStrong = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: _body);
  static const body = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: _body);
  static const bodySemi = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: _body);
  static const bodySmall = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: _body);
  static const caption = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, height: _body);
  static const captionSemi = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, height: _body);
  static const micro = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: _body);
  static const microBold = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: _body);

  // §3.4 / prototype values outside the §3.2 table (founder decision 2026-10-05).
  static const button = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: _heading);
  static const buttonSecondary = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: _heading);
  static const dashed = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, height: _heading);
  static const chip = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: _heading);
  static const pillSelected = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: _heading);
  static const pillUnselected = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: _heading);
  static const taglineLarge = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: _heading);
  static const taglineSmall = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: _heading);
  static const splashSub = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.7);
  static const cardTitle = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: _heading);
  static const cardSub = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w400, height: _body);
  static const langPill = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: _heading);
  static const stat = TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: _heading);
  static const avatarInitials = TextStyle(fontWeight: FontWeight.w700, height: 1);
}
