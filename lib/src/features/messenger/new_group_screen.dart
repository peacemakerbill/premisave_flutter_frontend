import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/widgets.dart';
import '../../state/messenger_controller.dart';
import 'member_picker.dart';

/// Two steps: choose the members, then name the group.
class NewGroupScreen extends ConsumerStatefulWidget {
  const NewGroupScreen({super.key});

  @override
  ConsumerState<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends ConsumerState<NewGroupScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _about = TextEditingController();
  Set<String> _members = <String>{};
  bool _naming = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showToast(context, 'Give the group a name.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final g = await ref.read(messengerProvider.notifier).createGroup(name: name, description: _about.text, memberIds: _members.toList());
      if (!mounted) return;
      final chatId = g.chatId;
      context.go(chatId == null || chatId.isEmpty ? '/messages' : '/messages/chat/${Uri.encodeComponent(chatId)}');
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_naming) {
      return SubPage(
        title: 'New group',
        fallbackRoute: '/messages',
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(shape: BoxShape.circle, color: context.pal.accentSoft),
                child: Icon(Icons.groups_rounded, size: 44, color: context.pal.accent),
              ),
            ),
            const SizedBox(height: 22),
            PTextField(label: 'Group name', controller: _name, hint: 'For example: Sky Gardens tenants', autofocus: true, maxLength: 60, textCapitalization: TextCapitalization.sentences),
            const SizedBox(height: 14),
            PTextField(label: 'Description', controller: _about, hint: 'What is this group for?', optional: true, maxLines: 3, minLines: 2, maxLength: 200, textCapitalization: TextCapitalization.sentences),
            const SizedBox(height: 8),
            Text('${_members.length} ${_members.length == 1 ? 'member' : 'members'} will be added. You can share an invite link later.', style: TextStyle(color: context.mutedColor, fontSize: 13)),
            const SizedBox(height: 22),
            PButton(label: 'Create group', icon: Icons.check_rounded, expand: true, loading: _busy, onPressed: _create),
            const SizedBox(height: 8),
            PButton(label: 'Back to members', kind: PButtonKind.text, expand: true, onPressed: _busy ? null : () => setState(() => _naming = false)),
          ],
        ),
      );
    }
    return SubPage(
      title: 'Add members',
      fallbackRoute: '/messages',
      body: Column(
        children: <Widget>[
          Expanded(
            child: MemberPicker(
              multi: true,
              selected: _members,
              onSelectionChanged: (s) => setState(() => _members = s),
              emptyMessage: 'No members match that search.',
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: PButton(
                label: _members.isEmpty ? 'Continue without members' : 'Continue with ${_members.length}',
                icon: Icons.arrow_forward_rounded,
                expand: true,
                onPressed: () => setState(() => _naming = true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
