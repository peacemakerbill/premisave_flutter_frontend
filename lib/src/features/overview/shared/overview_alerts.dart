import 'package:flutter/material.dart';

import '../../../core/theme/brand.dart';
import '../../../core/theme/palette.dart';
import '../../../core/widgets/widgets.dart';
import 'overview_tone.dart';

/// Something that needs a person's attention: what it is, how serious it feels and a line of detail.
class OverviewAlert {
  const OverviewAlert({required this.icon, required this.tone, required this.title, required this.detail});

  final IconData icon;
  final OverviewTone tone;
  final String title;
  final String detail;
}

/// Alert cards in as many columns as fit, or a calm "all clear" card when there is nothing to flag.
class OverviewAlerts extends StatelessWidget {
  const OverviewAlerts({super.key, required this.alerts, this.allClearMessage = 'All clear. Nothing needs your attention right now.'});

  final List<OverviewAlert> alerts;
  final String allClearMessage;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return PCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            IconBadge(Icons.check_circle_outline_rounded, size: 44, color: context.pal.good),
            const SizedBox(width: 16),
            Expanded(
              child: Text(allClearMessage, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.4)),
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

  final OverviewAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = alert.tone.color(context.pal);
    return PCard(
      color: color.op(0.07),
      borderColor: color.op(0.32),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IconBadge(alert.icon, size: 40, color: color),
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
