import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_sizes.dart';

/// Which mark to render. [symbol] is the ring+dot alone, [wordmark] is the
/// "Goora" text alone, [lockup] is the default: symbol + wordmark together.
enum GooraLogoVariant { symbol, wordmark, lockup }

/// [primary] is forest-on-paper, for light backgrounds. [reversed] is
/// paper-on-forest, for dark backgrounds. Each asset is a single flat color
/// baked in — never recolor it with an app token.
enum GooraLogoTone { primary, reversed }

/// Official brand mark, rendered from the SVG masters in `assets/brand/logo/`
/// (see `brand/README.md`). Never mirrored in RTL — the lockup is a fixed
/// asset in both languages.
class GooraLogo extends StatelessWidget {
  const GooraLogo({
    super.key,
    this.variant = GooraLogoVariant.lockup,
    this.tone = GooraLogoTone.reversed,
    this.size = AppSizes.logoMark,
  });

  static const brandName = 'Goora';

  final GooraLogoVariant variant;
  final GooraLogoTone tone;
  final double size;

  String get _assetPath {
    final toneName = tone == GooraLogoTone.primary ? 'primary' : 'reversed';
    final variantName = switch (variant) {
      GooraLogoVariant.symbol => 'symbol',
      GooraLogoVariant.wordmark => 'wordmark',
      GooraLogoVariant.lockup => 'lockup-horizontal',
    };
    return 'assets/brand/logo/goora-$variantName-$toneName.svg';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: brandName,
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SvgPicture.asset(_assetPath, height: size, fit: BoxFit.contain),
      ),
    );
  }
}
