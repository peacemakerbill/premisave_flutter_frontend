import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart' show QrImageView;

import '../../core/config/app_config.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/messenger_models.dart';
import '../../state/messenger_providers.dart';
import '../../state/providers.dart';

/// For group admins: make, share and revoke the group's invite link and QR code.
class GroupInviteScreen extends ConsumerStatefulWidget {
  const GroupInviteScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupInviteScreen> createState() => _GroupInviteScreenState();
}

class _GroupInviteScreenState extends ConsumerState<GroupInviteScreen> {
  // Hours until the link stops working. Zero means it never expires.
  int _hours = 168;
  // Most people who may join with it. Zero means no limit.
  int _uses = 0;
  bool _busy = false;

  static const List<(int, String)> _expiry = <(int, String)>[
    (1, '1 hour'),
    (24, '1 day'),
    (168, '7 days'),
    (720, '30 days'),
    (0, 'Never'),
  ];
  static const List<(int, String)> _limits = <(int, String)>[
    (0, 'No limit'),
    (1, '1 person'),
    (5, '5 people'),
    (10, '10 people'),
    (50, '50 people'),
  ];

  String _linkOf(MInvite invite) {
    if (invite.link.trim().isNotEmpty) return invite.link.trim();
    final base = AppConfig.inviteBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/${invite.code}';
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      await ref.read(messengerRepositoryProvider).createInvite(
            widget.groupId,
            expiresInHours: _hours == 0 ? null : _hours,
            maxUses: _uses == 0 ? null : _uses,
          );
      ref.invalidate(groupInviteProvider(widget.groupId));
      if (mounted) showToast(context, 'New invite link ready');
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke() async {
    final ok = await confirmDialog(
      context,
      title: 'Revoke this link?',
      message: 'Anyone who has it, or its QR code, will no longer be able to join. People already in the group stay.',
      confirmLabel: 'Revoke',
      danger: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref.read(messengerRepositoryProvider).revokeInvite(widget.groupId);
      ref.invalidate(groupInviteProvider(widget.groupId));
      if (mounted) showToast(context, 'Link revoked');
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) showToast(context, 'Link copied');
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupDetailsProvider(widget.groupId)).valueOrNull;
    final invite = ref.watch(groupInviteProvider(widget.groupId));

    return SubPage(
      title: 'Invite link',
      fallbackRoute: '/messages',
      body: AsyncBody<MInvite?>(
        value: invite,
        onRetry: () => ref.invalidate(groupInviteProvider(widget.groupId)),
        builder: (inv) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: <Widget>[
            if (group != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(group.name, style: context.display(size: 20, weight: FontWeight.w800)),
              ),
            if (inv != null) _current(context, inv) else _none(context),
            const SizedBox(height: 22),
            Text(inv == null ? 'Create a link' : 'Make a new link', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              inv == null ? 'Choose how long it works and how many people can use it.' : 'A new link replaces the one above, which stops working.',
              style: TextStyle(color: context.mutedColor, height: 1.4),
            ),
            const SizedBox(height: 14),
            PSelectField<int>(
              label: 'Expires after',
              value: _hours,
              options: <PChoice<int>>[for (final e in _expiry) PChoice<int>(e.$1, e.$2)],
              onChanged: (v) => setState(() => _hours = v ?? _hours),
            ),
            const SizedBox(height: 12),
            PSelectField<int>(
              label: 'Who can use it',
              value: _uses,
              options: <PChoice<int>>[for (final e in _limits) PChoice<int>(e.$1, e.$2)],
              onChanged: (v) => setState(() => _uses = v ?? _uses),
            ),
            const SizedBox(height: 18),
            PButton(
              label: inv == null ? 'Create link' : 'Create new link',
              icon: Icons.add_link_rounded,
              expand: true,
              loading: _busy,
              onPressed: _create,
            ),
          ],
        ),
      ),
    );
  }

  Widget _none(BuildContext context) {
    return PCard(
      child: Row(children: <Widget>[
        Icon(Icons.link_off_rounded, color: context.mutedColor),
        const SizedBox(width: 12),
        Expanded(child: Text('There is no working link. It may be new, revoked, expired or used up.', style: TextStyle(color: context.mutedColor, height: 1.4))),
      ]),
    );
  }

  Widget _current(BuildContext context, MInvite inv) {
    final link = _linkOf(inv);
    final pal = context.pal;
    final limit = inv.maxUses == null ? '${inv.uses} joined' : '${inv.uses} of ${inv.maxUses} used';
    final expiry = inv.expiresAt == null ? 'Never expires' : 'Expires ${formatDateTime(inv.expiresAt!)}';
    return PCard(
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(context.radius(16)), border: Border.all(color: pal.line)),
            child: QrImageView(data: link, size: 220, backgroundColor: Colors.white),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: pal.panel2, borderRadius: BorderRadius.circular(context.radius(12))),
            child: SelectableText(link, style: const TextStyle(fontSize: 13.5, height: 1.3)),
          ),
          const SizedBox(height: 10),
          Text('$expiry. $limit.', textAlign: TextAlign.center, style: TextStyle(color: context.mutedColor, fontSize: 13)),
          const SizedBox(height: 14),
          Row(children: <Widget>[
            Expanded(child: PButton(label: 'Copy link', icon: Icons.copy_rounded, kind: PButtonKind.accent, onPressed: () => _copy(link))),
            const SizedBox(width: 10),
            Expanded(child: PButton(label: 'Revoke', icon: Icons.link_off_rounded, kind: PButtonKind.outline, onPressed: _busy ? null : _revoke)),
          ]),
          const SizedBox(height: 4),
          Text('Anyone with this link or QR code can join. Share it only with people you trust.', textAlign: TextAlign.center, style: TextStyle(color: context.mutedColor, fontSize: 12.5, height: 1.4)),
        ],
      ),
    );
  }
}
