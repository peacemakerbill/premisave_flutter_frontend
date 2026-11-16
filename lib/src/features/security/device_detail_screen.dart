import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/security_models.dart';
import '../../state/data_providers.dart';
import '../../state/providers.dart';
import 'security_widgets.dart';
import 'sign_in_history_screen.dart';

class DeviceDetailScreen extends ConsumerStatefulWidget {
  const DeviceDetailScreen({super.key, required this.deviceId});

  final String deviceId;

  @override
  ConsumerState<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  bool _busy = false;

  void _reload() {
    ref.invalidate(deviceDetailProvider(widget.deviceId));
    ref.invalidate(devicesProvider);
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      _reload();
      if (mounted) showToast(context, done);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _trust() async {
    final password = await promptDialog(
      context,
      title: 'Trust this device',
      message: 'Enter your password to confirm this device belongs to you.',
      label: 'Current password',
      confirmLabel: 'Trust device',
      required: true,
      multiline: false,
      obscure: true,
    );
    if (password == null) return;
    await _run(() => ref.read(securityRepositoryProvider).trustDevice(widget.deviceId, password), 'Device trusted');
  }

  Future<void> _untrust() => _run(() => ref.read(securityRepositoryProvider).revokeTrust(widget.deviceId), 'Trust removed');

  Future<void> _revokeCredential() async {
    final ok = await confirmDialog(
      context,
      title: 'Forget this device?',
      message: 'Its remembered-device credential is cancelled, so the next sign-in from it is treated as a new device.',
      confirmLabel: 'Forget device',
      danger: true,
    );
    if (ok) await _run(() => ref.read(securityRepositoryProvider).revokeCredential(widget.deviceId), 'Device credential revoked');
  }

  Future<void> _remove() async {
    final ok = await confirmDialog(
      context,
      title: 'Remove this device?',
      message: 'It disappears from your list and its sessions end.',
      confirmLabel: 'Remove',
      danger: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref.read(securityRepositoryProvider).removeDevice(widget.deviceId);
      ref.invalidate(devicesProvider);
      ref.invalidate(sessionsProvider);
      if (!mounted) return;
      showToast(context, 'Device removed');
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/account/security/devices');
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(deviceDetailProvider(widget.deviceId));
    return SubPage(
      title: 'Device',
      fallbackRoute: '/account/security/devices',
      body: AsyncBody<DeviceDetail>(
        value: detail,
        onRetry: _reload,
        builder: (data) {
          final d = data.device;
          return PageBody(
            maxWidth: 760,
            onRefresh: () async => _reload(),
            children: <Widget>[
              PCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(color: Brand.info.op(0.12), borderRadius: BorderRadius.circular(14)),
                          child: Icon(deviceIcon(d.label, d.deviceType), color: Brand.info, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(d.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                children: <Widget>[
                                  if (d.current) const StatusPill('This device', color: Brand.success, dense: true),
                                  StatusPill(d.trusted ? 'Trusted' : 'Not trusted', color: d.trusted ? Brand.info : Brand.muted, dense: true),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    InfoRow('System', <String>[if (d.os != null) d.os!, if (d.browser != null) d.browser!].join(' · ')),
                    InfoRow('Last place', d.place),
                    InfoRow('Last IP', d.lastIp),
                    InfoRow('First seen', formatDateTime(d.firstSeenAt)),
                    InfoRow('Last seen', formatDateTime(d.lastSeenAt)),
                    InfoRow('Sign-ins', '${d.signInCount}'),
                    InfoRow('Active sessions', '${d.activeSessions}'),
                    if (d.trustedAt != null) InfoRow('Trusted on', formatDateTime(d.trustedAt)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (d.trusted)
                PButton(label: 'Remove trust', icon: Icons.remove_moderator_outlined, kind: PButtonKind.outline, expand: true, loading: _busy, onPressed: _busy ? null : _untrust)
              else
                PButton(label: 'Trust this device', icon: Icons.verified_user_outlined, expand: true, loading: _busy, onPressed: _busy ? null : _trust),
              const SizedBox(height: 10),
              PButton(label: 'Forget remembered credential', icon: Icons.key_off_outlined, kind: PButtonKind.outline, expand: true, onPressed: _busy ? null : _revokeCredential),
              const SizedBox(height: 10),
              PButton(label: 'Remove device', icon: Icons.delete_outline_rounded, kind: PButtonKind.danger, expand: true, onPressed: _busy ? null : _remove),
              const SectionHeader('Recent sign-ins'),
              if (data.recentSignIns.isEmpty)
                Text('No sign-ins recorded.', style: TextStyle(color: context.mutedColor))
              else
                MenuGroup(children: <Widget>[for (final s in data.recentSignIns) SignInTile(signIn: s)]),
            ],
          );
        },
      ),
    );
  }
}
