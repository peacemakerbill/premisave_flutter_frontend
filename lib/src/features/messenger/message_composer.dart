import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/messenger_models.dart';
import '../../data/repositories/messenger_repository.dart';
import 'emoji_panel.dart';
import 'messenger_common.dart';
import 'send_preview_dialog.dart';

/// Someone who can be tagged with @ in this chat.
class MentionTarget {
  const MentionTarget({
    required this.id,
    required this.name,
    this.photo,
    this.username = '',
    this.email = '',
    this.isAll = false,
  });

  /// The "@all" entry, shown first in a group. It tags everyone in the group.
  const MentionTarget.everyone()
      : id = '@all',
        name = 'all',
        photo = null,
        username = '',
        email = '',
        isAll = true;

  final String id;
  final String name;
  final String? photo;
  final String username;
  final String email;

  /// True for the @all entry.
  final bool isAll;
}

/// The message box: text, emoji, attachments, a reply or edit banner above it, and @ tagging.
class MessageComposer extends StatefulWidget {
  const MessageComposer({
    super.key,
    required this.onSend,
    required this.onSendFiles,
    this.onTyping,
    this.replyTo,
    this.editing,
    this.onCancelContext,
    this.onSaveEdit,
    this.mentionTargets = const <MentionTarget>[],
    this.replyAuthor,
  });

  /// Text, the ids of the people tagged in it, and whether it tags everyone with @all.
  final void Function(String text, List<String> mentionIds, bool mentionAll) onSend;
  final void Function(List<LocalFile> files, String caption) onSendFiles;
  final VoidCallback? onTyping;
  final MMessage? replyTo;
  final String? replyAuthor;

