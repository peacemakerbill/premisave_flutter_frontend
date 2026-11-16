import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/widgets.dart';
import '../data/models/user_model.dart';
import '../features/account/account_screen.dart';
import '../features/account/change_password_screen.dart';
import '../features/account/edit_profile_screen.dart';
import '../features/account/location_screen.dart';
import '../features/account/profile_screen.dart';
import '../features/account/profile_views_screen.dart';
import '../features/account/settings_screen.dart';
import '../features/admin/admin_user_detail_screen.dart';
import '../features/admin/admin_users_screen.dart';
import '../features/admin/audit_screen.dart';
import '../features/application/application_hub_screen.dart';
import '../features/application/application_wizard_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/resend_activation_screen.dart';
import '../features/auth/security_report_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/token_password_screen.dart';
import '../features/auth/verify_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/module_pages.dart';
import '../features/modules/client/client_explore_content.dart';
import '../features/people/people_screen.dart';
import '../features/people/public_profile_screen.dart';
import '../features/security/device_detail_screen.dart';
import '../features/security/devices_screen.dart';
import '../features/security/security_center_screen.dart';
import '../features/security/security_events_screen.dart';
import '../features/security/sessions_screen.dart';
import '../features/security/sign_in_history_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/staff/staff_detail_screen.dart';
import '../features/staff/staff_queue_screen.dart';
import '../state/session_controller.dart';

/// Pages anyone can open, signed in or not (links from emails land here).
const Set<String> _alwaysOpen = <String>{
  '/splash',
  '/verify',
  '/security-report',
  '/admin-invitation',
  '/reset-password',
};

/// Pages that only make sense when signed out.
const Set<String> _signedOutOnly = <String>{
  '/welcome',
  '/login',
  '/signup',
  '/forgot-password',
  '/resend-activation',
};

