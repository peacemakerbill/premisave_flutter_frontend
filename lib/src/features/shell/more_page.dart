import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import '../../roles/permissions.dart';
import '../../roles/role_registry.dart';
import '../../state/messenger_controller.dart';
import '../../state/session_controller.dart';
import 'nav.dart';

/// The More tab on a phone: every section that did not fit in the bottom bar, then the tools and information pages.
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(sessionProvider).role;
    final unread = ref.watch(messengerUnreadProvider);
    final overflow = overflowFor(role);

    return PageBody(
      maxWidth: 720,
      children: <Widget>[
        const PageTitle('More', subtitle: 'Every part of Premisave in one place.'),
        const SizedBox(height: 8),
        if (overflow.isNotEmpty) ...<Widget>[
          const SectionHeader('Sections'),
          MenuGroup(
            children: <Widget>[
              for (final d in overflow)
                MenuTile(
                  icon: d.icon,
                  title: d.label,
                  badge: d.path == '/messages' && unread > 0 ? (unread > 99 ? '99+' : '$unread') : null,
                  onTap: () => context.go(d.path),
                ),
            ],
          ),
        ],
        const SectionHeader('Tools'),
        MenuGroup(
          children: <Widget>[
            if (role.can(Capability.useClientWorkspace))
              MenuTile(icon: Icons.key_rounded, title: 'My tenancy', subtitle: 'Rent, leases, notices and maintenance', onTap: () => context.go('/tenancy')),
            if (role.can(Capability.lookupAccounts))
              MenuTile(icon: Icons.verified_user_outlined, title: 'M-Pesa name lookup', subtitle: 'Check who an M-Pesa number belongs to', onTap: () => context.go('/lookup')),
            MenuTile(icon: Icons.code_rounded, title: 'Developer portal', subtitle: 'Apps, API keys, businesses and transfers', onTap: () => context.go('/developers')),
          ],
        ),
        const SectionHeader('Information'),
        MenuGroup(
          children: <Widget>[
            MenuTile(icon: Icons.info_outline_rounded, title: 'About Premisave', onTap: () => context.push('/home/about')),
            MenuTile(icon: Icons.support_agent_outlined, title: 'Contact us', onTap: () => context.push('/home/contact')),
          ],
        ),
      ],
    );
  }
}
