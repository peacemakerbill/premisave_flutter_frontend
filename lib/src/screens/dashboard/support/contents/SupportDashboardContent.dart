import 'package:flutter/material.dart';

class SupportDashboardContent extends StatelessWidget {
  const SupportDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 768;
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: isWide ? 36 : 20, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(),
            const SizedBox(height: 28),
            _KpiRow(isWide: isWide),
            const SizedBox(height: 28),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _RecentTickets()),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _ActivityFeed()),
                ],
              )
            else ...[
              _RecentTickets(),
              const SizedBox(height: 20),
              _ActivityFeed(),
            ],
            const SizedBox(height: 20),
            _SupportLeaderboard(),
          ],
        ),
      );
    });
  }
}

// Header
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Support',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A3C34),
                    letterSpacing: -0.8)),
            SizedBox(height: 3),
            Text('June 2025  ·  Q2',
                style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500)),
          ],
        ),
        _Chip(label: 'Live', dot: true),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool dot;
  const _Chip({required this.label, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: Color(0xFF22C55E), shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16A34A))),
        ],
      ),
    );
  }
}

// KPI Row
class _KpiRow extends StatelessWidget {
  final bool isWide;
  const _KpiRow({required this.isWide});

  static const _kpis = [
    _KpiData('Open Tickets', '47', '↓ 8 this week', Icons.support_agent_rounded, true),
    _KpiData('Avg Response', '1.8 hrs', '↓ 12 min', Icons.timer_outlined, true),
    _KpiData('Resolution Rate', '94%', '↑ 3%', Icons.check_circle_outline, true),
    _KpiData('Satisfaction', '4.7/5', '↑ 0.2', Icons.thumb_up_outlined, true),
  ];

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return Row(
        children: _kpis
            .map((k) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: k == _kpis.last ? 0 : 14),
            child: _KpiCard(data: k),
          ),
        ))
            .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 148,
      ),
      itemCount: _kpis.length,
      itemBuilder: (_, i) => _KpiCard(data: _kpis[i]),
    );
  }
}

class _KpiData {
  final String label, value, sub;
  final IconData icon;
  final bool positive;
  const _KpiData(this.label, this.value, this.sub, this.icon, this.positive);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: Color(0xFFC9A84C), width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(data.icon, size: 18, color: const Color(0xFF1A3C34)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: data.positive
                      ? const Color(0xFFECFDF3)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(data.positive ? '↑' : '↓',
                    style: TextStyle(
                        fontSize: 11,
                        color: data.positive
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(data.value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A3C34),
                  letterSpacing: -0.8),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(data.label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(data.sub,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// Recent Tickets
class _RecentTickets extends StatelessWidget {
  static const _tickets = [
    _Ticket('Payment Issue', 'Karen Villa - Invoice #INV-3921', 'High', '2h ago', 0xFFFEF2F2, 0xFFEF4444),
    _Ticket('Login Problem', 'Westlands User', 'Medium', '5h ago', 0xFFFFFBEB, 0xFFF59E0B),
    _Ticket('Property Listing', 'Request to verify Runda Mansion', 'Low', 'Yesterday', 0xFFECFDF3, 0xFF22C55E),
    _Ticket('Commission Dispute', 'Lavington Townhouse', 'Medium', 'Yesterday', 0xFFFFFBEB, 0xFFF59E0B),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Recent Tickets',
      trailing: 'View all',
      child: Column(
        children: _tickets
            .map((t) => _TicketRow(ticket: t, last: t == _tickets.last))
            .toList(),
      ),
    );
  }
}

class _Ticket {
  final String title, subtitle, priority, time;
  final int bg, fg;
  const _Ticket(this.title, this.subtitle, this.priority, this.time, this.bg, this.fg);
}

class _TicketRow extends StatelessWidget {
  final _Ticket ticket;
  final bool last;
  const _TicketRow({required this.ticket, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.support_agent_outlined,
                    size: 18, color: Color(0xFF1A3C34)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A3C34))),
                    Text(ticket.subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9CA3AF)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(ticket.time,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF))),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(ticket.bg),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(ticket.priority,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(ticket.fg))),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!last)
          const Divider(height: 1, color: Color(0xFFF3EFE6), thickness: 1),
      ],
    );
  }
}

