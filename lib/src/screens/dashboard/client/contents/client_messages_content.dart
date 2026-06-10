import 'package:flutter/material.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);

class ClientMessagesContent extends StatefulWidget {
  const ClientMessagesContent({super.key});

  @override
  State<ClientMessagesContent> createState() => _ClientMessagesContentState();
}

class _ClientMessagesContentState extends State<ClientMessagesContent> {
  Map<String, dynamic>? _selectedChat;

  final List<Map<String, dynamic>> _conversations = [
    {
      'id': '1',
      'name': 'John Mwangi',
      'role': 'Host - Sky Gardens',
      'lastMessage': 'Check-in time is 2 PM. Looking forward!',
      'time': '10:30 AM',
      'unread': 2,
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
    },
    {
      'id': '2',
      'name': 'Premisave Support',
      'role': 'Customer Support',
      'lastMessage': 'Your payment has been confirmed',
      'time': 'Yesterday',
      'unread': 0,
      'avatar': 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=100',
    },
    {
      'id': '3',
      'name': 'Sarah Kimani',
      'role': 'Property Owner - Villa',
      'lastMessage': 'WiFi password: Premisave2024',
      'time': '2 days ago',
      'unread': 1,
      'avatar': 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100',
    },
  ];

  final Map<String, List<Map<String, dynamic>>> _chatMessages = {
    '1': [
      {'sender': 'host', 'message': 'Hello! Welcome to Sky Gardens', 'time': '9:00 AM'},
      {'sender': 'me', 'message': 'Hi! Thanks, excited to check in', 'time': '9:05 AM'},
      {'sender': 'host', 'message': 'Check-in time is 2 PM. Looking forward!', 'time': '10:30 AM'},
    ],
    '2': [
      {'sender': 'support', 'message': 'Your payment of KES 42,500 has been confirmed', 'time': 'Yesterday'},
      {'sender': 'me', 'message': 'Great, thanks for the update', 'time': 'Yesterday'},
    ],
    '3': [
      {'sender': 'owner', 'message': 'Hi! WiFi password: Premisave2024', 'time': '2 days ago'},
      {'sender': 'me', 'message': 'Got it, thank you!', 'time': '2 days ago'},
    ],
  };

  void _openChat(Map<String, dynamic> chat) {
    setState(() => _selectedChat = chat);
  }

  void _closeChat() {
    setState(() => _selectedChat = null);
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 768;

    if (_selectedChat != null) {
      return _buildChatScreen(_selectedChat!);
    }

    return _buildConversationsList(isSmall);
  }

  Widget _buildConversationsList(bool isSmall) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 20 : 36, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeaderSection(),
          const SizedBox(height: 28),
          const _MessageSearch(),
          const SizedBox(height: 24),
          _RecentConversations(
            conversations: _conversations,
            onChatTap: _openChat,
          ),
        ],
      ),
    );
  }

  Widget _buildChatScreen(Map<String, dynamic> chat) {
    final messages = _chatMessages[chat['id']] ?? [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _brand),
          onPressed: _closeChat,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(chat['name'], style: const TextStyle(fontSize: 16, color: _brand, fontWeight: FontWeight.w600)),
            Text(chat['role'], style: TextStyle(fontSize: 12, color: _slate)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined, color: _brand), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: _brand), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMe = message['sender'] == 'me';

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? _brand : _stone,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['message'],
                          style: TextStyle(color: isMe ? Colors.white : _brand),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message['time'],
                          style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : _slate),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: const Color(0xFFEAE6DE))),
            ),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.add_circle_outline, color: _brand), onPressed: () {}),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: _slate),
                      filled: true,
                      fillColor: _stone,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: _brand),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAE6DE)),
      ),
      padding: const EdgeInsets.all(28),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Messages',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.8),
                ),
                const SizedBox(height: 6),
                Text('Chat with hosts and support', style: TextStyle(fontSize: 14, color: _slate)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _stone, shape: BoxShape.circle),
            child: const Icon(Icons.message_rounded, color: _brand, size: 28),
          ),
        ],
      ),
    );
  }
}

class _MessageSearch extends StatelessWidget {
  const _MessageSearch();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE6DE)),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: TextStyle(color: _slate),
          prefixIcon: const Icon(Icons.search, color: _brand),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}

class _RecentConversations extends StatelessWidget {
  final List<Map<String, dynamic>> conversations;
  final Function(Map<String, dynamic>) onChatTap;

  const _RecentConversations({
    required this.conversations,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Conversations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _brand)),
        const SizedBox(height: 16),
        ...conversations.map((chat) => _ConversationTile(chat: chat, onTap: () => onChatTap(chat))).toList(),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> chat;
  final VoidCallback onTap;

  const _ConversationTile({required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE6DE)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(chat['avatar']),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chat['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _brand)),
                    Text(chat['role'], style: TextStyle(fontSize: 12, color: _slate)),
                    const SizedBox(height: 4),
                    Text(
                      chat['lastMessage'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(chat['time'], style: TextStyle(fontSize: 11.5, color: _slate)),
                  if (chat['unread'] > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _brand,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        chat['unread'].toString(),
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}