import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/social/social_provider.dart';
import 'profile_reviews_section.dart';

const _brand = Color(0xFF1A3C34);
const _brandLight = Color(0xFF2D5A4F);
const _gold  = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);
const _border = Color(0xFFEAE6DE);

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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n = ref.read(socialProvider.notifier);
    n.recordProfileView(widget.userId);
    final p = await n.getUserProfile(widget.userId);
    if (!mounted) return;
    setState(() {
      _profile = p;
      _loadingProfile = false;
      _error = p == null ? 'Profile not found' : null;
    });
    if (p != null) {
      final s = await n.getUserStats(widget.userId);
      if (!mounted) return;
      setState(() {
        _stats = s;
        _loadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ss    = ref.watch(socialProvider);
    final me    = ref.watch(authProvider).currentUser;
    final isOwn = _profile?.id == me?.id;
    final wide  = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _brand, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _loadingProfile ? 'Profile' : (_profile?.fullName ?? 'Profile'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.3),
        ),
        centerTitle: true,
        actions: [
          if (!_loadingProfile && _profile != null && !isOwn)
            _LikeButton(
              profileId: _profile!.id,
              isLiked: ss.likedUserIds.contains(_profile!.id),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loadingProfile
          ? const _Shimmer()
          : _error != null
          ? _ErrorView(
          error: _error!,
          onRetry: () {
            setState(() { _loadingProfile = true; _error = null; });
            _load();
          })
          : RefreshIndicator(
        color: _brand,
        onRefresh: () async {
          setState(() { _loadingProfile = true; });
          await _load();
        },
        child: wide
            ? _WideLayout(
          profile: _profile!,
          stats: _stats,
          loadingStats: _loadingStats,
          isOwn: isOwn,
          isLiked: ss.likedUserIds.contains(_profile!.id),
          isFollowing: ss.followingUserIds.contains(_profile!.id),
        )
            : _NarrowLayout(
          profile: _profile!,
          stats: _stats,
          loadingStats: _loadingStats,
          isOwn: isOwn,
          isLiked: ss.likedUserIds.contains(_profile!.id),
          isFollowing: ss.followingUserIds.contains(_profile!.id),
        ),
      ),
    );
  }
}

// ── Wide layout (GitHub-style: left sidebar + right content) ─────────────────

class _WideLayout extends StatelessWidget {
  final PublicUserProfile profile;
  final UserStats? stats;
  final bool loadingStats, isOwn, isLiked, isFollowing;
  const _WideLayout({
    required this.profile, required this.stats, required this.loadingStats,
    required this.isOwn, required this.isLiked, required this.isFollowing,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left sidebar
              SizedBox(
                width: 280,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _SidebarAvatar(profile: profile),
                  const SizedBox(height: 20),
                  _SidebarIdentity(profile: profile),
                  if (!isOwn) ...[
                    const SizedBox(height: 16),
                    _SidebarActions(profile: profile, isLiked: isLiked, isFollowing: isFollowing),
                  ],
                  const SizedBox(height: 20),
                  _DetailsCard(profile: profile),
                ]),
              ),
              const SizedBox(width: 32),
              // Right content
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _StatsCard(stats: stats, loading: loadingStats),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: ReviewsSection(targetId: profile.id, isOwnProfile: isOwn),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Narrow layout (original stacked, mobile) ─────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  final PublicUserProfile profile;
  final UserStats? stats;
  final bool loadingStats, isOwn, isLiked, isFollowing;
  const _NarrowLayout({
    required this.profile, required this.stats, required this.loadingStats,
    required this.isOwn, required this.isLiked, required this.isFollowing,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(children: [
        _HeroCard(profile: profile),
        const SizedBox(height: 14),
        _StatsCard(stats: stats, loading: loadingStats),
        const SizedBox(height: 14),
        if (!isOwn) ...[
          _SocialCard(profile: profile, isLiked: isLiked, isFollowing: isFollowing),
          const SizedBox(height: 14),
        ],
        _DetailsCard(profile: profile),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: ReviewsSection(targetId: profile.id, isOwnProfile: isOwn),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}

// ── Sidebar: Avatar (large, centred, no dark card bg) ────────────────────────

class _SidebarAvatar extends StatelessWidget {
  final PublicUserProfile profile;
  const _SidebarAvatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _gold.withOpacity(0.4), width: 2),
              boxShadow: [
                BoxShadow(color: _brand.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: CircleAvatar(
              radius: 64,
              backgroundColor: _stone,
              backgroundImage: (profile.profilePictureUrl?.isNotEmpty ?? false)
                  ? CachedNetworkImageProvider(profile.profilePictureUrl!) as ImageProvider
                  : null,
              child: (profile.profilePictureUrl?.isNotEmpty ?? false)
                  ? null
                  : Text(
                profile.firstName.isNotEmpty ? profile.firstName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: _brand),
              ),
            ),
          ),
          if (profile.verified)
            Positioned(
              bottom: 6, right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: _brand, shape: BoxShape.circle),
                child: const Icon(Icons.verified_rounded, size: 14, color: _gold),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Sidebar: Name / username / role pill ─────────────────────────────────────

class _SidebarIdentity extends StatelessWidget {
  final PublicUserProfile profile;
  const _SidebarIdentity({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(profile.fullName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.5)),
      if (profile.username.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text('@${profile.username}',
            style: const TextStyle(fontSize: 14, color: _slate, fontWeight: FontWeight.w500)),
      ],
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: _stone.withOpacity(0.6),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _border),
        ),
        child: Text(
          profile.displayRole.isNotEmpty ? profile.displayRole : profile.role,
          style: const TextStyle(fontSize: 11, color: _brandLight, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),
    ]);
  }
}

// ── Sidebar: Follow + Like buttons (compact, stacked) ────────────────────────

class _SidebarActions extends ConsumerWidget {
  final PublicUserProfile profile;
  final bool isLiked, isFollowing;
  const _SidebarActions({required this.profile, required this.isLiked, required this.isFollowing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.read(socialProvider.notifier);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ElevatedButton.icon(
        onPressed: () => n.toggleFollow(profile.id),
        icon: Icon(isFollowing ? Icons.done_rounded : Icons.person_add_alt_1_rounded, size: 16),
        label: Text(isFollowing ? 'Following' : 'Follow'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing ? Colors.white : _brand,
          foregroundColor: isFollowing ? _brand : Colors.white,
          elevation: 0,
          side: BorderSide(color: isFollowing ? _border : Colors.transparent),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => n.toggleLike(profile.id),
        icon: Icon(
          isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 16,
          color: isLiked ? Colors.red.shade700 : _slate,
        ),
        label: Text(isLiked ? 'Liked Profile' : 'Like Profile'),
        style: OutlinedButton.styleFrom(
          foregroundColor: isLiked ? Colors.red.shade800 : _slate,
          backgroundColor: isLiked ? Colors.red.withOpacity(0.05) : Colors.transparent,
          side: BorderSide(color: isLiked ? Colors.red.shade200 : _border),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    ]);
  }
}

// ── Hero Card (mobile only) ───────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final PublicUserProfile profile;
  const _HeroCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _brand,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _brand.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _gold.withOpacity(0.6), width: 1.5),
          ),
          child: CircleAvatar(
            radius: 46,
            backgroundColor: const Color(0xFF2A5446),
            backgroundImage: (profile.profilePictureUrl?.isNotEmpty ?? false)
                ? CachedNetworkImageProvider(profile.profilePictureUrl!) as ImageProvider
                : null,
            child: (profile.profilePictureUrl?.isNotEmpty ?? false)
                ? null
                : Text(
              profile.firstName.isNotEmpty ? profile.firstName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF9DC4B8)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(profile.fullName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
          if (profile.verified) ...[
            const SizedBox(width: 6),
            const Icon(Icons.verified_rounded, size: 16, color: _gold),
          ],
        ]),
        if (profile.username.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('@${profile.username}',
              style: const TextStyle(fontSize: 13, color: _gold, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Text(
            profile.displayRole.isNotEmpty ? profile.displayRole : profile.role,
            style: const TextStyle(fontSize: 11, color: Color(0xFFE8F0ED), fontWeight: FontWeight.w600, letterSpacing: 0.3),
          ),
        ),
      ]),
    );
  }
}

