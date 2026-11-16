import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/widgets/widgets.dart';
import '../../state/session_controller.dart';
import 'nav.dart';

/// Frame around every signed-in screen: bottom bar on phones, side rail on wide screens.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final dests = destinationsFor(session.role);
    var index = dests.indexWhere((d) => d.matches(location));
    if (index < 0) index = 0;

    void go(int i) {
      if (i != index) context.go(dests[i].path);
    }

    if (context.isWide) {
      final extended = MediaQuery.of(context).size.width >= 1240;
      return Scaffold(
        body: Row(
          children: <Widget>[
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: go,
              extended: extended,
              minExtendedWidth: 220,
              labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.fromLTRB(12, 22, 12, 22),
                child: extended
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          BrandMark(size: 34, onDark: context.isDark),
                          const SizedBox(width: 10),
                          const Text('premisave', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                        ],
                      )
                    : BrandMark(size: 34, onDark: context.isDark),
              ),
              destinations: <NavigationRailDestination>[
                for (final d in dests)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => context.go('/account'),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: UserAvatar(
                          initials: session.user?.initials ?? 'P',
                          imageUrl: session.user?.profilePictureUrl,
                          size: 38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            VerticalDivider(width: 1, color: context.borderColor),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: context.borderColor))),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: go,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: <NavigationDestination>[
            for (final d in dests)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }
}
