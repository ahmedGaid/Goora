import 'package:flutter/material.dart';

import '../../../app/language_toggle.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/goora_avatar.dart';
import '../../../core/widgets/goora_banner.dart';
import '../../../core/widgets/goora_bottom_nav.dart';
import '../../../core/widgets/goora_card.dart';
import '../../../core/widgets/goora_dashed_button.dart';
import '../../../core/widgets/goora_ghost_button.dart';
import '../../../core/widgets/goora_icons.dart';
import '../../../core/widgets/goora_logo.dart';
import '../../../core/widgets/goora_pill.dart';
import '../../../core/widgets/goora_primary_button.dart';
import '../../../core/widgets/goora_progress_bar.dart';
import '../../../core/widgets/goora_progress_dots.dart';
import '../../../core/widgets/goora_radio_card.dart';
import '../../../core/widgets/goora_route_map.dart';
import '../../../core/widgets/goora_stat_tile.dart';
import '../../../core/widgets/goora_status_chip.dart';
import '../../../core/widgets/goora_stepper.dart';
import '../../../core/widgets/goora_timeline_row.dart';

/// Debug-only: every token and shared component, in the current language.
class DesignGalleryScreen extends StatefulWidget {
  const DesignGalleryScreen({super.key});

  @override
  State<DesignGalleryScreen> createState() => _DesignGalleryScreenState();
}

class _DesignGalleryScreenState extends State<DesignGalleryScreen> {
  int _pill = 0;
  bool _radio = true;
  int _seats = 2;
  int _tab = 0;

  static const _colors = <(String, Color)>[
    ('forest', AppColors.forest),
    ('primary', AppColors.primary),
    ('green', AppColors.green),
    ('mint', AppColors.mint),
    ('greenText', AppColors.greenText),
    ('mintSurface', AppColors.mintSurface),
    ('background', AppColors.background),
    ('surface', AppColors.surface),
    ('border', AppColors.border),
    ('borderStrong', AppColors.borderStrong),
    ('divider', AppColors.divider),
    ('textPrimary', AppColors.textPrimary),
    ('textBody', AppColors.textBody),
    ('textSecondary', AppColors.textSecondary),
    ('textMuted', AppColors.textMuted),
    ('disabled', AppColors.disabled),
    ('onDarkSecondary', AppColors.onDarkSecondary),
    ('onDarkBody', AppColors.onDarkBody),
    ('onDarkBorder', AppColors.onDarkBorder),
    ('onDarkDivider', AppColors.onDarkDivider),
    ('warningBg', AppColors.warningBg),
    ('warningBorder', AppColors.warningBorder),
    ('warningTitle', AppColors.warningTitle),
    ('warningBody', AppColors.warningBody),
    ('infoBg', AppColors.infoBg),
    ('infoBorder', AppColors.infoBorder),
    ('infoTitle', AppColors.infoTitle),
    ('infoBody', AppColors.infoBody),
    ('danger', AppColors.danger),
    ('dangerText', AppColors.dangerText),
    ('dangerBorder', AppColors.dangerBorder),
    ('mapLand', AppColors.mapLand),
    ('mapDestination', AppColors.mapDestination),
  ];

  static const _type = <(String, TextStyle)>[
    ('display', AppTypography.display),
    ('h1', AppTypography.h1),
    ('h2', AppTypography.h2),
    ('title', AppTypography.title),
    ('heroTime', AppTypography.heroTime),
    ('section', AppTypography.section),
    ('bodyStrong', AppTypography.bodyStrong),
    ('body', AppTypography.body),
    ('bodySmall', AppTypography.bodySmall),
    ('caption', AppTypography.caption),
    ('micro', AppTypography.micro),
  ];

