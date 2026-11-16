import 'package:flutter/material.dart';

import '../../../core/theme/brand.dart';
import '../../../core/theme/palette.dart';
import '../../../core/widgets/widgets.dart';
import 'overview_format.dart';

/// Simple bar chart drawn with plain widgets. The last bar is highlighted as the current period.
class OverviewBarChart extends StatelessWidget {
  const OverviewBarChart({super.key, required this.values, required this.labels, this.valueLabel, this.tooltip})
      : assert(values.length == labels.length);

  final List<num> values;
  final List<String> labels;

  /// Text above each bar. Defaults to a short form such as "95K".
  final String Function(num value)? valueLabel;

  /// Text shown on hover or long press. Defaults to the full amount with its currency.
  final String Function(num value)? tooltip;

  static const double _barArea = 120;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final peak = values.fold<num>(1, (max, v) => v > max ? v : max);
    final last = values.length - 1;
    final top = valueLabel ?? overviewShort;
    final hint = tooltip ?? overviewMoney;
    return PCard(
      padding: EdgeInsets.fromLTRB(context.isCompact ? 14 : 22, 22, context.isCompact ? 14 : 22, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Tooltip(
                message: hint(values[i]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      top(values[i]),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: i == last ? FontWeight.w800 : FontWeight.w600,
                        color: i == last ? pal.accent : context.mutedColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: _barArea * values[i] / peak,
                      margin: const EdgeInsets.symmetric(horizontal: 7),
                      decoration: BoxDecoration(
                        color: i == last ? pal.accent : pal.accent.op(0.26),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(context.radius(8))),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labels[i],
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
