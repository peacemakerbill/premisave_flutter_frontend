import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../state/data_providers.dart';
import '../security/security_widgets.dart';

const List<String> _types = <String>[
  'SIGN_IN_SUCCEEDED',
  'SIGN_IN_FAILED',
  'SIGN_OUT',
  'NEW_DEVICE_SIGN_IN',
  'PASSWORD_CHANGED',
  'PASSWORD_RESET_REQUESTED',
  'ACCOUNT_LOCKED',
  'SESSION_REVOKED',
];

/// Administrators: the account activity trail across the platform, optionally for one user.
class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key, this.userId});

  /// Pre-filters to one account. The router fills this from `?userId=`.
  final String? userId;

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  String? _type;

  AuditFilter get _filter => AuditFilter(type: _type, userId: widget.userId);

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(auditEventsProvider(_filter));
    return SubPage(
      title: widget.userId == null ? 'Audit trail' : 'User activity',
      fallbackRoute: '/admin/users',
      body: PageBody(
        maxWidth: 820,
        onRefresh: () async {
          ref.invalidate(auditEventsProvider(_filter));
          await ref.read(auditEventsProvider(_filter).future);
        },
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(label: const Text('All events'), selected: _type == null, onSelected: (_) => setState(() => _type = null)),
                ),
                for (final t in _types)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(sentence(t)),
                      selected: _type == t,
                      onSelected: (v) => setState(() => _type = v ? t : null),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          value.when(
            loading: () => const SkeletonList(kind: SkeletonKind.row, count: 6, shrink: true, padding: EdgeInsets.symmetric(vertical: 8)),
            error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(auditEventsProvider(_filter))),
            data: (items) {
              if (items.isEmpty) {
                return EmptyState(
                  icon: Icons.list_alt_rounded,
                  title: 'Nothing recorded',
                  message: 'No events match this filter.',
                  actionLabel: _type == null ? null : 'Show all events',
                  onAction: _type == null ? null : () => setState(() => _type = null),
                );
              }
              return MenuGroup(
                children: <Widget>[
                  for (final e in items)
                    MenuTile(
                      icon: eventIcon(e.type),
                      tint: severityColor(e.severity),
                      title: e.title,
                      subtitle: <String>[
                        whenLabel(e.createdAt),
                        if (e.subject != null) e.subject!,
                        if (e.ipAddress != null) e.ipAddress!,
                        if (e.reason != null) e.reason!,
                      ].join(' · '),
                      trailing: e.isCritical
                          ? const StatusPill('Critical', dense: true, color: Brand.danger)
                          : (e.isWarning ? const StatusPill('Warning', dense: true, color: Brand.warning) : const SizedBox.shrink()),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
