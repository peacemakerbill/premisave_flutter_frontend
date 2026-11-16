import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/widgets.dart';
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
import '../features/overview/role_overview_page.dart';
import '../features/explore/explore_content.dart';
import '../features/people/people_screen.dart';
import '../features/people/public_profile_screen.dart';
import '../features/security/device_detail_screen.dart';
import '../features/security/devices_screen.dart';
import '../features/security/security_center_screen.dart';
import '../features/security/security_events_screen.dart';
import '../features/security/sessions_screen.dart';
import '../features/security/sign_in_history_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/review/review_detail_screen.dart';
import '../features/review/review_queue_screen.dart';
import '../state/session_controller.dart';
import 'guards.dart';
import 'transitions.dart';

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

    if (!canOpen(session.role, loc)) return '/home';
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
      GoRoute(path: '/splash', pageBuilder: (_, s) => fadePage(s, const SplashScreen())),
      GoRoute(path: '/welcome', pageBuilder: (_, s) => fadePage(s, const WelcomeScreen())),
      GoRoute(path: '/login', pageBuilder: (_, s) => fadePage(s, const LoginScreen())),
      GoRoute(path: '/signup', pageBuilder: (_, s) => fadePage(s, const SignupScreen())),
      GoRoute(path: '/forgot-password', pageBuilder: (_, s) => fadePage(s, const ForgotPasswordScreen())),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (_, s) => fadePage(s, TokenPasswordScreen(mode: TokenPasswordMode.reset, token: s.uri.queryParameters['token'])),
      ),
      GoRoute(
        path: '/admin-invitation',
        pageBuilder: (_, s) => fadePage(s, TokenPasswordScreen(mode: TokenPasswordMode.adminInvitation, token: s.uri.queryParameters['token'])),
      ),
      GoRoute(path: '/verify', pageBuilder: (_, s) => fadePage(s, VerifyScreen(token: s.uri.queryParameters['token']))),
      GoRoute(path: '/verify/:token', pageBuilder: (_, s) => fadePage(s, VerifyScreen(token: s.pathParameters['token']))),
      GoRoute(path: '/resend-activation', pageBuilder: (_, s) => fadePage(s, ResendActivationScreen(email: s.uri.queryParameters['email']))),
      GoRoute(path: '/security-report', pageBuilder: (_, s) => fadePage(s, SecurityReportScreen(token: s.uri.queryParameters['token']))),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
        routes: <RouteBase>[
          GoRoute(
            path: '/home',
            pageBuilder: (_, s) => tabPage(s, const HomeScreen()),
            routes: <RouteBase>[
              GoRoute(path: 'overview', pageBuilder: (_, s) => detailPage(s, const RoleOverviewPage())),
              GoRoute(path: 'bookings', pageBuilder: (_, s) => detailPage(s, const ModulePage(module: AppModule.bookings))),
              GoRoute(path: 'payments', pageBuilder: (_, s) => detailPage(s, const ModulePage(module: AppModule.payments))),
              GoRoute(path: 'transactions', pageBuilder: (_, s) => detailPage(s, const ModulePage(module: AppModule.transactions))),
              GoRoute(path: 'wishlists', pageBuilder: (_, s) => detailPage(s, const ModulePage(module: AppModule.wishlists))),
              GoRoute(path: 'messages', pageBuilder: (_, s) => detailPage(s, const ModulePage(module: AppModule.messages))),
              GoRoute(path: 'about', pageBuilder: (_, s) => detailPage(s, const ModulePage(module: AppModule.about))),
              GoRoute(path: 'contact', pageBuilder: (_, s) => detailPage(s, const ModulePage(module: AppModule.contact))),
            ],
          ),
          GoRoute(path: '/explore', pageBuilder: (_, s) => tabPage(s, const ExploreContent())),
          GoRoute(
            path: '/application',
            pageBuilder: (_, s) => tabPage(s, const ApplicationHubScreen()),
            routes: <RouteBase>[
              GoRoute(path: ':id', pageBuilder: (_, s) => detailPage(s, ApplicationWizardScreen(applicationId: s.pathParameters['id']!))),
            ],
          ),
          GoRoute(
            path: '/people',
            pageBuilder: (_, s) => tabPage(s, const PeopleScreen()),
            routes: <RouteBase>[
              GoRoute(path: ':id', pageBuilder: (_, s) => detailPage(s, PublicProfileScreen(userId: s.pathParameters['id']!))),
            ],
          ),
          GoRoute(
            path: '/account',
            pageBuilder: (_, s) => tabPage(s, const AccountScreen()),
            routes: <RouteBase>[
              GoRoute(path: 'profile', pageBuilder: (_, s) => detailPage(s, const ProfileScreen())),
              GoRoute(path: 'profile/edit', pageBuilder: (_, s) => detailPage(s, const EditProfileScreen())),
              GoRoute(path: 'password', pageBuilder: (_, s) => detailPage(s, const ChangePasswordScreen())),
              GoRoute(path: 'location', pageBuilder: (_, s) => detailPage(s, const LocationScreen())),
              GoRoute(path: 'settings', pageBuilder: (_, s) => detailPage(s, const SettingsScreen())),
              GoRoute(path: 'views', pageBuilder: (_, s) => detailPage(s, const ProfileViewsScreen())),
              GoRoute(
                path: 'security',
                pageBuilder: (_, s) => detailPage(s, const SecurityCenterScreen()),
                routes: <RouteBase>[
                  GoRoute(path: 'sessions', pageBuilder: (_, s) => detailPage(s, const SessionsScreen())),
                  GoRoute(path: 'devices', pageBuilder: (_, s) => detailPage(s, const DevicesScreen())),
                  GoRoute(path: 'devices/:id', pageBuilder: (_, s) => detailPage(s, DeviceDetailScreen(deviceId: s.pathParameters['id']!))),
                  GoRoute(path: 'history', pageBuilder: (_, s) => detailPage(s, const SignInHistoryScreen())),
                  GoRoute(path: 'events', pageBuilder: (_, s) => detailPage(s, const SecurityEventsScreen())),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/staff',
            pageBuilder: (_, s) => tabPage(s, const ReviewQueueScreen()),
            routes: <RouteBase>[
              GoRoute(path: ':id', pageBuilder: (_, s) => detailPage(s, ReviewDetailScreen(applicationId: s.pathParameters['id']!))),
            ],
          ),
          GoRoute(path: '/admin', redirect: (_, __) => '/admin/users'),
          GoRoute(
            path: '/admin/users',
            pageBuilder: (_, s) => tabPage(s, const AdminUsersScreen()),
            routes: <RouteBase>[
              GoRoute(path: ':id', pageBuilder: (_, s) => detailPage(s, AdminUserDetailScreen(userId: s.pathParameters['id']!))),
            ],
          ),
          GoRoute(path: '/admin/audit', pageBuilder: (_, s) => tabPage(s, AuditScreen(userId: s.uri.queryParameters['userId']))),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
