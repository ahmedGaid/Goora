import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/goora_pill.dart';
import '../../../core/widgets/goora_primary_button.dart';
import '../../../core/widgets/goora_text_field.dart';
import '../domain/choices.dart';
import '../domain/profile.dart';
import 'session_controller.dart';
import 'widgets/onboarding_scaffold.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _first;
  late final TextEditingController _last;
  Gender? _gender;

  @override
  void initState() {
    super.initState();
    final p = ref.read(sessionControllerProvider).profile;
    _first = TextEditingController(text: p?.firstName);
    _last = TextEditingController(text: p?.lastName);
    _gender = p?.gender;
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  bool get _valid => Profile.isValidName(_first.text) && Profile.isValidName(_last.text) && _gender != null;

  Future<void> _save() async {
    await ref.read(sessionControllerProvider.notifier).saveProfile(
          firstName: _first.text,
          lastName: _last.text,
          gender: _gender!,
        );
    if (mounted) context.go(Routes.role);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingScaffold(
      title: l10n.profileTitle,
      subtitle: l10n.profileSub,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GooraTextField(
            key: const Key('first-name'),
            controller: _first,
            label: l10n.firstName,
            maxLength: Profile.maxNameLength,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.gap),
          GooraTextField(
            key: const Key('last-name'),
            controller: _last,
            label: l10n.lastName,
            maxLength: Profile.maxNameLength,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.genderLabel, style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final g in Gender.values)
                GooraPill(
                  key: Key('gender-${g.name}'),
                  label: g == Gender.male ? l10n.male : l10n.female,
                  selected: _gender == g,
                  onTap: () => setState(() => _gender = g),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.genderNote, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
      bottom: GooraPrimaryButton(
        key: const Key('profile-continue'),
        label: l10n.continueBtn,
        onPressed: _valid ? _save : null,
      ),
    );
  }
}
