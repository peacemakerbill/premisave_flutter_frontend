import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/security_models.dart';
import '../../state/data_providers.dart';
import '../../state/providers.dart';
import 'security_widgets.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  bool _busy = false;

  Future<void> _end(SessionView s) async {
    final ok = await confirmDialog(
      context,
      title: 'End this session?',
      message: '${s.deviceLabel} will be signed out.',
      confirmLabel: 'End session',
      danger: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      final r = await ref.read(securityRepositoryProvider).endSession(s.id);
      ref.invalidate(sessionsProvider);
      if (mounted) showToast(context, r.message.isEmpty ? 'Session ended' : r.message);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _endOthers() async {
    final ok = await confirmDialog(
      context,
      title: 'Sign out everywhere else?',
      message: 'Every other session will end. This device stays signed in.',
      confirmLabel: 'Sign them out',
      danger: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      final r = await ref.read(securityRepositoryProvider).endOtherSessions();
      ref.invalidate(sessionsProvider);
      if (mounted) showToast(context, r.message.isEmpty ? 'Other sessions ended' : r.message);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider);
    return SubPage(
      title: 'Active sessions',
      fallbackRoute: '/account/security',
      body: AsyncBody<List<SessionView>>(
        value: sessions,
        onRetry: () => ref.invalidate(sessionsProvider),
        builder: (items) {
          final others = items.where((s) => !s.current).length;
          return PageBody(
            maxWidth: 760,
            onRefresh: () async => ref.invalidate(sessionsProvider),
            children: <Widget>[
              if (items.isEmpty)
                const SizedBox(height: 300, child: EmptyState(icon: Icons.login_rounded, title: 'No active sessions'))
              else
                for (final s in items) ...<Widget>[
                  _SessionCard(session: s, busy: _busy, onEnd: () => _end(s)),
                  const SizedBox(height: 10),
                ],
              if (others > 0) ...<Widget>[
                const SizedBox(height: 10),
                PButton(
                  label: 'Sign out of $others other ${others == 1 ? 'session' : 'sessions'}',
                  icon: Icons.logout_rounded,
                  kind: PButtonKind.danger,
                  expand: true,
                  loading: _busy,
                  onPressed: _busy ? null : _endOthers,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.busy, required this.onEnd});

  final SessionView session;
  final bool busy;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final s = session;
    return PCard(
      borderColor: s.current ? Brand.success.op(0.55) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: (s.current ? Brand.success : Brand.info).op(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(deviceIcon(s.deviceLabel), color: s.current ? Brand.success : Brand.info),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(child: Text(s.deviceLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                    if (s.current) ...<Widget>[const SizedBox(width: 8), const StatusPill('This device', color: Brand.success, dense: true)],
                  ],
                ),
                const SizedBox(height: 4),
                Text(s.place, style: TextStyle(fontSize: 13, color: context.mutedColor)),
                if (s.ipAddress != null) Text(s.ipAddress!, style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                const SizedBox(height: 4),
                Text(
                  'Signed in ${formatDateTime(s.createdAt)}${s.method != null ? ' with ${sentence(s.method).toLowerCase()}' : ''}',
                  style: TextStyle(fontSize: 12.5, color: context.mutedColor),
                ),
                Text('Last active ${timeAgo(s.lastSeenAt)}', style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
              ],
            ),
          ),
          if (!s.current)
            IconButton(
              tooltip: 'End session',
              icon: const Icon(Icons.logout_rounded, color: Brand.danger),
              onPressed: busy ? null : onEnd,
            ),
        ],
      ),
    );
  }
}
