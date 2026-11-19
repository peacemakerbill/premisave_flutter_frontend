import '../../data/repositories/profile_repository.dart';
import 'resource_form.dart';

/// A Premisave user, found by typing a name, username or email. Used wherever a form wants a user id, so nobody has to
/// copy one from another screen. Only the name and username are shown.
FieldSpec userPicker(
  ProfileRepository profiles, {
  String key = 'userId',
  String label = 'Person',
  bool required = false,
  String? helper,
  bool clearable = false,
}) {
  PickOption option(String id, String fullName, String username) =>
      PickOption(id, fullName.isEmpty ? (username.isEmpty ? 'User' : username) : fullName, description: username.isEmpty ? null : '@$username');
  return FieldSpec(
    key,
    label,
    kind: FieldKind.picker,
    required: required,
    clearable: clearable,
    helper: helper ?? 'Search by name, username or email.',
    searcher: (q) async {
      final found = await profiles.search(q);
      return <PickOption>[for (final u in found) if (u.id.isNotEmpty) option(u.id, u.fullName, u.username)];
    },
    resolve: (id) async {
      final u = await profiles.user(id);
      return option(u.id.isEmpty ? id : u.id, u.fullName, u.username);
    },
  );
}
