import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_avatar.dart';
import '../../../../core/widgets/goora_icons.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import '../../../../core/widgets/goora_text_field.dart';
import '../../../onboarding/domain/phone_number.dart';
import '../../../onboarding/domain/profile.dart';
import '../../domain/trust.dart';
import 'trust_controller.dart';

Future<void> showTrustedContactsSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => const TrustedContactsSheet(),
    );

/// Up to 3 trusted contacts, name + Egyptian mobile (FR-027, research R10).
class TrustedContactsSheet extends ConsumerStatefulWidget {
  const TrustedContactsSheet({super.key});

  @override
  ConsumerState<TrustedContactsSheet> createState() => _TrustedContactsSheetState();
}

class _TrustedContactsSheetState extends ConsumerState<TrustedContactsSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  PhoneNumber? _parsed;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    setState(() => _busy = true);
    await ref.read(trustControllerProvider.notifier).addContact(_name.text, _parsed!);
    _name.clear();
    _phone.clear();
    if (!mounted) return;
    setState(() {
      _parsed = null;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contacts = ref.watch(trustControllerProvider).value?.contacts ?? const <TrustedContact>[];
    final full = contacts.length >= TrustedContact.max;
    final canAdd = !_busy && _parsed != null && Profile.isValidName(_name.text);
    final secondary = AppTypography.bodySmall.copyWith(color: AppColors.textSecondary);
    return SafeArea(
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.tabH,
          end: AppSpacing.tabH,
          top: AppSpacing.tabH,
          bottom: AppSpacing.tabH + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.trustedTitle, style: AppTypography.title.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.xxs),
              Text(contacts.isEmpty ? l10n.sosNoContacts : l10n.trustedMax, style: secondary),
              const SizedBox(height: AppSpacing.gap),
              for (final c in contacts) ...[
                Row(
                  key: Key('contact-${c.id}'),
                  children: [
                    GooraAvatar(initials: c.name.isEmpty ? '' : c.name.characters.first.toUpperCase(), size: GooraAvatarSize.s40),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
                          Text(c.phone.local, textDirection: TextDirection.ltr, style: secondary),
                        ],
                      ),
                    ),
                    IconButton(
                      key: Key('remove-${c.id}'),
                      tooltip: l10n.removeContact(c.name),
                      constraints: const BoxConstraints(minWidth: AppSizes.minTouch, minHeight: AppSizes.minTouch),
                      onPressed: () => ref.read(trustControllerProvider.notifier).removeContact(c.id),
                      icon: const Icon(GooraIcons.close, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (!full) ...[
                GooraTextField(
                  key: const Key('contact-name'),
                  controller: _name,
                  label: l10n.contactName,
                  maxLength: Profile.maxNameLength,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                GooraTextField(
                  key: const Key('contact-phone'),
                  controller: _phone,
                  label: l10n.phoneLabel,
                  ltr: true,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d+ \-]'))],
                  errorText: _phone.text.isNotEmpty && _parsed == null ? l10n.phoneHint : null,
                  onChanged: (v) => setState(() => _parsed = PhoneNumber.tryParse(v)),
                ),
                const SizedBox(height: AppSpacing.gap),
                GooraPrimaryButton(
                  key: const Key('add-contact'),
                  label: l10n.trustedAdd,
                  onPressed: canAdd ? _add : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
