import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/widgets.dart';
import 'chat_list_pane.dart';
import 'conversation_pane.dart';

/// The Messages tab. On a phone it shows the chat list, or the open chat when [chatId] is set.
/// On a wide screen the list stays on the left and the chat opens beside it.
class MessengerScreen extends ConsumerStatefulWidget {
  const MessengerScreen({super.key, this.chatId});

  final String? chatId;

  @override
  ConsumerState<MessengerScreen> createState() => _MessengerScreenState();
}

class _MessengerScreenState extends ConsumerState<MessengerScreen> {
  @override
  Widget build(BuildContext context) {
    final id = widget.chatId;

    if (!context.isWide) {
      if (id != null) return ConversationPane(key: ValueKey<String>(id), chatId: id);
      return const ChatListPane();
    }

    return Row(
      children: <Widget>[
        SizedBox(width: 360, child: ChatListPane(selectedChatId: id)),
        VerticalDivider(width: 1, color: context.borderColor),
        Expanded(
          child: id == null
              ? const _NoChatSelected()
              : ConversationPane(key: ValueKey<String>(id), chatId: id),
        ),
      ],
    );
  }
}

class _NoChatSelected extends StatelessWidget {
  const _NoChatSelected();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.pal.bg,
      child: const EmptyState(
        icon: Icons.forum_outlined,
        title: 'Select a chat',
        message: 'Pick a conversation from the list, or start a new one.',
      ),
    );
  }
}