  static const _radii = <(String, double)>[
    ('pill', AppRadii.pill),
    ('button', AppRadii.button),
    ('tile', AppRadii.tile),
    ('card', AppRadii.card),
    ('hero', AppRadii.hero),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokenStyle = AppTypography.caption.copyWith(color: AppColors.textSecondary);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.galleryTitle, style: AppTypography.section),
        backgroundColor: AppColors.background,
        actions: const [LanguageToggle(), SizedBox(width: AppSpacing.md)],
      ),
      bottomNavigationBar: GooraBottomNav(
        semanticLabel: l10n.navMain,
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: [
          GooraNavItem(icon: GooraIcons.today, label: l10n.tabToday),
          GooraNavItem(icon: GooraIcons.week, label: l10n.tabWeek),
          GooraNavItem(icon: GooraIcons.wallet, label: l10n.tabWallet),
          GooraNavItem(icon: GooraIcons.trust, label: l10n.tabTrust),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.tabH),
        children: [
          _Section(l10n.galleryColors),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (name, color) in _colors)
                SizedBox(
                  width: AppSizes.iconTileLarge + AppSpacing.lg,
                  child: Column(
                    children: [
                      Container(
                        height: AppSizes.minTouch,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          border: Border.all(color: AppColors.border),
                        ),
                      ),
                      Text(name, style: tokenStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
            ],
          ),
          _Section(l10n.galleryType),
          Container(
            color: AppColors.forest,
            padding: const EdgeInsetsDirectional.all(AppSpacing.cardPad),
            child: const Align(alignment: AlignmentDirectional.centerStart, child: GooraLogo()),
          ),
          for (final (name, style) in _type)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SizedBox(width: AppSizes.iconTileLarge + AppSpacing.lg, child: Text(name, style: tokenStyle)),
                  Expanded(child: Text(l10n.tagline, style: style)),
                ],
              ),
            ),
          _Section(l10n.galleryShape),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final (name, r) in _radii)
                Column(
                  children: [
                    Container(
                      width: AppSizes.iconTileLarge,
                      height: AppSizes.iconTileLarge,
                      decoration: BoxDecoration(
                        color: AppColors.mintSurface,
                        borderRadius: BorderRadius.circular(r),
                        border: Border.all(color: AppColors.green),
                      ),
                    ),
                    Text(name, style: tokenStyle),
                  ],
                ),
            ],
          ),
          _Section(l10n.galleryButtons),
          GooraPrimaryButton(label: l10n.getStarted, trailingArrow: true, onPressed: () {}),
          const SizedBox(height: AppSpacing.gap),
          GooraPrimaryButton(label: l10n.continueBtn, onPressed: null),
          const SizedBox(height: AppSpacing.gap),
          Container(
            color: AppColors.forest,
            padding: const EdgeInsetsDirectional.all(AppSpacing.cardPad),
            child: Column(
              children: [
                GooraPrimaryButton(
                  label: l10n.getStarted,
                  trailingArrow: true,
                  variant: GooraPrimaryVariant.onDark,
                  onPressed: () {},
                ),
                const SizedBox(height: AppSpacing.md),
                GooraPrimaryButton(
                  label: l10n.login,
                  variant: GooraPrimaryVariant.outlineOnDark,
                  onPressed: () {},
                ),
                const SizedBox(height: AppSpacing.md),
                const Align(alignment: AlignmentDirectional.centerEnd, child: LanguageToggle(onDark: true)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gap),
          GooraGhostButton(label: l10n.join, onPressed: () {}),
          const SizedBox(height: AppSpacing.gap),
          GooraGhostButton(label: l10n.cantCome, danger: true, onPressed: () {}),
          const SizedBox(height: AppSpacing.gap),
          GooraDashedButton(label: l10n.postReq, onPressed: () {}),
          _Section(l10n.galleryCards),
          GooraCard.rows(
            rows: [
              Text(l10n.confirmed, style: AppTypography.bodyStrong),
              Text(l10n.covered, style: AppTypography.body),
            ],
          ),
          const SizedBox(height: AppSpacing.gap),
          GooraHeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.confirmed, style: AppTypography.bodySmall.copyWith(color: AppColors.onDarkSecondary)),
                Text(l10n.pickupIn, style: AppTypography.heroTime),
                Text(l10n.verifiedMember, style: AppTypography.bodySmall.copyWith(color: AppColors.onDarkBody)),
              ],
            ),
          ),
          _Section(l10n.gallerySelection),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (i, label) in [l10n.dirBoth, l10n.dirGoing, l10n.dirRet].indexed)
                GooraPill(label: label, selected: _pill == i, onTap: () => setState(() => _pill = i)),
            ],
          ),
          const SizedBox(height: AppSpacing.gap),
          Wrap(
            spacing: AppSpacing.sm,
            children: [GooraChip(label: l10n.matchPercent(92)), GooraChip(label: l10n.verifiedMember, icon: GooraIcons.check)],
          ),
          const SizedBox(height: AppSpacing.gap),
          GooraRadioCard(
            icon: GooraIcons.calendar,
            title: l10n.fRegular,
            chipLabel: l10n.fTag,
            subtitle: l10n.fRegRider,
            selected: _radio,
            onTap: () => setState(() => _radio = true),
          ),
          const SizedBox(height: AppSpacing.gap),
          GooraRadioCard(
            icon: GooraIcons.route,
            title: l10n.fOnce,
            subtitle: l10n.fOnceRider,
            selected: !_radio,
            onTap: () => setState(() => _radio = false),
          ),
          const SizedBox(height: AppSpacing.gap),
          GooraStepper(
            valueLabel: l10n.stepperValue('$_seats'),
            decreaseLabel: l10n.galleryDecrease,
            increaseLabel: l10n.galleryIncrease,
            onDecrease: _seats > 1 ? () => setState(() => _seats--) : null,
            onIncrease: _seats < 4 ? () => setState(() => _seats++) : null,
          ),
          const SizedBox(height: AppSpacing.gap),
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
              child: GooraProgressDots(count: 3, current: i, semanticLabel: l10n.stepOf(i + 1, 3)),
            ),
          _Section(l10n.galleryFeedback),
          GooraBanner(
            kind: GooraBannerKind.warning,
            title: l10n.backupTitle,
            body: l10n.backupBody,
            actionLabel: l10n.gotIt,
            onAction: () {},
          ),
          const SizedBox(height: AppSpacing.gap),
          GooraBanner(kind: GooraBannerKind.info, title: l10n.extraTrip, body: l10n.subNote),
          _Section(l10n.galleryPeople),
          Wrap(
            spacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final (i, size) in GooraAvatarSize.values.indexed)
                GooraAvatar(initials: 'AM', size: size, paletteIndex: i, highlight: i == 0),
            ],
          ),
          const SizedBox(height: AppSpacing.gap),
          const GooraAvatarStack(
            avatars: [
              GooraAvatar(initials: 'AM', ring: true, highlight: true),
              GooraAvatar(initials: 'MH', ring: true, paletteIndex: 1),
              GooraAvatar(initials: 'SR', ring: true, paletteIndex: 2),
              GooraAvatar(initials: 'YS', ring: true, paletteIndex: 3),
            ],
          ),
          const SizedBox(height: AppSpacing.gap),
          GooraTimelineRow(kind: GooraTimelineKind.pickup, title: l10n.arrivedBtn, subtitle: l10n.pickupIn),
          const SizedBox(height: AppSpacing.sm),
          GooraTimelineRow(kind: GooraTimelineKind.transit, title: l10n.covered),
          const SizedBox(height: AppSpacing.sm),
          GooraTimelineRow(kind: GooraTimelineKind.arrival, title: l10n.confirmed),
          const SizedBox(height: AppSpacing.gap),
          GooraRouteMap(
            fromLabel: l10n.areaSheikhZayed,
            toLabel: l10n.areaSmartVillage,
            semanticLabel: l10n.mapAria,
          ),
          const SizedBox(height: AppSpacing.gap),
          GooraRouteMap(
            fromLabel: l10n.areaSheikhZayed,
            toLabel: l10n.areaSmartVillage,
            semanticLabel: l10n.mapAria,
            driverProgress: 0.4,
          ),
          const SizedBox(height: AppSpacing.gap),
          Row(
            children: [
              Expanded(child: GooraStatTile(label: l10n.returnTime, value: l10n.timePm('5:00'))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: GooraStatTile(label: l10n.payPerTrip, value: l10n.egpAmount(44), caption: l10n.priceWithFee(40, 4))),
            ],
          ),
          const SizedBox(height: AppSpacing.gap),
          GooraProgressBar(value: 0.96, valueLabel: '96%', label: l10n.reliability),
          const SizedBox(height: AppSpacing.gap),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              GooraStatusChip(status: GooraStatus.covered, label: l10n.covered),
              GooraStatusChip(status: GooraStatus.waiting, label: l10n.stWaiting('4:12')),
              GooraStatusChip(status: GooraStatus.pickedUp, label: l10n.pickedUp),
              GooraStatusChip(status: GooraStatus.noShow, label: l10n.stNoShow),
              GooraStatusChip(status: GooraStatus.backup, label: l10n.backupName('Mohamed')),
              GooraStatusChip(status: GooraStatus.off, label: l10n.youOff),
            ],
          ),
          _Section(l10n.galleryNav),
          Text(l10n.navMain, style: tokenStyle),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.xl, bottom: AppSpacing.md),
      child: Text(label, style: AppTypography.h2.copyWith(color: AppColors.textPrimary)),
    );
  }
}