  /// The message being edited. The box shows its text, and sending saves the change.
  final MMessage? editing;
  final VoidCallback? onCancelContext;
  final void Function(String text, List<String> mentionIds, bool mentionAll)? onSaveEdit;
  final List<MentionTarget> mentionTargets;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();
  final Map<String, String> _tagged = <String, String>{}; // user id -> the name inserted after the @
  bool _allTagged = false; // @all was picked from the list
  bool _emoji = false;
  bool _hasText = false;
  String? _mentionQuery;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onChanged);
    _focus.addListener(() {
      if (_focus.hasFocus && _emoji) setState(() => _emoji = false);
    });
    _loadEditing();
  }

  @override
  void didUpdateWidget(covariant MessageComposer old) {
    super.didUpdateWidget(old);
    if (widget.editing?.id != old.editing?.id) _loadEditing();
    if (widget.replyTo?.id != old.replyTo?.id && widget.replyTo != null) _focus.requestFocus();
  }

  String? _editingId;

  void _loadEditing() {
    final e = widget.editing;
    if (e != null) {
      _editingId = e.id;
      _text.text = e.content;
      _text.selection = TextSelection.collapsed(offset: _text.text.length);
      _focus.requestFocus();
    } else if (_editingId != null) {
      _editingId = null;
      _text.clear();
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    final has = _text.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
    if (has && widget.editing == null) widget.onTyping?.call();
    _updateMention();
  }

  void _updateMention() {
    if (widget.mentionTargets.isEmpty) {
      if (_mentionQuery != null) setState(() => _mentionQuery = null);
      return;
    }
    final sel = _text.selection;
    final text = _text.text;
    String? query;
    if (sel.isValid && sel.isCollapsed) {
      final before = text.substring(0, sel.baseOffset.clamp(0, text.length));
      final at = before.lastIndexOf('@');
      if (at >= 0 && (at == 0 || before[at - 1] == ' ' || before[at - 1] == '\n')) {
        final word = before.substring(at + 1);
        if (!word.contains(' ') && !word.contains('\n')) query = word;
      }
    }
    if (query != _mentionQuery) setState(() => _mentionQuery = query);
  }

  List<MentionTarget> get _matches {
    final q = (_mentionQuery ?? '').toLowerCase();
    // Search by name, username or email, so a person can be found by whichever they remember.
    return widget.mentionTargets
        .where((t) => q.isEmpty || t.name.toLowerCase().contains(q) || t.username.toLowerCase().contains(q) || t.email.toLowerCase().contains(q))
        .take(6)
        .toList();
  }

  void _insertMention(MentionTarget t) {
    final sel = _text.selection;
    final text = _text.text;
    final cursor = sel.baseOffset.clamp(0, text.length);
    final before = text.substring(0, cursor);
    final at = before.lastIndexOf('@');
    if (at < 0) return;
    final inserted = '@${t.name} ';
    final next = text.substring(0, at) + inserted + text.substring(cursor);
    if (t.isAll) {
      _allTagged = true;
    } else {
      _tagged[t.id] = t.name;
    }
    _text.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: at + inserted.length));
    setState(() => _mentionQuery = null);
  }

  /// Ids of tagged people whose @name is still in the text.
  List<String> _mentionIds(String text) => <String>[
        for (final e in _tagged.entries)
          if (text.contains('@${e.value}')) e.key,
      ];

  /// True when the text still contains @all as a word of its own.
  bool _mentionsAll(String text) => _allTagged && RegExp(r'(^|\s)@all(?=\s|$|[.,!?])').hasMatch(text);

  void _submit() {
    final text = _text.text.trim();
    final captionOnly = widget.editing?.hasFile ?? false; // a photo or file may have its caption cleared
    if (text.isEmpty && !captionOnly) return;
    final ids = _mentionIds(text);
    final all = _mentionsAll(text);
    if (widget.editing != null) {
      widget.onSaveEdit?.call(text, ids, all);
    } else {
      widget.onSend(text, ids, all);
    }
    _text.clear();
    _tagged.clear();
    _allTagged = false;
    setState(() => _emoji = false);
  }

  /// One row of the @ list: name, then @username and email so people with the same name can be told apart.
  Widget _mentionTile(MentionTarget t) {
    final pal = context.pal;
    if (t.isAll) {
      return ListTile(
        dense: true,
        leading: CircleAvatar(radius: 15, backgroundColor: pal.accentSoft, child: Icon(Icons.groups_rounded, size: 18, color: pal.accent)),
        title: const Text('@all', style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: const Text('Notify everyone in this group'),
        onTap: () => _insertMention(t),
      );
    }
    final details = <String>[
      if (t.username.isNotEmpty && !t.username.contains('@')) '@${t.username}',
      if (t.email.isNotEmpty) t.email,
    ];
    return ListTile(
      dense: true,
      leading: MessengerAvatar(initials: t.name.isEmpty ? 'P' : t.name[0].toUpperCase(), imageUrl: t.photo, size: 30),
      title: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: details.isEmpty ? null : Text(details.join('  |  '), maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => _insertMention(t),
    );
  }

  void _toggleEmoji() {
    if (_emoji) {
      setState(() => _emoji = false);
      _focus.requestFocus();
    } else {
      _focus.unfocus();
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      setState(() => _emoji = true);
    }
  }

  void _addEmoji(String e) {
    final sel = _text.selection;
    final text = _text.text;
    final start = sel.isValid ? sel.start.clamp(0, text.length) : text.length;
    final end = sel.isValid ? sel.end.clamp(0, text.length) : text.length;
    _text.value = TextEditingValue(text: text.replaceRange(start, end, e), selection: TextSelection.collapsed(offset: start + e.length));
  }

  Future<void> _attach() async {
    final choice = await showCenteredSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Photo from gallery'), onTap: () => Navigator.of(ctx).pop('gallery')),
            if (hasCamera) ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Take a photo'), onTap: () => Navigator.of(ctx).pop('camera')),
            ListTile(leading: const Icon(Icons.attach_file_rounded), title: const Text('File'), subtitle: const Text('Documents, videos, audio and anything else'), onTap: () => Navigator.of(ctx).pop('file')),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    try {
      List<LocalFile> files;
      if (choice == 'file') {
        files = await pickAnyFiles();
      } else {
        final one = await pickPhoto(camera: choice == 'camera');
        files = one == null ? const <LocalFile>[] : <LocalFile>[one];
      }
      if (files.isEmpty || !mounted) return;
      final caption = await showSendFilesPreview(context, files);
      if (caption == null) return;
      widget.onSendFiles(files, caption);
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final editing = widget.editing != null;
    final editingFile = widget.editing?.hasFile ?? false;
    final banner = editing
        ? _Banner(
            icon: Icons.edit_outlined,
            title: editingFile ? 'Edit caption' : 'Edit message',
            text: widget.editing!.content.trim().isNotEmpty ? widget.editing!.content : (widget.editing!.fileName ?? typeLabel(widget.editing!.type)),
            onClose: widget.onCancelContext,
          )
        : (widget.replyTo != null
            ? _Banner(
                icon: Icons.reply_rounded,
                title: 'Replying to ${widget.replyAuthor ?? widget.replyTo!.senderName}',
                text: previewOf(widget.replyTo!),
                onClose: widget.onCancelContext,
              )
            : null);

    return Material(
      color: pal.panel,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Divider(height: 1, color: context.borderColor),
            if (banner != null) banner,
            if (_mentionQuery != null && _matches.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                color: pal.panel2,
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    for (final t in _matches)
                      _mentionTile(t),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  IconButton(tooltip: _emoji ? 'Keyboard' : 'Emoji', onPressed: _toggleEmoji, icon: Icon(_emoji ? Icons.keyboard_alt_outlined : Icons.emoji_emotions_outlined, color: context.mutedColor)),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      decoration: BoxDecoration(color: pal.field, borderRadius: BorderRadius.circular(22), border: Border.all(color: context.borderColor)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Focus(
                        onKeyEvent: (node, event) {
                          // On desktop and web, Enter sends and Shift+Enter adds a line.
                          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape && widget.editing != null) {
                            widget.onCancelContext?.call();
                            return KeyEventResult.handled;
                          }
                          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter && !HardwareKeyboard.instance.isShiftPressed && context.isWide) {
                            _submit();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextField(
                          controller: _text,
                          focusNode: _focus,
                          minLines: 1,
                          maxLines: 6,
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: editing ? (editingFile ? 'Add a caption' : 'Edit your message') : 'Message',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!editing) IconButton(tooltip: 'Attach', onPressed: _attach, icon: Icon(Icons.attach_file_rounded, color: context.mutedColor)),
                  const SizedBox(width: 2),
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: IconButton.filled(
                      tooltip: editing ? 'Save' : 'Send',
                      style: IconButton.styleFrom(backgroundColor: pal.accent, foregroundColor: pal.accentInk, disabledBackgroundColor: pal.panel2),
                      onPressed: (_hasText || editingFile) ? _submit : null,
                      icon: Icon(editing ? Icons.check_rounded : Icons.send_rounded, size: 21),
                    ),
                  ),
                ],
              ),
            ),
            if (_emoji) EmojiPanel(onPick: _addEmoji, height: 250),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.title, required this.text, this.onClose});

  final IconData icon;
  final String title;
  final String text;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Container(
      color: pal.panel2,
      padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: pal.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: pal.accent)),
                Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: context.mutedColor)),
              ],
            ),
          ),
          IconButton(tooltip: 'Cancel', onPressed: onClose, icon: const Icon(Icons.close_rounded, size: 20)),
        ],
      ),
    );
  }
}
