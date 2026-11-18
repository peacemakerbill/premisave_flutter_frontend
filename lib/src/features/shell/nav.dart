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
const NavDest _bookings = NavDest(
    '/bookings', 'Bookings', Icons.event_available_outlined, Icons.event_available_rounded, <String>['/home/bookings', '/home/wishlists']);
const NavDest _wallet = NavDest('/wallet', 'Wallet', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded,
    <String>['/home/payments', '/home/transactions']);
const NavDest _listings =
    NavDest('/listings', 'Listings', Icons.home_work_outlined, Icons.home_work_rounded, <String>['/home/listings']);
const NavDest _property =
    NavDest('/property', 'Property', Icons.apartment_outlined, Icons.apartment_rounded, <String>['/home/properties']);

/// Wallet administration for finance and operations staff.
const NavDest _finance = NavDest('/finance', 'Finance', Icons.account_balance_outlined, Icons.account_balance_rounded);

/// Listing and booking moderation.
const NavDest _moderation = NavDest('/moderation', 'Moderation', Icons.gavel_outlined, Icons.gavel_rounded);
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
    case AppTab.bookings:
      return _bookings;
    case AppTab.wallet:
      return _wallet;
    case AppTab.listings:
      return _listings;
    case AppTab.property:
      return _property;
    case AppTab.finance:
      return _finance;
    case AppTab.moderation:
      return _moderation;
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

/// How many slots the bottom bar of a phone has. A role with more tabs gets the first four and a More tab.
const int _phoneSlots = 5;

/// The tab that opens the list of every other section on a phone.
const NavDest moreDestination = NavDest('/more', 'More', Icons.apps_outlined, Icons.apps_rounded);

/// The tabs in the bottom bar of a phone.
List<NavDest> phoneDestinationsFor(Role role) {
  final all = destinationsFor(role);
  if (all.length <= _phoneSlots) return all;
  return <NavDest>[...all.take(_phoneSlots - 1), moreDestination];
}

/// The tabs a phone shows under More. Empty when they all fit in the bar.
List<NavDest> overflowFor(Role role) {
  final all = destinationsFor(role);
  if (all.length <= _phoneSlots) return <NavDest>[];
  return all.skip(_phoneSlots - 1).toList();
}
