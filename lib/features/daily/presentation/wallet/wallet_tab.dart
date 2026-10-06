import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../shell/tab_page.dart';

/// Placeholder until feature 004 (charges owed are already recorded).
class WalletTab extends StatelessWidget {
  const WalletTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TabPage(title: l10n.tabWallet, children: [ComingSoonCard(title: l10n.walletSoon)]);
  }
}
