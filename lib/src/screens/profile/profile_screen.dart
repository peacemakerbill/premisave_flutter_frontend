import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/auth/user_model.dart';
import '../../providers/auth/auth_provider.dart';
import 'widgets/edit_profile_form.dart';
import 'widgets/profile_completion_bar.dart';
import 'widgets/user_avatar.dart';
import 'widgets/change_password_dialog.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _picker = ImagePicker();
  bool _isUploading = false;

  double _completion(UserModel? u) {
    if (u == null) return 0;
    final fields = [
      u.username.isNotEmpty, u.firstName.isNotEmpty, u.lastName.isNotEmpty,
      u.phoneNumber.isNotEmpty, u.address1.isNotEmpty, u.address2.isNotEmpty,
      u.country.isNotEmpty, u.language.isNotEmpty,
      (u.profilePictureUrl?.isNotEmpty ?? false),
    ];
    return fields.where((f) => f).length / fields.length * 100;
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 800, maxHeight: 800);
    if (picked == null || !mounted) return;
    setState(() => _isUploading = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _UploadingDialog(),
    );
    try {
      await ref.read(authProvider.notifier).uploadProfilePicture(picked);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showEditSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(
        user: user,
        onSuccess: () => setState(() {}),
      ),
    );
  }

  void _showPasswordDialog() =>
      showDialog(context: context, builder: (_) => const ChangePasswordDialog());

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;
    final wide = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: _stone,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEAE6DE)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _brand),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Profile',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _brand, letterSpacing: -0.3)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: _slate, size: 20),
            onPressed: () => ref.read(authProvider.notifier).confirmLogout(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: user == null
          ? _Shimmer()
          : RefreshIndicator(
        color: _brand,
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 20, vertical: 24),
          child: wide
              ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 280, child: _LeftColumn(user: user, isUploading: _isUploading, onPickImage: _pickImage, completion: _completion(user))),
              const SizedBox(width: 20),
              Expanded(child: _RightColumn(user: user, onEdit: () => _showEditSheet(context, user), onPassword: _showPasswordDialog)),
            ],
          )
              : Column(
            children: [
              _HeroCard(user: user, isUploading: _isUploading, onPickImage: _pickImage),
              const SizedBox(height: 16),
              _CompletionCard(pct: _completion(user), onTap: () => _showEditSheet(context, user)),
              const SizedBox(height: 16),
              _InfoCard(user: user),
              const SizedBox(height: 16),
              _ActionsCard(onEdit: () => _showEditSheet(context, user), onPassword: _showPasswordDialog),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Upload Dialog ──────────────────────────────────────────────────────────

class _UploadingDialog extends StatelessWidget {
  const _UploadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _brand, strokeWidth: 2.5),
            SizedBox(height: 16),
            Text('Uploading photo…', style: TextStyle(fontSize: 14, color: _slate)),
          ],
        ),
      ),
    );
  }
}

// ── Edit Bottom Sheet ──────────────────────────────────────────────────────

class _EditSheet extends StatelessWidget {
  final UserModel user;
  final VoidCallback onSuccess;
  const _EditSheet({required this.user, required this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFEAE6DE), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _brand, letterSpacing: -0.4)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: _stone, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.close_rounded, size: 18, color: _slate),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Divider(color: Color(0xFFEAE6DE)),
            Expanded(
              child: EditProfileForm(
                scrollController: ctrl,
                onSuccess: () { Navigator.pop(context); onSuccess(); },
                initialData: {
                  'username': user.username, 'firstName': user.firstName,
                  'middleName': user.middleName, 'lastName': user.lastName,
                  'phoneNumber': user.phoneNumber, 'address1': user.address1,
                  'address2': user.address2, 'country': user.country, 'language': user.language,
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Layout blocks ─────────────────────────────────────────────────────────

class _LeftColumn extends StatelessWidget {
  final UserModel user;
  final bool isUploading;
  final VoidCallback onPickImage;
  final double completion;
  const _LeftColumn({required this.user, required this.isUploading, required this.onPickImage, required this.completion});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeroCard(user: user, isUploading: isUploading, onPickImage: onPickImage),
        const SizedBox(height: 16),
        _CompletionCard(pct: completion, onTap: () {}),
      ],
    );
  }
}

