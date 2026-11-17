import 'package:cached_network_image/cached_network_image.dart' show CachedNetworkImage;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' show LaunchMode, launchUrl;

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/messenger_models.dart';
import 'messenger_common.dart';

/// One message as a bubble: reply preview, text or file, reactions, time and delivery ticks.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.mine,
    required this.myId,
    this.showName = false,
    this.nameOf,
    this.onLongPress,
    this.onReact,
    this.onRetry,
    this.onOpenReply,
    this.onOpenInvite,
    this.highlight = '',
  });

  final MMessage message;
  final bool mine;
  final String myId;

  /// Show the sender's name above the text, for others' messages in a group.
  final bool showName;
  final String Function(String userId)? nameOf;
  final VoidCallback? onLongPress;
  final ValueChanged<String>? onReact;
  final VoidCallback? onRetry;
  final ValueChanged<String>? onOpenReply;
  final ValueChanged<String>? onOpenInvite;

  /// Text to mark inside the message while searching.
  final String highlight;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final m = message;
    final bg = mine ? pal.accent : pal.panel;
    final fg = mine ? pal.accentInk : pal.ink;
    final soft = mine ? pal.accentInk.op(0.75) : context.mutedColor;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(mine ? 16 : 4),
      bottomRight: Radius.circular(mine ? 4 : 16),
    );
    final maxWidth = MediaQuery.of(context).size.width * (context.isWide ? 0.38 : 0.78);

    final deleted = m.deleted || m.deletedForEveryone;
    final children = <Widget>[];

    if (showName && !mine) {
      final id = m.senderId;
      final name = nameOf != null ? nameOf!(id) : m.senderName;
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text(name.isEmpty ? 'Member' : name, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: nameColor(context, id))),
      ));
    }

    if (!deleted && m.reply != null) {
      children.add(_ReplyPreview(reply: m.reply!, mine: mine, onTap: onOpenReply == null ? null : () => onOpenReply!(m.reply!.messageId)));
    }

    if (deleted) {
      children.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.block_rounded, size: 15, color: soft),
          const SizedBox(width: 6),
          Text('This message was deleted', style: TextStyle(fontStyle: FontStyle.italic, color: soft, fontSize: 14)),
        ],
      ));
    } else {
      if (m.hasFile) children.add(_FileBody(message: m, mine: mine, fg: fg, soft: soft));
      if (m.content.trim().isNotEmpty) {
        children.add(Padding(
          padding: EdgeInsets.only(top: m.hasFile ? 6 : 0),
          child: _RichText(text: m.content, color: fg, linkColor: mine ? pal.accentInk : pal.accent, highlight: highlight, onInvite: onOpenInvite),
        ));
      }
    }

    children.add(Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          if (m.editedAt != null && !deleted) Padding(padding: const EdgeInsets.only(right: 5), child: Text('edited', style: TextStyle(fontSize: 11, color: soft))),
          Text(clock(m.createdAt), style: TextStyle(fontSize: 11, color: soft)),
          if (mine) ...<Widget>[const SizedBox(width: 4), DeliveryTicks(status: m.status, color: soft, size: 14)],
        ],
      ),
    ));

    final bubble = GestureDetector(
      onLongPress: onLongPress,
      onSecondaryTap: onLongPress,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: mine ? null : Border.all(color: context.borderColor),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: children),
      ),
    );

    final reactions = deleted ? const <String, List<String>>{} : m.reactions;
    return Column(
      crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: <Widget>[
        bubble,
        if (reactions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: <Widget>[
                for (final e in reactions.entries)
                  InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: onReact == null ? null : () => onReact!(e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: e.value.contains(myId) ? pal.accentSoft : pal.panel2,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: e.value.contains(myId) ? pal.accent : context.borderColor),
                      ),
                      child: Text('${e.key} ${e.value.length}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: pal.ink)),
                    ),
                  ),
              ],
            ),
          ),
        if (m.status == MDelivery.failed && mine)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: InkWell(
              onTap: onRetry,
              child: Text('Not sent. Tap to try again', style: TextStyle(fontSize: 12, color: pal.bad, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.reply, required this.mine, this.onTap});

  final MReply reply;
  final bool mine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final fg = mine ? pal.accentInk : pal.ink;
    final tint = mine ? pal.accentInk.op(0.16) : pal.accentSoft;
    final text = reply.content.trim().isNotEmpty ? reply.content.trim() : (reply.type == MType.text ? 'Message' : typeLabel(reply.type));
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: mine ? pal.accentInk : pal.accent, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(reply.senderName.isEmpty ? 'Message' : reply.senderName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: fg)),
              const SizedBox(height: 1),
              Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: fg.op(0.85))),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileBody extends StatelessWidget {
  const _FileBody({required this.message, required this.mine, required this.fg, required this.soft});

  final MMessage message;
  final bool mine;
  final Color fg;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final url = resolveMedia(m.mediaUrl);
    final pending = m.status == MDelivery.sending && m.progress != null;

    if (m.type == MType.image) {
      return GestureDetector(
        onTap: url == null ? null : () => openImageViewer(context, url, m.fileName),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280, maxHeight: 320, minWidth: 160, minHeight: 120),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                if (url != null)
                  CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    width: 280,
                    placeholder: (_, __) => Container(height: 160, color: context.pal.panel2, alignment: Alignment.center, child: const CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (_, __, ___) => _brokenImage(context),
                  )
                else
                  Container(width: 220, height: 160, color: context.pal.panel2, alignment: Alignment.center, child: Icon(Icons.image_outlined, color: context.mutedColor, size: 36)),
                if (pending) _ProgressRing(value: m.progress ?? 0),
              ],
            ),
          ),
        ),
      );
    }

    final icon = m.type == MType.video ? Icons.play_circle_outline_rounded : (m.type == MType.voice ? Icons.graphic_eq_rounded : Icons.insert_drive_file_outlined);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: url == null ? null : () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: (mine ? context.pal.accentInk : context.pal.accent).op(0.12), borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            pending
                ? SizedBox(width: 34, height: 34, child: _ProgressRing(value: m.progress ?? 0, onBubble: false, color: fg))
                : Icon(icon, size: 34, color: fg),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(m.fileName ?? typeLabel(m.type), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: fg, fontSize: 14)),
                  if ((m.fileSize ?? 0) > 0) Text(formatBytes(m.fileSize ?? 0), style: TextStyle(fontSize: 12, color: soft)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brokenImage(BuildContext context) => Container(
        width: 220,
        height: 140,
        color: context.pal.panel2,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.broken_image_outlined, color: context.mutedColor),
            const SizedBox(height: 6),
            Text('Photo unavailable', style: TextStyle(fontSize: 12, color: context.mutedColor)),
          ],
        ),
      );
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value, this.onBubble = true, this.color});

  final double value;
  final bool onBubble;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ring = SizedBox(
      width: onBubble ? 46 : 34,
      height: onBubble ? 46 : 34,
      child: CircularProgressIndicator(value: value <= 0 ? null : value, strokeWidth: 3, color: color ?? Colors.white),
    );
    if (!onBubble) return ring;
    return Container(
      width: 62,
      height: 62,
      decoration: const BoxDecoration(color: Color(0x88000000), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: ring,
    );
  }
}

