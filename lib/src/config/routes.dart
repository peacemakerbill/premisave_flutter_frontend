import 'package:go_router/go_router.dart';
import '../../main.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/verify_screen.dart';
import '../screens/dashboard/admin/admin_dashboard.dart';
import '../screens/dashboard/client/client_dashboard.dart';
import '../screens/dashboard/finance/finance_dashboard.dart';
import '../screens/dashboard/home-owner/home_owner_dashboard.dart';
import '../screens/dashboard/operartions/operations_dashboard.dart';
import '../screens/dashboard/support/support_dashboard.dart';
import '../screens/other_user_profiles/other_user_profile_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash_screen.dart';
import '../services/secure_storage.dart';

final GoRouter router = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/',
  redirect: (context, state) async {
    final token = await SecureStorage.getToken();
    final role = await SecureStorage.getRole();
    final isAuthenticated = token != null && role != null;

    final currentLocation = state.uri.path;

    final publicRoutes = [
      '/',
      '/splash',
      '/login',
      '/signup',
      '/forgot-password',
      '/reset-password',
      '/verify',
      '/verify/:token',
    ];

    // If user is authenticated and tries to access public routes → redirect to their dashboard
    if (isAuthenticated && publicRoutes.contains(currentLocation)) {
      return _getDashboardRoute(role);
    }

    // Role-based dashboard protection
    if (isAuthenticated) {
      final userDashboard = _getDashboardRoute(role);

      // If user tries to access a different dashboard → redirect to their own
      if (currentLocation.startsWith('/dashboard/') && currentLocation != userDashboard) {
        return userDashboard;
      }
    }

    // Protect private routes
    final privateRoutes = [
      '/dashboard/client',
      '/dashboard/home-owner',
      '/dashboard/admin',
      '/dashboard/operations',
      '/dashboard/finance',
      '/dashboard/support',
      '/profile',
      '/profile/user/:userId',
    ];

    if (!isAuthenticated && privateRoutes.any((route) => currentLocation.startsWith(route.split(':')[0]))) {
      return '/login';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(
      path: '/reset-password',
      builder: (_, state) {
        String? token = state.uri.queryParameters['token'] ?? state.pathParameters['token'];
        return ResetPasswordScreen(resetToken: token);
      },
    ),
    GoRoute(path: '/verify', builder: (_, __) => const VerifyScreen()),
    GoRoute(
      path: '/verify/:token',
      builder: (_, state) => VerifyScreen(verificationToken: state.pathParameters['token']),
    ),

    // Protected Dashboards
    GoRoute(path: '/dashboard/client', builder: (_, __) => const ClientDashboard()),
    GoRoute(path: '/dashboard/home-owner', builder: (_, __) => const HomeOwnerDashboard()),
    GoRoute(path: '/dashboard/admin', builder: (_, __) => const AdminDashboard()),
    GoRoute(path: '/dashboard/operations', builder: (_, __) => const OperationsDashboard()),
    GoRoute(path: '/dashboard/finance', builder: (_, __) => const FinanceDashboard()),
    GoRoute(path: '/dashboard/support', builder: (_, __) => const SupportDashboard()),

    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(
      path: '/profile/user/:userId',
      builder: (_, state) => OtherUserProfileScreen(userId: state.pathParameters['userId'] ?? ''),
    ),
  ],
);

// Helper function to get correct dashboard route based on role
String _getDashboardRoute(String? role) {
  switch (role?.toUpperCase()) {
    case 'CLIENT':
      return '/dashboard/client';
    case 'HOME_OWNER':
      return '/dashboard/home-owner';
    case 'ADMIN':
      return '/dashboard/admin';
    case 'OPERATIONS':
      return '/dashboard/operations';
    case 'FINANCE':
      return '/dashboard/finance';
    case 'SUPPORT':
      return '/dashboard/support';
    default:
      return '/dashboard/client';
  }
}