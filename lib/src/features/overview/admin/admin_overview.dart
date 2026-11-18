import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand.dart';
import '../../../core/theme/palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/application_models.dart';
import '../../../data/models/call_models.dart';
import '../../../data/models/security_models.dart';
import '../../../data/models/storage_models.dart';
import '../../../data/models/user_model.dart';
import '../../../roles/role.dart';
import '../../../state/call_providers.dart';
import '../../../state/data_providers.dart';
import '../../../state/session_controller.dart';
import '../../../state/storage_providers.dart';
import '../../admin/audit_summary.dart';
import '../../security/security_widgets.dart';
import '../shared/overview_widgets.dart';

/// The administrator's overview, built from live data: who is on the platform, where applications stand, what happened
/// in the last day, and whether the places files are kept are working. Each part loads on its own, so one service being
/// down does not hide the rest.
class AdminOverview extends ConsumerWidget {
  const AdminOverview({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(adminUsersProvider);
    ref.invalidate(staffStatsProvider);
    ref.invalidate(auditSummaryProvider(24));
    ref.invalidate(auditRecentProvider);
    ref.invalidate(documentStorageProvider);
    ref.invalidate(storageSettingsProvider);
    ref.invalidate(callSettingsProvider);
    await Future.wait<Object?>(<Future<Object?>>[
      ref.read(adminUsersProvider.future).then<Object?>((v) => v, onError: (_) => null),
      ref.read(staffStatsProvider.future).then<Object?>((v) => v, onError: (_) => null),
      ref.read(auditSummaryProvider(24).future).then<Object?>((v) => v, onError: (_) => null),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    final users = ref.watch(adminUsersProvider);
    final apps = ref.watch(staffStatsProvider);
    final sec = ref.watch(auditSummaryProvider(24));
    final docs = ref.watch(documentStorageProvider);
    final chat = ref.watch(storageSettingsProvider);
    final calls = ref.watch(callSettingsProvider);

    return PageBody(
      bottomPadding: 48,
      onRefresh: () => _refresh(ref),
      children: <Widget>[
        OverviewHero(
          role: Role.admin,
          user: user,
          message: 'People, applications, security and storage across the platform.',
          metrics: <OverviewMetric>[
            OverviewMetric('People', _figure(users, (List<UserModel> l) => '${l.length}'),
                _figure(users, (List<UserModel> l) => '${l.where((u) => u.active && !u.archived).length} active')),
            OverviewMetric('Awaiting review', _figure(apps, (StaffStats s) => '${s.awaitingReview}'), 'applications'),
            OverviewMetric('Events', _figure(sec, (AuditSummary s) => '${s.total}'), 'last 24 hours'),
            OverviewMetric('Failed sign ins', _figure(sec, (AuditSummary s) => '${s.failedSignIns}'), 'last 24 hours'),
          ],
          actions: <Widget>[
            HeroAction(label: 'Users', icon: Icons.people_alt_outlined, onPressed: () => context.go('/admin/users')),
            HeroAction(label: 'Applications', icon: Icons.assignment_outlined, filled: false, onPressed: () => context.go('/staff')),
            HeroAction(label: 'Audit trail', icon: Icons.fact_check_outlined, filled: false, onPressed: () => context.push('/admin/audit')),
          ],
        ),
        OverviewBlock(
          title: 'Needs your attention',
          child: _Attention(users: users, apps: apps, sec: sec, docs: docs, chat: chat),
        ),
        OverviewColumns(
          left: OverviewBlock(title: 'People', child: _People(users: users, onRetry: () => ref.invalidate(adminUsersProvider))),
          right: OverviewBlock(
            title: 'Applications',
            subtitle: 'Home Owner applications by status',
            child: _Applications(apps: apps, onRetry: () => ref.invalidate(staffStatsProvider)),
          ),
        ),
        const OverviewBlock(
          title: 'Security',
          subtitle: 'What happened in the last 24 hours',
          child: AuditSummaryStrip(),
        ),
        OverviewColumns(
          left: OverviewBlock(title: 'Recent activity', child: const _Recent()),
          right: OverviewBlock(
            title: 'Storage and calls',
            subtitle: 'Where files are kept',
            child: _Systems(docs: docs, chat: chat, calls: calls),
          ),
        ),
      ],
    );
  }

  /// A figure for the hero: the value when it is loaded, a dash while it loads or when it could not be read.
  static String _figure<T>(AsyncValue<T> value, String Function(T) pick) {
    if (value.hasValue) return pick(value.value as T);
    return value.hasError ? '-' : '...';
  }
}

class _Attention extends StatelessWidget {
  const _Attention({required this.users, required this.apps, required this.sec, required this.docs, required this.chat});

  final AsyncValue<List<UserModel>> users;
  final AsyncValue<StaffStats> apps;
  final AsyncValue<AuditSummary> sec;
  final AsyncValue<DocumentStorageSettings> docs;
  final AsyncValue<StorageSettings> chat;

  @override
  Widget build(BuildContext context) {
    final waiting = <AsyncValue<Object?>>[users, apps, sec, docs, chat].any((v) => v.isLoading && !v.hasValue);
    if (waiting) {
      return const SkeletonList(count: 2, height: 84, shrink: true, padding: EdgeInsets.symmetric(vertical: 4));
    }
    final alerts = <OverviewAlert>[];

    final s = sec.valueOrNull;
    if (s != null) {
      if (s.critical > 0) {
        alerts.add(OverviewAlert(
          icon: Icons.gpp_maybe_outlined,
          tone: OverviewTone.bad,
          title: '${plural(s.critical, 'critical security event')} in the last 24 hours',
          detail: 'Open the audit trail and filter by severity to see what happened.',
        ));
      }
      if (s.lockouts > 0) {
        alerts.add(OverviewAlert(
          icon: Icons.lock_outline_rounded,
          tone: OverviewTone.bad,
          title: '${plural(s.lockouts, 'account')} locked after failed sign ins',
          detail: 'Someone may be guessing passwords. Check the addresses in the audit trail.',
        ));
      }
      if (s.failedSignIns >= 10) {
        alerts.add(OverviewAlert(
          icon: Icons.block_rounded,
          tone: OverviewTone.warn,
          title: '${plural(s.failedSignIns, 'failed sign in')} in the last 24 hours',
          detail: 'That is more than usual. Search the audit trail for "failed" to see who and from where.',
        ));
      }
      if (s.warning > 0 && s.critical == 0 && s.lockouts == 0) {
        alerts.add(OverviewAlert(
          icon: Icons.warning_amber_rounded,
          tone: OverviewTone.warn,
          title: '${plural(s.warning, 'warning')} in the last 24 hours',
          detail: 'Staff changes and unusual sign ins are marked as warnings.',
        ));
      }
    }

    final a = apps.valueOrNull;
    if (a != null) {
      if (a.readyToPromote > 0) {
        alerts.add(OverviewAlert(
          icon: Icons.workspace_premium_outlined,
          tone: OverviewTone.accent,
          title: '${plural(a.readyToPromote, 'application')} ready for your decision',
          detail: 'They passed review. Open Applications to make them Home Owners or send them back.',
        ));
      }
      if (a.unassigned > 0) {
        alerts.add(OverviewAlert(
          icon: Icons.person_search_outlined,
          tone: OverviewTone.warn,
          title: '${plural(a.unassigned, 'application')} with no reviewer',
          detail: 'Assign a reviewer so they do not wait.',
        ));
      }
      final since = a.oldestWaitingSince;
      if (since != null && DateTime.now().difference(since.toLocal()).inDays >= 3) {
        alerts.add(OverviewAlert(
          icon: Icons.schedule_rounded,
          tone: OverviewTone.warn,
          title: 'The longest wait is ${timeAgo(since).replaceAll(' ago', '')}',
          detail: 'An application has been waiting for review since ${formatDate(since)}.',
        ));
      }
    }

    final d = docs.valueOrNull?.documents;
    if (d != null && !d.ready) {
      alerts.add(OverviewAlert(
        icon: Icons.folder_off_outlined,
        tone: OverviewTone.bad,
        title: 'Application documents cannot be saved',
        detail: d.problem ?? 'The document storage is not available. Open Settings, Storage.',
      ));
    }
    final m = chat.valueOrNull;
    if (m != null && !m.attachments.ready) {
      alerts.add(OverviewAlert(
        icon: Icons.folder_off_outlined,
        tone: OverviewTone.bad,
        title: 'Chat files cannot be saved',
        detail: m.attachments.problem ?? 'The chat file storage is not available. Open Settings, Storage.',
      ));
    }
    if (m != null && !m.recordings.ready) {
      alerts.add(OverviewAlert(
        icon: Icons.videocam_off_outlined,
        tone: OverviewTone.bad,
        title: 'Call recordings cannot be saved',
        detail: m.recordings.problem ?? 'The recordings storage is not available. Open Settings, Storage.',
      ));
    }

    final list = users.valueOrNull;
    if (list != null) {
      final unverified = list.where((u) => !u.verified && !u.archived).length;
      if (unverified > 0) {
        alerts.add(OverviewAlert(
          icon: Icons.mark_email_unread_outlined,
          tone: OverviewTone.accent,
          title: '${plural(unverified, 'person', 'people')} not verified yet',
          detail: 'They have not confirmed their email address.',
        ));
      }
    }

    final failed = <String>[
      if (users.hasError) 'people',
      if (apps.hasError) 'applications',
      if (sec.hasError) 'security',
      if (docs.hasError) 'document storage',
      if (chat.hasError) 'chat storage',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OverviewAlerts(alerts: alerts, allClearMessage: 'All clear. Nothing needs your attention right now.'),
        if (failed.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Could not read: ${failed.join(', ')}. Pull down to try again.',
              style: TextStyle(fontSize: 12.5, color: context.mutedColor),
            ),
          ),
      ],
    );
  }
}

class _People extends StatelessWidget {
  const _People({required this.users, required this.onRetry});

