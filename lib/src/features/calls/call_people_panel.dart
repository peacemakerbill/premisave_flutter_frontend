import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/call_models.dart';
import '../../state/call_controller.dart';
import '../messenger/member_picker.dart';
import 'call_widgets.dart';

/// Opens the member list to add more people to the running call. They ring straight away.
Future<void> addPeopleToCall(BuildContext context, CallSession session) async {
  final already = session.call.people.where((p) => p.state == PersonState.joined || p.state == PersonState.invited).map((p) => p.userId).toSet();
  final picked = await showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.pal.bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _AddPeopleSheet(exclude: already),
  );
  if (picked == null || picked.isEmpty) return;
  try {
    await session.invite(picked.toList());
    if (context.mounted) showToast(context, picked.length == 1 ? 'Calling 1 person' : 'Calling ${picked.length} people');
  } catch (e) {
    if (context.mounted) showApiError(context, e);
  }
}

class _AddPeopleSheet extends StatefulWidget {
  const _AddPeopleSheet({required this.exclude});

  final Set<String> exclude;

  @override
  State<_AddPeopleSheet> createState() => _AddPeopleSheetState();
}

class _AddPeopleSheetState extends State<_AddPeopleSheet> {
  Set<String> _picked = <String>{};

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.86,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
            child: Row(
              children: <Widget>[
                Expanded(child: Text('Add people to the call', style: context.display(size: 18, weight: FontWeight.w800))),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
          Expanded(
            child: MemberPicker(
              multi: true,
              excludeIds: widget.exclude,
              onSelectionChanged: (v) => setState(() => _picked = v),
              emptyMessage: 'No members match that search.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: PButton(
              label: _picked.isEmpty ? 'Pick people to call' : (_picked.length == 1 ? 'Call 1 person' : 'Call ${_picked.length} people'),
              icon: Icons.call_rounded,
              expand: true,
              onPressed: _picked.isEmpty ? null : () => Navigator.of(context).pop(_picked),
            ),
          ),
        ],
      ),
    );
  }
}

/// Who is in the call, who is ringing, and what a host can do about it.
class CallPeoplePanel extends StatelessWidget {
  const CallPeoplePanel({super.key, required this.session, required this.onClose});

