import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/goora_primary_button.dart';
import '../../../core/widgets/goora_text_field.dart';
import '../data/providers.dart';
import '../domain/phone_number.dart';
import '../domain/repositories.dart';
import 'onboarding_routes.dart';
import 'session_controller.dart';
import 'widgets/onboarding_scaffold.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});

  static const codeLength = 6;
  static const resendAfter = Duration(seconds: 60);

  final PhoneNumber phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  Timer? _timer;
  late int _secondsLeft;
  bool _wrong = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = OtpScreen.resendAfter.inSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_controller.text.length != OtpScreen.codeLength || _busy) return;
    setState(() {
      _busy = true;
      _wrong = false;
    });
    try {
      await ref.read(authRepositoryProvider).verifyCode(widget.phone, _controller.text);
      await ref.read(sessionControllerProvider.notifier).signedIn(widget.phone);
      if (!mounted) return;
      context.go(routeForSession(ref.read(sessionControllerProvider)));
    } on InvalidCodeException {
      if (mounted) setState(() => _wrong = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authRepositoryProvider).sendCode(widget.phone);
      if (mounted) setState(_startTimer);
    } on AuthNetworkException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).networkError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFake = ref.watch(authRepositoryProvider).isFake;
    return OnboardingScaffold(
      title: l10n.otpTitle,
      subtitle: l10n.otpSub(widget.phone.local),
      onBack: () => context.go(Routes.phone),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GooraTextField(
            key: const Key('otp-field'),
            controller: _controller,
            label: l10n.otpTitle,
            ltr: true,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: OtpScreen.codeLength,
            textAlign: TextAlign.center,
            style: AppTypography.title,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            errorText: _wrong ? l10n.otpWrong : null,
            onChanged: (v) {
              if (_wrong) setState(() => _wrong = false);
              if (v.length == OtpScreen.codeLength) _verify();
              setState(() {});
            },
          ),
          if (isFake) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.otpDevHint, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_secondsLeft > 0)
                Text(
                  l10n.otpResendIn(_secondsLeft),
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                )
              else
                _LinkButton(label: l10n.otpResend, onPressed: _resend),
              _LinkButton(label: l10n.changeNumber, onPressed: () => context.go(Routes.phone)),
            ],
          ),
        ],
      ),
      bottom: GooraPrimaryButton(
        key: const Key('otp-continue'),
        label: l10n.continueBtn,
        onPressed: _controller.text.length == OtpScreen.codeLength && !_busy ? _verify : null,
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.greenText,
        textStyle: AppTypography.bodyStrong.withLocaleFont(context),
        minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
      ),
      child: Text(label),
    );
  }
}
