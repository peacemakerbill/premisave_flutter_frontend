import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/social/social_provider.dart';
import 'profile_reviews_section.dart';

const _brand = Color(0xFF1A3C34);
const _gold  = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);

class OtherUserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const OtherUserProfileScreen({super.key, required this.userId});
  @override
  ConsumerState<OtherUserProfileScreen> createState() => _State();
}

class _State extends ConsumerState<OtherUserProfileScreen> {
  PublicUserProfile? _profile;
  UserStats? _stats;
  bool _loadingProfile = true;
  bool _loadingStats = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final n = ref.read(socialProvider.notifier);
    n.recordProfileView(widget.userId);
    final p = await n.getUserProfile(widget.userId);
    if (!mounted) return;
    setState(() { _profile = p; _loadingProfile = false; _error = p == null ? 'Profile not found' : null; });
    final s = await n.getUserStats(widget.userId);
    if (!mounted) return;
    setState(() { _stats = s; _loadingStats = false; });
  }

  @override
  Widget build(BuildContext context) {
    final ss   = ref.watch(socialProvider);
    final me   = ref.watch(authProvider).currentUser;
    final isOwn = _profile?.id == me?.id;

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _loadingProfile ? 'Profile' : (_profile?.fullName ?? 'Profile'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _brand, letterSpacing: -0.3),
        ),
        centerTitle: true,
        actions: [
          if (!_loadingProfile && _profile != null && !isOwn)
            _LikeButton(
              profileId: _profile!.id,
              isLiked: ss.likedUserIds.contains(_profile!.id),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loadingProfile
          ? const _Shimmer()
          : _error != null
          ? _ErrorView(error: _error!, onRetry: () { setState(() { _loadingProfile = true; _error = null; }); _load(); })
          : RefreshIndicator(
        color: _brand,
        onRefresh: () async { setState(() { _loadingProfile = true; }); await _load(); },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(children: [
            _HeroCard(profile: _profile!),
            const SizedBox(height: 16),
            _StatsCard(stats: _stats, loading: _loadingStats),
            const SizedBox(height: 16),
            if (!isOwn) ...[
              _SocialCard(
                profile: _profile!,
                isLiked: ss.likedUserIds.contains(_profile!.id),
                isFollowing: ss.followingUserIds.contains(_profile!.id),
              ),
              const SizedBox(height: 16),
            ],
            _DetailsCard(profile: _profile!),
            const SizedBox(height: 16),
            ReviewsSection(targetId: _profile!.id, isOwnProfile: isOwn),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}

// ── Hero Card (mirrors _HeroCard from own profile) ────────────────────────

class _HeroCard extends StatelessWidget {
  final PublicUserProfile profile;
  const _HeroCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(color: _brand, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        // Avatar with gold ring
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _gold, width: 2.5),
          ),
          child: CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0xFF2A5446),
            backgroundImage: (profile.profilePictureUrl?.isNotEmpty ?? false)
                ? CachedNetworkImageProvider(profile.profilePictureUrl!) as ImageProvider
                : null,
            child: (profile.profilePictureUrl?.isNotEmpty ?? false)
                ? null
                : Text(
              profile.firstName.isNotEmpty ? profile.firstName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF9DC4B8)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Name
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${profile.firstName} ${profile.lastName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  color: Colors.white, letterSpacing: -0.5)),
          if (profile.verified) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 11, color: Colors.white),
            ),
          ],
        ]),
        if (profile.username.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('@${profile.username}',
              style: const TextStyle(fontSize: 13, color: _gold, fontWeight: FontWeight.w500)),
        ],
        const SizedBox(height: 8),
        // Role pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Text(
            profile.displayRole.isNotEmpty ? profile.displayRole : profile.role,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9DC4B8), fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }
}

// ── Stats Card ────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final UserStats? stats;
  final bool loading;
  const _StatsCard({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: loading
          ? SizedBox(height: 70,
          child: Shimmer.fromColors(
              baseColor: const Color(0xFFEAE6DE), highlightColor: Colors.white,
              child: Container(color: Colors.white)))
          : Row(children: [
        _StatCell('${stats?.followerCount ?? 0}', 'Followers', Icons.people_rounded),
        _vDiv(),
        _StatCell('${stats?.followingCount ?? 0}', 'Following', Icons.person_add_rounded),
        _vDiv(),
        _StatCell('${stats?.likeCount ?? 0}', 'Likes', Icons.favorite_rounded, red: true),
        _vDiv(),
        _StatCell('${stats?.totalProfileViews ?? 0}', 'Views', Icons.visibility_rounded),
        _vDiv(),
        _StatCell(
          (stats?.averageRating ?? 0.0).toStringAsFixed(1),
          'Rating', Icons.star_rounded, gold: true,
        ),
      ]),
    );
  }

  Widget _vDiv() => Container(width: 1, height: 40, color: const Color(0xFFEAE6DE));
}

