import '../roles/permissions.dart';
import '../roles/role.dart';
import '../roles/role_registry.dart';

/// Which capability each guarded area needs. The most specific prefix comes first.
const List<(String, Capability)> _guarded = <(String, Capability)>[
  ('/home/lookup', Capability.lookupAccounts),
  ('/home/properties', Capability.manageProperties),
  ('/home/listings', Capability.manageProperties),
  ('/home/tenancy', Capability.useClientWorkspace),
  ('/admin/audit', Capability.viewAuditTrail),
  ('/admin', Capability.manageUsers),
  ('/staff', Capability.reviewApplications),
  ('/explore', Capability.exploreProperties),
];

bool _under(String location, String prefix) => location == prefix || location.startsWith('$prefix/');

/// Whether this role may open the page. Pages not listed in [_guarded] are open to every signed in person.
bool canOpen(Role role, String location) {
  for (final (prefix, capability) in _guarded) {
    if (_under(location, prefix)) return role.can(capability);
  }
  return true;
}
