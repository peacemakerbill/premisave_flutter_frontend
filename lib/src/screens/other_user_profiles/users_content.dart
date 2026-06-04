import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/social/social_provider.dart';
import 'other_user_profile_screen.dart';

// Earthy palette constants
const _kForestGreen = Color(0xFF2D6A4F);
const _kGreenLight = Color(0xFF52B788);
const _kGreenSurface = Color(0xFFD8F3DC);
const _kAmber = Color(0xFFD4A017);
const _kAmberSurface = Color(0xFFFFF8E1);
const _kSoil = Color(0xFF6B4F3A);
const _kSoilLight = Color(0xFFF5EFE6);

class UsersContent extends ConsumerStatefulWidget {
  const UsersContent({super.key});

  @override
  ConsumerState<UsersContent> createState() => _UsersContentState();
}

class _UsersContentState extends ConsumerState<UsersContent> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(socialProvider.notifier);
      notifier.loadAllUsers();
      notifier.loadMyLikes();
      notifier.loadMyFollowing();
    });
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text;
    setState(() => _isSearchActive = q.isNotEmpty);
    ref.read(socialProvider.notifier).searchUsers(q);
  }

  void _openProfile(BuildContext context, PublicUserProfile user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtherUserProfileScreen(userId: user.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final socialState = ref.watch(socialProvider);
    final currentUser = ref.watch(authProvider).currentUser;
    final isMobile = MediaQuery.of(context).size.width < 768;

    final displayList = _isSearchActive
        ? socialState.searchResults
        : socialState.users.where((u) => u.id != currentUser?.id).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSearchBar(socialState),
          const SizedBox(height: 20),
          _buildStatsRow(socialState),
          const SizedBox(height: 24),
          _buildUserGrid(context, displayList, socialState, isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kForestGreen, _kGreenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kForestGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'People',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Discover and connect with users',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(SocialState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kGreenLight.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search by name, username or email...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: _kGreenLight),
          suffixIcon: _isSearchActive
              ? IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.grey),
            onPressed: () {
              _searchCtrl.clear();
              ref.read(socialProvider.notifier).clearSearch();
            },
          )
              : state.isSearching
              ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _kGreenLight,
              ),
            ),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildStatsRow(SocialState state) {
    final total = state.users.length;
    return Row(
      children: [
        _StatChip(
          icon: Icons.people_outline_rounded,
          label: '$total ${total == 1 ? 'user' : 'users'}',
          color: _kForestGreen,
          bgColor: _kGreenSurface,
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: Icons.favorite_border_rounded,
          label: '${state.likedUserIds.length} liked',
          color: _kAmber,
          bgColor: _kAmberSurface,
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: Icons.person_add_alt_1_rounded,
          label: '${state.followingUserIds.length} following',
          color: _kSoil,
          bgColor: _kSoilLight,
        ),
      ],
    );
  }

  Widget _buildUserGrid(
      BuildContext context,
      List<PublicUserProfile> users,
      SocialState socialState,
      bool isMobile,
      ) {
    if (socialState.isLoadingUsers && users.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(color: _kForestGreen),
        ),
      );
    }

    if (socialState.error != null && users.isEmpty) {
      return _buildErrorState(socialState.error!);
    }

    if (users.isEmpty) {
      return _buildEmptyState();
    }

    final crossAxisCount = isMobile ? 2 : (MediaQuery.of(context).size.width > 1200 ? 4 : 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSearchActive
              ? '${users.length} result${users.length == 1 ? '' : 's'} found'
              : 'All Users',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kSoil,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.78,
          ),
          itemCount: users.length,
          itemBuilder: (context, i) {
            final user = users[i];
            return _UserCard(
              user: user,
              isLiked: socialState.likedUserIds.contains(user.id),
              isFollowing: socialState.followingUserIds.contains(user.id),
              onTap: () => _openProfile(context, user),
              onLike: () => ref.read(socialProvider.notifier).toggleLike(user.id),
              onFollow: () => ref.read(socialProvider.notifier).toggleFollow(user.id),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _isSearchActive ? 'No users match your search' : 'No users found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 52, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(error, style: TextStyle(color: Colors.red[400], fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(socialProvider.notifier).loadAllUsers(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kForestGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── User Card ────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final PublicUserProfile user;
  final bool isLiked;
  final bool isFollowing;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onFollow;

  const _UserCard({
    required this.user,
    required this.isLiked,
    required this.isFollowing,
    required this.onTap,
    required this.onLike,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isFollowing ? _kGreenLight.withOpacity(0.6) : Colors.grey[200]!,
            width: isFollowing ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: _kGreenSurface,
                    backgroundImage: user.profilePictureUrl != null &&
                        user.profilePictureUrl!.isNotEmpty
                        ? NetworkImage(user.profilePictureUrl!)
                        : null,
                    child: user.profilePictureUrl == null ||
                        user.profilePictureUrl!.isEmpty
                        ? Text(
                      user.firstName.isNotEmpty
                          ? user.firstName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _kForestGreen,
                      ),
                    )
                        : null,
                  ),
                  if (user.verified)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: _kGreenLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 11, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                user.fullName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                '@${user.username}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kAmberSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.displayRole,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _kAmber,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionIconBtn(
                    icon: isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isLiked ? Colors.red : Colors.grey[400]!,
                    onTap: onLike,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: onFollow,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: isFollowing ? _kGreenSurface : _kForestGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isFollowing ? 'Following' : 'Follow',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isFollowing ? _kForestGreen : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}