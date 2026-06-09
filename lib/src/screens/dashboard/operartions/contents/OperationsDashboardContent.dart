import 'package:flutter/material.dart';

class OperationsDashboardContent extends StatelessWidget {
  const OperationsDashboardContent({super.key});

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
                  Expanded(flex: 3, child: _RecentListings()),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _ActivityFeed()),
                ],
              )
            else ...[
              _RecentListings(),
              const SizedBox(height: 20),
              _ActivityFeed(),
            ],
            const SizedBox(height: 20),
            _AgentLeaderboard(),
          ],
        ),
      );
    });
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

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
            Text('Operations',
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

// ── KPI Row ──────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final bool isWide;
  const _KpiRow({required this.isWide});

  static const _kpis = [
    _KpiData('Active Listings', '124', '+8 this week', Icons.home_work_outlined, true),
    _KpiData('Deals Closed', '37', 'This quarter', Icons.handshake_outlined, false),
    _KpiData('Revenue', 'KES 48.2M', '↑ 12% vs last Q', Icons.trending_up_rounded, true),
    _KpiData('Avg. Days on Market', '21', '↓ 4 days vs last Q', Icons.schedule_outlined, true),
  ];

  @override
  Widget build(BuildContext context) {
    return isWide
        ? Row(
      children: _kpis
          .map((k) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(
              right: k == _kpis.last ? 0 : 14),
          child: _KpiCard(data: k),
        ),
      ))
          .toList(),
    )
        : GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      children: _kpis.map((k) => _KpiCard(data: k)).toList(),
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: const Color(0xFFC9A84C), width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 12),
          Text(data.value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A3C34),
                  letterSpacing: -0.8)),
          const SizedBox(height: 3),
          Text(data.label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151))),
          const SizedBox(height: 2),
          Text(data.sub,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

// ── Recent Listings ──────────────────────────────────────────────────────────

class _RecentListings extends StatelessWidget {
  static const _listings = [
    _Listing('Westlands Penthouse', 'Nairobi · 4 bed', 'KES 28.5M', 'For Sale', 14, 0xFFEFF6FF, 0xFF3B82F6),
    _Listing('Karen Villa Estate', 'Nairobi · 5 bed', 'KES 65M', 'Under Offer', 7, 0xFFFFFBEB, 0xFFF59E0B),
    _Listing('Kilimani Apartment', 'Nairobi · 2 bed', 'KES 8.2M', 'For Sale', 22, 0xFFEFF6FF, 0xFF3B82F6),
    _Listing('Runda Mansion', 'Nairobi · 6 bed', 'KES 120M', 'New', 3, 0xFFECFDF3, 0xFF22C55E),
    _Listing('Lavington Townhouse', 'Nairobi · 3 bed', 'KES 18M', 'For Sale', 19, 0xFFEFF6FF, 0xFF3B82F6),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Recent Listings',
      trailing: 'View all',
      child: Column(
        children: _listings
            .map((l) => _ListingRow(listing: l, last: l == _listings.last))
            .toList(),
      ),
    );
  }
}

class _Listing {
  final String name, location, price, status;
  final int daysAgo;
  final int badgeBg, badgeFg;
  const _Listing(this.name, this.location, this.price, this.status,
      this.daysAgo, this.badgeBg, this.badgeFg);
}

class _ListingRow extends StatelessWidget {
  final _Listing listing;
  final bool last;
  const _ListingRow({required this.listing, this.last = false});

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
                child: const Icon(Icons.home_outlined,
                    size: 18, color: Color(0xFF1A3C34)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A3C34))),
                    const SizedBox(height: 2),
                    Text(listing.location,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(listing.price,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A3C34))),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(listing.badgeBg),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(listing.status,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(listing.badgeFg))),
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

// ── Activity Feed ────────────────────────────────────────────────────────────

class _ActivityFeed extends StatelessWidget {
  static const _events = [
    _Event('New offer received', 'Karen Villa · KES 62M', '2h ago', Icons.local_offer_outlined, 0xFFFFFBEB, 0xFFF59E0B),
    _Event('Viewing scheduled', 'Westlands Penthouse', '5h ago', Icons.calendar_today_outlined, 0xFFEFF6FF, 0xFF3B82F6),
    _Event('Document signed', 'Kilimani Apt — SPA', 'Yesterday', Icons.task_alt_rounded, 0xFFECFDF3, 0xFF22C55E),
    _Event('Price reduced', 'Lavington · KES 18M', 'Yesterday', Icons.price_change_outlined, 0xFFFEF2F2, 0xFFEF4444),
    _Event('Listing published', 'Runda Mansion', '2 days ago', Icons.publish_rounded, 0xFFECFDF3, 0xFF22C55E),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Activity',
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
                            fontSize: 11, color: Color(0xFF9CA3AF))),
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

// ── Agent Leaderboard ────────────────────────────────────────────────────────

class _AgentLeaderboard extends StatelessWidget {
  static const _agents = [
    _Agent('Amara Osei', 'Senior Agent', 14, 'KES 18.4M', 1),
    _Agent('Nadia Mwangi', 'Agent', 11, 'KES 14.2M', 2),
    _Agent('James Kariuki', 'Associate', 9, 'KES 11.8M', 3),
    _Agent('Priya Desai', 'Agent', 7, 'KES 9.1M', 4),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Agent Performance',
      trailing: 'This quarter',
      child: LayoutBuilder(builder: (context, c) {
        final isWide = c.maxWidth >= 500;
        return isWide
            ? Row(
          children: _agents
              .map((a) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  right: a == _agents.last ? 0 : 12),
              child: _AgentCard(agent: a),
            ),
          ))
              .toList(),
        )
            : Column(
          children: _agents.map((a) => _AgentCard(agent: a)).toList(),
        );
      }),
    );
  }
}

class _Agent {
  final String name, role, revenue;
  final int deals, rank;
  const _Agent(this.name, this.role, this.deals, this.revenue, this.rank);
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF5F0E8),
                child: Text(
                  agent.name.substring(0, 1),
                  style: const TextStyle(
                      fontSize: 14,
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
          const SizedBox(height: 10),
          Text(agent.name,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A3C34))),
          Text(agent.role,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF3EFE6)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(label: 'Deals', value: '${agent.deals}'),
              _Stat(label: 'Revenue', value: agent.revenue),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A3C34),
                letterSpacing: -0.4)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
      ],
    );
  }
}

// ── Shared Section Wrapper ───────────────────────────────────────────────────

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