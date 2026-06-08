import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/auth/user_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../other_user_profiles/users_content.dart';

class HomeOwnerDashboard extends ConsumerStatefulWidget {
  const HomeOwnerDashboard({super.key});

  @override
  ConsumerState<HomeOwnerDashboard> createState() => _HomeOwnerDashboardState();
}

class _HomeOwnerDashboardState extends ConsumerState<HomeOwnerDashboard> {
  String _currentRoute = '/dashboard/home-owner';

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'route': '/dashboard/home-owner'},
    {'icon': Icons.people_rounded, 'label': 'People', 'route': '/home-owner/people'},
  ];

  void _navigateToRoute(String route) {
    setState(() => _currentRoute = route);
  }

  Widget _getCurrentContent() {
    switch (_currentRoute) {
      case '/home-owner/people':
        return const UsersContent();
      case '/dashboard/home-owner':
      default:
        return const _HomeOwnerDashboardContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, authState.currentUser, notifier, isMobile),
      body: _getCurrentContent(),
      bottomNavigationBar: isMobile ? _buildBottomNav() : null,
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context,
      UserModel? user,
      AuthNotifier notifier,
      bool isMobile,
      ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      surfaceTintColor: Colors.white,
      leadingWidth: 200,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: GestureDetector(
          onTap: () => _navigateToRoute('/dashboard/home-owner'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A4F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('P', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Home Owner', style: TextStyle(color: Color(0xFF2D6A4F), fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
      title: !isMobile ? _buildDesktopNav() : null,
      centerTitle: !isMobile,
      actions: [
        _buildProfileMenu(context, user, notifier),
        if (!isMobile) const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildDesktopNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _menuItems.map((item) {
          final isActive = _currentRoute == item['route'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: TextButton.icon(
              onPressed: () => _navigateToRoute(item['route'] as String),
              icon: Icon(item['icon'] as IconData, size: 16),
              label: Text(item['label'] as String,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  )),
              style: TextButton.styleFrom(
                foregroundColor: isActive ? const Color(0xFF2D6A4F) : Colors.black87,
                backgroundColor: isActive ? Colors.white : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context, UserModel? user, AuthNotifier notifier) {
    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == 'profile') context.push('/profile');
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'profile',
          child: ListTile(
            leading: _buildProfileAvatar(user),
            title: Text(user?.firstName ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(user?.email ?? '', style: const TextStyle(fontSize: 12)),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log out', style: TextStyle(color: Colors.red)),
            onTap: () => notifier.confirmLogout(context),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu, color: Colors.grey, size: 20),
            const SizedBox(width: 6),
            _buildProfileAvatar(user, radius: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(UserModel? user, {double radius = 16}) {
    if (user?.profilePictureUrl?.isNotEmpty == true) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(user!.profilePictureUrl!),
        onBackgroundImageError: (_, __) => CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFF2D6A4F),
          child: Text(
            user.firstName?.substring(0, 1).toUpperCase() ?? 'U',
            style: TextStyle(color: Colors.white, fontSize: radius > 14 ? 14 : 12),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF2D6A4F),
      child: Text(
        user?.firstName?.substring(0, 1).toUpperCase() ?? 'U',
        style: TextStyle(color: Colors.white, fontSize: radius > 14 ? 14 : 12),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _menuItems.indexWhere((i) => i['route'] == _currentRoute).clamp(0, _menuItems.length - 1),
      onTap: (i) => _navigateToRoute(_menuItems[i]['route'] as String),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF2D6A4F),
      unselectedItemColor: Colors.grey[600],
      items: _menuItems
          .map((i) => BottomNavigationBarItem(
        icon: Icon(i['icon'] as IconData),
        label: i['label'] as String,
      ))
          .toList(),
    );
  }
}

class _HomeOwnerDashboardContent extends StatelessWidget {
  const _HomeOwnerDashboardContent();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Home Owner Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
    );
  }
}