import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/security_models.dart';
import '../../data/models/user_model.dart';
import '../../roles/permissions.dart';
import '../../roles/role.dart';
import '../../roles/role_registry.dart';
import '../../state/data_providers.dart';
import '../../state/session_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(sessionsProvider);
    ref.invalidate(myStatsProvider);
    ref.invalidate(securityEventsProvider);
    ref.invalidate(myApplicationProvider);
    ref.invalidate(staffStatsProvider);
    try {
      await ref.read(sessionProvider.notifier).refreshUser();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    if (user == null) return const LoadingState();
    final role = user.role;

    return SafeArea(
      bottom: false,
      child: PageBody(
        onRefresh: () => _refresh(ref),
        children: <Widget>[
          _Hero(user: user),
          if (!user.verified) ...<Widget>[
            const SizedBox(height: 14),
            const InlineMessage(
              'Your email is not verified yet. Open the activation email we sent you to finish setting up.',
              kind: MessageKind.warning,
            ),
          ],
          const _SecurityGlance(),
          if (role.can(Capability.applyAsHomeOwner)) const _BecomeHomeOwnerCard(),
          if (role.can(Capability.viewHomeOwnerApplication)) const _HomeOwnerStatusCard(),
          if (role.can(Capability.reviewApplications)) const _StaffGlance(),
          const SectionHeader('Your workspace'),
          _Workspace(role: role),
          const SectionHeader('Your standing'),
          const _SocialGlance(),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return HeroPanel(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(greeting(), style: TextStyle(fontSize: 13.5, color: Brand.cream.op(0.75), fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  user.firstName.isEmpty ? user.displayName : user.firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1, color: Brand.cream, height: 1.1),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    StatusPill(user.role.label, color: Brand.gold, icon: Icons.badge_outlined),
                    if (user.verified) const StatusPill('Verified', color: Color(0xFF5FD39A), icon: Icons.verified_rounded),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.go('/account'),
            child: UserAvatar(initials: user.initials, imageUrl: user.profilePictureUrl, size: 64, ring: true),
          ),
        ],
      ),
    );
  }
}

/// Active sessions at a glance, with a nudge when something looks unfamiliar.
class _SecurityGlance extends ConsumerWidget {
  const _SecurityGlance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    final events = ref.watch(securityEventsProvider);

    final count = sessions.valueOrNull?.length;
    final alerts = (events.valueOrNull ?? <SecurityEventView>[]).where((e) => e.isWarning || e.isCritical).take(1).toList();

    if (count == null && alerts.isEmpty) return const SizedBox.shrink();

    final other = count == null ? 0 : (count - 1).clamp(0, 99);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: PCard(
        onTap: () => context.push('/account/security'),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (alerts.isEmpty ? Brand.success : Brand.warning).op(0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                alerts.isEmpty ? Icons.shield_outlined : Icons.warning_amber_rounded,
                color: alerts.isEmpty ? Brand.success : Brand.warning,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    alerts.isEmpty ? 'Your account looks secure' : alerts.first.title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alerts.isNotEmpty
                        ? 'Latest alert ${timeAgo(alerts.first.createdAt)}. Review your activity.'
                        : (other == 0 ? 'Only this device is signed in.' : '${plural(other, 'other session')} signed in.'),
                    style: TextStyle(fontSize: 12.5, color: context.mutedColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.mutedColor),
          ],
        ),
      ),
    );
  }
}

class _BecomeHomeOwnerCard extends ConsumerWidget {
  const _BecomeHomeOwnerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(myApplicationProvider);
    return app.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (a) {
        final started = a != null;
        final color = started ? colorFromHex(a.statusColor, fallback: Brand.gold) : Brand.gold;
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: PCard(
            onTap: () => context.push('/application'),
            borderColor: Brand.gold.op(0.5),
            child: Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: Brand.gold.op(0.16), borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.home_work_outlined, color: Brand.goldDeep),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(started ? 'Your home owner application' : 'Become a home owner',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 3),
                      if (started)
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            StatusPill(a.statusLabel, color: color, dense: true),
                            Text('${a.readiness.percent}% complete', style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                          ],
                        )
                      else
                        Text('List your properties and reach renters. Apply in a few minutes.',
                            style: TextStyle(fontSize: 12.5, height: 1.35, color: context.mutedColor)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: context.mutedColor),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeOwnerStatusCard extends StatelessWidget {
  const _HomeOwnerStatusCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: PCard(
        onTap: () => context.push('/application'),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: Brand.success.op(0.13), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.verified_rounded, color: Brand.success),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Verified home owner', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                  SizedBox(height: 2),
                  Text('Your application was approved. View its record.', style: TextStyle(fontSize: 12.5)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.mutedColor),
          ],
        ),
      ),
    );
  }
}

