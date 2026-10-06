import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/goora_bottom_nav.dart';
import '../../../../core/widgets/goora_icons.dart';

/// The member app: Today · Week · Wallet · Trust (FR-001, research R1). Each
/// tab keeps its own state; a language switch rebuilds in place.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: shell,
      bottomNavigationBar: GooraBottomNav(
        semanticLabel: l10n.navMain,
        currentIndex: shell.currentIndex,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        items: [
          GooraNavItem(icon: GooraIcons.today, label: l10n.tabToday),
          GooraNavItem(icon: GooraIcons.week, label: l10n.tabWeek),
          GooraNavItem(icon: GooraIcons.wallet, label: l10n.tabWallet),
          GooraNavItem(icon: GooraIcons.trust, label: l10n.tabTrust),
        ],
      ),
    );
  }
}
