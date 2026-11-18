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

  /// The wallet: balance, deposits, withdrawals, transfers and history.
  useWallet,

  /// Listings, bookings and leads on the person's own listings, and property management (units, leases, rent).
  manageProperties,

  /// The M-Pesa name lookup tool of the C2B Hakikisha service.
  lookupAccounts,

  /// Every wallet, the ledger, reconciliation, M-Pesa operations, gateway balances and exchange rates.
  administerWallet,

  /// Moderate every listing and booking: approve, reject, archive, restore, delete and settle payments.
  administerListings,
}
