import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand.dart';
import '../../../core/theme/palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../state/session_controller.dart';
import '../shared/info_parts.dart';

/// Currency shown on this overview. The figures are sample data until the property and payment services exist,
/// so this is the one place to change when real amounts arrive with their own currency.
const String _currency = 'USD';

const List<String> _monthNames = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
];

/// A home owner's portfolio at a glance: who is renting, what needs attention, what is due and how income is moving.
class HomeOwnerDashboardContent extends ConsumerWidget {
  const HomeOwnerDashboardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    final data = _Portfolio.sample(DateTime.now());
    return PageBody(
      bottomPadding: 48,
      children: <Widget>[
        _OverviewHero(
          data: data,
          name: user == null ? '' : (user.firstName.isEmpty ? user.displayName : user.firstName),
          verified: user?.verified ?? false,
        ),
        _Block(title: 'Needs your attention', child: _Attention(data: data)),
        _Block(
          title: 'Your properties',
          subtitle: '${plural(data.properties.length, 'property', 'properties')} in your portfolio',
          child: _Properties(data: data),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final maintenance = _Block(title: 'Maintenance', child: _MaintenancePanel(data: data));
            final money = _Block(title: 'Coming up', child: _MoneyPanel(data: data));
            if (constraints.maxWidth < 860) {
              return Column(children: <Widget>[maintenance, money]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: maintenance),
                const SizedBox(width: 18),
                Expanded(child: money),
              ],
            );
          },
        ),
        _Block(
          title: 'Rental income',
          subtitle: 'Collected rent over the last six months',
          child: _IncomeChart(data: data),
        ),
        const SizedBox(height: 22),
        const _SampleNote(),
      ],
    );
  }
}

// Sample data

enum _RequestStatus {
  urgent('Urgent'),
  open('Open'),
  scheduled('Scheduled'),
  done('Done');

  const _RequestStatus(this.label);

  final String label;

  Color color(AppPalette pal) {
    switch (this) {
      case _RequestStatus.urgent:
        return pal.bad;
      case _RequestStatus.open:
        return pal.warn;
      case _RequestStatus.scheduled:
        return pal.accent;
      case _RequestStatus.done:
        return pal.good;
    }
  }
}

class _Property {
  const _Property({required this.name, required this.kind, required this.rent, this.leaseEnds, this.vacantSince});

  final String name;
  final String kind;
  final int rent;
  final DateTime? leaseEnds;
  final DateTime? vacantSince;

  bool get rented => leaseEnds != null;
}

class _Request {
  const _Request({required this.title, required this.property, required this.status, required this.at, required this.icon});

  final String title;
  final String property;
  final _RequestStatus status;
  final DateTime at;
  final IconData icon;

  bool get active => status == _RequestStatus.urgent || status == _RequestStatus.open;
}

class _Payment {
  const _Payment({required this.label, required this.property, required this.amount, required this.due, required this.income});

  final String label;
  final String property;
  final int amount;
  final DateTime due;
  final bool income;
}

/// One consistent set of sample figures. Every number on the screen is worked out from these lists,
/// so the hero, the cards and the chart always agree with each other.
class _Portfolio {
  const _Portfolio({
    required this.now,
    required this.properties,
    required this.requests,
    required this.payments,
    required this.history,
  });

  final DateTime now;
  final List<_Property> properties;
  final List<_Request> requests;
  final List<_Payment> payments;

  /// Rent collected in each of the last six months, oldest first.
  final List<int> history;

  factory _Portfolio.sample(DateTime now) {
    DateTime ago({int days = 0, int hours = 0}) => now.subtract(Duration(days: days, hours: hours));
    DateTime ahead(int days) => now.add(Duration(days: days));
    return _Portfolio(
      now: now,
      properties: <_Property>[
        _Property(name: 'Riverside Apartment', kind: '2 bedrooms, apartment', rent: 45000, leaseEnds: ahead(280)),
        _Property(name: 'Garden Cottage', kind: '3 bedrooms, cottage', rent: 50000, leaseEnds: ahead(150)),
        _Property(name: 'City Studio', kind: '1 bedroom, studio', rent: 22000, vacantSince: ago(days: 12)),
      ],
      requests: <_Request>[
        _Request(
          title: 'Leaking tap',
          property: 'Riverside Apartment',
          status: _RequestStatus.open,
          at: ago(hours: 2),
          icon: Icons.water_drop_outlined,
        ),
        _Request(
          title: 'Broken gate lock',
          property: 'Garden Cottage',
          status: _RequestStatus.urgent,
          at: ago(hours: 26),
          icon: Icons.lock_outline_rounded,
        ),
        _Request(
          title: 'Plumbing inspection',
          property: 'Garden Cottage',
          status: _RequestStatus.scheduled,
          at: ahead(5),
          icon: Icons.plumbing_outlined,
        ),
        _Request(
          title: 'Repainting finished',
          property: 'City Studio',
          status: _RequestStatus.done,
          at: ago(days: 3),
          icon: Icons.format_paint_outlined,
        ),
      ],
      payments: <_Payment>[
        _Payment(label: 'Service charge', property: 'Riverside Apartment', amount: 5000, due: ahead(3), income: false),
        _Payment(label: 'Rent', property: 'Garden Cottage', amount: 50000, due: ahead(5), income: true),
        _Payment(label: 'Rent', property: 'Riverside Apartment', amount: 45000, due: ahead(7), income: true),
        _Payment(label: 'Insurance premium', property: 'All properties', amount: 12000, due: ahead(14), income: false),
      ],
      history: const <int>[78000, 82000, 85000, 90000, 90000, 95000],
    );
  }

