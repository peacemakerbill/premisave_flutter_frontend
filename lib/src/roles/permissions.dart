/// Something a person may be allowed to see or do. Screens, routes and menus ask for a capability
/// instead of checking which role someone has, so a new role only needs an entry in `role_registry.dart`.
enum Capability {
  /// The Explore tab and its pages.
  exploreProperties,

  /// Bookings, wishlists, messages, payments and transactions as a client.
  useClientWorkspace,

  /// Start a home owner application.
  applyAsHomeOwner,

  /// Open the record of an approved home owner application.
  viewHomeOwnerApplication,

  /// The staff queue and the review screens.
  reviewApplications,

  /// Give the final approval to a verified application.
  approveApplications,

  /// The users list, user details and role changes.
  manageUsers,

  /// The platform wide security audit trail.
  viewAuditTrail,
}
