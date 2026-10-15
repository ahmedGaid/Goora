import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/theme/app_spacing.dart';
import 'package:goora/core/widgets/goora_bottom_nav.dart';

/// T104 F5: on a phone with Android's 3-button bar the tab labels sat under the
/// system Back/Home/Recents buttons, and a tap on a tab's lower half went Home.
void main() {
  Widget host({required double systemBar}) => MediaQuery(
        data: MediaQueryData(
          size: const Size(400, 800),
          padding: EdgeInsets.only(bottom: systemBar),
          viewPadding: EdgeInsets.only(bottom: systemBar),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: const SizedBox.shrink(),
            bottomNavigationBar: GooraBottomNav(
              semanticLabel: 'nav',
              currentIndex: 0,
              onTap: (_) {},
              items: const [
                GooraNavItem(icon: Icons.today, label: 'Today'),
                GooraNavItem(icon: Icons.wallet, label: 'Wallet'),
              ],
            ),
          ),
        ),
      );

  testWidgets('tabs sit above a 48 dp system navigation bar', (tester) async {
    await tester.pumpWidget(host(systemBar: 48));
    final screen = tester.getSize(find.byType(Scaffold)).height;
    for (final label in ['Today', 'Wallet']) {
      final button = find.ancestor(of: find.text(label), matching: find.byType(InkWell));
      expect(tester.getRect(button).bottom, lessThanOrEqualTo(screen - 48), reason: '$label is under the system bar');
    }
  });

  testWidgets('no system bar: keeps the design bottom spacing', (tester) async {
    await tester.pumpWidget(host(systemBar: 0));
    final screen = tester.getSize(find.byType(Scaffold)).height;
    final button = find.ancestor(of: find.text('Today'), matching: find.byType(InkWell));
    expect(tester.getRect(button).bottom, screen - AppSpacing.bottomNavBottom);
  });
}