  List<_Property> get rentedProperties => properties.where((p) => p.rented).toList();

  int get monthlyIncome => rentedProperties.fold<int>(0, (sum, p) => sum + p.rent);

  int get occupancyPercent => properties.isEmpty ? 0 : (rentedProperties.length * 100 / properties.length).round();

  int get openRequests => requests.where((r) => r.active).length;

  int get urgentRequests => requests.where((r) => r.status == _RequestStatus.urgent).length;

  int get expectedIn => payments.where((p) => p.income).fold<int>(0, (sum, p) => sum + p.amount);

  int get expectedOut => payments.where((p) => !p.income).fold<int>(0, (sum, p) => sum + p.amount);
}

// Formatting

String _money(num value) {
  final digits = value.round().toString();
  final grouped = digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '$_currency $grouped';
}

String _trimZero(double v) {
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

String _short(num value) {
  if (value >= 1000000) return '${_trimZero(value / 1000000)}M';
  if (value >= 1000) return '${_trimZero(value / 1000)}K';
  return value.round().toString();
}

/// "today", "tomorrow" or "in 5 days", counted in calendar days.
String _dueIn(DateTime now, DateTime due) {
  final days = DateTime(due.year, due.month, due.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  if (days <= 0) return 'today';
  if (days == 1) return 'tomorrow';
  return 'in $days days';
}

// Hero

class _OverviewHero extends StatelessWidget {
  const _OverviewHero({required this.data, required this.name, required this.verified});

  final _Portfolio data;
  final String name;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final title = name.isEmpty ? greeting(data.now) : '${greeting(data.now)}, $name';
    final metrics = <_HeroMetric>[
      _HeroMetric('Income', '$_currency ${_short(data.monthlyIncome)}', 'per month'),
      _HeroMetric('Occupancy', '${data.occupancyPercent}%', '${data.rentedProperties.length} of ${data.properties.length} rented'),
      _HeroMetric(
        'Requests',
        '${data.openRequests}',
        data.urgentRequests == 0 ? 'None urgent' : '${data.urgentRequests} urgent',
      ),
    ];
    return HeroPanel(
      padding: EdgeInsets.fromLTRB(compact ? 22 : 36, compact ? 24 : 34, compact ? 22 : 36, compact ? 22 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              const StatusPill('Home owner', color: Brand.gold, icon: Icons.badge_outlined),
              if (verified) const StatusPill('Verified', color: Color(0xFF5FD39A), icon: Icons.verified_rounded),
              const StatusPill('Sample data', color: Brand.cream, icon: Icons.info_outline_rounded),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.display(size: compact ? 26 : 36, weight: FontWeight.w800, spacing: -1, height: 1.1, color: Brand.cream),
          ),
          const SizedBox(height: 8),
          Text(
            'Here is how your portfolio looks today, from rent to repairs.',
            style: TextStyle(fontSize: compact ? 14.5 : 16, height: 1.5, color: Brand.cream.op(0.88)),
          ),
          SizedBox(height: compact ? 22 : 28),
          Container(
            padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 22, vertical: compact ? 14 : 18),
            decoration: BoxDecoration(
              color: Brand.cream.op(0.1),
              borderRadius: BorderRadius.circular(context.radius(16)),
              border: Border.all(color: Brand.cream.op(0.18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (var i = 0; i < metrics.length; i++) ...<Widget>[
                  if (i != 0)
                    Container(
                      width: 1,
                      height: compact ? 58 : 64,
                      margin: EdgeInsets.symmetric(horizontal: compact ? 10 : 20),
                      color: Brand.cream.op(0.22),
                    ),
                  Expanded(child: _HeroMetricView(metrics[i], compact: compact)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              HeroAction(
                label: 'My application',
                icon: Icons.assignment_turned_in_outlined,
                onPressed: () => context.push('/application'),
              ),
              HeroAction(
                label: 'Edit profile',
                icon: Icons.person_outline_rounded,
                filled: false,
                onPressed: () => context.push('/account/profile/edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric {
  const _HeroMetric(this.label, this.value, this.caption);

  final String label;
  final String value;
  final String caption;
}

class _HeroMetricView extends StatelessWidget {
  const _HeroMetricView(this.metric, {required this.compact});

  final _HeroMetric metric;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          metric.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Brand.cream.op(0.78)),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            metric.value,
            maxLines: 1,
            style: context.display(size: compact ? 22 : 30, weight: FontWeight.w800, spacing: -0.8, height: 1.1, color: Brand.cream),
          ),
        ),
        const SizedBox(height: 4),
        Text(metric.caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, height: 1.35, color: Brand.cream.op(0.8))),
      ],
    );
  }
}

// Sections

/// A titled block with room above it, matching the About and Contact pages.
class _Block extends StatelessWidget {
  const _Block({required this.title, this.subtitle, required this.child});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.isCompact ? 28 : 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: context.display(size: context.isCompact ? 20 : 22, weight: FontWeight.w800, spacing: -0.5, height: 1.2)),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(subtitle!, style: TextStyle(fontSize: 14, height: 1.4, color: context.mutedColor)),
            ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Alert {
  const _Alert(this.icon, this.color, this.title, this.detail);

  final IconData icon;
  final Color color;
  final String title;
  final String detail;
}

class _Attention extends StatelessWidget {
  const _Attention({required this.data});

  final _Portfolio data;

  List<_Alert> _alerts(AppPalette pal) {
    final alerts = <_Alert>[];
    for (final r in data.requests.where((r) => r.status == _RequestStatus.urgent)) {
      alerts.add(_Alert(Icons.priority_high_rounded, pal.bad, '${r.title} at ${r.property}', 'Urgent request, reported ${timeAgo(r.at)}.'));
    }
    for (final p in data.properties.where((p) => !p.rented)) {
      final days = p.vacantSince == null ? 0 : data.now.difference(p.vacantSince!).inDays;
      alerts.add(_Alert(
        Icons.meeting_room_outlined,
        pal.warn,
        '${p.name} is vacant',
        days <= 0 ? 'Empty since today. Check the listing is ready.' : 'Empty for ${plural(days, 'day')}. Check the listing is ready.',
      ));
    }
    for (final pay in data.payments.where((p) => !p.income)) {
      if (pay.due.difference(data.now).inDays <= 5) {
        alerts.add(_Alert(
          Icons.event_outlined,
          pal.accent,
          '${pay.label} due ${_dueIn(data.now, pay.due)}',
          '${_money(pay.amount)} for ${pay.property}.',
        ));
      }
    }
    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final alerts = _alerts(pal);
    if (alerts.isEmpty) {
      return PCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            IconBadge(Icons.check_circle_outline_rounded, size: 44, color: pal.good),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'All clear. Nothing needs your attention right now.',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }
    return ResponsiveWrap(
      minItemWidth: 280,
      spacing: 14,
      maxColumns: 3,
      children: <Widget>[for (final a in alerts) _AlertCard(alert: a)],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final _Alert alert;

  @override
  Widget build(BuildContext context) {
    return PCard(
      color: alert.color.op(0.07),
      borderColor: alert.color.op(0.32),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IconBadge(alert.icon, size: 40, color: alert.color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(alert.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, height: 1.3)),
                const SizedBox(height: 4),
                Text(alert.detail, style: TextStyle(fontSize: 13, height: 1.45, color: context.mutedColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Properties extends StatelessWidget {
  const _Properties({required this.data});

  final _Portfolio data;

  @override
  Widget build(BuildContext context) {
    if (data.properties.isEmpty) {
      return const EmptyState(
        icon: Icons.home_work_outlined,
        title: 'No properties yet',
        message: 'Properties you list will appear here with their rent and tenancy.',
      );
    }
    return ResponsiveWrap(
      minItemWidth: 270,
      spacing: 14,
      maxColumns: 3,
      children: <Widget>[for (final p in data.properties) _PropertyCard(property: p, now: data.now)],
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property, required this.now});

  final _Property property;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final rented = property.rented;
    final days = property.vacantSince == null ? 0 : now.difference(property.vacantSince!).inDays;
    final detail = rented
        ? 'Lease ends ${formatDate(property.leaseEnds)}'
        : (days <= 0 ? 'Vacant since today' : 'Vacant for ${plural(days, 'day')}');
    return PCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 92,
            width: double.infinity,
            color: pal.accentSoft,
            child: Stack(
              children: <Widget>[
                Center(child: Icon(Icons.home_work_outlined, size: 42, color: pal.accent.op(0.55))),
                Positioned(
                  top: 12,
                  right: 12,
                  child: StatusPill(rented ? 'Rented' : 'Vacant', color: rented ? pal.good : pal.warn, dense: true),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(property.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(property.kind, style: TextStyle(fontSize: 13, color: context.mutedColor)),
                const SizedBox(height: 14),
                Divider(height: 1, color: context.borderColor),
                const SizedBox(height: 14),
                Text(rented ? 'Monthly rent' : 'Listed rent', style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    text: _money(property.rent),
                    style: context.display(size: 19, weight: FontWeight.w800, spacing: -0.4),
                    children: <InlineSpan>[
                      TextSpan(
                        text: '  per month',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, letterSpacing: 0, color: context.mutedColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Icon(rented ? Icons.event_available_outlined : Icons.schedule_rounded, size: 16, color: context.mutedColor),
                    const SizedBox(width: 7),
                    Expanded(child: Text(detail, style: TextStyle(fontSize: 13, color: context.mutedColor))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenancePanel extends StatelessWidget {
  const _MaintenancePanel({required this.data});

  final _Portfolio data;

  String _when(_Request r) {
    switch (r.status) {
      case _RequestStatus.scheduled:
        return 'Scheduled for ${formatDate(r.at)}';
      case _RequestStatus.done:
        return 'Finished ${timeAgo(r.at)}';
      case _RequestStatus.urgent:
      case _RequestStatus.open:
        return 'Reported ${timeAgo(r.at)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    if (data.requests.isEmpty) {
      return const EmptyState(
        icon: Icons.build_circle_outlined,
        title: 'No maintenance requests',
        message: 'Repairs and inspections for your properties will be tracked here.',
      );
    }
    return PCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < data.requests.length; i++) ...<Widget>[
            if (i != 0) Divider(height: 1, color: context.borderColor),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: <Widget>[
                  IconBadge(data.requests[i].icon, size: 42, color: data.requests[i].status.color(pal)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(data.requests[i].title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          '${data.requests[i].property}. ${_when(data.requests[i])}',
                          style: TextStyle(fontSize: 13, height: 1.4, color: context.mutedColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  StatusPill(data.requests[i].status.label, color: data.requests[i].status.color(pal), dense: true),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoneyPanel extends StatelessWidget {
  const _MoneyPanel({required this.data});

  final _Portfolio data;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final items = List<_Payment>.of(data.payments)..sort((a, b) => a.due.compareTo(b.due));
    return PCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _Figure(label: 'Money in', value: _money(data.expectedIn), color: pal.good)),
              const SizedBox(width: 12),
              Expanded(child: _Figure(label: 'Money out', value: _money(data.expectedOut), color: pal.bad)),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: context.borderColor),
          for (var i = 0; i < items.length; i++) ...<Widget>[
            if (i != 0) Divider(height: 1, color: context.borderColor),
            _PaymentRow(payment: items[i]),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: color.op(0.09), borderRadius: BorderRadius.circular(context.radius(12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.mutedColor)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, maxLines: 1, style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: color)),
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final _Payment payment;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final color = payment.income ? pal.good : pal.bad;
    final sign = payment.income ? '+' : '−';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(color: pal.panel2, borderRadius: BorderRadius.circular(context.radius(11))),
            child: Column(
              children: <Widget>[
                Text('${payment.due.day}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.1)),
                Text(
                  _monthNames[payment.due.month - 1].toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: context.mutedColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(payment.label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(payment.property, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: context.mutedColor)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('$sign${_money(payment.amount)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _IncomeChart extends StatelessWidget {
  const _IncomeChart({required this.data});

  final _Portfolio data;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final values = data.history;
    final peak = values.fold<int>(1, (max, v) => v > max ? v : max);
    final last = values.length - 1;
    const barArea = 120.0;
    return PCard(
      padding: EdgeInsets.fromLTRB(context.isCompact ? 14 : 22, 22, context.isCompact ? 14 : 22, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Tooltip(
                message: _money(values[i]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _short(values[i]),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: i == last ? FontWeight.w800 : FontWeight.w600,
                        color: i == last ? pal.accent : context.mutedColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: barArea * values[i] / peak,
                      margin: const EdgeInsets.symmetric(horizontal: 7),
                      decoration: BoxDecoration(
                        color: i == last ? pal.accent : pal.accent.op(0.26),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(context.radius(8))),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _monthNames[DateTime(data.now.year, data.now.month - (last - i)).month - 1],
                      style: TextStyle(fontSize: 12.5, fontWeight: i == last ? FontWeight.w800 : FontWeight.w500, color: context.mutedColor),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SampleNote extends StatelessWidget {
  const _SampleNote();

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return PCard(
      color: pal.accentSoft,
      borderColor: pal.accent.op(0.25),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, color: pal.accent, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'These figures are sample data. Your real properties, rent and maintenance will appear here '
              'once those services are connected.',
              style: TextStyle(fontSize: 13.5, height: 1.55, color: context.inkColor),
            ),
          ),
        ],
      ),
    );
  }
}
