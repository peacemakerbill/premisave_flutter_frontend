import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/security_models.dart';
import '../../state/data_providers.dart';
import 'security_widgets.dart';

/// Everything the backend recorded about your account.
class SecurityEventsScreen extends ConsumerWidget {
  const SecurityEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(securityEventsProvider);
    return SubPage(
      title: 'Security events',
      fallbackRoute: '/account/security',
      body: AsyncBody<List<SecurityEventView>>(
        value: value,
        onRetry: () => ref.invalidate(securityEventsProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.list_alt_rounded,
              title: 'No events yet',
              message: 'Sign-ins, password changes and other account activity will be listed here.',
            );
          }
          return PageBody(
            maxWidth: 760,
            onRefresh: () async => ref.invalidate(securityEventsProvider),
            children: <Widget>[
              MenuGroup(
                children: <Widget>[
                  for (final e in items)
                    MenuTile(
                      icon: eventIcon(e.type),
                      tint: severityColor(e.severity),
                      title: e.title,
                      subtitle: <String>[
                        whenLabel(e.createdAt),
                        if (e.ipAddress != null) e.ipAddress!,
                        if (e.reason != null) e.reason!,
                      ].join(' · '),
                      trailing: const SizedBox.shrink(),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