// Activity Feed
class _ActivityFeed extends StatelessWidget {
  static const _events = [
    _Event('Ticket resolved', 'Payment Issue - Karen Villa', '12m ago', Icons.check_circle_rounded, 0xFFECFDF3, 0xFF22C55E),
    _Event('New ticket assigned', '#SUP-4812 to James Kariuki', '47m ago', Icons.assignment_rounded, 0xFFEFF6FF, 0xFF3B82F6),
    _Event('User replied', 'Login Problem', '2h ago', Icons.reply_rounded, 0xFFFFFBEB, 0xFFF59E0B),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Recent Activity',
      child: Column(
        children: _events
            .map((e) => _EventRow(event: e, last: e == _events.last))
            .toList(),
      ),
    );
  }
}

class _Event {
  final String title, sub, time;
  final IconData icon;
  final int bg, fg;
  const _Event(this.title, this.sub, this.time, this.icon, this.bg, this.fg);
}

class _EventRow extends StatelessWidget {
  final _Event event;
  final bool last;
  const _EventRow({required this.event, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Color(event.bg),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(event.icon, size: 16, color: Color(event.fg)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A3C34))),
                    Text(event.sub,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text(event.time,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
        if (!last)
          const Divider(height: 1, color: Color(0xFFF3EFE6), thickness: 1),
      ],
    );
  }
}

// Support Leaderboard
class _SupportLeaderboard extends StatelessWidget {
  static const _agents = [
    _Agent('Amara Osei', 'Senior Support', 28, '98%', 1),
    _Agent('James Kariuki', 'Support Lead', 24, '95%', 2),
    _Agent('Nadia Mwangi', 'Support Agent', 19, '92%', 3),
    _Agent('Priya Desai', 'Support Agent', 15, '89%', 4),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Top Support Agents',
      trailing: 'This month',
      child: LayoutBuilder(builder: (context, c) {
        final isWide = c.maxWidth >= 500;
        if (isWide) {
          return Row(
            children: _agents
                .map((a) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: a == _agents.last ? 0 : 12),
                child: _AgentCard(agent: a),
              ),
            ))
                .toList(),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 162,
          ),
          itemCount: _agents.length,
          itemBuilder: (_, i) => _AgentCard(agent: _agents[i]),
        );
      }),
    );
  }
}

class _Agent {
  final String name, role, resolution;
  final int tickets, rank;
  const _Agent(this.name, this.role, this.tickets, this.resolution, this.rank);
}

class _AgentCard extends StatelessWidget {
  final _Agent agent;
  const _AgentCard({required this.agent});

  static const _rankColors = [
    Color(0xFFC9A84C),
    Color(0xFF9CA3AF),
    Color(0xFFCD7F32),
    Color(0xFFD1D5DB),
  ];

  @override
  Widget build(BuildContext context) {
    final rankColor = _rankColors[(agent.rank - 1).clamp(0, 3)];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFF5F0E8),
                child: Text(
                  agent.name.substring(0, 1),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A3C34)),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    color: rankColor.withOpacity(0.12),
                    shape: BoxShape.circle),
                child: Center(
                  child: Text('#${agent.rank}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: rankColor)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(agent.name,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A3C34))),
          Text(agent.role,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 6),
          const Divider(height: 1, color: Color(0xFFF3EFE6)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(label: 'Tickets', value: '${agent.tickets}'),
              _Stat(label: 'Resolution', value: agent.resolution, alignEnd: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final bool alignEnd;
  const _Stat({required this.label, required this.value, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A3C34),
                letterSpacing: -0.4)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
      ],
    );
  }
}

// Section Wrapper
class _Section extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget child;
  const _Section({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A3C34),
                      letterSpacing: -0.2)),
              if (trailing != null)
                Text(trailing!,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFC9A84C),
                        fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(color: Color(0xFFF3EFE6)),
          child,
        ],
      ),
    );
  }
}