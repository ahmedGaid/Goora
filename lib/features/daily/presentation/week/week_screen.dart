import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../shell/tab_page.dart';

/// Week tab; the schedule arrives with US5 (P2).
class WeekScreen extends StatelessWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TabPage(title: l10n.scheduleTitle, children: const [ComingSoonCard()]);
  }
}
