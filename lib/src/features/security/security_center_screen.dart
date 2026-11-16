import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/security_models.dart';
import '../../state/data_providers.dart';
import 'security_widgets.dart';

class SecurityCenterScreen extends ConsumerWidget {
  const SecurityCenterScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(sessionsProvider);
    ref.invalidate(devicesProvider);
    ref.invalidate(securityEventsProvider);
    try {
      await ref.read(sessionsProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    final devices = ref.watch(devicesProvider);
    final events = ref.watch(securityEventsProvider);

    final sessionCount = sessions.valueOrNull?.length;
    final deviceList = devices.valueOrNull;
    final trusted = deviceList?.where((d) => d.trusted).length;
    final List<SecurityEventView> recent = events.valueOrNull?.take(5).toList() ?? <SecurityEventView>[];
    final warnings = (events.valueOrNull ?? <SecurityEventView>[]).where((e) => e.isWarning || e.isCritical).length;

    return SubPage(
      title: 'Security center',
      fallbackRoute: '/account',
      body: PageBody(
        onRefresh: () => _refresh(ref),
        maxWidth: 820,
        children: <Widget>[
          HeroPanel(
            child: Row(
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: Brand.gold.op(0.18), borderRadius: BorderRadius.circular(15)),
                  child: Icon(warnings == 0 ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded, color: Brand.gold, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        warnings == 0 ? 'Nothing unusual' : '${plural(warnings, 'alert')} to review',
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You are alerted when a new device signs in, and you can end any session at any time.',
                        style: TextStyle(fontSize: 13, height: 1.4, color: Brand.cream.op(0.75)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ResponsiveWrap(
            minItemWidth: 150,
            children: <Widget>[
              StatTile(label: 'Active sessions', value: sessionCount?.toString() ?? '-', icon: Icons.login_rounded, onTap: () => context.push('/account/security/sessions')),
              StatTile(
                label: 'Known devices',
                value: deviceList?.length.toString() ?? '-',
                caption: trusted == null ? null : '$trusted trusted',
                icon: Icons.devices_rounded,
                tint: Brand.info,
                onTap: () => context.push('/account/security/devices'),
              ),
            ],
          ),
          const SectionHeader('Manage'),
          MenuGroup(
            children: <Widget>[
              MenuTile(icon: Icons.login_rounded, title: 'Active sessions', subtitle: 'Where you are signed in right now', onTap: () => context.push('/account/security/sessions')),
              MenuTile(icon: Icons.devices_rounded, title: 'Devices', subtitle: 'Trust or remove devices', onTap: () => context.push('/account/security/devices')),
              MenuTile(icon: Icons.history_rounded, title: 'Sign-in history', subtitle: 'Your last 30 sign-ins', onTap: () => context.push('/account/security/history')),
              MenuTile(icon: Icons.list_alt_rounded, title: 'Security events', subtitle: 'Everything that affected your account', onTap: () => context.push('/account/security/events')),
              MenuTile(icon: Icons.password_rounded, title: 'Change password', onTap: () => context.push('/account/password')),
            ],
          ),
          SectionHeader('Recent activity', action: recent.isEmpty ? null : 'See all', onAction: () => context.push('/account/security/events')),
          events.when(
            loading: () => const SizedBox(height: 100, child: LoadingState()),
            error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(securityEventsProvider)),
            data: (_) => recent.isEmpty
                ? Text('No activity yet.', style: TextStyle(color: context.mutedColor))
                : MenuGroup(
                    children: <Widget>[
                      for (final e in recent)
                        MenuTile(
                          icon: eventIcon(e.type),
                          tint: severityColor(e.severity),
                          title: e.title,
                          subtitle: <String>[timeAgo(e.createdAt), if (e.reason != null) e.reason!].join(' · '),
                          trailing: const SizedBox.shrink(),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
