import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_avatar.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_ghost_button.dart';
import '../../../../core/widgets/goora_icons.dart';
import '../../../../core/widgets/goora_pill.dart';
import '../../../../core/widgets/goora_progress_bar.dart';
import '../../domain/privacy.dart';
import '../../domain/trust.dart';
import '../labels.dart';
import '../shell/tab_page.dart';
import '../today/today_widgets.dart';
import 'trust_controller.dart';
import 'trusted_contacts_sheet.dart';

/// Trust tab: profile, verification, reliability, role switch, who can ride
/// with me, trusted contacts (US6, FR-023 – FR-027).
class TrustScreen extends ConsumerWidget {
  const TrustScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(trustControllerProvider);
    final view = state.value;
    if (view == null) {
      return TabPage(
        title: l10n.tabTrust,
        children: [TabLoadState(failed: state.hasError, onRetry: () => ref.invalidate(trustControllerProvider))],
      );
    }
    final p = view.profile;
    return TabPage(
      title: l10n.tabTrust,
      children: [
        _ProfileCard(profile: p),
        const SizedBox(height: AppSpacing.gap),
        SectionTitle(l10n.verificationTitle),
        GooraCard.rows(rows: [for (final item in p.items) _CheckRow(item: item)]),
        const SizedBox(height: AppSpacing.gap),
        _ReliabilityCard(reliability: view.reliability),
        const SizedBox(height: AppSpacing.gap),
        GooraGhostButton(
          key: const Key('trust-switch-role'),
          label: view.isDriver ? l10n.toRider : l10n.toDriver,
          onPressed: () => _switchRole(context, ref, toDriver: !view.isDriver),
        ),
        const SizedBox(height: AppSpacing.gap),
        SectionTitle(l10n.whoRide),
        _PrivacyPills(profile: p),
        const SizedBox(height: AppSpacing.gap),
        _ContactsCard(contacts: view.contacts),
      ],
    );
  }

  Future<void> _switchRole(BuildContext context, WidgetRef ref, {required bool toDriver}) async {
    final router = GoRouter.of(context);
    await switchCommuteRole(ref);
    // A new driver sets seats, trips and contribution (US6/AC4).
    if (toDriver) router.go(Routes.commuteSetup);
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final TrustProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GooraCard(
      child: Row(
        children: [
          GooraAvatar(initials: profile.initials, size: GooraAvatarSize.s52),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.firstName, style: AppTypography.h2.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    const Icon(GooraIcons.verified, size: AppSizes.iconTiny, color: AppColors.greenText),
                    const SizedBox(width: AppSpacing.xxs),
                    Flexible(
                      child: Text(
                        l10n.verifiedMemberRating(profile.rating.toStringAsFixed(1)),
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A checklist line: the item and its status as icon + word (FR-023a).
class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.item});

  final VerificationItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (IconData? icon, Color color, String text) = switch (item.status) {
      VerificationStatus.verified => (GooraIcons.verified, AppColors.greenText, l10n.verified),
      VerificationStatus.notVerified => (GooraIcons.waiting, AppColors.warningTitle, l10n.notVerified),
      VerificationStatus.notNeeded => (null, AppColors.textSecondary, l10n.notNeeded),
    };
    return Row(
      key: Key('check-${item.kind.name}'),
      children: [
        Expanded(
          child: Text(l10n.checkLabel(item.kind), style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
        ),
        if (icon != null) ...[
          Icon(icon, size: AppSizes.iconTiny, color: color),
          const SizedBox(width: AppSpacing.xxs),
        ],
        Text(text, style: AppTypography.bodySmall.copyWith(color: color)),
      ],
    );
  }
}

/// "Reliability", the % as text and bar, and this month's facts (FR-036).
class _ReliabilityCard extends StatelessWidget {
  const _ReliabilityCard({required this.reliability});

  final Reliability reliability;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = reliability;
    final caption = AppTypography.caption.copyWith(color: AppColors.textSecondary);
    return GooraCard(
      key: const Key('reliability'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GooraProgressBar(value: r.percent / 100, valueLabel: l10n.percentValue(r.percent), label: l10n.reliability),
          const SizedBox(height: AppSpacing.sm),
          if (r.monthLateCancels > 0) Text(l10n.relLateCancels(r.monthLateCancels), style: caption),
          if (r.monthNoShows > 0) Text(l10n.relNoShows(r.monthNoShows), style: caption),
          Text(l10n.relRule, style: caption),
        ],
      ),
    );
  }
}

/// One pill per offered preference; unavailable ones stay visible, disabled,
/// with a hint ("Women only" is not offered to men) (FR-024 – FR-026).
class _PrivacyPills extends ConsumerWidget {
  const _PrivacyPills({required this.profile});

  final TrustProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final facts = profile.facts;
    final shown = [for (final p in PrivacyPreference.values) if (PrivacyRules.shown(p, facts)) p];
    final hints = [
      for (final p in shown)
        if (!PrivacyRules.available(p, facts) && l10n.privacyHint(p) != null) l10n.privacyHint(p)!,
    ];
    final caption = AppTypography.caption.copyWith(color: AppColors.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final p in shown)
              GooraPill(
                key: Key('privacy-${p.name}'),
                label: l10n.privacyLabel(p),
                selected: profile.privacy == p,
                onTap: PrivacyRules.available(p, facts)
                    ? () => ref.read(trustControllerProvider.notifier).setPrivacy(p)
                    : null,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final h in hints) Text(h, style: caption),
        Text(l10n.privacyNote, style: caption),
      ],
    );
  }
}

class _ContactsCard extends StatelessWidget {
  const _ContactsCard({required this.contacts});

  final List<TrustedContact> contacts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GooraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.trustedTitle, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
          Text(
            contacts.isEmpty ? l10n.sosNoContacts : l10n.trustedCount(contacts.length),
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          GooraGhostButton(
            key: const Key('open-contacts'),
            label: contacts.isEmpty ? l10n.trustedAdd : l10n.trustedTitle,
            onPressed: () => showTrustedContactsSheet(context),
          ),
        ],
      ),
    );
  }
}
