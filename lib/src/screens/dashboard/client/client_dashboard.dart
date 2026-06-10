import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/auth/user_model.dart';
import '../../../providers/auth/auth_provider.dart';

import '../../other_user_profiles/users_content.dart';
import '../../shared/about_content.dart';
import '../../shared/contact_content.dart';
import 'contents/client_dashboard_content.dart';
import 'contents/client_explore_content.dart';
import 'contents/client_bookings_content.dart';
import 'contents/client_wishlists_content.dart';
import 'contents/client_payments_content.dart';
import 'contents/client_messages_content.dart';
import 'contents/client_transactions_content.dart';

class ClientDashboard extends ConsumerStatefulWidget {
  const ClientDashboard({super.key});

  @override
  ConsumerState<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends ConsumerState<ClientDashboard> {
  String _currentRoute = '/client/explore';

  static const _brand = Color(0xFF1A3C34);
  static const _gold = Color(0xFFC9A84C);
  static const _stone = Color(0xFFF5F0E8);
  static const _slate = Color(0xFF6B7280);

  final List<Map<String, dynamic>> _primaryMenu = [
    {'icon': Icons.search_rounded, 'label': 'Explore', 'route': '/client/explore'},
    {'icon': Icons.calendar_month_rounded, 'label': 'Bookings', 'route': '/client/bookings'},
    {'icon': Icons.favorite_rounded, 'label': 'Wishlists', 'route': '/client/wishlists'},
    {'icon': Icons.message_rounded, 'label': 'Messages', 'route': '/client/messages'},
  ];

  final List<Map<String, dynamic>> _moreMenu = [
    {'icon': Icons.home_rounded, 'label': 'Dashboard', 'route': '/dashboard/client'},
    {'icon': Icons.people_outline_rounded, 'label': 'Community', 'route': '/client/users'},
    {'icon': Icons.payments_rounded, 'label': 'Payments', 'route': '/client/payments'},
    {'icon': Icons.receipt_long_rounded, 'label': 'Transactions', 'route': '/client/transactions'},
    {'icon': Icons.info_outline_rounded, 'label': 'About', 'route': '/client/about'},
    {'icon': Icons.contact_support_rounded, 'label': 'Contact', 'route': '/client/contact'},
  ];

  void _navigate(String route) => setState(() => _currentRoute = route);

  Widget _getCurrentContent() {
    switch (_currentRoute) {
      case '/client/bookings': return const ClientBookingsContent();
      case '/client/wishlists': return const ClientWishlistsContent();
      case '/client/payments': return const ClientPaymentsContent();
      case '/client/transactions': return const ClientTransactionsContent();
      case '/client/messages': return const ClientMessagesContent();
      case '/client/users': return const UsersContent();
      case '/client/about': return const AboutContent();
      case '/client/contact': return const ContactContent();
      case '/dashboard/client': return const ClientDashboardContent();
      case '/client/explore':
      default: return const ClientExploreContent();
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
      body: _getCurrentContent(),
      bottomNavigationBar: isMobile ? _buildBottomNav() : null,
    );
  }

  PreferredSizeWidget _buildAppBar(UserModel? user, AuthNotifier notifier, bool isMobile) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFEAE6DE)),
      ),
      leadingWidth: 180,
      leading: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: GestureDetector(
          onTap: () => _navigate('/dashboard/client'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(color: _brand, borderRadius: BorderRadius.circular(7)),
                child: const Center(child: Text('P', style: TextStyle(color: _gold, fontSize: 17, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 9),
              const Text('premisave', style: TextStyle(color: _brand, fontSize: 15, fontWeight: FontWeight.w700)),
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
      children: [
        ..._primaryMenu.map((item) {
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
                  Icon(item['icon'] as IconData, size: 15, color: isActive ? Colors.white : const Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Text(item['label'] as String, style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500, color: isActive ? Colors.white : const Color(0xFF6B7280))),
                ],
              ),
            ),
          );
        }).toList(),

        PopupMenuButton<String>(
          position: PopupMenuPosition.under,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 6,
          color: Colors.white,
          shadowColor: Colors.black26,
          onSelected: (route) => _navigate(route),
          itemBuilder: (_) => _moreMenu.map((item) {
            final isActive = _currentRoute == item['route'];
            return PopupMenuItem<String>(
              value: item['route'] as String,
              child: Row(
                children: [
                  Icon(item['icon'] as IconData, size: 18, color: _brand),
                  const SizedBox(width: 12),
                  Text(
                    item['label'] as String,
                    style: const TextStyle(fontSize: 14, color: _brand, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }).toList(),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Row(
              children: [
                Text('More', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _brand)),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _brand),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _getBottomNavIndex(),
      onTap: (index) {
        if (index < _primaryMenu.length) {
          _navigate(_primaryMenu[index]['route'] as String);
        } else {
          _showMoreBottomSheet();
        }
      },
      backgroundColor: Colors.white,
      selectedItemColor: _brand,
      unselectedItemColor: const Color(0xFF6B7280),
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      items: [
        ..._primaryMenu.map((item) => BottomNavigationBarItem(
          icon: Icon(item['icon'] as IconData),
          label: item['label'] as String,
        )),
        const BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz_rounded),
          label: 'More',
        ),
      ],
    );
  }

  int _getBottomNavIndex() {
    final index = _primaryMenu.indexWhere((item) => item['route'] == _currentRoute);
    return index != -1 ? index : 4;
  }

  void _showMoreBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: _stone, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ..._moreMenu.map((item) {
              final isActive = _currentRoute == item['route'];
              return ListTile(
                leading: Icon(item['icon'] as IconData, color: _brand),
                title: Text(
                  item['label'] as String,
                  style: TextStyle(fontWeight: isActive ? FontWeight.w600 : FontWeight.w500, color: _brand),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigate(item['route'] as String);
                },
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenu(UserModel? user, AuthNotifier notifier) {
    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      color: Colors.white,
      onSelected: (value) {
        if (value == 'profile') context.push('/profile');
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.firstName ?? 'Client', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _brand)),
              Text(user?.email ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
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
              Text('View profile', style: TextStyle(fontSize: 13, color: _brand, fontWeight: FontWeight.w500)),
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
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(UserModel? user, {double radius = 16}) {
    if (user?.profilePictureUrl?.isNotEmpty == true) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(user!.profilePictureUrl!));
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _brand,
      child: Text(
        user?.firstName?.substring(0, 1).toUpperCase() ?? 'C',
        style: TextStyle(color: _gold, fontSize: radius * 0.85, fontWeight: FontWeight.w700),
      ),
    );
  }
}