import 'package:flutter/foundation.dart';

import 'permissions.dart';
import 'role.dart';

/// A destination in the bottom bar (phones) or side rail (wide screens). Only names the tab;
/// `features/shell/nav.dart` owns how it looks and where it goes.
enum AppTab {
  home,
  explore,
  bookings,
  wallet,
  listings,
  property,
  finance,
  moderation,
  applications,
  users,
  security,
  settings,
  messages,
  people,
  account,
}

/// Everything that differs between roles, in one place.
@immutable
class RoleSpec {
  const RoleSpec({required this.tabs, required this.capabilities, required this.overviewTitle});

  /// Tabs in the order they appear.
  final List<AppTab> tabs;

  /// What this role may see and do.
  final Set<Capability> capabilities;

  /// Name of the dashboard entry on the Home screen.
  final String overviewTitle;
}

const RoleSpec _client = RoleSpec(
  tabs: <AppTab>[AppTab.home, AppTab.explore, AppTab.bookings, AppTab.wallet, AppTab.messages, AppTab.people, AppTab.account],
  capabilities: <Capability>{
    Capability.exploreProperties,
    Capability.useClientWorkspace,
    Capability.applyAsHomeOwner,
    Capability.useWallet,
  },
  overviewTitle: 'My dashboard',
);

const RoleSpec _homeOwner = RoleSpec(
  tabs: <AppTab>[AppTab.home, AppTab.listings, AppTab.property, AppTab.wallet, AppTab.messages, AppTab.people, AppTab.account],
  capabilities: <Capability>{Capability.viewHomeOwnerApplication, Capability.useWallet, Capability.manageProperties},
  overviewTitle: 'Home owner overview',
);

const RoleSpec _operations = RoleSpec(
  tabs: <AppTab>[AppTab.home, AppTab.applications, AppTab.finance, AppTab.messages, AppTab.people, AppTab.account],
  capabilities: <Capability>{Capability.reviewApplications, Capability.lookupAccounts, Capability.administerWallet},
  overviewTitle: 'Operations overview',
);

const RoleSpec _finance = RoleSpec(
  tabs: <AppTab>[AppTab.home, AppTab.applications, AppTab.finance, AppTab.moderation, AppTab.messages, AppTab.people, AppTab.account],
  capabilities: <Capability>{
    Capability.reviewApplications,
    Capability.lookupAccounts,
    Capability.administerWallet,
    Capability.administerListings,
  },
  overviewTitle: 'Finance overview',
);

const RoleSpec _support = RoleSpec(
  tabs: <AppTab>[AppTab.home, AppTab.applications, AppTab.messages, AppTab.people, AppTab.account],
  capabilities: <Capability>{Capability.reviewApplications, Capability.lookupAccounts},
  overviewTitle: 'Support overview',
);

const RoleSpec _admin = RoleSpec(
  tabs: <AppTab>[
    AppTab.home,
    AppTab.applications,
    AppTab.users,
    AppTab.finance,
    AppTab.moderation,
    AppTab.security,
    AppTab.settings,
    AppTab.messages,
    AppTab.people,
    AppTab.account,
  ],
  capabilities: <Capability>{
    Capability.reviewApplications,
    Capability.approveApplications,
    Capability.manageUsers,
    Capability.viewAuditTrail,
    Capability.lookupAccounts,
    Capability.administerWallet,
    Capability.administerListings,
  },
  overviewTitle: 'Administrator overview',
);

/// The spec for a role. The switch has no default on purpose: adding a value to [Role] without
/// adding its spec here is a compile error, so a new role can never ship half configured.
RoleSpec specFor(Role role) {
  switch (role) {
    case Role.client:
      return _client;
    case Role.homeOwner:
      return _homeOwner;
    case Role.operations:
      return _operations;
    case Role.finance:
      return _finance;
    case Role.support:
      return _support;
    case Role.admin:
      return _admin;
  }
}

extension RoleAccess on Role {
  /// Whether this role has the given capability.
  bool can(Capability capability) => specFor(this).capabilities.contains(capability);

  /// Tabs this role sees, in order.
  List<AppTab> get tabs => specFor(this).tabs;

  /// Name of the dashboard entry on the Home screen.
  String get overviewTitle => specFor(this).overviewTitle;
}
