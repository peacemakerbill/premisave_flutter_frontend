import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/widgets/widgets.dart';

/// One entry of a hub's menu: a name, an icon and the screen it opens.
class HubTab {
  const HubTab(this.label, this.icon, this.builder);

  final String label;
  final IconData icon;
  final WidgetBuilder builder;
}

/// A section of the app with its own menu: a title and a scrollable row of tabs, one screen each. Wallet, listings,
/// bookings, property management and the rest are hubs, so every feature of a service is one tap from its menu.
class HubPage extends StatelessWidget {
  const HubPage({super.key, required this.title, required this.tabs, this.actions, this.initialIndex = 0});

  final String title;
  final List<HubTab> tabs;
  final List<Widget>? actions;
  final int initialIndex;

  /// A link such as /finance?tab=to-resolve opens that tab. The value is a tab's name with spaces as dashes, or its number.
  int? _wantedTab(BuildContext context) {
    String? raw;
    try {
      raw = GoRouterState.of(context).uri.queryParameters['tab'];
    } catch (_) {
      return null;
    }
    if (raw == null || raw.isEmpty) return null;
    final number = int.tryParse(raw);
    if (number != null) return number;
    String flat(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final want = flat(raw);
    for (var i = 0; i < tabs.length; i++) {
      if (flat(tabs[i].label) == want) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final wanted = _wantedTab(context);
    return DefaultTabController(
      key: ValueKey<String>('tabs-${wanted ?? 'default'}'),
      length: tabs.length,
      initialIndex: (wanted ?? initialIndex).clamp(0, tabs.length - 1),
      child: PScaffold(
        appBar: AppBar(
          automaticallyImplyLeading: Navigator.of(context).canPop(),
          title: Text(title, style: context.display(size: 22, weight: FontWeight.w800, spacing: -0.6)),
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          actions: actions,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: context.borderColor,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            tabs: <Widget>[
              for (final t in tabs) Tab(height: 46, icon: Icon(t.icon, size: 18), text: t.label, iconMargin: const EdgeInsets.only(bottom: 2)),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[for (final t in tabs) Builder(builder: t.builder)],
        ),
      ),
    );
  }
}
