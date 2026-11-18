import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/application_models.dart';
import '../../../roles/role.dart';
import '../../../state/data_providers.dart';
import '../../../state/overview_providers.dart';
import '../../../state/session_controller.dart';
import '../../application/application_widgets.dart';
import '../shared/overview_widgets.dart';

/// The home owner application queue, for the support team. There is no ticketing service, so this shows the work
/// support really has: applications waiting for a reviewer and applications waiting for more information from the
/// applicant. The figures come from the authentication service's staff application endpoints.
class SupportOverview extends ConsumerWidget {
  const SupportOverview({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(staffStatsProvider);
    ref.invalidate(supportQueueProvider);
    await ref.read(staffStatsProvider.future).then<Object?>((v) => v, onError: (_) => null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    final stats = ref.watch(staffStatsProvider);
    final queue = ref.watch(supportQueueProvider);

    return PageBody(
      bottomPadding: 48,
      onRefresh: () => _refresh(ref),
      children: <Widget>[
        OverviewHero(
          role: Role.support,
          user: user,
          message: 'Home owner applications waiting on a reviewer or on the applicant.',
          metrics: <OverviewMetric>[
            OverviewMetric('Awaiting review', overviewFigure(stats, (StaffStats s) => '${s.awaitingReview}'), 'applications'),
            OverviewMetric('Need more info', overviewFigure(stats, (StaffStats s) => '${s.needsInfoFromApplicant}'), 'waiting on the applicant'),
            OverviewMetric('Unassigned', overviewFigure(stats, (StaffStats s) => '${s.unassigned}'), 'no reviewer yet'),
            OverviewMetric(
              'Decision time',
              overviewFigure(stats, (StaffStats s) => s.averageDecisionHours == null ? 'None yet' : waitingLabel(s.averageDecisionHours!.round())),
              'on average',
            ),
          ],
          actions: <Widget>[
            HeroAction(label: 'Open the queue', icon: Icons.assignment_outlined, onPressed: () => context.go('/staff')),
            HeroAction(label: 'M-Pesa lookup', icon: Icons.person_search_outlined, filled: false, onPressed: () => context.push('/home/lookup')),
          ],
        ),
        OverviewBlock(title: 'Needs your attention', child: _Attention(stats: stats)),
        OverviewColumns(
          left: OverviewBlock(
            title: 'Waiting longest',
            subtitle: 'Oldest applications first',
            child: OverviewLoad<PagedApplications>(
              value: queue,
              onRetry: () => ref.invalidate(supportQueueProvider),
              builder: (page) => _Queue(items: page.items),
            ),
          ),
          right: OverviewBlock(
            title: 'By status',
            subtitle: 'Where every application stands',
            child: OverviewLoad<StaffStats>(
              value: stats,
              onRetry: () => ref.invalidate(staffStatsProvider),
              builder: (s) => _Statuses(stats: s),
            ),
          ),
        ),
      ],
    );
  }
}

class _Attention extends StatelessWidget {
  const _Attention({required this.stats});

  final AsyncValue<StaffStats> stats;

  @override
  Widget build(BuildContext context) {
    if (stats.isLoading && !stats.hasValue) {
      return const SkeletonList(count: 2, height: 84, shrink: true, padding: EdgeInsets.symmetric(vertical: 4));
    }
    final s = stats.valueOrNull;
    final alerts = <OverviewAlert>[];
    if (s != null) {
      if (s.unassigned > 0) {
        alerts.add(OverviewAlert(
          icon: Icons.person_search_outlined,
          tone: OverviewTone.warn,
          title: '${plural(s.unassigned, 'application')} with no reviewer',
          detail: 'Claim one from the queue so the applicant is not left waiting.',
        ));
      }
      if (s.needsInfoFromApplicant > 0) {
        alerts.add(OverviewAlert(
          icon: Icons.mark_email_unread_outlined,
          tone: OverviewTone.accent,
          title: '${plural(s.needsInfoFromApplicant, 'applicant')} asked for more information',
          detail: 'They have been told what is missing. Follow up if they go quiet.',
        ));
      }
      final since = s.oldestWaitingSince;
      if (since != null && DateTime.now().difference(since.toLocal()).inDays >= 3) {
        alerts.add(OverviewAlert(
          icon: Icons.schedule_rounded,
          tone: OverviewTone.warn,
          title: 'The longest wait is ${timeAgo(since).replaceAll(' ago', '')}',
          detail: 'An application has been waiting for review since ${formatDate(since)}.',
        ));
      }
    }
    return OverviewAlerts(alerts: alerts, allClearMessage: 'All clear. Every application has a reviewer and nothing is overdue.');
  }
}

class _Queue extends StatelessWidget {
  const _Queue({required this.items});

  final List<ApplicationSummary> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'The queue is empty',
        message: 'Submitted applications will appear here for review.',
      );
    }
    return OverviewList(
      children: <Widget>[
        for (final a in items)
          OverviewRow(
            leading: UserAvatar(initials: initialsOf(a.applicantName.isEmpty ? a.applicantEmail : a.applicantName), size: 42),
            title: a.applicantName.isEmpty ? a.applicantEmail : a.applicantName,
            subtitle: '${a.applicationNumber}. Waiting ${waitingLabel(a.waitingHours)}',
            trailing: StatusPill(a.statusLabel, color: statusTint(a.statusColor), dense: true),
            onTap: () => context.push('/staff/${a.id}'),
          ),
      ],
    );
  }
}

class _Statuses extends StatelessWidget {
  const _Statuses({required this.stats});

  final StaffStats stats;

  @override
  Widget build(BuildContext context) {
    final entries = stats.byStatus.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) {
      return const EmptyState(icon: Icons.assignment_outlined, title: 'No applications yet', message: 'Applications are counted by status here.');
    }
    return OverviewList(
      header: Row(
        children: <Widget>[
          Expanded(child: OverviewFigure(label: 'All applications', value: '${stats.total}', color: context.pal.accent)),
          const SizedBox(width: 12),
          Expanded(child: OverviewFigure(label: 'Assigned to me', value: '${stats.assignedToMe}', color: context.pal.good)),
        ],
      ),
      children: <Widget>[
        for (final e in entries)
          OverviewRow(
            leading: const IconBadge(Icons.assignment_outlined, size: 42),
            title: sentence(e.key),
            subtitle: '${(e.value * 100 / (stats.total == 0 ? 1 : stats.total)).round()}% of all',
            trailing: OverviewTrailing(value: '${e.value}'),
            onTap: () => context.go('/staff'),
          ),
      ],
    );
  }
}
