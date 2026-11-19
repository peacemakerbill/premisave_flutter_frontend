import '../../core/utils/formatters.dart';
import '../../core/utils/masking.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/profile_repository.dart';
import 'resource_form.dart';

/// What a chosen person is sent as.
enum PersonValue { id, email }

PickOption _personOption(UserModel u, PersonValue by) {
  final name = u.fullName.trim().isEmpty ? (u.username.isEmpty ? 'User' : u.username) : u.fullName.trim();
  final parts = <String>[if (u.username.isNotEmpty) '@${u.username}', if (u.email.isNotEmpty) maskEmail(u.email)];
  final value = by == PersonValue.email ? u.email : u.id;
  return PickOption(
    value,
    name,
    description: parts.isEmpty ? null : parts.join('  '),
    initials: initialsOf(name),
    imageUrl: u.profilePictureUrl,
  );
}

/// A Premisave user, found by typing a name, username or email, with the profile picture beside each match. The list
/// narrows as the person types. Used wherever a form wants a user, so nobody has to copy an id or an address from another
/// screen. Only the name, username and a masked email are shown. [by] says whether the form sends the user id or the email.
FieldSpec userPicker(
  ProfileRepository profiles, {
  String key = 'userId',
  String label = 'Person',
  bool required = false,
  String? helper,
  bool clearable = false,
  PersonValue by = PersonValue.id,
}) {
  return FieldSpec(
    key,
    label,
    kind: FieldKind.picker,
    required: required,
    clearable: clearable,
    helper: helper ?? 'Type a name, username or email. Matches appear as you type.',
    searcher: (q) async {
      final found = await profiles.search(q);
      return <PickOption>[
        for (final u in found)
          if ((by == PersonValue.email ? u.email : u.id).isNotEmpty) _personOption(u, by),
      ];
    },
    resolve: (value) async {
      if (by == PersonValue.id) return _personOption(await profiles.user(value), by);
      final found = await profiles.search(value);
      for (final u in found) {
        if (u.email.toLowerCase() == value.toLowerCase()) return _personOption(u, by);
      }
      return null;
    },
  );
}
