import 'package:flutter/material.dart';

import '../../../core/theme/brand.dart';
import '../../../core/theme/palette.dart';
import '../../../core/widgets/widgets.dart';

/// Footnote that says the figures on an overview are sample data. Remove it from a role's overview
/// once that role's figures come from a real service.
class SampleDataNote extends StatelessWidget {
  const SampleDataNote({
    super.key,
    this.message = 'These figures are sample data. Your real figures will appear here once the matching services are connected.',
  });

  final String message;

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
          Expanded(child: Text(message, style: TextStyle(fontSize: 13.5, height: 1.55, color: context.inkColor))),
        ],
      ),
    );
  }
}
