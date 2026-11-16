import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/widgets/widgets.dart';
import '../../state/data_providers.dart';
import '../../state/session_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    final stats = ref.watch(myStatsProvider);

    return SubPage(
      title: 'Profile',
      fallbackRoute: '/account',
      actions: <Widget>[
        IconButton(
          tooltip: 'Edit profile',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => context.push('/account/profile/edit'),
        ),
      ],
      body: user == null
          ? const LoadingState()
          : PageBody(
              onRefresh: () => ref.read(sessionProvider.notifier).refreshUser(),
              maxWidth: 720,
              children: <Widget>[
                Center(child: UserAvatar(initials: user.initials, imageUrl: user.profilePictureUrl, size: 96, ring: true)),
                const SizedBox(height: 14),
                Center(child: Text(user.fullName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5))),
                if (user.username.isNotEmpty)
                  Center(child: Text('@${user.username}', style: TextStyle(color: context.mutedColor, fontWeight: FontWeight.w600))),
                const SizedBox(height: 12),
                Center(
                  child: Wrap(
                    spacing: 8,
                    children: <Widget>[
                      StatusPill(user.role.label, color: context.isDark ? Brand.gold : Brand.green),
                      StatusPill(user.verified ? 'Email verified' : 'Email not verified', color: user.verified ? Brand.success : Brand.warning),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                stats.maybeWhen(
                  data: (s) => ResponsiveWrap(
                    minItemWidth: 140,
                    children: <Widget>[
                      StatTile(label: 'Followers', value: '${(s.followers ?? 0).toInt()}', icon: Icons.group_outlined),
                      StatTile(label: 'Likes', value: '${(s.likes ?? 0).toInt()}', icon: Icons.favorite_border_rounded, tint: Brand.danger),
                      StatTile(label: 'Reviews', value: '${(s.reviews ?? 0).toInt()}', icon: Icons.star_outline_rounded, tint: Brand.warning),
                    ],
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SectionHeader('Details'),
                PCard(
                  child: Column(
                    children: <Widget>[
                      InfoRow('Email', user.email, icon: Icons.mail_outline_rounded),
                      InfoRow('Phone', user.phoneNumber, icon: Icons.phone_outlined),
                      InfoRow('Address', <String>[user.address1, user.address2].where((e) => e.isNotEmpty).join(', '), icon: Icons.home_outlined),
                      InfoRow('Country', user.country, icon: Icons.public_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                PButton(label: 'Edit profile', icon: Icons.edit_outlined, expand: true, onPressed: () => context.push('/account/profile/edit')),
              ],
            ),
    );
  }
}
