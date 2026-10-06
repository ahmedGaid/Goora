import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../commute/domain/group.dart';
import '../../../daily/presentation/shell/tab_page.dart';
import 'rider_wallet.dart';
import 'wallet_controller.dart';

/// Wallet tab: rider or driver layout (US2 rider branch wired; driver
/// branch stubbed until US3 — T037).
class WalletTab extends ConsumerWidget {
  const WalletTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(walletControllerProvider);
    final view = state.value;

    if (view == null) {
      return TabPage(
        title: l10n.tabWallet,
        children: [TabLoadState(failed: state.hasError, onRetry: () => ref.invalidate(walletControllerProvider))],
      );
    }

    return TabPage(
      title: l10n.tabWallet,
      children: [view.role == MemberRole.driver ? ComingSoonCard(title: l10n.walletSoon) : RiderWallet(view: view)],
    );
  }
}
