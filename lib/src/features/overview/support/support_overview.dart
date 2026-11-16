import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brand.dart';
import '../../../core/theme/palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../roles/role.dart';
import '../../../state/session_controller.dart';
import '../shared/overview_widgets.dart';
import 'support_overview_data.dart';

/// Open tickets, response times and how the support team is doing.
class SupportOverview extends ConsumerWidget {
  const SupportOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    final data = SupportData.sample(DateTime.now());
    return PageBody(
      bottomPadding: 48,
      children: <Widget>[
        OverviewHero(
          role: Role.support,
          user: user,
          message: 'Tickets, response times and how members rate their help.',
          metrics: <OverviewMetric>[
            OverviewMetric('Open tickets', '${data.openTickets}', 'waiting for a reply'),
            OverviewMetric('Response time', data.averageResponse, 'on average'),
            OverviewMetric('Resolved', '${data.resolutionRate}%', 'of all tickets'),
            OverviewMetric('Satisfaction', data.satisfaction, 'member rating'),
          ],
        ),
        OverviewBlock(
          title: 'Needs your attention',
          child: OverviewAlerts(
            alerts: <OverviewAlert>[
              for (final t in data.urgent)
                OverviewAlert(
                  icon: Icons.priority_high_rounded,
                  tone: OverviewTone.bad,
                  title: '${t.title}: ${t.detail}',
                  detail: 'High priority, opened ${timeAgo(t.openedAt)}.',
                ),
            ],
            allClearMessage: 'All clear. No high priority tickets are waiting.',
          ),
        ),
        OverviewColumns(
          left: OverviewBlock(title: 'Recent tickets', child: _Tickets(data: data)),
          right: OverviewBlock(title: 'Recent activity', child: _Activity(data: data)),
        ),
        OverviewBlock(title: 'Top support agents', subtitle: 'Tickets resolved this month', child: _Agents(data: data)),
        const SizedBox(height: 22),
        const SampleDataNote(message: 'These figures are sample data. Real tickets and agent results will appear here once the support service is connected.'),
      ],
    );
  }
}

class _Tickets extends StatelessWidget {
  const _Tickets({required this.data});

  final SupportData data;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    if (data.tickets.isEmpty) {
      return const EmptyState(
        icon: Icons.support_agent_outlined,
        title: 'No open tickets',
        message: 'New requests from members will appear here.',
      );
    }
    return OverviewList(
      children: <Widget>[
        for (final t in data.tickets)
          OverviewRow(
            leading: IconBadge(Icons.confirmation_number_outlined, size: 42, color: t.priority.tone.color(pal)),
            title: t.title,
            subtitle: t.detail,
            trailing: OverviewTrailing(
              value: timeAgo(t.openedAt),
              badge: StatusPill(t.priority.label, color: t.priority.tone.color(pal), dense: true),
            ),
          ),
      ],
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity({required this.data});

  final SupportData data;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return OverviewList(
      children: <Widget>[
        for (final e in data.events)
          OverviewRow(
            leading: IconBadge(e.icon, size: 42, color: e.tone.color(pal)),
            title: e.title,
            subtitle: e.detail,
            trailing: Text(timeAgo(e.at), style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
          ),
      ],
    );
  }
}

class _Agents extends StatelessWidget {
  const _Agents({required this.data});

  final SupportData data;

  @override
  Widget build(BuildContext context) {
    return OverviewList(
      children: <Widget>[
        for (final a in data.agents)
          OverviewRow(
            leading: UserAvatar(initials: initialsOf(a.name), size: 42),
            title: a.name,
            subtitle: a.role,
            trailing: OverviewTrailing(value: '${a.resolved}', caption: '${a.resolutionRate}% resolved'),
          ),
      ],
    );
  }
}
