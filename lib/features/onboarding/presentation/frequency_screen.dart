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

class FrequencyScreen extends ConsumerStatefulWidget {
  const FrequencyScreen({super.key});

  @override
  ConsumerState<FrequencyScreen> createState() => _FrequencyScreenState();
}

class _FrequencyScreenState extends ConsumerState<FrequencyScreen> {
  late Frequency _frequency;

  @override
  void initState() {
    super.initState();
    _frequency = ref.read(sessionControllerProvider).profile?.frequency ?? Frequency.everyDay;
  }

  Future<void> _continue() async {
    final controller = ref.read(sessionControllerProvider.notifier);
    await controller.setFrequency(_frequency);
    final role = ref.read(sessionControllerProvider).profile!.role!;
    if (mounted) context.go(Routes.forDestination(OnboardingFlow.destinationFor(role, _frequency)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final driver = ref.watch(sessionControllerProvider).profile?.role == Role.driver;
    return OnboardingScaffold(
      title: l10n.freqTitle,
      subtitle: l10n.freqSub,
      progressIndex: OnboardingFlow.progressIndex(step: OnboardingStep.frequency),
      onBack: () => context.go(Routes.role),
      body: Column(
        children: [
          GooraRadioCard(
            key: const Key('freq-every-day'),
            icon: GooraIcons.calendar,
            title: l10n.fRegular,
            chipLabel: l10n.fTag,
            subtitle: driver ? l10n.fRegDriver : l10n.fRegRider,
            selected: _frequency == Frequency.everyDay,
            onTap: () => setState(() => _frequency = Frequency.everyDay),
          ),
          const SizedBox(height: AppSpacing.gap),
          GooraRadioCard(
            key: const Key('freq-once'),
            icon: GooraIcons.route,
            title: l10n.fOnce,
            subtitle: driver ? l10n.fOnceDriver : l10n.fOnceRider,
            selected: _frequency == Frequency.once,
            onTap: () => setState(() => _frequency = Frequency.once),
          ),
        ],
      ),
      bottom: GooraPrimaryButton(
        key: const Key('freq-continue'),
        label: l10n.continueBtn,
        onPressed: _continue,
      ),
    );
  }
}
