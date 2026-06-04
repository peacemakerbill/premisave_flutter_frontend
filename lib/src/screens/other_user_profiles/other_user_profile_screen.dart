import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/social/social_provider.dart';
import 'profile_reviews_section.dart';

const _kForestGreen = Color(0xFF2D6A4F);
const _kGreenLight = Color(0xFF52B788);
const _kGreenSurface = Color(0xFFD8F3DC);
const _kAmber = Color(0xFFD4A017);
const _kAmberSurface = Color(0xFFFFF8E1);
const _kSoil = Color(0xFF6B4F3A);
const _kSoilLight = Color(0xFFF5EFE6);

class OtherUserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const OtherUserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<OtherUserProfileScreen> createState() =>
      _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState
    extends ConsumerState<OtherUserProfileScreen> {
  PublicUserProfile? _profile;
  UserStats? _stats;
  bool _isLoadingProfile = true;
  bool _isLoadingStats = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notifier = ref.read(socialProvider.notifier);
    notifier.recordProfileView(widget.userId);

    final profile = await notifier.getUserProfile(widget.userId);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _isLoadingProfile = false;
      if (profile == null) _error = 'Could not load profile';
    });

    final stats = await notifier.getUserStats(widget.userId);
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _isLoadingStats = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final socialState = ref.watch(socialProvider);
    final currentUser = ref.watch(authProvider).currentUser;
    final isOwnProfile = _profile?.id == currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator(color: _kForestGreen))
          : _error != null
          ? _buildError()
          : _buildBody(context, socialState, isOwnProfile),
    );
  }

  Widget _buildError() {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey[500], fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoadingProfile = true;
                  _error = null;
                });
                _load();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kForestGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context,
      SocialState socialState,
      bool isOwnProfile,
      ) {
    final profile = _profile!;
    final isLiked = socialState.likedUserIds.contains(profile.id);
    final isFollowing = socialState.followingUserIds.contains(profile.id);

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, profile, isLiked, isFollowing, isOwnProfile),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNameCard(profile),
                const SizedBox(height: 16),
                _buildStatsCard(),
                const SizedBox(height: 16),
                if (!isOwnProfile) ...[
                  _buildActionButtons(profile, isLiked, isFollowing),
                  const SizedBox(height: 16),
                ],
                _buildRoleCard(profile),
                if (profile.country != null && profile.country!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoCard(Icons.location_on_rounded, 'Country', profile.country!),
                ],
                const SizedBox(height: 16),
                ReviewsSection(
                  targetId: profile.id,
                  isOwnProfile: isOwnProfile,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(
      BuildContext context,
      PublicUserProfile profile,
      bool isLiked,
      bool isFollowing,
      bool isOwnProfile,
      ) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: _kForestGreen,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (!isOwnProfile)
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(isLiked),
                color: isLiked ? Colors.red[300] : Colors.white,
              ),
            ),
            onPressed: () => ref.read(socialProvider.notifier).toggleLike(profile.id),
          ),
        IconButton(
          icon: const Icon(Icons.share_rounded, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kForestGreen, _kGreenLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    backgroundImage: profile.profilePictureUrl != null &&
                        profile.profilePictureUrl!.isNotEmpty
                        ? NetworkImage(profile.profilePictureUrl!)
                        : null,
                    child: profile.profilePictureUrl == null ||
                        profile.profilePictureUrl!.isEmpty
                        ? Text(
                      profile.firstName.isNotEmpty
                          ? profile.firstName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                        : null,
                  ),
                  if (profile.verified)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _kAmber,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.verified, size: 13, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                profile.fullName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '@${profile.username}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameCard(PublicUserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _kGreenSurface, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.person_rounded, color: _kForestGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.fullName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text('@${profile.username}', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ],
            ),
          ),
          if (profile.verified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: _kAmberSurface, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: const [
                  Icon(Icons.verified_rounded, size: 13, color: _kAmber),
                  SizedBox(width: 4),
                  Text('Verified', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kAmber)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSoilLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kSoil.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _kSoil.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _kSoil, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: _kSoil, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kSoil)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_isLoadingStats) {
      return Container(
        height: 100,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kGreenLight)),
      );
    }

    final s = _stats ?? const UserStats();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          _StatCell(value: '${s.followerCount}', label: 'Followers', color: _kForestGreen),
          _divider(),
          _StatCell(value: '${s.followingCount}', label: 'Following', color: _kGreenLight),
          _divider(),
          _StatCell(value: '${s.likeCount}', label: 'Likes', color: Colors.red[400]!),
          _divider(),
          _StatCell(value: '${s.totalProfileViews}', label: 'Views', color: _kSoil),
          _divider(),
          _StatCell(value: s.averageRating.toStringAsFixed(1), label: 'Rating', color: _kAmber, icon: Icons.star_rounded),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: Colors.grey[200]);

  Widget _buildActionButtons(PublicUserProfile profile, bool isLiked, bool isFollowing) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: () => ref.read(socialProvider.notifier).toggleFollow(profile.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isFollowing ? _kGreenSurface : _kForestGreen,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isFollowing ? _kForestGreen.withOpacity(0.4) : Colors.transparent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isFollowing ? Icons.how_to_reg_rounded : Icons.person_add_alt_1_rounded,
                      size: 18, color: isFollowing ? _kForestGreen : Colors.white),
                  const SizedBox(width: 8),
                  Text(isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isFollowing ? _kForestGreen : Colors.white)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () => ref.read(socialProvider.notifier).toggleLike(profile.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isLiked ? Colors.red[50] : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isLiked ? Colors.red[300]! : Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 18, color: isLiked ? Colors.red[400] : Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(isLiked ? 'Liked' : 'Like',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isLiked ? Colors.red[400] : Colors.grey[600])),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(PublicUserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSoilLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kSoil.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _kSoil.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.badge_rounded, color: _kSoil, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Account Type', style: TextStyle(fontSize: 11, color: _kSoil, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                profile.displayRole.isNotEmpty ? profile.displayRole.capitalize() : profile.role,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kSoil),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData? icon;

  const _StatCell({required this.value, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          if (icon != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 3),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ] else ...[
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ],
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}