class _StatCell extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final bool gold, red;
  const _StatCell(this.value, this.label, this.icon, {this.gold = false, this.red = false});

  @override
  Widget build(BuildContext context) {
    final color = gold ? _gold : red ? Colors.red[400]! : _brand;
    return Expanded(child: Column(children: [
      Icon(icon, size: 15, color: color.withOpacity(0.6)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
          color: color, letterSpacing: -0.5)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: _slate, fontWeight: FontWeight.w500)),
    ]));
  }
}

// ── Social Actions Card ────────────────────────────────────────────────────

class _SocialCard extends ConsumerWidget {
  final PublicUserProfile profile;
  final bool isLiked, isFollowing;
  const _SocialCard({required this.profile, required this.isLiked, required this.isFollowing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.read(socialProvider.notifier);
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        _ActionTile(
          icon: isFollowing ? Icons.how_to_reg_rounded : Icons.person_add_alt_1_rounded,
          label: isFollowing ? 'Following' : 'Follow',
          sub: isFollowing ? 'You follow this person' : 'Add to your network',
          iconColor: _brand,
          active: isFollowing,
          onTap: () => n.toggleFollow(profile.id),
        ),
        const Divider(height: 1, indent: 56, color: Color(0xFFEAE6DE)),
        _ActionTile(
          icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          label: isLiked ? 'Liked' : 'Like',
          sub: isLiked ? 'You liked this profile' : 'Show appreciation',
          iconColor: Colors.red[400]!,
          active: isLiked,
          onTap: () => n.toggleLike(profile.id),
        ),
      ]),
    );
  }
}

// ── Details Card (mirrors _InfoCard) ─────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  final PublicUserProfile profile;
  const _DetailsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final rows = [
      if (profile.username.isNotEmpty)
        _Row(Icons.alternate_email_rounded, 'Username', '@${profile.username}'),
      if (profile.country?.isNotEmpty ?? false)
        _Row(Icons.location_on_outlined, 'Country', profile.country!),
      _Row(Icons.badge_rounded, 'Role',
          profile.displayRole.isNotEmpty ? profile.displayRole : profile.role),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Details',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: _brand, letterSpacing: -0.2)),
        const SizedBox(height: 4),
        const Divider(color: Color(0xFFEAE6DE)),
        ...rows.map((r) => _InfoRow(row: r)),
      ]),
    );
  }
}

// ── Shared atoms (mirrors own-profile style exactly) ─────────────────────

class _Row { final IconData icon; final String label, value; const _Row(this.icon, this.label, this.value); }

class _InfoRow extends StatelessWidget {
  final _Row row;
  const _InfoRow({required this.row});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Icon(row.icon, size: 17, color: _gold),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(row.label, style: const TextStyle(fontSize: 11, color: _slate)),
        Text(row.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _brand)),
      ])),
    ]),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color iconColor;
  final bool active;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.sub,
    required this.iconColor, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(active ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: active ? iconColor : _brand)),
          Text(sub, style: const TextStyle(fontSize: 11, color: _slate)),
        ])),
        Icon(active ? Icons.check_rounded : Icons.chevron_right_rounded,
            size: 18, color: active ? iconColor : _slate),
      ]),
    ),
  );
}

// ── Like Button (app bar) ─────────────────────────────────────────────────

class _LikeButton extends ConsumerWidget {
  final String profileId;
  final bool isLiked;
  const _LikeButton({required this.profileId, required this.isLiked});

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    icon: AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
      child: Icon(
        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        key: ValueKey(isLiked),
        color: isLiked ? Colors.red[400] : _slate,
        size: 22,
      ),
    ),
    onPressed: () => ref.read(socialProvider.notifier).toggleLike(profileId),
  );
}

// ── Error View ────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.person_off_rounded, size: 56, color: Colors.grey[300]),
        const SizedBox(height: 14),
        Text(error, style: const TextStyle(fontSize: 15, color: _slate)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(backgroundColor: _brand, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ]),
    ),
  );
}

// ── Shimmer (matches own-profile loading state) ───────────────────────────

class _Shimmer extends StatelessWidget {
  const _Shimmer();
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: const Color(0xFFEAE6DE),
    highlightColor: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Container(height: 210, decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(20))),
        const SizedBox(height: 16),
        Container(height: 90, decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(16))),
        const SizedBox(height: 16),
        Container(height: 120, decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(16))),
        const SizedBox(height: 16),
        Container(height: 160, decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(16))),
      ]),
    ),
  );
}

extension _Capitalize on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}