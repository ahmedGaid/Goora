import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../shell/tab_page.dart';

/// Trust tab; profile, checklist, reliability and privacy arrive with US6 (P2).
class TrustScreen extends StatelessWidget {
  const TrustScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TabPage(title: l10n.tabTrust, children: const [ComingSoonCard()]);
  }
}
