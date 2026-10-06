import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_ghost_button.dart';
import '../../../../core/widgets/goora_icons.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../data/providers.dart';
import '../../domain/trust.dart';

/// SOS: one confirm step → "Call 122" and "Alert my trusted contacts" with
/// the trip link (FR-029, FR-030, SC-006). Works with no active trip; with
/// no contacts it invites adding one in the Trust tab.
Future<void> showSosSheet(BuildContext context, {String? rideId}) => showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      builder: (_) => SosSheet(rideId: rideId),
    );

class SosSheet extends ConsumerStatefulWidget {
  const SosSheet({super.key, this.rideId});

  static const emergencyNumber = '122';

  /// The current trip, linked in the alert; null when there is none.
  final String? rideId;

  @override
  ConsumerState<SosSheet> createState() => _SosSheetState();
}

class _SosSheetState extends ConsumerState<SosSheet> {
  late final Future<List<TrustedContact>> _contacts = ref.read(trustRepositoryProvider).contacts();
  bool _sending = false;
  bool _sent = false;

  Future<void> _alert() async {
    setState(() => _sending = true);
    try {
      await ref.read(trustRepositoryProvider).sendSos(rideId: widget.rideId);
      if (mounted) setState(() => _sent = true);
    } finally {
      // A failed send leaves the button ready to try again; 122 stays above.
      if (mounted) setState(() => _sending = false);
    }
  }

  void _addContact() {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(Routes.trust);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.tabH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.sosTitle, style: AppTypography.title.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.gap),
            GooraPrimaryButton(
              key: const Key('sos-call'),
              label: l10n.sosCall,
              onPressed: () => ref.read(phoneDialerProvider).dial(SosSheet.emergencyNumber),
            ),
            const SizedBox(height: AppSpacing.md),
            FutureBuilder<List<TrustedContact>>(
              future: _contacts,
              builder: (context, snap) {
                // Contacts that cannot be read are treated as none: Call 122 and
                // "Add contact" still work.
                final contacts = snap.data ?? (snap.hasError ? const <TrustedContact>[] : null);
                // Same height while loading, so the sheet does not jump.
                if (contacts == null) return const SizedBox(height: AppSizes.ghostButtonHeight);
                if (contacts.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.sosNoContacts, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.md),
                      GooraGhostButton(
                        key: const Key('sos-add-contact'),
                        label: l10n.trustedAdd,
                        icon: GooraIcons.plus,
                        onPressed: _addContact,
                      ),
                    ],
                  );
                }
                if (_sent) {
                  return Semantics(
                    liveRegion: true,
                    child: Row(
                      key: const Key('sos-sent'),
                      children: [
                        const Icon(GooraIcons.check, size: AppSizes.iconSmall, color: AppColors.greenText),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(l10n.sosAlertSent, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
                        ),
                      ],
                    ),
                  );
                }
                return GooraGhostButton(
                  key: const Key('sos-alert'),
                  label: l10n.sosAlert,
                  danger: true,
                  onPressed: _sending ? null : _alert,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
