import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/auth/user_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../shared/profiles/users_content.dart';

class OperationsDashboard extends ConsumerStatefulWidget {
  const OperationsDashboard({super.key});

  @override
  ConsumerState<OperationsDashboard> createState() =>
      _OperationsDashboardState();
}

class _OperationsDashboardState extends ConsumerState<OperationsDashboard> {
  String _currentRoute = '/dashboard/operations';

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'route': '/dashboard/operations'},
    {'icon': Icons.people_rounded, 'label': 'People', 'route': '/operations/people'},
  ];

  void _navigateToRoute(String route) =>
      setState(() => _currentRoute = route);

  Widget _getCurrentContent() {
    switch (_currentRoute) {
      case '/operations/people':
        return const UsersContent();
      case '/dashboard/operations':
      default:
        return const _OperationsDashboardContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = ref.read(authProvider.notifier);
    final authState = ref.watch(authProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, authState.currentUser, authNotifier, isMobile),
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
          onTap: () => _navigateToRoute('/dashboard/operations'),
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
                  child: Text('P',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Operations',
                  style: TextStyle(
                      color: Color(0xFF2D6A4F),
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
      title: !isMobile ? _buildDesktopNav() : null,
      centerTitle: !isMobile,
      actions: [
        _buildProfileMenu(context, user, notifier),
        const SizedBox(width: 16),
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
                      fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13)),
              style: TextButton.styleFrom(
                foregroundColor:
                isActive ? const Color(0xFF2D6A4F) : Colors.black87,
                backgroundColor:
                isActive ? Colors.white : Colors.transparent,
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProfileMenu(
      BuildContext context,
      UserModel? user,
      AuthNotifier notifier,
      ) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: PopupMenuButton<String>(
        position: PopupMenuPosition.under,
        onSelected: (value) {
          if (value == 'profile') context.push('/profile');
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'profile',
            child: ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF2D6A4F),
                child: Text(
                  user?.firstName.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(user?.firstName ?? 'User',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(user?.email ?? '',
                  style: const TextStyle(fontSize: 12)),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'logout',
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Log out',
                  style: TextStyle(color: Colors.red)),
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
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF2D6A4F),
                child: Text(
                  user?.firstName.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final idx = _menuItems
        .indexWhere((i) => i['route'] == _currentRoute)
        .clamp(0, _menuItems.length - 1);
    return BottomNavigationBar(
      currentIndex: idx,
      onTap: (i) => _navigateToRoute(_menuItems[i]['route'] as String),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF2D6A4F),
      unselectedItemColor: Colors.grey[600],
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: _menuItems
          .map((i) => BottomNavigationBarItem(
        icon: Icon(i['icon'] as IconData),
        label: i['label'] as String,
      ))
          .toList(),
    );
  }
}

class _OperationsDashboardContent extends StatelessWidget {
  const _OperationsDashboardContent();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Operations Dashboard', style: TextStyle(fontSize: 24)),
    );
  }
}