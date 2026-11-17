import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/widgets.dart';
import '../../state/messenger_controller.dart';
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
    // Watching the unread count also starts the live messenger connection for as long as someone is signed in.
    final unread = ref.watch(messengerUnreadProvider);
    ref.listen<int>(messengerProvider.select((s) => s.noticeSeq), (prev, next) {
      final text = ref.read(messengerProvider).notice;
      if (text != null && text.isNotEmpty) showToast(context, text, error: true);
    });
    final dests = destinationsFor(session.role);
    var index = dests.indexWhere((d) => d.matches(location));
    if (index < 0) index = 0;

    Widget iconFor(NavDest d, bool selected) {
      final icon = Icon(selected ? d.selectedIcon : d.icon);
      if (d.path != '/messages' || unread <= 0) return icon;
      return Badge(label: Text(unread > 99 ? '99+' : '$unread'), child: icon);
    }

    void go(int i) {
      if (i != index) context.go(dests[i].path);
    }

    if (context.isWide) {
      final extended = MediaQuery.of(context).size.width >= 1240;
      return PScaffold(
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
                          BrandMark(size: 34, onDark: context.isDark, ink: context.isDark ? null : context.pal.accent),
                          const SizedBox(width: 10),
                          Text('premisave', style: context.display(size: 19, weight: FontWeight.w800, spacing: -0.6)),
                        ],
                      )
                    : BrandMark(size: 34, onDark: context.isDark, ink: context.isDark ? null : context.pal.accent),
              ),
              destinations: <NavigationRailDestination>[
                for (final d in dests)
                  NavigationRailDestination(
                    icon: iconFor(d, false),
                    selectedIcon: iconFor(d, true),
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

    // An open chat or status takes the whole screen on a phone, like in any messenger.
    final immersive = location.startsWith('/messages/chat/') || location.startsWith('/messages/status/user/') || location == '/messages/status/mine';
    if (immersive) return PScaffold(body: child);

    return PScaffold(
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
                icon: iconFor(d, false),
                selectedIcon: iconFor(d, true),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }
}
