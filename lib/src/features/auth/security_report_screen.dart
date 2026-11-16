import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/security_models.dart';
import '../../state/providers.dart';
import 'auth_scaffold.dart';

/// Opened from a "new sign-in" email: shows what happened, then lets the owner say
/// "this was not me". Looking does not use up the link; confirming does.
class SecurityReportScreen extends ConsumerStatefulWidget {
  const SecurityReportScreen({super.key, this.token});

  final String? token;

  @override
  ConsumerState<SecurityReportScreen> createState() => _SecurityReportScreenState();
}

class _SecurityReportScreenState extends ConsumerState<SecurityReportScreen> {
  ReportPreview? _preview;
  ReportResult? _result;
  String? _error;
  bool _loading = true;
  bool _busy = false;
  bool _resetPassword = true;

  @override
  void initState() {
    super.initState();
    final t = widget.token;
    if (t == null || t.isEmpty) {
      _loading = false;
      _error = 'This page needs the link from your security email.';
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _inspect(t));
    }
  }

  Future<void> _inspect(String token) async {
    try {
      final p = await ref.read(authRepositoryProvider).inspectReport(token);
      if (mounted) setState(() => _preview = p);
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      final r = await ref.read(authRepositoryProvider).confirmReport(widget.token!, requestPasswordReset: _resetPassword);
      if (mounted) setState(() => _result = r);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: LoadingState());
    } else if (_error != null) {
      body = AuthResultView(
        success: false,
        icon: Icons.link_off_rounded,
        title: 'This link is not valid',
        message: _error!,
        actions: <Widget>[PButton(label: 'Back to sign in', expand: true, onPressed: () => context.go('/login'))],
      );
    } else if (_result != null) {
      final r = _result!;
      body = AuthResultView(
        icon: Icons.shield_rounded,
        title: 'Thank you for telling us',
        message: r.message.isEmpty ? 'We ended that session and removed its device trust.' : r.message,
        actions: <Widget>[
          if (r.passwordResetEmailSent)
            const InlineMessage('We emailed you a link to choose a new password.', kind: MessageKind.success),
          PButton(label: 'Go to sign in', expand: true, onPressed: () => context.go('/login')),
        ],
      );
    } else {
      final p = _preview!;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PCard(
            child: Column(
              children: <Widget>[
                InfoRow('When', formatDateTime(p.signedInAt), icon: Icons.schedule_rounded),
                InfoRow('Device', p.device, icon: Icons.devices_rounded),
                InfoRow('Place', p.approximateLocation, icon: Icons.place_outlined),
                InfoRow('IP address', p.maskedIp, icon: Icons.router_outlined),
                InfoRow('Method', sentence(p.method), icon: Icons.login_rounded),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (!p.sessionStillActive) const InlineMessage('That session has already ended.'),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() => _resetPassword = !_resetPassword),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: <Widget>[
                Checkbox(value: _resetPassword, onChanged: (v) => setState(() => _resetPassword = v ?? false)),
                Expanded(child: Text('Also email me a link to reset my password', style: TextStyle(color: context.inkColor))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PButton(label: 'This was not me', kind: PButtonKind.danger, icon: Icons.gpp_bad_outlined, expand: true, loading: _busy, onPressed: _busy ? null : _confirm),
          const SizedBox(height: 10),
          PButton(label: 'That was me', kind: PButtonKind.outline, expand: true, onPressed: () => context.go('/login')),
        ],
      );
    }

    return AuthScaffold(
      title: 'Was this you?',
      subtitle: 'We noticed a sign-in to your account.',
      child: body,
    );
  }
}
