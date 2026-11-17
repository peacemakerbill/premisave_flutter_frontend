import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/messenger_models.dart';
import '../../state/messenger_controller.dart';
import '../../state/messenger_providers.dart';
import '../../state/providers.dart';
import 'member_picker.dart';
import 'messenger_common.dart';

/// Group details: picture, name, description, invite link, members and the admin tools.
class GroupInfoScreen extends ConsumerStatefulWidget {
  const GroupInfoScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends ConsumerState<GroupInfoScreen> {
  bool _busy = false;

  MessengerController get _controller => ref.read(messengerProvider.notifier);

  Future<void> _run(Future<void> Function() job, {String? done}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
      ref.invalidate(groupDetailsProvider(widget.groupId));
      await _controller.refreshChats();
      if (done != null && mounted) showToast(context, done);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rename(MGroup g) async {
    final name = await promptDialog(context, title: 'Group name', label: 'Name', initial: g.name, required: true, multiline: false, confirmLabel: 'Save');
    if (name == null || name.trim().isEmpty || name.trim() == g.name) return;
    await _run(() => ref.read(messengerRepositoryProvider).renameGroup(g.id, name.trim()), done: 'Name changed');
  }

  Future<void> _describe(MGroup g) async {
    final text = await promptDialog(context, title: 'Description', label: 'What is this group for?', initial: g.description, confirmLabel: 'Save');
    if (text == null || text.trim() == g.description) return;
    await _run(() => ref.read(messengerRepositoryProvider).setGroupDescription(g.id, text.trim()), done: 'Description saved');
  }

  Future<void> _photo(MGroup g) async {
    final file = await pickImageFile();
    if (file == null) return;
    await _run(() => ref.read(messengerRepositoryProvider).setGroupPhoto(g.id, file), done: 'Picture updated');
  }

  Future<void> _addMembers(MGroup g) async {
    var picked = <String>{};
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => Column(
          children: <Widget>[
            const SizedBox(height: 6),
            Row(children: <Widget>[
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(ctx).pop(false)),
              const Expanded(child: Text('Add members', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Add')),
            ]),
            Expanded(
              child: MemberPicker(
                multi: true,
                excludeIds: <String>{...g.memberIds, for (final m in g.members) m.id},
                onSelectionChanged: (s) => picked = s,
                emptyMessage: 'Everyone is in the group already.',
              ),
            ),
          ],
        ),
      ),
    );
    if (ok != true || picked.isEmpty) return;
    await _run(() => ref.read(messengerRepositoryProvider).addMembers(g.id, picked.toList()), done: 'Members added');
  }

  Future<void> _memberMenu(MGroup g, MGroupMember m, String myId) async {
    final iAmOwner = g.isOwner(myId);
    final iAmAdmin = g.isAdmin(myId);
    if (m.id == myId) return;
    final options = <(String, IconData, String, bool)>[
      if (iAmOwner && !m.isOwner && !m.isAdmin) ('admin', Icons.shield_outlined, 'Make admin', false),
      if (iAmOwner && m.isAdmin) ('unadmin', Icons.remove_moderator_outlined, 'Remove as admin', false),
      if (iAmOwner && !m.isOwner) ('owner', Icons.workspace_premium_outlined, 'Make owner', false),
      if (m.id.isNotEmpty) ('profile', Icons.person_outline_rounded, 'View profile', false),
      if (iAmAdmin && !m.isOwner && (iAmOwner || !m.isAdmin)) ('remove', Icons.person_remove_outlined, 'Remove from group', true),
    ];
    final pick = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            child: Row(children: <Widget>[
              MessengerAvatar(initials: m.user.initials, imageUrl: m.profilePictureUrl, size: 40),
              const SizedBox(width: 12),
              Expanded(child: Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            ]),
          ),
          for (final o in options)
            ListTile(
              leading: Icon(o.$2, color: o.$4 ? ctx.pal.bad : null),
              title: Text(o.$3, style: TextStyle(color: o.$4 ? ctx.pal.bad : null)),
              onTap: () => Navigator.of(ctx).pop(o.$1),
            ),
        ]),
      ),
    );
    if (pick == null || !mounted) return;
    final repo = ref.read(messengerRepositoryProvider);
    if (pick == 'profile') {
      context.push('/people/${Uri.encodeComponent(m.id)}');
    } else if (pick == 'admin') {
      await _run(() => repo.addAdmin(g.id, m.id), done: '${m.name} is now an admin');
    } else if (pick == 'unadmin') {
      await _run(() => repo.removeAdmin(g.id, m.id), done: '${m.name} is no longer an admin');
    } else if (pick == 'owner') {
      final ok = await confirmDialog(
        context,
        title: 'Make ${m.name} the owner?',
        message: 'They take over the group. You stay on as an admin.',
        confirmLabel: 'Make owner',
      );
      if (ok) await _run(() => repo.transferOwnership(g.id, m.id), done: '${m.name} is now the owner');
    } else if (pick == 'remove') {
      final ok = await confirmDialog(context, title: 'Remove ${m.name}?', message: 'They will no longer see this group.', confirmLabel: 'Remove', danger: true);
      if (ok) await _run(() => repo.removeMember(g.id, m.id), done: '${m.name} was removed');
    }
  }

  /// An owner who still has other members picks who takes over before leaving.
  Future<void> _leave(MGroup g, String myId) async {
    final repo = ref.read(messengerRepositoryProvider);
    String? newOwner;
    final others = g.sortedMembers.where((m) => m.id != myId).toList();
    if (g.isOwner(myId) && others.isNotEmpty) {
      newOwner = await _chooseOwner(others);
      if (newOwner == null) return;
    } else {
      final ok = await confirmDialog(context, title: 'Leave ${g.name}?', message: 'You will stop receiving its messages.', confirmLabel: 'Leave', danger: true);
      if (!ok) return;
    }
    setState(() => _busy = true);
    try {
      await repo.leaveGroup(g.id, newOwnerId: newOwner);
      final chatId = g.chatId;
      if (chatId != null) _controller.forgetChat(chatId);
      await _controller.refreshChats();
      if (mounted) {
        showToast(context, 'You left ${g.name}');
        context.go('/messages');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  Future<String?> _chooseOwner(List<MGroupMember> others) {
    String? chosen;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Choose a new owner', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('You own this group, so someone has to take over before you leave.', style: TextStyle(color: ctx.mutedColor, height: 1.4)),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      for (final m in others)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: MessengerAvatar(initials: m.user.initials, imageUrl: m.profilePictureUrl, size: 38),
                          title: Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: m.isAdmin ? const Text('Admin') : null,
                          trailing: chosen == m.id ? Icon(Icons.check_circle_rounded, color: ctx.pal.accent) : Icon(Icons.circle_outlined, color: ctx.mutedColor),
                          onTap: () => setLocal(() => chosen = m.id),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: chosen == null ? null : () => Navigator.of(ctx).pop(chosen), child: const Text('Make owner and leave')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(groupDetailsProvider(widget.groupId));
    final myId = ref.watch(messengerProvider.select((s) => s.me?.id)) ?? _controller.meId;

    return SubPage(
      title: 'Group info',
      fallbackRoute: '/messages',
      body: AsyncBody<MGroup>(
        value: value,
        onRetry: () => ref.invalidate(groupDetailsProvider(widget.groupId)),
        builder: (g) => _content(context, g, myId),
      ),
    );
  }

  Widget _content(BuildContext context, MGroup g, String myId) {
    final pal = context.pal;
    final admin = g.isAdmin(myId);
    final members = g.sortedMembers;
    final stillMember = g.memberIds.contains(myId) || members.any((m) => m.id == myId);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(groupDetailsProvider(widget.groupId));
        await ref.read(groupDetailsProvider(widget.groupId).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          Center(
            child: Stack(children: <Widget>[
              MessengerAvatar(initials: g.name.isEmpty ? 'G' : g.name[0].toUpperCase(), imageUrl: g.groupPhotoUrl, size: 104, group: true),
              if (admin)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: pal.accent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _busy ? null : () => _photo(g),
                      child: Padding(padding: const EdgeInsets.all(9), child: Icon(Icons.photo_camera_outlined, size: 18, color: pal.accentInk)),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 14),
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: admin && !_busy ? () => _rename(g) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  Flexible(child: Text(g.name, textAlign: TextAlign.center, style: context.display(size: 22, weight: FontWeight.w800))),
                  if (admin) ...<Widget>[const SizedBox(width: 6), Icon(Icons.edit_outlined, size: 16, color: context.mutedColor)],
                ]),
              ),
            ),
          ),
          Center(child: Text('${members.length} ${members.length == 1 ? 'member' : 'members'}', style: TextStyle(color: context.mutedColor))),
          const SizedBox(height: 16),
          PCard(
            padding: EdgeInsets.zero,
            child: InkWell(
              borderRadius: BorderRadius.circular(context.radius(Brand.radiusLarge)),
              onTap: admin && !_busy ? () => _describe(g) : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      Text('Description', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.mutedColor)),
                      const SizedBox(height: 4),
                      Text(g.description.isEmpty ? (admin ? 'Add a description' : 'No description') : g.description, style: TextStyle(height: 1.4, color: g.description.isEmpty ? context.mutedColor : null)),
                    ]),
                  ),
                  if (admin) Icon(Icons.edit_outlined, size: 18, color: context.mutedColor),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          MenuGroup(children: <Widget>[
            if (g.chatId != null)
              MenuTile(icon: Icons.chat_bubble_outline_rounded, title: 'Open chat', onTap: () => context.go('/messages/chat/${Uri.encodeComponent(g.chatId ?? '')}')),
            if (admin) MenuTile(icon: Icons.link_rounded, title: 'Invite link and QR code', subtitle: 'Let people join without being added', onTap: () => context.push('/messages/group/${Uri.encodeComponent(g.id)}/invite')),
            if (admin) MenuTile(icon: Icons.person_add_alt_1_outlined, title: 'Add members', onTap: _busy ? null : () => _addMembers(g)),
          ]),
          const SizedBox(height: 18),
          Text('Members', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.mutedColor)),
          const SizedBox(height: 8),
          PCard(
            padding: EdgeInsets.zero,
            child: Column(children: <Widget>[
              for (var i = 0; i < members.length; i++) ...<Widget>[
                if (i > 0) Divider(height: 1, indent: 70, color: context.borderColor),
                _memberRow(context, g, members[i], myId),
              ],
            ]),
          ),
          const SizedBox(height: 20),
          if (stillMember)
            PButton(
              label: 'Leave group',
              icon: Icons.logout_rounded,
              kind: PButtonKind.danger,
              expand: true,
              loading: _busy,
              onPressed: () => _leave(g, myId),
            ),
        ],
      ),
    );
  }

  Widget _memberRow(BuildContext context, MGroup g, MGroupMember m, String myId) {
    final pal = context.pal;
    final me = m.id == myId;
    final role = m.isOwner ? 'Owner' : (m.isAdmin ? 'Admin' : null);
    return ListTile(
      leading: MessengerAvatar(initials: m.user.initials, imageUrl: m.profilePictureUrl, size: 44),
      title: Text(me ? '${m.name} (you)' : m.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: m.username.isNotEmpty && !m.username.contains('@') ? Text('@${m.username}', maxLines: 1, overflow: TextOverflow.ellipsis) : null,
      trailing: role == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: pal.accentSoft, borderRadius: BorderRadius.circular(99)),
              child: Text(role, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: pal.ink)),
            ),
      onTap: me ? null : () => _memberMenu(g, m, myId),
    );
  }
}
