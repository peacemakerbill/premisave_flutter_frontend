import 'package:flutter/material.dart';

import '../../roles/role.dart';
import '../../roles/role_registry.dart';

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
    NavDest('/admin/users', 'Users', Icons.manage_accounts_outlined, Icons.manage_accounts_rounded);

/// Administrators: the security audit trail.
const NavDest _security = NavDest(
    '/admin/security', 'Security', Icons.shield_outlined, Icons.shield_rounded, <String>['/admin/audit']);

/// Administrators: the switches for calls and the places where files are kept.
const NavDest _settings = NavDest(
    '/admin/settings', 'Settings', Icons.tune_outlined, Icons.tune_rounded, <String>['/admin/calls', '/admin/storage']);
const NavDest _messages = NavDest('/messages', 'Messages', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded);
const NavDest _people = NavDest('/people', 'People', Icons.groups_outlined, Icons.groups_rounded);
const NavDest _account =
    NavDest('/account', 'Account', Icons.account_circle_outlined, Icons.account_circle_rounded);

NavDest _destinationFor(AppTab tab) {
  switch (tab) {
    case AppTab.home:
      return _home;
    case AppTab.explore:
      return _explore;
    case AppTab.applications:
      return _queue;
    case AppTab.users:
      return _users;
    case AppTab.security:
      return _security;
    case AppTab.settings:
      return _settings;
    case AppTab.messages:
      return _messages;
    case AppTab.people:
      return _people;
    case AppTab.account:
      return _account;
  }
}

/// The tabs for a role. Which tabs a role gets is decided in `roles/role_registry.dart`.
List<NavDest> destinationsFor(Role role) => <NavDest>[for (final tab in role.tabs) _destinationFor(tab)];
