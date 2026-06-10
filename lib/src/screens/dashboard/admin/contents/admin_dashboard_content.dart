import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/auth/user_model.dart';
import '../../../../providers/auth/auth_provider.dart';

// ── Shared palette ────────────────────────────────────────────────────────────
const _brand = Color(0xFF1A3C34);
const _gold  = Color(0xFFC9A84C);

class AdminDashboardContent extends ConsumerWidget {
  const AdminDashboardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 768;
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: isWide ? 36 : 20, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(user: user),
            const SizedBox(height: 28),
            _KpiRow(isWide: isWide),
            const SizedBox(height: 28),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _RecentActivity()),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _SystemHealth()),
                ],
              )
            else ...[
              _RecentActivity(),
              const SizedBox(height: 20),
              _SystemHealth(),
            ],
            const SizedBox(height: 20),
            _QuickActions(),
          ],
        ),
      );
    });
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final UserModel? user;
  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${user?.firstName ?? 'Admin'}',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _brand,
                    letterSpacing: -0.8)),
            const SizedBox(height: 3),
            const Text('June 2026  ·  Q2',
                style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500)),
          ],
        ),
        _StatusChip(label: 'System Active', dot: true),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool dot;
  const _StatusChip({required this.label, this.dot = false});

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
              width: 6, height: 6,
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

// ── KPI Row ───────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final bool isWide;
  const _KpiRow({required this.isWide});

  static const _kpis = [
    _KpiData('Total Users',    '1,254',      '+12 this week',   Icons.people_outline_rounded,     true),
    _KpiData('Properties',     '842',         '+5 this week',   Icons.home_work_outlined,          true),
    _KpiData('Revenue Today',  'KES 45.8K',  '↑ 8% vs yesterday', Icons.trending_up_rounded,     true),
    _KpiData('Open Tickets',   '12',          '3 urgent',       Icons.support_agent_outlined,      false),
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
        border: const Border(left: BorderSide(color: _gold, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(data.icon, size: 18, color: _brand),
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
                  color: _brand,
                  letterSpacing: -0.8),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(data.label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
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

// ── Recent Activity ───────────────────────────────────────────────────────────

class _RecentActivity extends StatelessWidget {
  static const _events = [
    _Event('New user registered',       'John Doe · homeowner@premisave.com', Icons.person_add_outlined,        0xFFEFF6FF, 0xFF3B82F6, '2h ago'),
    _Event('Payment processed',         'KES 15,000 · Property #123',        Icons.payments_outlined,           0xFFECFDF3, 0xFF22C55E, '3h ago'),
    _Event('Property listed',           'Runda Mansion · KES 120M',          Icons.home_work_outlined,          0xFFFFFBEB, 0xFFF59E0B, '4h ago'),
    _Event('System backup completed',   'Daily backup · All services OK',    Icons.backup_outlined,             0xFFF5F0E8, 0xFF1A3C34, '5h ago'),
    _Event('Support ticket opened',     'Ticket #88 · Billing issue',        Icons.support_agent_outlined,      0xFFFEF2F2, 0xFFDC2626, '6h ago'),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Recent Activity',
      trailing: 'Today',
      child: Column(
        children: _events
            .asMap()
            .entries
            .map((e) => _EventRow(event: e.value, last: e.key == _events.length - 1))
            .toList(),
      ),
    );
  }
}

class _Event {
  final String title, sub, time;
  final IconData icon;
  final int bg, fg;
  const _Event(this.title, this.sub, this.icon, this.bg, this.fg, this.time);
}

class _EventRow extends StatelessWidget {
  final _Event event;
  final bool last;
  const _EventRow({required this.event, required this.last});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
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
                            fontSize: 12, fontWeight: FontWeight.w600, color: _brand),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(event.sub,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(event.time,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
        if (!last)
          const Divider(height: 1, color: Color(0xFFF3EFE6), thickness: 1),
      ],
    );
  }
}

// ── System Health ─────────────────────────────────────────────────────────────

class _SystemHealth extends StatelessWidget {
  static const _services = [
    _Service('Database',         95, 0xFF22C55E),
    _Service('API Services',     88, 0xFF3B82F6),
    _Service('Payment Gateway',  92, 0xFF1A3C34),
    _Service('Email Service',    75, 0xFFF59E0B),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'System Health',
      trailing: 'Live',
      child: Column(
        children: _services
            .map((s) => _HealthBar(service: s))
            .toList(),
      ),
    );
  }
}

class _Service {
  final String name;
  final int pct;
  final int color;
  const _Service(this.name, this.pct, this.color);
}

class _HealthBar extends StatelessWidget {
  final _Service service;
  const _HealthBar({required this.service});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(service.name,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: _brand)),
              Text('${service.pct}%',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(service.color))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: service.pct / 100,
              backgroundColor: const Color(0xFFF3EFE6),
              color: Color(service.color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  static const _actions = [
    _Action('Manage Users',    Icons.manage_accounts_rounded, 0xFF1A3C34),
    _Action('View Reports',    Icons.bar_chart_rounded,       0xFF3B82F6),
    _Action('System Settings', Icons.settings_rounded,        0xFF6B7280),
    _Action('Analytics',       Icons.analytics_outlined,      0xFFC9A84C),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Quick Actions',
      child: LayoutBuilder(builder: (_, c) {
        final isWide = c.maxWidth >= 500;
        if (isWide) {
          return Row(
            children: _actions
                .map((a) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: a == _actions.last ? 0 : 12),
                child: _ActionCard(action: a),
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
            mainAxisExtent: 100,
          ),
          itemCount: _actions.length,
          itemBuilder: (_, i) => _ActionCard(action: _actions[i]),
        );
      }),
    );
  }
}

class _Action {
  final String label;
  final IconData icon;
  final int color;
  const _Action(this.label, this.icon, this.color);
}

class _ActionCard extends StatelessWidget {
  final _Action action;
  const _ActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color(action.color).withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(action.color).withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, size: 22, color: Color(action.color)),
            const SizedBox(height: 8),
            Text(action.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(action.color)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ── Shared Section Wrapper ────────────────────────────────────────────────────

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
                      color: _brand,
                      letterSpacing: -0.2)),
              if (trailing != null)
                Text(trailing!,
                    style: const TextStyle(
                        fontSize: 12, color: _gold, fontWeight: FontWeight.w600)),
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