import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/goora_icons.dart';
import '../../../core/widgets/goora_primary_button.dart';
import '../../../core/widgets/goora_radio_card.dart';
import '../domain/choices.dart';
import '../domain/onboarding_flow.dart';
import 'session_controller.dart';
import 'widgets/onboarding_scaffold.dart';

class RoleScreen extends ConsumerStatefulWidget {
  const RoleScreen({super.key});

  @override
  ConsumerState<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends ConsumerState<RoleScreen> {
  Role? _role;

  @override
  void initState() {
    super.initState();
    _role = ref.read(sessionControllerProvider).profile?.role;
  }

  Future<void> _continue() async {
    await ref.read(sessionControllerProvider.notifier).setRole(_role!);
    if (mounted) context.go(Routes.frequency);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingScaffold(
      title: l10n.howTravel,
      subtitle: l10n.switchAnytime,
      progressIndex: OnboardingFlow.progressIndex(step: OnboardingStep.role),
      onBack: () => context.go(Routes.profile),
      body: Column(
        children: [
          GooraRadioCard(
            key: const Key('role-driver'),
            icon: GooraIcons.car,
            title: l10n.canDrive,
            subtitle: l10n.canDriveSub,
            selected: _role == Role.driver,
            onTap: () => setState(() => _role = Role.driver),
          ),
          const SizedBox(height: AppSpacing.gap),
          GooraRadioCard(
            key: const Key('role-rider'),
            icon: GooraIcons.person,
            title: l10n.needRide,
            subtitle: l10n.needRideSub,
            selected: _role == Role.rider,
            onTap: () => setState(() => _role = Role.rider),
          ),
        ],
      ),
      bottom: GooraPrimaryButton(
        key: const Key('role-continue'),
        label: l10n.continueBtn,
        onPressed: _role == null ? null : _continue,
      ),
    );
  }
}
