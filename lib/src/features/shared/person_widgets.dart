import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/user_model.dart';
import '../../state/providers.dart';

/// A person found by user id (`id:...`) or by email (`email:...`), with their picture. Cached, so a list with the same
/// person on many rows asks once. It is null when nobody is found or the profile cannot be read, and every widget that
/// uses it then falls back to initials.
final personProvider = FutureProvider.family<UserModel?, String>((ref, key) async {
  final profiles = ref.read(profileRepositoryProvider);
  try {
    if (key.startsWith('id:')) return await profiles.user(key.substring(3));
    final email = key.substring(6).toLowerCase();
    final found = await profiles.search(email);
    for (final u in found) {
      if (u.email.toLowerCase() == email) return u;
    }
  } catch (_) {
    // A person who cannot be looked up is shown by initials.
  }
  return null;
});

/// Who is on the other side of a record. Any of the parts may be missing.
class PersonRef {
  const PersonRef({this.id, this.email, this.name});

  final String? id;
  final String? email;
  final String? name;

  bool get isKnown => (id ?? '').isNotEmpty || (email ?? '').isNotEmpty;

  String? get key {
    if ((id ?? '').isNotEmpty) return 'id:$id';
    if ((email ?? '').isNotEmpty) return 'email:${email!.toLowerCase()}';
    return null;
  }

  String get label {
    if ((name ?? '').isNotEmpty) return name!;
    if ((email ?? '').isNotEmpty) return email!;
    return 'Someone';
  }
}

/// A round profile picture that looks the person up. [size] is its width.
class PersonAvatar extends ConsumerWidget {
  const PersonAvatar(this.person, {super.key, this.size = 42});

  final PersonRef person;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = person.key;
    final user = key == null ? null : ref.watch(personProvider(key)).valueOrNull;
    final name = user == null || user.fullName.trim().isEmpty ? person.label : user.fullName;
    return UserAvatar(initials: initialsOf(name), imageUrl: user?.profilePictureUrl, size: size);
  }
}

/// A person's picture, name, username and email, for the top of a detail pop-up. [role] says what they were in the record,
/// for example "Sent by" or "Received by".
class PersonCard extends ConsumerWidget {
  const PersonCard(this.person, {super.key, this.role});

  final PersonRef person;
  final String? role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = person.key;
    final user = key == null ? null : ref.watch(personProvider(key)).valueOrNull;
    final fullName = user?.fullName.trim() ?? '';
    final name = fullName.isNotEmpty ? fullName : person.label;
    final email = (user?.email.isNotEmpty ?? false) ? user!.email : person.email;
    final lines = <String>[
      if (user != null && user.username.isNotEmpty) '@${user.username}',
      if (email != null && email.isNotEmpty) email,
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.pal.accent.op(0.08),
        borderRadius: BorderRadius.circular(context.radius(14)),
      ),
      child: Row(
        children: <Widget>[
          UserAvatar(initials: initialsOf(name), imageUrl: user?.profilePictureUrl, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (role != null)
                  Text(role!, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: context.mutedColor)),
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                for (final l in lines)
                  Text(l, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String? _text(Object? v) => v is String && v.isNotEmpty ? v : null;

/// The people in one wallet record, whichever shape it came in: a merged activity line (a counterparty), a transfer
/// (sender and recipient) or an admin record (the user). Each has the role to show above their card.
List<(String, PersonRef)> peopleOf(Map<String, dynamic> m) {
  final out = <(String, PersonRef)>[];
  final direction = _text(m['direction']);
  final counterEmail = _text(m['counterpartyEmail']);
  final counterId = _text(m['counterpartyId']);
  if (counterEmail != null || counterId != null || _text(m['counterpartyName']) != null) {
    out.add((direction == 'IN' ? 'Received from' : 'Sent to', PersonRef(id: counterId, email: counterEmail, name: _text(m['counterpartyName']))));
    return out;
  }
  final senderId = _text(m['senderId']) ?? _text(m['senderUserId']);
  final senderEmail = _text(m['senderEmail']);
  final recipientId = _text(m['recipientId']) ?? _text(m['recipientUserId']);
  final recipientEmail = _text(m['recipientEmail']);
  final sender = PersonRef(id: senderId, email: senderEmail, name: _text(m['senderName']));
  final recipient = PersonRef(id: recipientId, email: recipientEmail, name: _text(m['recipientName']));
  if (direction == 'SENT' && recipient.isKnown) {
    // The person's own history: only the other side is interesting.
    out.add(('Sent to', recipient));
  } else if (direction == 'RECEIVED' && sender.isKnown) {
    out.add(('Received from', sender));
  } else {
    if (sender.isKnown) out.add(('From', sender));
    if (recipient.isKnown) out.add(('To', recipient));
  }
  if (out.isEmpty) {
    final userId = _text(m['userId']);
    final email = _text(m['email']) ?? _text(m['accountNumber']);
    if (userId != null || email != null) out.add(('Account holder', PersonRef(id: userId, email: email, name: _text(m['userName']) ?? _text(m['fullName']))));
  }
  return out;
}

/// What a row shows in front: the picture of the main person when there is one, otherwise [icon] tinted by direction.
Widget walletRowLeading(BuildContext context, Map<String, dynamic> m, IconData icon) {
  final people = peopleOf(m);
  if (people.isNotEmpty) {
    // A transfer between two people shows the one who is not the viewer: the first when only one is known.
    final main = people.first.$2;
    return PersonAvatar(main, size: 42);
  }
  final direction = _text(m['direction']);
  final tint = direction == 'IN' ? Brand.success : (direction == 'OUT' ? Brand.danger : context.pal.accent);
  return Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(color: tint.op(0.12), borderRadius: BorderRadius.circular(context.radius(12))),
    child: Icon(icon, size: 21, color: tint),
  );
}

/// The cards for everyone in a record, to put above its details.
Widget walletRowHeader(BuildContext context, Map<String, dynamic> m) {
  final people = peopleOf(m);
  if (people.isEmpty) return const SizedBox.shrink();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[for (final p in people) PersonCard(p.$2, role: p.$1)],
  );
}
