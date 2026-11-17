import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart' show BarcodeCapture, BarcodeFormat, MobileScanner, MobileScannerController;

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../state/messenger_controller.dart';
import '../../state/messenger_providers.dart';
import '../../state/providers.dart';
import 'messenger_common.dart';

/// Where an invite link or QR code lands. With a [code] it shows the group and a Join button.
/// Without one it asks for a pasted link, or scans a QR code where the device has a camera.
class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key, this.code});

  final String? code;

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final TextEditingController _link = TextEditingController();
  String? _problem;
  bool _scanning = false;
  bool _joining = false;

  bool get _canScan =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  void _openCode(String code) {
    context.go('/messages/join/${Uri.encodeComponent(code)}');
  }

  void _submit(String text) {
    final code = inviteCodeFrom(text);
    if (code == null) {
      setState(() => _problem = 'That does not look like a Premisave group link.');
      return;
    }
    _openCode(code);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.trim().isEmpty) {
      if (mounted) showToast(context, 'Nothing to paste.', error: true);
      return;
    }
    _link.text = text.trim();
    _submit(text);
  }

  Future<void> _join(String code) async {
    setState(() => _joining = true);
    try {
      final result = await ref.read(messengerRepositoryProvider).joinWithInvite(code);
      await ref.read(messengerProvider.notifier).refreshChats();
      if (!mounted) return;
      showToast(context, result.alreadyMember ? 'You are already in ${result.name}' : 'You joined ${result.name}');
      context.go('/messages/chat/${Uri.encodeComponent(result.chatId)}');
    } catch (e) {
      if (mounted) {
        setState(() => _joining = false);
        showApiError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.code;
    return SubPage(
      title: code == null ? 'Join a group' : 'Group invite',
      fallbackRoute: '/messages',
      body: code == null ? _entry(context) : _preview(context, code),
    );
  }

  // --------------------------------------------------------------- entering

  Widget _entry(BuildContext context) {
    if (_scanning) {
      return _Scanner(
        onCode: (raw) {
          final code = inviteCodeFrom(raw);
          if (code == null) return false;
          _openCode(code);
          return true;
        },
        onClose: () => setState(() => _scanning = false),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(shape: BoxShape.circle, color: context.pal.accentSoft),
            child: Icon(Icons.qr_code_2_rounded, size: 44, color: context.pal.accent),
          ),
        ),
        const SizedBox(height: 18),
        Text('Join with an invite', textAlign: TextAlign.center, style: context.display(size: 22, weight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Paste a group link, or scan the QR code an admin shared with you.', textAlign: TextAlign.center, style: TextStyle(color: context.mutedColor, height: 1.45)),
        const SizedBox(height: 22),
        if (_canScan) ...<Widget>[
          PButton(label: 'Scan a QR code', icon: Icons.qr_code_scanner_rounded, expand: true, onPressed: () => setState(() => _scanning = true)),
          const SizedBox(height: 18),
          Row(children: <Widget>[
            Expanded(child: Divider(color: context.borderColor)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(color: context.mutedColor))),
            Expanded(child: Divider(color: context.borderColor)),
          ]),
          const SizedBox(height: 18),
        ],
        PTextField(
          label: 'Invite link or code',
          controller: _link,
          hint: 'https://premisave.com/join/...',
          errorText: _problem,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onChanged: (_) {
            if (_problem != null) setState(() => _problem = null);
          },
          onSubmitted: _submit,
          suffix: IconButton(tooltip: 'Paste', icon: const Icon(Icons.content_paste_rounded), onPressed: _paste),
        ),
        const SizedBox(height: 16),
        PButton(label: 'Continue', expand: true, kind: _canScan ? PButtonKind.outline : PButtonKind.primary, onPressed: () => _submit(_link.text)),
        if (!_canScan) ...<Widget>[
          const SizedBox(height: 14),
          Text('Scanning needs a phone or tablet camera. On this device, open the link or paste it above.', textAlign: TextAlign.center, style: TextStyle(color: context.mutedColor, fontSize: 13, height: 1.4)),
        ],
      ],
    );
  }

  // -------------------------------------------------------------- previewing

  Widget _preview(BuildContext context, String code) {
    final value = ref.watch(invitePreviewProvider(code));
    return value.when(
      loading: () => const LoadingState(label: 'Checking the invite'),
      error: (e, _) => _Dead(error: e, onTryAnother: () => context.go('/messages/join')),
      data: (p) => ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const SizedBox(height: 12),
          Center(child: MessengerAvatar(initials: p.name.isEmpty ? 'G' : p.name[0].toUpperCase(), imageUrl: p.groupPhotoUrl, size: 110, group: true)),
          const SizedBox(height: 16),
          Text(p.name, textAlign: TextAlign.center, style: context.display(size: 24, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${p.memberCount} ${p.memberCount == 1 ? 'member' : 'members'}', textAlign: TextAlign.center, style: TextStyle(color: context.mutedColor)),
          if (p.description.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            Text(p.description, textAlign: TextAlign.center, style: const TextStyle(height: 1.45)),
          ],
          if (p.expiresAt != null) ...<Widget>[
            const SizedBox(height: 10),
            Text('This invite works until ${formatDateTime(p.expiresAt)}.', textAlign: TextAlign.center, style: TextStyle(color: context.mutedColor, fontSize: 13)),
          ],
          const SizedBox(height: 26),
          if (p.alreadyMember)
            PButton(
              label: 'Open chat',
              icon: Icons.chat_bubble_outline_rounded,
              expand: true,
              onPressed: p.chatId == null ? () => context.go('/messages') : () => context.go('/messages/chat/${Uri.encodeComponent(p.chatId ?? '')}'),
            )
          else
            PButton(label: 'Join group', icon: Icons.login_rounded, expand: true, loading: _joining, onPressed: () => _join(code)),
          const SizedBox(height: 8),
          PButton(label: 'Not now', kind: PButtonKind.text, expand: true, onPressed: () => context.go('/messages')),
        ],
      ),
    );
  }
}

class _Dead extends StatelessWidget {
  const _Dead({required this.error, required this.onTryAnother});

  final Object error;
  final VoidCallback onTryAnother;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.link_off_rounded,
      title: 'This invite does not work',
      message: ApiException.from(error).message,
      actionLabel: 'Try another link',
      onAction: onTryAnother,
    );
  }
}

/// A camera view that hands back the first QR code it can read. [onCode] returns true once it took the code.
class _Scanner extends StatefulWidget {
  const _Scanner({required this.onCode, required this.onClose});

  final bool Function(String raw) onCode;
  final VoidCallback onClose;

  @override
  State<_Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<_Scanner> {
  final MobileScannerController _controller = MobileScannerController(formats: const <BarcodeFormat>[BarcodeFormat.qrCode]);
  bool _done = false;
  bool _wrong = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _detect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null || raw.isEmpty) continue;
      if (widget.onCode(raw)) {
        _done = true;
        return;
      }
      if (!_wrong) setState(() => _wrong = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(child: MobileScanner(controller: _controller, onDetect: _detect)),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(24)),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 28,
          child: SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.black.op(0.6), borderRadius: BorderRadius.circular(99)),
                child: Text(
                  _wrong ? 'That QR code is not a Premisave group invite.' : 'Point the camera at the group QR code',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 14),
              PButton(label: 'Paste a link instead', kind: PButtonKind.accent, onPressed: widget.onClose),
            ]),
          ),
        ),
      ],
    );
  }
}
