import 'package:flutter/material.dart';

const _brand = Color(0xFF1A3C34);
const _brandLight = Color(0xFF2D5A4F);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);
const _border = Color(0xFFEAE6DE);

class ClientMessagesContent extends StatefulWidget {
  const ClientMessagesContent({super.key});

  @override
  State<ClientMessagesContent> createState() => _ClientMessagesContentState();
}

class _ClientMessagesContentState extends State<ClientMessagesContent> {
  Map<String, dynamic>? _selectedChat;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Unified dynamic message history storage array
  final List<Map<String, dynamic>> _messagesArchive = [
    {'id': 'm1', 'chatId': '1', 'sender': 'host', 'text': 'Hello! Thanks for choosing Sky Gardens.', 'time': '10:15 AM'},
    {'id': 'm2', 'chatId': '1', 'sender': 'client', 'text': 'Hi John, excited to visit! What are the check-in rules?', 'time': '10:22 AM'},
    {'id': 'm3', 'chatId': '1', 'sender': 'host', 'text': 'Check-in time is 2 PM. Looking forward!', 'time': '10:30 AM'},
    {'id': 'm4', 'chatId': '2', 'sender': 'support', 'text': 'Your payment has been confirmed', 'time': 'Yesterday'},
  ];

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
      'avatar': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100',
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Reactive computer mapping engine that tracks search parameter strings
  List<Map<String, dynamic>> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    return _conversations.where((chat) {
      final nameMatch = (chat['name'] as String).toLowerCase().contains(_searchQuery);
      final roleMatch = (chat['role'] as String).toLowerCase().contains(_searchQuery);
      return nameMatch || roleMatch;
    }).toList();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _selectedChat == null) return;

    setState(() {
      final text = _messageController.text.trim();
      _messagesArchive.add({
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
        'chatId': _selectedChat!['id'],
        'sender': 'client',
        'text': text,
        'time': 'Just now',
      });

      final idx = _conversations.indexWhere((c) => c['id'] == _selectedChat!['id']);
      if (idx != -1) {
        _conversations[idx]['lastMessage'] = text;
        _conversations[idx]['time'] = 'Just now';
      }

      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 768;

      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 340,
              child: _buildLeftSidebar(),
            ),
            VerticalDivider(width: 1, color: _border, thickness: 1),
            Expanded(
              child: _selectedChat != null
                  ? _buildActiveChatPanel()
                  : _buildEmptyWorkspaceView(),
            ),
          ],
        );
      }

      return _selectedChat != null
          ? _buildActiveChatPanel()
          : _buildLeftSidebar();
    });
  }

  Widget _buildLeftSidebar() {
    final listData = _filteredConversations;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Messages',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.6),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Connect directly with hosts & support',
                  style: TextStyle(fontSize: 13, color: _slate, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),

                // Embedded Premium Search Module Container Layout
                Container(
                  decoration: BoxDecoration(
                    color: _stone.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: _slate, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 14, color: _brand),
                          decoration: const InputDecoration(
                            hintText: 'Search chats...',
                            hintStyle: TextStyle(color: _slate, fontSize: 13.5),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: _slate, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _searchController.clear(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),
          Expanded(
            child: listData.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off_rounded, size: 36, color: _slate),
                    const SizedBox(height: 8),
                    const Text(
                      'No matching discussions',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _brand),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Try altering your search text query.',
                      style: TextStyle(fontSize: 12.5, color: _slate),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: listData.length,
              separatorBuilder: (context, idx) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, color: Color(0xFFF3EFE6)),
              ),
              itemBuilder: (context, index) {
                final chat = listData[index];
                final isCurrent = _selectedChat?['id'] == chat['id'];

                return InkWell(
                  onTap: () {
                    setState(() {
                      chat['unread'] = 0;
                      _selectedChat = chat;
                    });
                  },
                  child: Container(
                    color: isCurrent ? _stone.withOpacity(0.5) : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.network(
                                chat['avatar'],
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 48,
                                  height: 48,
                                  color: _stone,
                                  child: const Icon(Icons.person, color: _brand),
                                ),
                              ),
                            ),
                            if (chat['unread'] > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.pink,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      chat['name'],
                                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _brand),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    chat['time'],
                                    style: const TextStyle(fontSize: 11, color: _slate, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                chat['role'],
                                style: const TextStyle(fontSize: 11.5, color: _gold, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                chat['lastMessage'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: chat['unread'] > 0 ? _brand : _slate,
                                  fontWeight: chat['unread'] > 0 ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChatPanel() {
    final activeMessages = _messagesArchive.where((m) => m['chatId'] == _selectedChat!['id']).toList();

    return Container(
      color: const Color(0xFFFBF9F6),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  if (MediaQuery.of(context).size.width <= 768)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _brand),
                      onPressed: () => setState(() => _selectedChat = null),
                    ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      _selectedChat!['avatar'],
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 40,
                        height: 40,
                        color: _stone,
                        child: const Icon(Icons.person, color: _brand),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedChat!['name'],
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: _brand),
                        ),
                        Text(
                          _selectedChat!['role'],
                          style: const TextStyle(fontSize: 11.5, color: _slate, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded, color: _slate),
                    onPressed: () {},
                  )
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: _border),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: activeMessages.length,
              itemBuilder: (context, idx) {
                final msg = activeMessages[idx];
                final isMe = msg['sender'] == 'client';

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: isMe ? _brand : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      border: isMe ? null : Border.all(color: _border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.015),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg['text']!,
                          style: TextStyle(color: isMe ? Colors.white : _brand, fontSize: 14, height: 1.3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg['time']!,
                          style: TextStyle(color: isMe ? Colors.white60 : _slate, fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: _brandLight, size: 26),
                  onPressed: () {},
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _stone.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _messageController,
                      maxLines: 3,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 14.5, color: _brand),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: _slate, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _brand,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWorkspaceView() {
    return Container(
      color: const Color(0xFFFBF9F6),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: _slate),
            SizedBox(height: 12),
            Text(
              'Select a conversation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _brand),
            ),
            SizedBox(height: 2),
            Text(
              'Choose a message thread from the listing left panel to read.',
              style: TextStyle(fontSize: 13, color: _slate),
            ),
          ],
        ),
      ),
    );
  }
}