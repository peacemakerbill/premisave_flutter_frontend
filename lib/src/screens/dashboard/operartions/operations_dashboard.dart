import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/auth/user_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../other_user_profiles/users_content.dart';
import '../../shared/about_content.dart';
import '../../shared/contact_content.dart';
import 'contents/OperationsDashboardContent.dart';

class OperationsDashboard extends ConsumerStatefulWidget {
  const OperationsDashboard({super.key});

  @override
  ConsumerState<OperationsDashboard> createState() => _OperationsDashboardState();
}

class _OperationsDashboardState extends ConsumerState<OperationsDashboard> {
  String _currentRoute = '/dashboard/operations';

  static const _brand = Color(0xFF1A3C34);
  static const _gold = Color(0xFFC9A84C);

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.grid_view_rounded, 'label': 'Overview', 'route': '/dashboard/operations'},
    {'icon': Icons.people_outline_rounded, 'label': 'People', 'route': '/operations/people'},
    {'icon': Icons.info_outline_rounded, 'label': 'About', 'route': '/about'},
    {'icon': Icons.contact_support_rounded, 'label': 'Contact', 'route': '/contact'},
  ];

  void _navigate(String route) {
    setState(() => _currentRoute = route);
  }

  Widget _buildContent() {
    switch (_currentRoute) {
      case '/operations/people':
        return const UsersContent();
      case '/about':
        return const AboutContent();
      case '/contact':
        return const ContactContent();
      default:
        return const OperationsDashboardContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: _buildAppBar(authState.currentUser, notifier, isMobile),
      body: _buildContent(),
      bottomNavigationBar: isMobile ? _buildBottomNav() : null,
    );
  }

  PreferredSizeWidget _buildAppBar(UserModel? user, AuthNotifier notifier, bool isMobile) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.white,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFEAE6DE)),
      ),
      leadingWidth: 180,
      leading: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: GestureDetector(
          onTap: () => _navigate('/dashboard/operations'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _brand,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Center(
                  child: Text('P',
                      style: TextStyle(
                          color: _gold,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                ),
              ),
              const SizedBox(width: 9),
              const Text('premisave',
                  style: TextStyle(
                      color: _brand,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3)),
            ],
          ),
        ),
      ),
      title: !isMobile ? _buildDesktopNav() : null,
      centerTitle: !isMobile,
      actions: [
        _buildProfileMenu(user, notifier),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildDesktopNav() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _menuItems.map((item) {
        final isActive = _currentRoute == item['route'];
        return GestureDetector(
          onTap: () => _navigate(item['route'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isActive ? _brand : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item['icon'] as IconData,
                    size: 15,
                    color: isActive ? Colors.white : const Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(item['label'] as String,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive ? Colors.white : const Color(0xFF6B7280),
                        letterSpacing: -0.1)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfileMenu(UserModel? user, AuthNotifier notifier) {
    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      color: Colors.white,
      shadowColor: Colors.black12,
      onSelected: (value) {
        if (value == 'profile') context.push('/profile');
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.firstName ?? 'User',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _brand)),
              Text(user?.email ?? '',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 16, color: _brand),
              SizedBox(width: 10),
              Text('View profile',
                  style: TextStyle(fontSize: 13, color: _brand, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: const Row(
            children: [
              Icon(Icons.logout_rounded, size: 16, color: Colors.red),
              SizedBox(width: 10),
              Text('Log out', style: TextStyle(fontSize: 13, color: Colors.red)),
            ],
          ),
          onTap: () => notifier.confirmLogout(context),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEAE6DE)),
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatar(user, radius: 13),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(UserModel? user, {double radius = 16}) {
    if (user?.profilePictureUrl?.isNotEmpty == true) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(user!.profilePictureUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _brand,
      child: Text(
        user?.firstName?.substring(0, 1).toUpperCase() ?? 'U',
        style: TextStyle(
            color: _gold,
            fontSize: radius * 0.85,
            fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildBottomNav() {
    final idx = _menuItems
        .indexWhere((i) => i['route'] == _currentRoute)
        .clamp(0, _menuItems.length - 1);
    return BottomNavigationBar(
      currentIndex: idx,
      onTap: (i) => _navigate(_menuItems[i]['route'] as String),
      backgroundColor: Colors.white,
      selectedItemColor: _brand,
      unselectedItemColor: const Color(0xFF9CA3AF),
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      items: _menuItems
          .map((i) => BottomNavigationBarItem(
        icon: Icon(i['icon'] as IconData),
        label: i['label'] as String,
      ))
          .toList(),
    );
  }
}