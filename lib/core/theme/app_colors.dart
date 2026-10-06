import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const forest = Color(0xFF0B3B2E);
  static const primary = Color(0xFF0E3B2F);
  static const green = Color(0xFF1FA463);
  static const mint = Color(0xFF2BC275);
  static const greenText = Color(0xFF0E6B45);
  static const mintSurface = Color(0xFFE7F5EC);

  // Neutrals (light UI)
  static const background = Color(0xFFF5F4EF);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE6E8E2);
  static const borderStrong = Color(0xFFD7DCD6);
  static const divider = Color(0xFFEEF0EB);
  static const textPrimary = Color(0xFF10231C);
  static const textBody = Color(0xFF33433C);
  static const textSecondary = Color(0xFF56645E);
  static const textMuted = Color(0xFF8A968F);
  static const disabled = Color(0xFFB8C2BC);

  // On dark (forest/primary backgrounds)
  static const onDarkSecondary = Color(0xFFA9C9B9);
  static const onDarkBody = Color(0xFFD9EFE3);
  static const onDarkBorder = Color(0xFF3E6B5B);
  static const onDarkDivider = Color(0xFF23574A);

  // Status
  static const warningBg = Color(0xFFFFF4E5);
  static const warningBorder = Color(0xFFF5C98A);
  static const warningTitle = Color(0xFF8A4B00);
  static const warningBody = Color(0xFF5B3A10);
  static const infoBg = Color(0xFFEEF2F7);
  static const infoBorder = Color(0xFFC9D4E3);
  static const infoTitle = Color(0xFF23364F);
  static const infoBody = Color(0xFF3A4A60);
  static const danger = Color(0xFFC93A3A);
  static const dangerText = Color(0xFFA33030);
  static const dangerBorder = Color(0xFFE3B4B4);
  static const dangerBg = Color(0xFFFBECEC);

  // Map
  static const mapLand = Color(0xFFEAF0E8);
  static const mapDestination = Color(0xFFD64545);

  // Avatar fallbacks (initials on these, white text)
  static const avatarPalette = [
    Color(0xFFC9A27A),
    Color(0xFF5B7C99),
    Color(0xFFB5677D),
    Color(0xFF7A8F55),
  ];

  static const white = Color(0xFFFFFFFF);

  // Language pill on dark backgrounds (prototype: white at 12% / 25%).
  static const onDarkPillFill = Color(0x1FFFFFFF);
  static const onDarkPillBorder = Color(0x40FFFFFF);
}
