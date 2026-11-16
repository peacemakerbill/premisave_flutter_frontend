import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/user_model.dart';
import '../../state/session_controller.dart';
import '../../core/theme/palette.dart';

/// Account hub: profile, security, preferences and sign out.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    if (user == null) return const LoadingState();

    return SafeArea(
      bottom: false,
      child: PageBody(
        onRefresh: () => ref.read(sessionProvider.notifier).refreshUser(),
        children: <Widget>[
          const PageTitle('Account'),
          PCard(
            onTap: () => context.push('/account/profile'),
            child: Row(
              children: <Widget>[
                UserAvatar(initials: user.initials, imageUrl: user.profilePictureUrl, size: 62),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(user.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: context.mutedColor)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: <Widget>[
                          StatusPill(user.role.label, color: context.pal.accent, dense: true),
                          StatusPill(user.verified ? 'Verified' : 'Not verified', color: user.verified ? Brand.success : Brand.warning, dense: true),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: context.mutedColor),
              ],
            ),
          ),
          const SectionHeader('Profile'),
          MenuGroup(
            children: <Widget>[
              MenuTile(icon: Icons.person_outline_rounded, title: 'View profile', subtitle: 'How others see you', onTap: () => context.push('/account/profile')),
              MenuTile(icon: Icons.edit_outlined, title: 'Edit profile', subtitle: 'Name, phone, address and photo', onTap: () => context.push('/account/profile/edit')),
              MenuTile(icon: Icons.place_outlined, title: 'My location', subtitle: 'Save where you are', onTap: () => context.push('/account/location')),
              MenuTile(icon: Icons.visibility_outlined, title: 'Profile views', subtitle: 'Who looked at your profile', onTap: () => context.push('/account/views')),
            ],
          ),
          const SectionHeader('Security'),
          MenuGroup(
            children: <Widget>[
              MenuTile(
                icon: Icons.shield_outlined,
                title: 'Security center',
                subtitle: 'Sessions, devices and sign-in history',
                onTap: () => context.push('/account/security'),
              ),
              MenuTile(icon: Icons.password_rounded, title: 'Change password', onTap: () => context.push('/account/password')),
            ],
          ),
          if (user.role == Role.client || user.role == Role.homeOwner) ...<Widget>[
            const SectionHeader('Hosting'),
            MenuGroup(
              children: <Widget>[
                MenuTile(
                  icon: Icons.home_work_outlined,
                  title: user.role == Role.homeOwner ? 'Home owner application' : 'Become a home owner',
                  subtitle: user.role == Role.homeOwner ? 'Your approved application' : 'Apply to list your properties',
                  onTap: () => context.push('/application'),
                ),
              ],
            ),
          ],
          if (user.role == Role.admin) ...<Widget>[
            const SectionHeader('Administration'),
            MenuGroup(
              children: <Widget>[
                MenuTile(icon: Icons.manage_accounts_outlined, title: 'Users', onTap: () => context.go('/admin/users')),
                MenuTile(icon: Icons.history_edu_outlined, title: 'Security audit trail', onTap: () => context.push('/admin/audit')),
              ],
            ),
          ],
          const SectionHeader('App'),
          MenuGroup(
            children: <Widget>[
              MenuTile(icon: Icons.palette_outlined, title: 'Appearance', subtitle: '14 themes, 9 fonts, corner styles', onTap: () => context.push('/account/settings')),
              MenuTile(icon: Icons.info_outline_rounded, title: 'About Premisave', onTap: () => context.push('/home/about')),
              MenuTile(icon: Icons.support_agent_outlined, title: 'Contact us', onTap: () => context.push('/home/contact')),
            ],
          ),
          const SizedBox(height: 22),
          PButton(
            label: 'Sign out',
            icon: Icons.logout_rounded,
            kind: PButtonKind.outline,
            expand: true,
            onPressed: () async {
              final ok = await confirmDialog(
                context,
                title: 'Sign out?',
                message: 'You will need to sign in again on this device.',
                confirmLabel: 'Sign out',
              );
              if (ok) await ref.read(sessionProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }
}
