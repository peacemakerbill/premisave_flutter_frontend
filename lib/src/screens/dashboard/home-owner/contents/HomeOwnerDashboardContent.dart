import 'package:flutter/material.dart';

class HomeOwnerDashboardContent extends StatelessWidget {
  const HomeOwnerDashboardContent({super.key});

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
                  Expanded(flex: 3, child: _MyProperties()),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _MaintenanceFeed()),
                ],
              )
            else ...[
              _MyProperties(),
              const SizedBox(height: 20),
              _MaintenanceFeed(),
            ],
            const SizedBox(height: 20),
            _UpcomingPayments(),
          ],
        ),
      );
    });
  }
}

// ── Shared palette ───────────────────────────────────────────────────────────

const _brand = Color(0xFF1A3C34);
const _gold  = Color(0xFFC9A84C);

// ── Header ───────────────────────────────────────────────────────────────────

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
            Text('Home Owner',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _brand,
                    letterSpacing: -0.8)),
            SizedBox(height: 3),
            Text('June 2026  ·  Q2',
                style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500)),
          ],
        ),
        _Chip(label: 'Active', dot: true),
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

// ── KPI Row ──────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final bool isWide;
  const _KpiRow({required this.isWide});

  static const _kpis = [
    _KpiData('My Properties',    '3',          '2 rented · 1 vacant', Icons.home_work_outlined,      true),
    _KpiData('Rental Income',    'KES 95K',    '↑ 5% vs last month',  Icons.trending_up_rounded,     true),
    _KpiData('Open Requests',    '2',          '1 urgent',            Icons.build_circle_outlined,   false),
    _KpiData('Next Payment Due', '18 Jun',     'KES 32,500',          Icons.calendar_today_outlined, true),
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

// ── Section 1 · My Properties ─────────────────────────────────────────────────

class _MyProperties extends StatelessWidget {
  static const _props = [
    _Property('Westlands Apartment', '2 bed · Nairobi', 'KES 45,000 / mo', 'Rented',    21, 0xFFEFF6FF, 0xFF3B82F6),
    _Property('Karen Cottage',       '3 bed · Nairobi', 'KES 50,000 / mo', 'Rented',     9, 0xFFEFF6FF, 0xFF3B82F6),
    _Property('Kilimani Studio',     '1 bed · Nairobi', 'KES 22,000 / mo', 'Vacant',     0, 0xFFFEF2F2, 0xFFDC2626),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'My Properties',
      trailing: '${_props.length} total',
      child: Column(
        children: _props
            .asMap()
            .entries
            .map((e) => _PropertyRow(
          prop: e.value,
          last: e.key == _props.length - 1,
        ))
            .toList(),
      ),
    );
  }
}

class _Property {
  final String name, meta, price, status;
  final int days;
  final int bg, fg;
  const _Property(
      this.name, this.meta, this.price, this.status, this.days, this.bg, this.fg);
}

class _PropertyRow extends StatelessWidget {
  final _Property prop;
  final bool last;
  const _PropertyRow({required this.prop, required this.last});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.home_rounded, size: 18, color: _brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(prop.name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _brand),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(prop.meta,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(prop.price,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _brand,
                          letterSpacing: -0.3)),
                  const SizedBox(height: 3),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Color(prop.bg),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(prop.status,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(prop.fg))),
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

// ── Section 2 · Maintenance Feed ─────────────────────────────────────────────

class _MaintenanceFeed extends StatelessWidget {
  static const _items = [
    _MaintItem('Leaking Tap',        'Westlands Apt · Reported 2h ago',   Icons.water_drop_outlined,  0xFFFFF7ED, 0xFFF97316, 'Open'),
    _MaintItem('Broken Gate Lock',   'Karen Cottage · Reported 1d ago',   Icons.lock_outline_rounded, 0xFFFEF2F2, 0xFFDC2626, 'Urgent'),
    _MaintItem('Painting Completed', 'Kilimani Studio · 3 days ago',      Icons.format_paint_outlined, 0xFFECFDF3, 0xFF22C55E, 'Done'),
    _MaintItem('Plumbing Check',     'Karen Cottage · Scheduled 20 Jun',  Icons.plumbing_outlined,    0xFFEFF6FF, 0xFF3B82F6, 'Scheduled'),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Maintenance',
      trailing: 'Recent',
      child: Column(
        children: _items
            .asMap()
            .entries
            .map((e) => _MaintRow(item: e.value, last: e.key == _items.length - 1))
            .toList(),
      ),
    );
  }
}

class _MaintItem {
  final String title, sub, status;
  final IconData icon;
  final int bg, fg;
  const _MaintItem(this.title, this.sub, this.icon, this.bg, this.fg, this.status);
}

class _MaintRow extends StatelessWidget {
  final _MaintItem item;
  final bool last;
  const _MaintRow({required this.item, required this.last});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Color(item.bg),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.icon, size: 16, color: Color(item.fg)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _brand),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(item.sub,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Color(item.bg),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(item.status,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(item.fg))),
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

// ── Section 3 · Upcoming Payments ────────────────────────────────────────────

class _UpcomingPayments extends StatelessWidget {
  static const _payments = [
    _Payment('Service Charge',    'Westlands Apt',  'KES 5,000',  '18 Jun', 1),
    _Payment('Rental Income',     'Karen Cottage',  'KES 50,000', '20 Jun', 2),
    _Payment('Rental Income',     'Westlands Apt',  'KES 45,000', '22 Jun', 3),
    _Payment('Insurance Premium', 'All Properties', 'KES 12,000', '30 Jun', 4),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Upcoming Payments',
      trailing: 'This month',
      child: LayoutBuilder(builder: (context, c) {
        final isWide = c.maxWidth >= 500;
        if (isWide) {
          return Row(
            children: _payments
                .map((p) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: p == _payments.last ? 0 : 12),
                child: _PaymentCard(payment: p),
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
            mainAxisExtent: 130,
          ),
          itemCount: _payments.length,
          itemBuilder: (_, i) => _PaymentCard(payment: _payments[i]),
        );
      }),
    );
  }
}

class _Payment {
  final String label, property, amount, date;
  final int index;
  const _Payment(this.label, this.property, this.amount, this.date, this.index);
}

class _PaymentCard extends StatelessWidget {
  final _Payment payment;
  const _PaymentCard({required this.payment});

  static const _dotColors = [
    Color(0xFFC9A84C),
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFF9CA3AF),
  ];

  @override
  Widget build(BuildContext context) {
    final dot = _dotColors[(payment.index - 1).clamp(0, 3)];
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
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              Text(payment.date,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _gold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(payment.amount,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _brand,
                  letterSpacing: -0.6),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(payment.label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(payment.property,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
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
                        fontSize: 12,
                        color: _gold,
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