class _RightColumn extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit, onPassword;
  const _RightColumn({required this.user, required this.onEdit, required this.onPassword});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoCard(user: user),
        const SizedBox(height: 16),
        _ActionsCard(onEdit: onEdit, onPassword: onPassword),
      ],
    );
  }
}

// ── Hero Card ──────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final UserModel user;
  final bool isUploading;
  final VoidCallback onPickImage;
  const _HeroCard({required this.user, required this.isUploading, required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: _brand,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: isUploading ? null : onPickImage,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _gold, width: 2.5),
                  ),
                  child: UserAvatar(
                    imageUrl: user.profilePictureUrl?.isNotEmpty == true ? user.profilePictureUrl : null,
                    radius: 44,
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: _gold, shape: BoxShape.circle, border: Border.all(color: _brand, width: 2)),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('${user.firstName} ${user.lastName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
          if (user.username.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('@${user.username}',
                style: const TextStyle(fontSize: 13, color: _gold, fontWeight: FontWeight.w500)),
          ],
          const SizedBox(height: 6),
          Text(user.email,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9DC4B8))),
        ],
      ),
    );
  }
}

// ── Completion Card ────────────────────────────────────────────────────────

class _CompletionCard extends StatelessWidget {
  final double pct;
  final VoidCallback onTap;
  const _CompletionCard({required this.pct, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Profile strength', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _brand)),
              Text('${pct.toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _gold)),
            ],
          ),
          const SizedBox(height: 10),
          ProfileCompletionBar(percentage: pct),
          if (pct < 100) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onTap,
              child: const Text('Complete your profile →',
                  style: TextStyle(fontSize: 12, color: _gold, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Info Card ──────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final UserModel user;
  const _InfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final rows = [
      if (user.email.isNotEmpty) _Row(Icons.mail_outline_rounded, 'Email', user.email),
      if (user.phoneNumber.isNotEmpty) _Row(Icons.phone_outlined, 'Phone', user.phoneNumber),
      if (user.address1.isNotEmpty) _Row(Icons.home_outlined, 'Address', user.address1),
      if (user.country.isNotEmpty) _Row(Icons.location_on_outlined, 'Country', user.country),
      if (user.language.isNotEmpty) _Row(Icons.language_rounded, 'Language', user.language),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _brand, letterSpacing: -0.2)),
          const SizedBox(height: 4),
          const Divider(color: Color(0xFFEAE6DE)),
          ...rows.map((r) => _InfoRow(row: r)),
        ],
      ),
    );
  }
}

class _Row { final IconData icon; final String label, value; const _Row(this.icon, this.label, this.value); }

class _InfoRow extends StatelessWidget {
  final _Row row;
  const _InfoRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(row.icon, size: 17, color: _gold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.label, style: const TextStyle(fontSize: 11, color: _slate)),
                Text(row.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _brand)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Actions Card ───────────────────────────────────────────────────────────

class _ActionsCard extends StatelessWidget {
  final VoidCallback onEdit, onPassword;
  const _ActionsCard({required this.onEdit, required this.onPassword});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _ActionTile(icon: Icons.person_outline_rounded, label: 'Edit Profile', sub: 'Update your information', onTap: onEdit),
          const Divider(height: 1, indent: 56, color: Color(0xFFEAE6DE)),
          _ActionTile(icon: Icons.lock_outline_rounded, label: 'Change Password', sub: 'Update security credentials', onTap: onPassword, iconColor: _gold),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final VoidCallback onTap;
  final Color iconColor;
  const _ActionTile({required this.icon, required this.label, required this.sub, required this.onTap, this.iconColor = _brand});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _brand)),
                  Text(sub, style: const TextStyle(fontSize: 11, color: _slate)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: _slate),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer ────────────────────────────────────────────────────────────────

class _Shimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEAE6DE),
      highlightColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 16),
          Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 16),
          Container(height: 220, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
        ]),
      ),
    );
  }
}