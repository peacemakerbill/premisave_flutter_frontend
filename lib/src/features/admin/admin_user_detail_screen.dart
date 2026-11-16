import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/user_model.dart';
import '../../state/data_providers.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';
import '../../core/theme/palette.dart';

/// Administrators: one account, with every management action.
class AdminUserDetailScreen extends ConsumerStatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  bool _busy = false;

  void _reload() {
    ref.invalidate(adminUserProvider(widget.userId));
    ref.invalidate(adminUsersProvider);
  }

  Future<void> _run(Future<String> Function() call, {String? fallback}) async {
    setState(() => _busy = true);
    try {
      final message = await call();
      _reload();
      if (mounted) showToast(context, message.isEmpty ? (fallback ?? 'Done') : message);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeRole(UserModel u) async {
    final picked = await showModalBottomSheet<Role>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: <Widget>[
          const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text('Change role', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          for (final r in Role.values)
            ListTile(
              title: Text(r.label, style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: r == u.role ? const Icon(Icons.check_rounded) : null,
              onTap: () => Navigator.of(ctx).pop(r),
            ),
        ],
      ),
    );
    if (picked == null || picked == u.role || !mounted) return;
    final ok = await confirmDialog(
      context,
      title: 'Make ${u.displayName} ${picked.label.toLowerCase()}?',
      message: 'Their permissions change the next time they sign in or refresh.',
      confirmLabel: 'Change role',
    );
    if (!ok) return;
    await _run(() => ref.read(adminRepositoryProvider).changeRole(u.id, picked));
  }

  Future<void> _confirmThen(UserModel u, {required String title, required String message, required String label, required Future<String> Function() call, bool danger = false}) async {
    final ok = await confirmDialog(context, title: title, message: message, confirmLabel: label, danger: danger);
    if (!ok) return;
    await _run(call);
  }

  Future<void> _delete(UserModel u) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete ${u.displayName}?',
      message: 'This permanently removes the account and cannot be undone. Archive the account instead if you may need it later.',
      confirmLabel: 'Delete permanently',
      danger: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      final message = await ref.read(adminRepositoryProvider).delete(u.id);
      ref.invalidate(adminUsersProvider);
      if (!mounted) return;
      showToast(context, message);
      context.go('/admin/users');
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(adminUserProvider(widget.userId));
    final me = ref.watch(sessionProvider).user;
    final repo = ref.read(adminRepositoryProvider);

    return SubPage(
      title: 'User',
      fallbackRoute: '/admin/users',
      body: AsyncBody<UserModel>(
        value: value,
        onRetry: _reload,
        builder: (u) {
          final self = me?.id == u.id;
          return PageBody(
            maxWidth: 760,
            onRefresh: () async => _reload(),
            children: <Widget>[
              Center(child: UserAvatar(initials: u.initials, imageUrl: u.profilePictureUrl, size: 88, ring: true)),
              const SizedBox(height: 12),
              Center(child: Text(u.fullName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.4))),
              if (u.username.isNotEmpty) Center(child: Text('@${u.username}', style: TextStyle(color: context.mutedColor, fontWeight: FontWeight.w600))),
              const SizedBox(height: 12),
              Center(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    StatusPill(u.role.label, color: context.pal.accent),
                    StatusPill(u.active ? 'Active' : 'Inactive', color: u.active ? Brand.success : Brand.danger),
                    StatusPill(u.verified ? 'Verified' : 'Not verified', color: u.verified ? Brand.success : Brand.warning),
                    if (u.archived) const StatusPill('Archived', color: Brand.muted),
                  ],
                ),
              ),
              if (self) const Padding(padding: EdgeInsets.only(top: 14), child: InlineMessage('This is your own account. Role and status changes are blocked to keep you from locking yourself out.')),
              const SectionHeader('Details'),
              PCard(
                child: Column(
                  children: <Widget>[
                    InfoRow('Email', u.email, icon: Icons.mail_outline_rounded),
                    InfoRow('Phone', u.phoneNumber.isEmpty ? null : u.phoneNumber, icon: Icons.phone_outlined),
                    InfoRow('Country', u.country.isEmpty ? null : u.country, icon: Icons.public_rounded),
                    InfoRow('Address', <String>[u.address1, u.address2].where((p) => p.isNotEmpty).join(', '), icon: Icons.place_outlined),
                    InfoRow('Language', sentence(u.language), icon: Icons.translate_rounded),
                    InfoRow('User ID', u.id, icon: Icons.tag_rounded),
                  ],
                ),
              ),
              const SectionHeader('Manage'),
              MenuGroup(
                children: <Widget>[
                  MenuTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Change role',
                    subtitle: 'Currently ${u.role.label}',
                    onTap: self || _busy ? null : () => _changeRole(u),
                  ),
                  MenuTile(
                    icon: u.active ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                    title: u.active ? 'Deactivate' : 'Activate',
                    subtitle: u.active ? 'Blocks sign in until reactivated' : 'Lets them sign in again',
                    onTap: self || _busy
                        ? null
                        : () => u.active
                            ? _confirmThen(u, title: 'Deactivate ${u.displayName}?', message: 'They are signed out and cannot sign in until you activate the account again.', label: 'Deactivate', call: () => repo.deactivate(u.id), danger: true)
                            : _run(() => repo.activate(u.id)),
                  ),
                  MenuTile(
                    icon: u.verified ? Icons.gpp_maybe_outlined : Icons.verified_outlined,
                    title: u.verified ? 'Mark as not verified' : 'Mark as verified',
                    subtitle: u.verified ? 'They must confirm their email again' : 'Skips email confirmation',
                    onTap: _busy ? null : () => _run(() => u.verified ? repo.unverify(u.id) : repo.verify(u.id)),
                  ),
                  MenuTile(
                    icon: Icons.lock_reset_rounded,
                    title: 'Send password reset',
                    subtitle: 'Emails them a link to choose a new password',
                    onTap: _busy ? null : () => _confirmThen(u, title: 'Send a reset email?', message: 'A password reset link goes to ${u.email}.', label: 'Send', call: () => repo.resetPassword(u.id)),
                  ),
                  MenuTile(
                    icon: u.archived ? Icons.unarchive_outlined : Icons.archive_outlined,
                    title: u.archived ? 'Restore from archive' : 'Archive',
                    subtitle: u.archived ? 'Brings the account back' : 'Hides the account without deleting it',
                    onTap: self || _busy ? null : () => u.archived ? _run(() => repo.unarchive(u.id)) : _confirmThen(u, title: 'Archive ${u.displayName}?', message: 'The account is hidden and cannot sign in. You can restore it later.', label: 'Archive', call: () => repo.archive(u.id)),
                  ),
                  MenuTile(
                    icon: Icons.delete_outline_rounded,
                    tint: Brand.danger,
                    title: 'Delete permanently',
                    subtitle: 'Cannot be undone',
                    onTap: self || _busy ? null : () => _delete(u),
                  ),
                ],
              ),
              const SectionHeader('Activity'),
              MenuGroup(
                children: <Widget>[
                  MenuTile(
                    icon: Icons.fact_check_outlined,
                    title: 'Security events for this user',
                    onTap: () => context.push('/admin/audit?userId=${Uri.encodeComponent(u.id)}'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