class _StaffGlance extends ConsumerWidget {
  const _StaffGlance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(staffStatsProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: stats.when(
        loading: () => const SkeletonList(count: 1, height: 110, shrink: true, padding: EdgeInsets.zero),
        error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(staffStatsProvider)),
        data: (s) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader('Review queue', padding: EdgeInsets.only(bottom: 12)),
            ResponsiveWrap(
              minItemWidth: 150,
              children: <Widget>[
                StatTile(label: 'Awaiting review', value: '${s.awaitingReview}', icon: Icons.hourglass_top_rounded, tint: Brand.info, onTap: () => context.go('/staff')),
                StatTile(label: 'Unassigned', value: '${s.unassigned}', icon: Icons.person_search_outlined, tint: Brand.warning, onTap: () => context.go('/staff')),
                StatTile(label: 'Assigned to me', value: '${s.assignedToMe}', icon: Icons.assignment_ind_outlined, onTap: () => context.go('/staff')),
                StatTile(label: 'Ready to approve', value: '${s.readyToPromote}', icon: Icons.task_alt_rounded, tint: Brand.success, onTap: () => context.go('/staff')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Workspace extends StatelessWidget {
  const _Workspace({required this.role});

  final Role role;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      MenuTile(
        icon: Icons.dashboard_outlined,
        title: role.overviewTitle,
        subtitle: 'Summary and shortcuts',
        onTap: () => context.push('/home/overview'),
      ),
      if (role.can(Capability.useClientWorkspace)) ...<Widget>[
        MenuTile(icon: Icons.event_available_outlined, title: 'Bookings', subtitle: 'Stays and viewings', onTap: () => context.push('/home/bookings')),
        MenuTile(icon: Icons.favorite_border_rounded, title: 'Wishlists', subtitle: 'Places you saved', onTap: () => context.push('/home/wishlists')),
        MenuTile(icon: Icons.chat_bubble_outline_rounded, title: 'Messages', subtitle: 'Talk to owners and support', onTap: () => context.push('/home/messages')),
        MenuTile(icon: Icons.account_balance_wallet_outlined, title: 'Payments', subtitle: 'Methods and upcoming payments', onTap: () => context.push('/home/payments')),
        MenuTile(icon: Icons.receipt_long_outlined, title: 'Transactions', subtitle: 'Your payment history', onTap: () => context.push('/home/transactions')),
      ],
      MenuTile(icon: Icons.info_outline_rounded, title: 'About Premisave', onTap: () => context.push('/home/about')),
      MenuTile(icon: Icons.support_agent_outlined, title: 'Contact us', onTap: () => context.push('/home/contact')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MenuGroup(children: items),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text(
            'Bookings, payments and messages show sample data until those services are connected.',
            style: TextStyle(fontSize: 12, color: context.mutedColor),
          ),
        ),
      ],
    );
  }
}

class _SocialGlance extends ConsumerWidget {
  const _SocialGlance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(myStatsProvider);
    return stats.when(
      loading: () => const SkeletonList(count: 1, height: 100, shrink: true, padding: EdgeInsets.zero),
      error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(myStatsProvider)),
      data: (s) {
        String fmt(num? n) => n == null ? '0' : n.toInt().toString();
        return ResponsiveWrap(
          minItemWidth: 150,
          children: <Widget>[
            StatTile(label: 'Followers', value: fmt(s.followers), icon: Icons.group_outlined, onTap: () => context.go('/people')),
            StatTile(label: 'Likes', value: fmt(s.likes), icon: Icons.favorite_border_rounded, tint: Brand.danger, onTap: () => context.go('/people')),
            StatTile(label: 'Reviews', value: fmt(s.reviews), icon: Icons.star_outline_rounded, tint: Brand.warning, onTap: () => context.go('/people')),
            StatTile(label: 'Profile views', value: fmt(s.views), icon: Icons.visibility_outlined, tint: Brand.info, onTap: () => context.push('/account/views')),
          ],
        );
      },
    );
  }
}
