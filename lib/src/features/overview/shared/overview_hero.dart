import 'package:flutter/material.dart';

import '../../../core/theme/brand.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/user_model.dart';
import '../../../roles/role.dart';

/// One headline figure in the hero: a label, a big value and a short caption.
class OverviewMetric {
  const OverviewMetric(this.label, this.value, this.caption);

  final String label;
  final String value;
  final String caption;
}

/// The top of every role's overview: a greeting, status labels, up to four headline figures and shortcuts.
class OverviewHero extends StatelessWidget {
  const OverviewHero({
    super.key,
    required this.role,
    required this.user,
    required this.message,
    required this.metrics,
    this.actions = const <Widget>[],
  });

  final Role role;
  final UserModel? user;
  final String message;
  final List<OverviewMetric> metrics;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final u = user;
    final name = u == null ? '' : (u.firstName.isEmpty ? u.displayName : u.firstName);
    final title = name.isEmpty ? greeting() : '${greeting()}, $name';
    return HeroPanel(
      padding: EdgeInsets.fromLTRB(compact ? 22 : 36, compact ? 24 : 34, compact ? 22 : 36, compact ? 22 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              StatusPill(role.label, color: Brand.gold, icon: Icons.badge_outlined),
              if (u != null && u.verified) const StatusPill('Verified', color: Color(0xFF5FD39A), icon: Icons.verified_rounded),
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
          Text(message, style: TextStyle(fontSize: compact ? 14.5 : 16, height: 1.5, color: Brand.cream.op(0.88))),
          if (metrics.isNotEmpty) ...<Widget>[
            SizedBox(height: compact ? 22 : 28),
            _MetricPanel(metrics: metrics),
          ],
          if (actions.isNotEmpty) ...<Widget>[
            const SizedBox(height: 22),
            Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
        ],
      ),
    );
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({required this.metrics});

  final List<OverviewMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    // Four figures do not fit in one row on a phone, so they wrap into two columns.
    final stacked = compact && metrics.length > 3;
    final Widget content;
    if (stacked) {
      content = LayoutBuilder(
        builder: (context, constraints) {
          const gap = 18.0;
          final width = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: 18,
            children: <Widget>[for (final m in metrics) SizedBox(width: width, child: _MetricView(m, compact: true))],
          );
        },
      );
    } else {
      content = Row(
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
            Expanded(child: _MetricView(metrics[i], compact: compact)),
          ],
        ],
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 22, vertical: compact ? 14 : 18),
      decoration: BoxDecoration(
        color: Brand.cream.op(0.1),
        borderRadius: BorderRadius.circular(context.radius(16)),
        border: Border.all(color: Brand.cream.op(0.18)),
      ),
      child: content,
    );
  }
}

class _MetricView extends StatelessWidget {
  const _MetricView(this.metric, {required this.compact});

  final OverviewMetric metric;
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
        Text(
          metric.caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12.5, height: 1.35, color: Brand.cream.op(0.8)),
        ),
      ],
    );
  }
}
