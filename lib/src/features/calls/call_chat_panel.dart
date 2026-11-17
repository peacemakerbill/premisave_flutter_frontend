import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../state/call_controller.dart';
import 'call_widgets.dart';

/// The chat inside a call. It belongs to the call: it is kept for a while for the people who were in it, and is not
/// part of any chat thread.
class CallChatPanel extends StatefulWidget {
  const CallChatPanel({super.key, required this.session, required this.onClose});

  final CallSession session;
  final VoidCallback onClose;

  @override
  State<CallChatPanel> createState() => _CallChatPanelState();
}

class _CallChatPanelState extends State<CallChatPanel> {
  final TextEditingController _text = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;
  int _shown = 0;

  CallSession get _s => widget.session;

  @override
  void initState() {
    super.initState();
    _s.addListener(_onSession);
    WidgetsBinding.instance.addPostFrameCallback((_) => _toEnd(jump: true));
  }

  @override
  void dispose() {
    _s.removeListener(_onSession);
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onSession() {
    if (!mounted) return;
    setState(() {});
    if (_s.chat.length != _shown) {
      _shown = _s.chat.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _toEnd());
    }
    // Messages that arrive while the panel is open are read.
    if (_s.unreadChat > 0) _s.setChatOpen(true);
  }

  void _toEnd({bool jump = false}) {
    if (!_scroll.hasClients) return;
    final end = _scroll.position.maxScrollExtent;
    if (jump) {
      _scroll.jumpTo(end);
    } else {
      _scroll.animateTo(end, duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
    }
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _s.sendChat(t);
      _text.clear();
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _hhmm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final msgs = _s.chat;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 6, 6),
          child: Row(
            children: <Widget>[
              const Expanded(child: Text('Chat in this call', style: TextStyle(color: CallColors.text, fontSize: 16, fontWeight: FontWeight.w800))),
              IconButton(tooltip: 'Close', icon: const Icon(Icons.close_rounded, color: CallColors.text), onPressed: widget.onClose),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Only people in the call can see these messages.', style: TextStyle(color: CallColors.muted, fontSize: 12.5)),
          ),
        ),
        Expanded(
          child: msgs.isEmpty
              ? const Center(child: Text('No messages yet.', style: TextStyle(color: CallColors.muted)))
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    final mine = m.senderId == _s.meId;
                    final sameAsPrev = i > 0 && msgs[i - 1].senderId == m.senderId;
                    return Padding(
                      padding: EdgeInsets.only(top: sameAsPrev ? 2 : 10),
                      child: Column(
                        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: <Widget>[
                          if (!sameAsPrev && !mine)
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 2),
                              child: Text(m.senderName.isEmpty ? 'Member' : m.senderName, style: const TextStyle(color: CallColors.muted, fontSize: 11.5, fontWeight: FontWeight.w700)),
                            ),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 280),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: mine ? const Color(0xFF1F6B4D) : CallColors.control,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                SelectableText(m.text, style: const TextStyle(color: CallColors.text, fontSize: 14.5, height: 1.3)),
                                const SizedBox(height: 2),
                                Text(_hhmm(m.createdAt), style: const TextStyle(color: CallColors.muted, fontSize: 10.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(12, 6, 12, 10 + MediaQuery.of(context).viewInsets.bottom * 0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _text,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: const TextStyle(color: CallColors.text),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Message everyone',
                    hintStyle: const TextStyle(color: CallColors.muted),
                    filled: true,
                    fillColor: CallColors.control,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: CallColors.speaking,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _sending ? null : _send,
                  child: const SizedBox(width: 44, height: 44, child: Icon(Icons.send_rounded, color: CallColors.bg, size: 20)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