  final CallSession session;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => _build(context),
    );
  }

  Future<void> _run(BuildContext context, Future<void> Function() job, {String? done}) async {
    try {
      await job();
      if (done != null && context.mounted) showToast(context, done);
    } catch (e) {
      if (context.mounted) showApiError(context, e);
    }
  }

  Widget _build(BuildContext context) {
    final s = session;
    final call = s.call;
    final tiles = s.tiles().where((t) => !t.isScreen).toList();
    final inCall = tiles.where((t) => t.status == null).toList();
    final ringing = tiles.where((t) => t.status != null).toList();
    // People with a raised hand come first, so a host sees who wants to speak.
    inCall.sort((a, b) {
      if (a.isLocal != b.isLocal) return a.isLocal ? -1 : 1;
      if (a.handUp != b.handUp) return a.handUp ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    final manager = s.isManager;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 6, 6),
          child: Row(
            children: <Widget>[
              Expanded(child: Text('People (${inCall.length})', style: const TextStyle(color: CallColors.text, fontSize: 16, fontWeight: FontWeight.w800))),
              IconButton(tooltip: 'Close', icon: const Icon(Icons.close_rounded, color: CallColors.text), onPressed: onClose),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _chip(Icons.person_add_alt_1_rounded, 'Add people', () => addPeopleToCall(context, s)),
              if (call.linkUrl != null)
                _chip(Icons.link_rounded, 'Copy link', () async {
                  await Clipboard.setData(ClipboardData(text: call.linkUrl!));
                  if (context.mounted) showToast(context, 'Call link copied');
                }),
              if (manager && call.isGroupLike) _chip(Icons.mic_off_rounded, 'Mute everyone', () => _run(context, s.muteAll, done: 'Everyone is muted')),
              if (manager) _chip(call.locked ? Icons.lock_open_rounded : Icons.lock_rounded, call.locked ? 'Unlock call' : 'Lock call', () => _run(context, () => s.setLocked(!call.locked))),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            children: <Widget>[
              for (final t in inCall) _row(context, t, manager),
              if (ringing.isNotEmpty) ...<Widget>[
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 16, 10, 4),
                  child: Text('Ringing', style: TextStyle(color: CallColors.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
                for (final t in ringing) _row(context, t, manager),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String label, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 17, color: CallColors.text),
      label: Text(label, style: const TextStyle(color: CallColors.text, fontWeight: FontWeight.w600, fontSize: 13)),
      backgroundColor: CallColors.control,
      side: BorderSide.none,
      onPressed: onTap,
    );
  }

  Widget _row(BuildContext context, CallTile t, bool manager) {
    final s = session;
    final role = s.call.roleOf(t.userId);
    final ringing = t.status != null;
    final canManage = manager && !t.isLocal && !ringing;
    final roleText = role == CallRole.host ? 'Host' : (role == CallRole.cohost ? 'Co-host' : null);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: UserAvatar(initials: initialsOf(t.name), imageUrl: t.picture, size: 38),
      title: Text(t.isLocal ? 'You' : t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CallColors.text, fontWeight: FontWeight.w700, fontSize: 14.5)),
      subtitle: ringing
          ? const Text('Ringing', style: TextStyle(color: CallColors.muted, fontSize: 12))
          : (roleText == null ? null : Text(roleText, style: const TextStyle(color: CallColors.speaking, fontSize: 12, fontWeight: FontWeight.w700))),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (t.handUp) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.back_hand_rounded, size: 18, color: CallColors.hand)),
          if (!ringing) Icon(t.micOff ? Icons.mic_off_rounded : Icons.mic_rounded, size: 18, color: t.micOff ? CallColors.muted : CallColors.speaking),
          if (canManage || ringing && manager)
            PopupMenuButton<String>(
              tooltip: 'Options',
              color: CallColors.control,
              icon: const Icon(Icons.more_vert_rounded, color: CallColors.text, size: 20),
              onSelected: (v) {
                switch (v) {
                  case 'mute':
                    _run(context, () => s.muteOther(t.userId), done: 'Muted ${t.name}');
                    break;
                  case 'cohost':
                    _run(context, () => s.setRole(t.userId, CallRole.cohost));
                    break;
                  case 'member':
                    _run(context, () => s.setRole(t.userId, CallRole.member));
                    break;
                  case 'host':
                    _run(context, () => s.setRole(t.userId, CallRole.host), done: '${t.name} is now the host');
                    break;
                  case 'remove':
                    _run(context, () => s.removeOther(t.userId));
                    break;
                }
              },
              itemBuilder: (ctx) => <PopupMenuEntry<String>>[
                if (!ringing && !t.micOff) _item('mute', Icons.mic_off_rounded, 'Mute'),
                if (!ringing && role == CallRole.member) _item('cohost', Icons.shield_outlined, 'Make co-host'),
                if (!ringing && role == CallRole.cohost) _item('member', Icons.person_outline_rounded, 'Remove co-host'),
                if (!ringing && s.call.roleOf(s.meId) == CallRole.host) _item('host', Icons.workspace_premium_outlined, 'Make host'),
                _item('remove', Icons.person_remove_alt_1_rounded, ringing ? 'Cancel call' : 'Remove from call', danger: true),
              ],
            ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _item(String value, IconData icon, String label, {bool danger = false}) {
    final color = danger ? CallColors.danger : CallColors.text;
    return PopupMenuItem<String>(
      value: value,
      child: Row(children: <Widget>[Icon(icon, size: 18, color: color), const SizedBox(width: 10), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600))]),
    );
  }
}
