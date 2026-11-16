import 'package:flutter/material.dart';

import '../../core/theme/brand.dart';
import '../../core/utils/validators.dart';

/// Four-segment strength bar shown under a new-password field.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final s = passwordStrength(password);
    final color = s <= 1 ? Brand.danger : (s == 2 ? Brand.warning : Brand.success);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: <Widget>[
          for (var i = 1; i <= 4; i++)
            Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i == 4 ? 0 : 5),
                decoration: BoxDecoration(
                  color: i <= s ? color : context.borderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          const SizedBox(width: 10),
          Text(passwordStrengthLabel(s), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