/// Opens a photo full screen, with pinch to zoom.
void openImageViewer(BuildContext context, String url, String? title) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(title ?? 'Photo', style: const TextStyle(fontSize: 15))),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (_, __) => const CircularProgressIndicator(),
            errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
          ),
        ),
      ),
    ),
  ));
}

/// Message text with links you can tap, invite links that open the join screen, and the words being searched marked.
class _RichText extends StatefulWidget {
  const _RichText({required this.text, required this.color, required this.linkColor, this.highlight = '', this.onInvite});

  final String text;
  final Color color;
  final Color linkColor;
  final String highlight;
  final ValueChanged<String>? onInvite;

  @override
  State<_RichText> createState() => _RichTextState();
}

class _RichTextState extends State<_RichText> {
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  static final RegExp _url = RegExp(r'(https?://[^\s]+)|(www\.[^\s]+)');

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  List<InlineSpan> _spans() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final base = TextStyle(color: widget.color, fontSize: 15, height: 1.32);
    final spans = <InlineSpan>[];
    var last = 0;

    void plain(String s) {
      if (s.isEmpty) return;
      final q = widget.highlight.trim().toLowerCase();
      if (q.isEmpty) {
        spans.add(TextSpan(text: s, style: base));
        return;
      }
      final lower = s.toLowerCase();
      var i = 0;
      while (true) {
        final at = lower.indexOf(q, i);
        if (at < 0) {
          spans.add(TextSpan(text: s.substring(i), style: base));
          break;
        }
        if (at > i) spans.add(TextSpan(text: s.substring(i, at), style: base));
        spans.add(TextSpan(text: s.substring(at, at + q.length), style: base.copyWith(backgroundColor: const Color(0x55FFD54F), fontWeight: FontWeight.w700)));
        i = at + q.length;
      }
    }

    for (final match in _url.allMatches(widget.text)) {
      plain(widget.text.substring(last, match.start));
      var link = match.group(0) ?? '';
      var trailing = '';
      while (link.isNotEmpty && '.,;:!?)'.contains(link[link.length - 1])) {
        trailing = link[link.length - 1] + trailing;
        link = link.substring(0, link.length - 1);
      }
      final code = inviteCodeFromLink(link);
      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          if (code != null && widget.onInvite != null) {
            widget.onInvite!(code);
          } else {
            launchUrl(Uri.parse(link.startsWith('http') ? link : 'https://$link'), mode: LaunchMode.externalApplication);
          }
        };
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: code != null ? 'Group invite link' : link,
        style: base.copyWith(color: widget.linkColor, decoration: TextDecoration.underline, fontWeight: code != null ? FontWeight.w700 : null),
        recognizer: recognizer,
      ));
      if (trailing.isNotEmpty) plain(trailing);
      last = match.end;
    }
    plain(widget.text.substring(last));
    return spans;
  }

  @override
  Widget build(BuildContext context) => Text.rich(TextSpan(children: _spans()));
}

/// The invite code when [link] is a group invite link, otherwise null.
String? inviteCodeFromLink(String link) => inviteLinkPattern.hasMatch(link) ? inviteCodeFrom(link) : null;