// ── Stats Card ────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final UserStats? stats;
  final bool loading;
  const _StatsCard({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: loading
          ? SizedBox(
          height: 60,
          child: Shimmer.fromColors(
              baseColor: const Color(0xFFEAE6DE), highlightColor: Colors.white,
              child: Container(color: Colors.white)))
          : LayoutBuilder(
          builder: (context, constraints) {
            final cells = [
              _StatCell('${stats?.followerCount ?? 0}', 'Followers', Icons.people_rounded),
              _StatCell('${stats?.followingCount ?? 0}', 'Following', Icons.person_add_rounded),
              _StatCell('${stats?.likeCount ?? 0}', 'Likes', Icons.favorite_rounded, red: true),
              _StatCell('${stats?.totalProfileViews ?? 0}', 'Views', Icons.visibility_rounded),
              _StatCell((stats?.averageRating ?? 0.0).toStringAsFixed(1), 'Rating', Icons.star_rounded, gold: true),
            ];

            return Row(
              children: List.generate(cells.length * 2 - 1, (index) {
                if (index.isOdd) return Container(width: 1, height: 32, color: _border);
                return Expanded(child: cells[index ~/ 2]);
              }),
            );
          }
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final bool gold, red;
  const _StatCell(this.value, this.label, this.icon, {this.gold = false, this.red = false});

  @override
  Widget build(BuildContext context) {
    final color = gold ? _gold : red ? Colors.red.shade600 : _brand;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: _slate, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Social Actions Card (mobile only) ────────────────────────────────────────

class _SocialCard extends ConsumerWidget {
  final PublicUserProfile profile;
  final bool isLiked, isFollowing;
  const _SocialCard({required this.profile, required this.isLiked, required this.isFollowing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.read(socialProvider.notifier);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(children: [
        _ActionTile(
          icon: isFollowing ? Icons.check_circle_rounded : Icons.person_add_alt_1_rounded,
          label: isFollowing ? 'Following' : 'Follow User',
          sub: isFollowing ? 'Connected in your network' : 'Add to your network updates',
          iconColor: _brand,
          active: isFollowing,
          onTap: () => n.toggleFollow(profile.id),
        ),
        const Divider(height: 1, indent: 64, color: _border),
        _ActionTile(
          icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          label: isLiked ? 'Liked Profile' : 'Like Profile',
          sub: isLiked ? 'You saved this profile' : 'Show your overall appreciation',
          iconColor: Colors.red.shade600,
          active: isLiked,
          onTap: () => n.toggleLike(profile.id),
        ),
      ]),
    );
  }
}

// ── Details Card ─────────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  final PublicUserProfile profile;
  const _DetailsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final rows = [
      if (profile.username.isNotEmpty)
        _Row(Icons.alternate_email_rounded, 'Username', '@${profile.username}'),
      if (profile.country?.isNotEmpty ?? false)
        _Row(Icons.location_on_outlined, 'Location Country', profile.country!),
      _Row(Icons.badge_rounded, 'Account Designation', profile.displayRole.isNotEmpty ? profile.displayRole : profile.role),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Profile Context', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.2)),
        const SizedBox(height: 8),
        const Divider(color: _border, height: 1),
        const SizedBox(height: 6),
        ...rows.map((r) => _InfoRow(row: r)),
      ]),
    );
  }
}