  final AsyncValue<List<UserModel>> users;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return users.when(
      loading: () => const SkeletonList(kind: SkeletonKind.row, count: 5, shrink: true, padding: EdgeInsets.symmetric(vertical: 4)),
      error: (e, _) => ErrorState(error: e, onRetry: onRetry),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(icon: Icons.people_outline_rounded, title: 'No people yet', message: 'Accounts will be listed here.');
        }
        final counts = <Role, int>{for (final r in Role.values) r: 0};
        for (final u in list) {
          counts[u.role] = (counts[u.role] ?? 0) + 1;
        }
        final active = list.where((u) => u.active && !u.archived).length;
        final off = list.where((u) => !u.active && !u.archived).length;
        final archived = list.where((u) => u.archived).length;
        return OverviewList(
          children: <Widget>[
            for (final r in Role.values)
              if ((counts[r] ?? 0) > 0)
                OverviewRow(
                  leading: const IconBadge(Icons.badge_outlined, size: 42),
                  title: r.label,
                  subtitle: '${(counts[r]! * 100 / list.length).round()}% of everyone',
                  trailing: OverviewTrailing(value: '${counts[r]}'),
                  onTap: () => context.go('/admin/users'),
                ),
            OverviewRow(
              leading: IconBadge(Icons.toggle_on_outlined, size: 42, color: context.pal.good),
              title: 'Status',
              subtitle: '$active active, $off deactivated, $archived archived',
              onTap: () => context.go('/admin/users'),
            ),
          ],
        );
      },
    );
  }
}

