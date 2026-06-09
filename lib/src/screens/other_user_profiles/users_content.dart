import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/social/social_provider.dart';
import 'other_user_profile_screen.dart';

const _green  = Color(0xFF2D6A4F);
const _greenL = Color(0xFF52B788);
const _greenS = Color(0xFFD8F3DC);
const _amber  = Color(0xFFD4A017);
const _amberS = Color(0xFFFFF3CD);
const _soil   = Color(0xFF5C3D2E);
const _soilS  = Color(0xFFF5EFE6);

class UsersContent extends ConsumerStatefulWidget {
  const UsersContent({super.key});
  @override
  ConsumerState<UsersContent> createState() => _State();
}

class _State extends ConsumerState<UsersContent> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final n = ref.read(socialProvider.notifier);
      n.loadAllUsers(); n.loadMyLikes(); n.loadMyFollowing();
    });
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text;
      setState(() => _searching = q.isNotEmpty);
      ref.read(socialProvider.notifier).searchUsers(q);
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(socialProvider);
    final me = ref.watch(authProvider).currentUser;
    final w = MediaQuery.of(context).size.width;
    final list = _searching
        ? ss.searchResults
        : ss.users.where((u) => u.id != me?.id).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(w < 768 ? 16 : 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _header(),
        const SizedBox(height: 16),
        _searchBar(ss),
        const SizedBox(height: 14),
        _statsRow(ss),
        const SizedBox(height: 20),
        _grid(context, list, ss, w),
      ]),
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), _green, _greenL],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: _green.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 5))],
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('People', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
            color: Colors.white, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text('Discover and connect', style: TextStyle(fontSize: 13,
            color: Colors.white.withOpacity(0.8))),
      ])),
      Container(width: 50, height: 50,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(Icons.people_rounded, color: Colors.white, size: 26)),
    ]),
  );

  Widget _searchBar(SocialState ss) => Container(
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _greenL.withOpacity(0.3)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: TextField(
      controller: _searchCtrl,
      style: const TextStyle(fontSize: 14, color: _soil),
      decoration: InputDecoration(
        hintText: 'Search people...',
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded, color: _greenL, size: 20),
        suffixIcon: _searching
            ? IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
            onPressed: () { _searchCtrl.clear(); ref.read(socialProvider.notifier).clearSearch(); })
            : ss.isSearching
            ? const Padding(padding: EdgeInsets.all(14),
            child: SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: _greenL)))
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      ),
    ),
  );

  Widget _statsRow(SocialState ss) => Row(children: [
    _Chip(Icons.people_outline_rounded, '${ss.users.length} users', _green, _greenS),
    const SizedBox(width: 8),
    _Chip(Icons.favorite_border_rounded, '${ss.likedUserIds.length} liked', _amber, _amberS),
    const SizedBox(width: 8),
    _Chip(Icons.person_add_alt_1_rounded, '${ss.followingUserIds.length} following', _soil, _soilS),
  ]);

  Widget _grid(BuildContext ctx, List<PublicUserProfile> users, SocialState ss, double w) {
    if (ss.isLoadingUsers && users.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(color: _green)));
    }
    if (ss.error != null && users.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[300]),
          const SizedBox(height: 10),
          Text(ss.error!, style: TextStyle(color: Colors.red[400], fontSize: 13)),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => ref.read(socialProvider.notifier).loadAllUsers(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(backgroundColor: _green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ]),
      ));
    }
    if (users.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(children: [
          Icon(Icons.people_outline_rounded, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(_searching ? 'No results found' : 'No users yet',
              style: TextStyle(fontSize: 15, color: Colors.grey[500])),
        ]),
      ));
    }

    final cols = w < 768 ? 2 : (w > 1200 ? 4 : 3);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_searching ? '${users.length} result${users.length == 1 ? '' : 's'}' : 'All Users',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _soil)),
      const SizedBox(height: 14),
      GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols, crossAxisSpacing: 12, mainAxisSpacing: 12,
            childAspectRatio: 0.8),
        itemCount: users.length,
        itemBuilder: (_, i) {
          final u = users[i];
          return _UserCard(
            user: u,
            isLiked: ss.likedUserIds.contains(u.id),
            isFollowing: ss.followingUserIds.contains(u.id),
            onTap: () => Navigator.push(ctx,
                MaterialPageRoute(builder: (_) => OtherUserProfileScreen(userId: u.id))),
            onLike: () => ref.read(socialProvider.notifier).toggleLike(u.id),
            onFollow: () => ref.read(socialProvider.notifier).toggleFollow(u.id),
          );
        },
      ),
    ]);
  }
}

// ── User Card ─────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final PublicUserProfile user;
  final bool isLiked, isFollowing;
  final VoidCallback onTap, onLike, onFollow;
  const _UserCard({required this.user, required this.isLiked, required this.isFollowing,
    required this.onTap, required this.onLike, required this.onFollow});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isFollowing ? _greenL.withOpacity(0.5) : Colors.grey[200]!,
            width: isFollowing ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Avatar
          Stack(children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: _greenS,
              backgroundImage: (user.profilePictureUrl?.isNotEmpty ?? false)
                  ? NetworkImage(user.profilePictureUrl!) : null,
              child: (user.profilePictureUrl?.isNotEmpty ?? false) ? null
                  : Text(user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: _green)),
            ),
            if (user.verified)
              Positioned(bottom: 0, right: 0,
                  child: Container(width: 16, height: 16,
                      decoration: const BoxDecoration(color: _greenL, shape: BoxShape.circle),
                      child: const Icon(Icons.check, size: 10, color: Colors.white))),
          ]),
          const SizedBox(height: 10),
          // Name
          Text(user.fullName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
              maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text('@${user.username}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          // Role pill
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _amberS, borderRadius: BorderRadius.circular(8)),
              child: Text(user.displayRole,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _amber))),
          const SizedBox(height: 12),
          // Actions
          Row(children: [
            GestureDetector(
              onTap: onLike,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: isLiked ? Colors.red[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 16, color: isLiked ? Colors.red[400] : Colors.grey[500]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: onFollow,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: isFollowing ? _greenS : _green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(isFollowing ? 'Following' : 'Follow',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: isFollowing ? _green : Colors.white)),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Atoms ─────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color fg, bg;
  const _Chip(this.icon, this.label, this.fg, this.bg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: fg),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    ]),
  );
}