// ── Shared atoms ──────────────────────────────────────────────────────────────

class _Row {
  final IconData icon;
  final String label, value;
  const _Row(this.icon, this.label, this.value);
}

class _InfoRow extends StatelessWidget {
  final _Row row;
  const _InfoRow({required this.row});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: _stone.withOpacity(0.4), borderRadius: BorderRadius.circular(8)),
        child: Icon(row.icon, size: 15, color: _gold),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(row.label, style: const TextStyle(fontSize: 10.5, color: _slate, fontWeight: FontWeight.w500)),
        const SizedBox(height: 1),
        Text(row.value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _brand)),
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
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(active ? 0.12 : 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: active ? iconColor : _brand)),
          const SizedBox(height: 1),
          Text(sub, style: const TextStyle(fontSize: 11, color: _slate)),
        ])),
        Icon(active ? Icons.check_circle_rounded : Icons.chevron_right_rounded, size: 18, color: active ? iconColor : _slate),
      ]),
    ),
  );
}

// ── Like Button (app bar) ─────────────────────────────────────────────────────

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
        color: isLiked ? Colors.red.shade600 : _slate,
        size: 22,
      ),
    ),
    onPressed: () => ref.read(socialProvider.notifier).toggleLike(profileId),
  );
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.person_off_rounded, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 14),
        Text(error, style: const TextStyle(fontSize: 14, color: _slate, fontWeight: FontWeight.w500)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
              backgroundColor: _brand, foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Retry Connection', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ]),
    ),
  );
}

// ── Shimmer ───────────────────────────────────────────────────────────────────

class _Shimmer extends StatelessWidget {
  const _Shimmer();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 768;
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEAE6DE),
      highlightColor: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(wide ? 32 : 16),
        child: wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 280,
            child: Column(children: [
              Container(height: 128, width: 128, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              const SizedBox(height: 16),
              Container(height: 22, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              Container(height: 14, width: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 16),
              Container(height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 8),
              Container(height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),
              Container(height: 130, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
            ]),
          ),
          const SizedBox(width: 32),
          Expanded(child: Column(children: [
            Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 16),
            Container(height: 260, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
          ])),
        ])
            : Column(children: [
          Container(height: 210, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 16),
          Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 16),
          Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 16),
          Container(height: 160, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
        ]),
      ),
    );
  }
}

extension _Capitalize on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}