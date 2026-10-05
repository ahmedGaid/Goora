import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'goora_icons.dart';

enum GooraAvatarSize {
  s40(40),
  s44(44),
  s48(48),
  s52(52);

  const GooraAvatarSize(this.value);
  final double value;
}

/// Circle avatar: photo, or initials on a palette color.
class GooraAvatar extends StatelessWidget {
  const GooraAvatar({
    super.key,
    required this.initials,
    this.size = GooraAvatarSize.s44,
    this.image,
    this.paletteIndex = 0,
    this.highlight = false,
    this.ring = false,
  }) : anonymous = false,
       semanticLabel = null;

  /// No name or photo: used for riders shown to drivers (constitution IV).
  const GooraAvatar.anonymous({
    super.key,
    required String this.semanticLabel,
    this.size = GooraAvatarSize.s44,
    this.ring = false,
  })  : initials = '',
        image = null,
        paletteIndex = 0,
        highlight = false,
        anonymous = true;

  final bool anonymous;

  /// Spoken label for the anonymous avatar ("Verified rider").
  final String? semanticLabel;

  final String initials;
  final GooraAvatarSize size;
  final ImageProvider? image;
  final int paletteIndex;

  /// "Me" avatar uses the primary color.
  final bool highlight;

  /// 3 px white ring, used in group stacks.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final bg = anonymous
        ? AppColors.textSecondary
        : highlight
        ? AppColors.primary
        : AppColors.avatarPalette[paletteIndex % AppColors.avatarPalette.length];
    final d = size.value;
    final avatar = Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: ring ? Border.all(color: AppColors.white, width: AppSpacing.avatarRing) : null,
        image: image == null ? null : DecorationImage(image: image!, fit: BoxFit.cover),
      ),
      alignment: AlignmentDirectional.center,
      child: anonymous
          ? Icon(GooraIcons.person, size: d * 0.5, color: AppColors.white)
          : image != null
          ? null
          : Text(
              initials,
              style: AppTypography.avatarInitials.copyWith(color: AppColors.white, fontSize: d * 0.36),
            ),
    );
    return semanticLabel == null
        ? avatar
        : Semantics(label: semanticLabel, excludeSemantics: true, child: avatar);
  }
}

/// Overlapping avatars: each one after the first overlaps the previous by 12
/// at its start side (brief §3.4: margin-start −12).
class GooraAvatarStack extends StatelessWidget {
  const GooraAvatarStack({super.key, required this.avatars});

  final List<GooraAvatar> avatars;

  @override
  Widget build(BuildContext context) {
    if (avatars.isEmpty) return const SizedBox.shrink();
    final d = avatars.first.size.value;
    final step = d + AppSpacing.avatarOverlap;
    return SizedBox(
      width: d + step * (avatars.length - 1),
      height: d,
      child: Stack(
        children: [
          for (var i = 0; i < avatars.length; i++)
            PositionedDirectional(start: step * i, top: 0, child: avatars[i]),
        ],
      ),
    );
  }
}
