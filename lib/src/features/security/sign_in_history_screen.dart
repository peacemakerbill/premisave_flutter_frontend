import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/security_models.dart';
import '../../state/data_providers.dart';

/// One row of sign-in history, with risk hints.
class SignInTile extends StatelessWidget {
  const SignInTile({super.key, required this.signIn});

  final SignInView signIn;

  @override
  Widget build(BuildContext context) {
    final s = signIn;
    final tint = s.risky ? Brand.warning : (s.newDevice ? Brand.info : Brand.success);
    final lines = <String>[
      '${s.place}${s.ipAddress != null ? ' · ${s.ipAddress}' : ''}',
      if (s.method != null) sentence(s.method),
      if (s.riskReasons.isNotEmpty) s.riskReasons.join(', '),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: tint.op(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(s.risky ? Icons.gpp_maybe_outlined : Icons.login_rounded, size: 19, color: tint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(child: Text(s.deviceLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                    if (s.newDevice) ...<Widget>[const SizedBox(width: 8), const StatusPill('New device', color: Brand.info, dense: true)],
                  ],
                ),
                const SizedBox(height: 3),
                for (final l in lines) Text(l, style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                const SizedBox(height: 2),
                Text(whenLabel(s.at), style: TextStyle(fontSize: 12, color: context.mutedColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SignInHistoryScreen extends ConsumerWidget {
  const SignInHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(signInsProvider);
    return SubPage(
      title: 'Sign-in history',
      fallbackRoute: '/account/security',
      body: AsyncBody<List<SignInView>>(
        value: value,
        onRetry: () => ref.invalidate(signInsProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.history_rounded,
              title: 'No sign-ins recorded',
              message: 'Each time you sign in, the device and place are recorded here.',
            );
          }
          return PageBody(
            maxWidth: 760,
            onRefresh: () async => ref.invalidate(signInsProvider),
            children: <Widget>[MenuGroup(children: <Widget>[for (final s in items) SignInTile(signIn: s)])],
          );
        },
      ),
    );
  }
}
