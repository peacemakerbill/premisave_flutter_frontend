import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/messenger_models.dart';
import '../../state/messenger_controller.dart';
import 'member_picker.dart';

/// Pick a member to start a private chat with. If the chat exists already it simply opens.
class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  bool _busy = false;

  Future<void> _start(MUser user) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final id = await ref.read(messengerProvider.notifier).startPrivateChat(user.id);
      if (mounted) context.go('/messages/chat/${Uri.encodeComponent(id)}');
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'New chat',
      fallbackRoute: '/messages',
      actions: <Widget>[
        IconButton(tooltip: 'New group', icon: const Icon(Icons.group_add_outlined), onPressed: () => context.push('/messages/new-group')),
      ],
      body: Stack(
        children: <Widget>[
          MemberPicker(onPick: _start, emptyMessage: 'No members match that search.'),
          if (_busy) const Positioned.fill(child: ColoredBox(color: Color(0x33000000), child: LoadingState())),
        ],
      ),
    );
  }
}