class _Applications extends StatelessWidget {
  const _Applications({required this.apps, required this.onRetry});

  final AsyncValue<StaffStats> apps;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return apps.when(
      loading: () => const SkeletonList(kind: SkeletonKind.row, count: 4, shrink: true, padding: EdgeInsets.symmetric(vertical: 4)),
      error: (e, _) => ErrorState(error: e, onRetry: onRetry),
      data: (s) {
        final rows = s.byStatus.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
        if (s.total == 0 || rows.isEmpty) {
          return const EmptyState(
            icon: Icons.assignment_outlined,
            title: 'No applications yet',
            message: 'Home Owner applications will be counted here.',
          );
        }
        return OverviewList(
          children: <Widget>[
            for (final e in rows)
              OverviewRow(
                leading: const IconBadge(Icons.assignment_outlined, size: 42),
                title: sentence(e.key),
                trailing: OverviewTrailing(value: '${e.value}'),
                onTap: () => context.go('/staff'),
              ),
            OverviewRow(
              leading: IconBadge(Icons.hourglass_bottom_rounded, size: 42, color: context.pal.warn),
              title: 'Waiting for review',
              subtitle: s.averageDecisionHours == null
                  ? 'No decisions yet to average'
                  : 'Decisions take about ${waitingLabel(s.averageDecisionHours!.round())} on average',
              trailing: OverviewTrailing(value: '${s.awaitingReview}'),
              onTap: () => context.go('/staff'),
            ),
          ],
        );
      },
    );
  }
}