bool _isAlwaysOpen(String loc) => _alwaysOpen.any((p) => loc == p || loc.startsWith('$p/'));

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<SessionState>(sessionProvider, (previous, next) {
    final changedStatus = previous?.status != next.status;
    final changedRole = previous?.user?.role != next.user?.role;
    if (changedStatus || changedRole) refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  String? redirect(BuildContext context, GoRouterState state) {
    final session = ref.read(sessionProvider);
    final loc = state.uri.path;

    if (session.status == SessionStatus.booting) return loc == '/splash' ? null : '/splash';
    if (_isAlwaysOpen(loc)) return null;

    if (!session.isSignedIn) {
      return _signedOutOnly.contains(loc) ? null : '/welcome';
    }
    if (_signedOutOnly.contains(loc) || loc == '/') return '/home';

    final role = session.role;
    if (loc.startsWith('/admin') && role != Role.admin) return '/home';
    if (loc.startsWith('/staff') && !role.isStaff) return '/home';
    if (loc.startsWith('/explore') && role != Role.client) return '/home';
    return null;
  }

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: redirect,
    errorBuilder: (context, state) => Scaffold(
      body: EmptyState(
        icon: Icons.travel_explore_rounded,
        title: 'Page not found',
        message: 'That page does not exist or has moved.',
        actionLabel: 'Go home',
        onAction: () => context.go('/home'),
      ),
    ),
    routes: <RouteBase>[
      GoRoute(path: '/', redirect: (_, __) => '/home'),
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (_, s) => TokenPasswordScreen(mode: TokenPasswordMode.reset, token: s.uri.queryParameters['token']),
      ),
      GoRoute(
        path: '/admin-invitation',
        builder: (_, s) =>
            TokenPasswordScreen(mode: TokenPasswordMode.adminInvitation, token: s.uri.queryParameters['token']),
      ),
      GoRoute(path: '/verify', builder: (_, s) => VerifyScreen(token: s.uri.queryParameters['token'])),
      GoRoute(path: '/verify/:token', builder: (_, s) => VerifyScreen(token: s.pathParameters['token'])),
      GoRoute(path: '/resend-activation', builder: (_, s) => ResendActivationScreen(email: s.uri.queryParameters['email'])),
      GoRoute(path: '/security-report', builder: (_, s) => SecurityReportScreen(token: s.uri.queryParameters['token'])),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
        routes: <RouteBase>[
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
            routes: <RouteBase>[
              GoRoute(path: 'overview', builder: (_, __) => const RoleOverviewPage()),
              GoRoute(path: 'bookings', builder: (_, __) => const ModulePage(module: AppModule.bookings)),
              GoRoute(path: 'payments', builder: (_, __) => const ModulePage(module: AppModule.payments)),
              GoRoute(path: 'transactions', builder: (_, __) => const ModulePage(module: AppModule.transactions)),
              GoRoute(path: 'wishlists', builder: (_, __) => const ModulePage(module: AppModule.wishlists)),
              GoRoute(path: 'messages', builder: (_, __) => const ModulePage(module: AppModule.messages)),
              GoRoute(path: 'about', builder: (_, __) => const ModulePage(module: AppModule.about)),
              GoRoute(path: 'contact', builder: (_, __) => const ModulePage(module: AppModule.contact)),
            ],
          ),
          GoRoute(path: '/explore', builder: (_, __) => const ClientExploreContent()),
          GoRoute(
            path: '/application',
            builder: (_, __) => const ApplicationHubScreen(),
            routes: <RouteBase>[
              GoRoute(path: ':id', builder: (_, s) => ApplicationWizardScreen(applicationId: s.pathParameters['id']!)),
            ],
          ),
          GoRoute(
            path: '/people',
            builder: (_, __) => const PeopleScreen(),
            routes: <RouteBase>[
              GoRoute(path: ':id', builder: (_, s) => PublicProfileScreen(userId: s.pathParameters['id']!)),
            ],
          ),
          GoRoute(
            path: '/account',
            builder: (_, __) => const AccountScreen(),
            routes: <RouteBase>[
              GoRoute(path: 'profile', builder: (_, __) => const ProfileScreen()),
              GoRoute(path: 'profile/edit', builder: (_, __) => const EditProfileScreen()),
              GoRoute(path: 'password', builder: (_, __) => const ChangePasswordScreen()),
              GoRoute(path: 'location', builder: (_, __) => const LocationScreen()),
              GoRoute(path: 'settings', builder: (_, __) => const SettingsScreen()),
              GoRoute(path: 'views', builder: (_, __) => const ProfileViewsScreen()),
              GoRoute(
                path: 'security',
                builder: (_, __) => const SecurityCenterScreen(),
                routes: <RouteBase>[
                  GoRoute(path: 'sessions', builder: (_, __) => const SessionsScreen()),
                  GoRoute(path: 'devices', builder: (_, __) => const DevicesScreen()),
                  GoRoute(path: 'devices/:id', builder: (_, s) => DeviceDetailScreen(deviceId: s.pathParameters['id']!)),
                  GoRoute(path: 'history', builder: (_, __) => const SignInHistoryScreen()),
                  GoRoute(path: 'events', builder: (_, __) => const SecurityEventsScreen()),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/staff',
            builder: (_, __) => const StaffQueueScreen(),
            routes: <RouteBase>[
              GoRoute(path: ':id', builder: (_, s) => StaffDetailScreen(applicationId: s.pathParameters['id']!)),
            ],
          ),
          GoRoute(path: '/admin', redirect: (_, __) => '/admin/users'),
          GoRoute(
            path: '/admin/users',
            builder: (_, __) => const AdminUsersScreen(),
            routes: <RouteBase>[
              GoRoute(path: ':id', builder: (_, s) => AdminUserDetailScreen(userId: s.pathParameters['id']!)),
            ],
          ),
          GoRoute(path: '/admin/audit', builder: (_, s) => AuditScreen(userId: s.uri.queryParameters['userId'])),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
