
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show ImagePicker, ImageSource;

import '../../core/config/app_config.dart';
import '../../core/files/file_chooser.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/messenger_models.dart';
import '../../data/repositories/messenger_repository.dart';
import '../../state/messenger_controller.dart';

// Small pieces the messenger screens share: addresses, times, avatars, ticks, file pickers and invite links.

// ---------------------------------------------------------------- addresses

/// Turns a stored file link into one this device can open. A link the server wrote with its own
/// "localhost" is pointed at the messenger address the app was given, so photos load on a phone or emulator.
String? resolveMedia(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final u = url.trim();
  final base = Uri.parse(AppConfig.messengerUrl);
  if (u.startsWith('/')) return '${AppConfig.messengerUrl}$u';
  final uri = Uri.tryParse(u);
  if (uri == null || !uri.hasAuthority) return u;
  const local = <String>{'localhost', '127.0.0.1', '10.0.2.2', '0.0.0.0'};
  if (local.contains(uri.host) && uri.host != base.host) {
    return uri.replace(scheme: base.scheme, host: base.host, port: base.hasPort ? base.port : null).toString();
  }
  return u;
}

// -------------------------------------------------------------------- times

String _two(int n) => n.toString().padLeft(2, '0');

const List<String> _weekdays = <String>['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// 09:30
String clock(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

/// For the chat list: the time today, "Yesterday", the weekday this week, then the date.
String chatStamp(DateTime? d) {
  if (d == null) return '';
  final now = DateTime.now();
  if (sameDay(d, now)) return clock(d);
  if (sameDay(d, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  if (now.difference(d).inDays < 6) return _weekdays[d.weekday - 1];
  return formatDate(d);
}

/// For the day dividers inside a chat.
String dayLabel(DateTime d) {
  final now = DateTime.now();
  if (sameDay(d, now)) return 'Today';
  if (sameDay(d, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  if (now.difference(d).inDays < 6) return _weekdays[d.weekday - 1];
  return formatDate(d);
}

/// "online", "last seen today at 09:30" and so on.
String presenceLabel(Presence p) {
  if (p.online) return 'online';
  final t = p.lastSeen;
  if (t == null) return 'offline';
  final now = DateTime.now();
  if (sameDay(t, now)) return 'last seen today at ${clock(t)}';
  if (sameDay(t, now.subtract(const Duration(days: 1)))) return 'last seen yesterday at ${clock(t)}';
  return 'last seen ${formatDate(t)}';
}

// ------------------------------------------------------------------ previews

String typeLabel(MType t) {
  switch (t) {
    case MType.image:
      return 'Photo';
    case MType.video:
      return 'Video';
    case MType.voice:
      return 'Audio';
    case MType.document:
      return 'File';
    case MType.call:
      return 'Call';
    case MType.text:
    case MType.other:
      return 'Message';
  }
}

IconData typeIcon(MType t) {
  switch (t) {
    case MType.image:
      return Icons.photo_outlined;
    case MType.video:
      return Icons.videocam_outlined;
    case MType.voice:
      return Icons.mic_none_rounded;
    case MType.document:
      return Icons.insert_drive_file_outlined;
    case MType.call:
      return Icons.call_outlined;
    case MType.text:
    case MType.other:
      return Icons.chat_bubble_outline_rounded;
  }
}

/// One line for the chat list and for reply previews.
String previewOf(MMessage m) {
  if (m.deletedForEveryone || m.deleted) return 'This message was deleted';
  if (m.hasFile) return m.content.trim().isEmpty ? typeLabel(m.type) : '${typeLabel(m.type)}: ${m.content.trim()}';
  return m.content.trim();
}

// ------------------------------------------------------------------- avatars

/// A picture or initials, with a green dot when the person is online.
class MessengerAvatar extends StatelessWidget {
  const MessengerAvatar({super.key, required this.initials, this.imageUrl, this.size = 48, this.online = false, this.group = false});

  final String initials;
  final String? imageUrl;
  final double size;
  final bool online;
  final bool group;

  @override
  Widget build(BuildContext context) {
    final url = resolveMedia(imageUrl);
    final avatar = group && url == null
        ? Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: context.pal.accentSoft),
            child: Icon(Icons.groups_rounded, size: size * 0.5, color: context.pal.accent),
          )
        : UserAvatar(initials: initials, imageUrl: url, size: size);
    if (!online) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        avatar,
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: BoxDecoration(
              color: context.pal.good,
              shape: BoxShape.circle,
              border: Border.all(color: context.pal.bg, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

/// The small tick or clock beside the time of a message you sent.
class DeliveryTicks extends StatelessWidget {
  const DeliveryTicks({super.key, required this.status, this.color, this.size = 15});

  final MDelivery status;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final base = color ?? context.mutedColor;
    switch (status) {
      case MDelivery.sending:
        return Icon(Icons.schedule_rounded, size: size - 2, color: base);
      case MDelivery.sent:
        return Icon(Icons.done_rounded, size: size, color: base);
      case MDelivery.delivered:
        return Icon(Icons.done_all_rounded, size: size, color: base);
      case MDelivery.read:
        return Icon(Icons.done_all_rounded, size: size, color: context.pal.good);
      case MDelivery.failed:
        return Icon(Icons.error_outline_rounded, size: size, color: context.pal.bad);
    }
  }
}

/// A rounded count badge for unread chats.
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key, this.dot = false});

  final int count;

  /// Show a plain dot, for a chat marked unread by hand.
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    if (dot) {
      return Container(width: 12, height: 12, decoration: BoxDecoration(color: pal.accent, shape: BoxShape.circle));
    }
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: pal.accent, borderRadius: BorderRadius.circular(99)),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: TextStyle(color: pal.accentInk, fontSize: 11.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}

// -------------------------------------------------------------------- files

/// Chooses files from the device. Web returns bytes, other platforms return a path.
Future<List<LocalFile>> pickAnyFiles() async {
  final files = await chooseFiles(multiple: true, withData: kIsWeb);
  return <LocalFile>[
    for (final f in files)
      if (f.bytes != null || f.path != null) LocalFile(name: f.name, bytes: f.bytes, path: f.path, size: f.size),
  ];
}

/// A photo from the gallery or, where the device has one, the camera.
Future<LocalFile?> pickPhoto({required bool camera}) async {
  final x = await ImagePicker().pickImage(source: camera ? ImageSource.camera : ImageSource.gallery, imageQuality: 88, maxWidth: 2400);
  if (x == null) return null;
  final size = await x.length();
  if (kIsWeb) {
    final Uint8List bytes = await x.readAsBytes();
    return LocalFile(name: x.name, bytes: bytes, size: size);
  }
  return LocalFile(name: x.name, path: x.path, size: size);
}

/// One image for a status or a group picture.
Future<LocalFile?> pickImageFile() async {
  final files = await chooseFiles(extensions: imageExtensions, withData: kIsWeb);
  if (files.isEmpty) return null;
  final f = files.first;
  if (f.bytes == null && f.path == null) return null;
  return LocalFile(name: f.name, bytes: f.bytes, path: f.path, size: f.size);
}

/// The camera only exists on phones and tablets.
bool get hasCamera => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

// ------------------------------------------------------------- invite links

final RegExp _codePattern = RegExp(r'^[A-Za-z0-9_-]{16,64}$');

/// Reads the invite code from a pasted or scanned link such as https://premisave.com/join/CODE,
/// from `?join=CODE` or `#join=CODE`, or from the bare code. Returns null when the text is none of these.
String? inviteCodeFrom(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  final fromPath = RegExp(r'/join/([A-Za-z0-9_-]{16,64})').firstMatch(t);
  if (fromPath != null) return fromPath.group(1);
  final fromQuery = RegExp(r'[?#&]join=([A-Za-z0-9_-]{16,64})').firstMatch(t);
  if (fromQuery != null) return fromQuery.group(1);
  if (_codePattern.hasMatch(t)) return t;
  return null;
}

/// Matches an invite link inside a longer message, so it can be tapped.
final RegExp inviteLinkPattern = RegExp(r'https?://[^\s]+/join/[A-Za-z0-9_-]{16,64}');

// ------------------------------------------------------------------ colours

/// A steady colour for a person's name in a group chat.
Color nameColor(BuildContext context, String id) {
  const hues = <double>[8, 28, 48, 150, 190, 215, 265, 300, 335];
  var h = 0;
  for (final c in id.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  final hue = hues[h % hues.length];
  return HSLColor.fromAHSL(1, hue, 0.62, context.isDark ? 0.68 : 0.38).toColor();
}

// ------------------------------------------------------------------ statuses

/// Backgrounds offered for a text status, as the hex strings the server stores.
const List<String> kStatusColors = <String>['#0E3B2F', '#1F6F54', '#2563EB', '#7C3AED', '#DB2777', '#DC2626', '#EA580C', '#CA8A04', '#374151', '#000000'];

/// Reads "#RRGGBB" or "#AARRGGBB". Returns [fallback] when the text is not a colour.
Color parseHexColor(String? value, Color fallback) {
  if (value == null) return fallback;
  var h = value.trim().replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return fallback;
  final n = int.tryParse(h, radix: 16);
  return n == null ? fallback : Color(n);
}

/// A photo, video or audio clip for a status.
Future<LocalFile?> pickStatusMedia({required bool audio}) async {
  final files = await chooseFiles(extensions: audio ? audioExtensions : mediaExtensions, withData: kIsWeb);
  if (files.isEmpty) return null;
  final f = files.first;
  if (f.bytes == null && f.path == null) return null;
  return LocalFile(name: f.name, bytes: f.bytes, path: f.path, size: f.size);
}

bool looksLikeImage(String name) {
  final n = name.toLowerCase();
  return n.endsWith('.jpg') || n.endsWith('.jpeg') || n.endsWith('.png') || n.endsWith('.gif') || n.endsWith('.webp') || n.endsWith('.bmp');
}
