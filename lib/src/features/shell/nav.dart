import 'package:flutter/material.dart';

import '../../data/models/user_model.dart';

/// One tab in the bottom bar (phones) or side rail (wide screens).
class NavDest {
  const NavDest(this.path, this.label, this.icon, this.selectedIcon, [this.alsoMatches = const <String>[]]);

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Other path prefixes that belong to this tab.
  final List<String> alsoMatches;

  bool matches(String location) {
    if (location == path || location.startsWith('$path/')) return true;
    for (final p in alsoMatches) {
      if (location == p || location.startsWith('$p/')) return true;
    }
    return false;
  }
}

const NavDest _home = NavDest('/home', 'Home', Icons.home_outlined, Icons.home_rounded, <String>['/application']);
const NavDest _explore = NavDest('/explore', 'Explore', Icons.explore_outlined, Icons.explore_rounded);
const NavDest _queue =
    NavDest('/staff', 'Applications', Icons.fact_check_outlined, Icons.fact_check_rounded);
const NavDest _users =
    NavDest('/admin', 'Users', Icons.manage_accounts_outlined, Icons.manage_accounts_rounded);
const NavDest _people = NavDest('/people', 'People', Icons.groups_outlined, Icons.groups_rounded);
const NavDest _account =
    NavDest('/account', 'Account', Icons.account_circle_outlined, Icons.account_circle_rounded);

List<NavDest> destinationsFor(Role role) {
  switch (role) {
    case Role.client:
      return const <NavDest>[_home, _explore, _people, _account];
    case Role.homeOwner:
      return const <NavDest>[_home, _people, _account];
    case Role.admin:
      return const <NavDest>[_home, _queue, _users, _people, _account];
    case Role.operations:
    case Role.finance:
    case Role.support:
      return const <NavDest>[_home, _queue, _people, _account];
  }
}