class _Recent extends ConsumerWidget {
  const _Recent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(auditRecentProvider);
    final pal = context.pal;
    return recent.when(
      loading: () => const SkeletonList(kind: SkeletonKind.row, count: 5, shrink: true, padding: EdgeInsets.symmetric(vertical: 4)),
      error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(auditRecentProvider)),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(icon: Icons.list_alt_rounded, title: 'Nothing recorded yet', message: 'Activity will appear here.');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            OverviewList(
              children: <Widget>[
                for (final e in items)
                  OverviewRow(
                    leading: IconBadge(
                      eventIcon(e.type),
                      size: 42,
                      color: e.isFailure || e.isCritical ? pal.bad : (e.isWarning ? pal.warn : pal.accent),
                    ),
                    title: e.title,
                    subtitle: <String>[
                      if (e.personLabel != null) e.personLabel!,
                      if (e.actorLabel != null && e.actor != e.userId) 'by ${e.actorLabel}',
                    ].join(' '),
                    trailing: Text(timeAgo(e.createdAt), style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                    onTap: e.id == null ? null : () => context.push('/admin/audit/${Uri.encodeComponent(e.id!)}'),
                  ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => context.push('/admin/audit'),
                child: const Text('Open the audit trail', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Systems extends StatelessWidget {
  const _Systems({required this.docs, required this.chat, required this.calls});

  final AsyncValue<DocumentStorageSettings> docs;
  final AsyncValue<StorageSettings> chat;
  final AsyncValue<CallSettings> calls;

  static String _free(int mb) => mb >= 1024 ? '${(mb / 1024).toStringAsFixed(1)} GB free' : '$mb MB free';

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String title,
    required AsyncValue<Object?> value,
    required bool Function(Object) ready,
    required String Function(Object) detail,
  }) {
    final Widget pill;
    String? subtitle;
    if (value.hasValue && value.value != null) {
      final ok = ready(value.value!);
      pill = StatusPill(ok ? 'Ready' : 'Not available', dense: true, color: ok ? Brand.success : Brand.danger);
      subtitle = detail(value.value!);
    } else if (value.hasError) {
      pill = const StatusPill('Could not load', dense: true, color: Brand.muted);
      subtitle = 'The service did not answer.';
    } else {
      pill = const StatusPill('Checking', dense: true, color: Brand.muted);
    }
    return OverviewRow(
      leading: IconBadge(icon, size: 42),
      title: title,
      subtitle: subtitle,
      trailing: pill,
      onTap: () => context.push('/admin/storage'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordingOn = calls.valueOrNull?.recordingEnabled;
    return OverviewList(
      children: <Widget>[
        _row(
          context,
          icon: Icons.description_outlined,
          title: 'Application documents',
          value: docs,
          ready: (o) => (o as DocumentStorageSettings).documents.ready,
          detail: (o) {
            final d = (o as DocumentStorageSettings).documents;
            return <String>[if (d.location.isNotEmpty) d.location, if (d.freeMb != null) _free(d.freeMb!)].join('\n');
          },
        ),
        _row(
          context,
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Chat files',
          value: chat,
          ready: (o) => (o as StorageSettings).attachments.ready,
          detail: (o) {
            final a = (o as StorageSettings).attachments;
            return <String>[if (a.location.isNotEmpty) a.location, if (a.freeMb != null) _free(a.freeMb!)].join('\n');
          },
        ),
        _row(
          context,
          icon: Icons.videocam_outlined,
          title: recordingOn == null ? 'Call recordings' : (recordingOn ? 'Call recordings (on)' : 'Call recordings (off)'),
          value: chat,
          ready: (o) => (o as StorageSettings).recordings.ready,
          detail: (o) {
            final r = (o as StorageSettings).recordings;
            return <String>[if (r.location.isNotEmpty) r.location, if (r.freeMb != null) _free(r.freeMb!)].join('\n');
          },
        ),
      ],
    );
  }
}
