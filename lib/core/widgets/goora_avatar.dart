import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

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
  });

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
    final bg = highlight
        ? AppColors.primary
        : AppColors.avatarPalette[paletteIndex % AppColors.avatarPalette.length];
    final d = size.value;
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: ring ? Border.all(color: AppColors.white, width: AppSpacing.avatarRing) : null,
        image: image == null ? null : DecorationImage(image: image!, fit: BoxFit.cover),
      ),
      alignment: AlignmentDirectional.center,
      child: image != null
          ? null
          : Text(
              initials,
              style: AppTypography.avatarInitials.copyWith(color: AppColors.white, fontSize: d * 0.36),
            ),
    );
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
