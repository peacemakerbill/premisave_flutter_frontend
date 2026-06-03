import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_config.dart';
import '../../models/auth/auth_response.dart';
import '../../models/auth/user_model.dart';
import '../../services/secure_storage.dart';
import '../../utils/toast_utils.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
      (ref) => AuthNotifier(),
);

class AuthState {
  final String? token;
  final String? role;
  final UserModel? currentUser;
  final bool isLoading;
  final String? error;
  final String? redirectUrl;
  final bool shouldRedirectToLogin;
  final DateTime? tokenExpiry;

  AuthState({
    this.token,
    this.role,
    this.currentUser,
    this.isLoading = false,
    this.error,
    this.redirectUrl,
    this.shouldRedirectToLogin = false,
    this.tokenExpiry,
  });

  AuthState copyWith({
    String? token,
    String? role,
    UserModel? currentUser,
    bool? isLoading,
    String? error,
    String? redirectUrl,
    bool? shouldRedirectToLogin,
    DateTime? tokenExpiry,
  }) {
    return AuthState(
      token: token ?? this.token,
      role: role ?? this.role,
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      shouldRedirectToLogin: shouldRedirectToLogin ?? this.shouldRedirectToLogin,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AuthNotifier() : super(AuthState()) {
    checkAuthStatus();
  }

  // ==================== AUTH STATUS ====================
  Future<void> checkAuthStatus() async {
    try {
      final token = await SecureStorage.getToken();
      final role = await SecureStorage.getRole();
      final expiry = await SecureStorage.getTokenExpiry();

      if (token != null && role != null) {
        if (await SecureStorage.shouldRefreshToken()) {
          await _refreshToken();
        } else {
          state = state.copyWith(
            token: token,
            role: role,
            tokenExpiry: expiry,
          );
          await loadCurrentUser();
        }
      }
    } catch (e) {
      print('Error checking auth status: $e');
    }
  }

  // ==================== REFRESH TOKEN ====================
  Future<void> _refreshToken() async {
    final oldToken = await SecureStorage.getToken();
    if (oldToken == null) return;

    try {
      state = state.copyWith(isLoading: true);
      final response = await _dio.post(
        '/auth/refresh',
        options: Options(headers: {'Authorization': 'Bearer $oldToken'}),
      );

      final newToken = response.data['token'] as String;
      await SecureStorage.saveToken(newToken);

      final expiry = await SecureStorage.getTokenExpiry();
      state = state.copyWith(
        token: newToken,
        tokenExpiry: expiry,
        isLoading: false,
      );

      await loadCurrentUser();
    } catch (e) {
      print('Token refresh failed: $e');
      await _logoutSilently();
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _logoutSilently() async {
    await SecureStorage.clear();
    state = AuthState();
  }

  // ==================== LOAD CURRENT USER ====================
  Future<void> loadCurrentUser() async {
    if (state.token == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get(
        '/profile/me',
        options: Options(headers: {'Authorization': 'Bearer ${state.token}'}),
      );

      final user = UserModel.fromJson(response.data);
      state = state.copyWith(currentUser: user, isLoading: false);
    } catch (e) {
      print('Error loading user profile: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to load profile');
    }
  }

  // ==================== SIGN UP ====================
  Future<void> signUp(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null, shouldRedirectToLogin: false);
    try {
      final response = await _dio.post('/auth/signup', data: data);
      final authRes = AuthResponse.fromJson(response.data);

      ToastUtils.showSuccessToast('Account created successfully! Please check your email to verify your account.');

      state = state.copyWith(
        isLoading: false,
        shouldRedirectToLogin: true,
      );
    } catch (e) {
      _handleError(e, 'Failed to create account. Please try again.');
    }
  }

  // ==================== SIGN IN ====================
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post('/auth/signin', data: {
        'email': email,
        'password': password,
      });

      final authRes = AuthResponse.fromJson(response.data);

      await SecureStorage.saveToken(authRes.token);
      await SecureStorage.saveRole(authRes.role);

      final expiry = await SecureStorage.getTokenExpiry();

      ToastUtils.showSuccessToast('Welcome back!');

      state = state.copyWith(
        token: authRes.token,
        role: authRes.role,
        redirectUrl: authRes.redirectUrl,
        tokenExpiry: expiry,
        isLoading: false,
        shouldRedirectToLogin: false,
      );

      await loadCurrentUser();
    } catch (e) {
      _handleError(e, 'Login failed. Please try again.');
    }
  }

  // ==================== PASSWORD RESET ====================
  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
      ToastUtils.showSuccessToast('Password reset link sent to your email!');
      state = state.copyWith(isLoading: false);
    } catch (e) {
      _handleError(e, 'Failed to send reset email');
    }
  }

  Future<void> confirmResetPassword(String token, String newPassword, String confirmPassword) async {
    if (newPassword != confirmPassword) {
      ToastUtils.showErrorToast('New passwords do not match');
      state = state.copyWith(error: 'New passwords do not match');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.post('/auth/reset-password', data: {
        'token': token,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      });
      ToastUtils.showSuccessToast('Password has been reset successfully!');
      state = state.copyWith(isLoading: false);
    } catch (e) {
      _handleError(e, 'Failed to reset password');
    }
  }

  // ==================== CHANGE PASSWORD ====================
  Future<void> changePassword(String oldPassword, String newPassword, String confirmPassword) async {
    if (newPassword != confirmPassword) {
      ToastUtils.showErrorToast('New passwords do not match');
      state = state.copyWith(error: 'New passwords do not match');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.post(
        '/auth/change-password',
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
        options: Options(headers: {'Authorization': 'Bearer ${state.token}'}),
      );

      ToastUtils.showSuccessToast('Password changed successfully!');
      state = state.copyWith(isLoading: false);
    } catch (e) {
      _handleError(e, 'Failed to change password');
    }
  }

  // ==================== SOCIAL LOGIN ====================
  Future<void> googleSignIn(BuildContext context) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        ToastUtils.showErrorToast('Failed to get Google credentials');
        state = state.copyWith(isLoading: false, error: 'Failed to get ID token');
        return;
      }

      final response = await _dio.post('/auth/social/google', data: {'token': idToken});
      final authRes = AuthResponse.fromJson(response.data);

      await SecureStorage.saveToken(authRes.token);
      await SecureStorage.saveRole(authRes.role);

      final expiry = await SecureStorage.getTokenExpiry();

      ToastUtils.showSuccessToast('Signed in with Google successfully!');

      state = state.copyWith(
        token: authRes.token,
        role: authRes.role,
        redirectUrl: authRes.redirectUrl,
        tokenExpiry: expiry,
        isLoading: false,
      );

      await loadCurrentUser();
    } catch (e) {
      _handleError(e, 'Google sign-in failed');
    }
  }

  Future<void> facebookSignIn(BuildContext context) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final String accessToken = result.accessToken!.tokenString;

      final response = await _dio.post('/auth/social/facebook', data: {'token': accessToken});
      final authRes = AuthResponse.fromJson(response.data);

      await SecureStorage.saveToken(authRes.token);
      await SecureStorage.saveRole(authRes.role);

      final expiry = await SecureStorage.getTokenExpiry();

      ToastUtils.showSuccessToast('Signed in with Facebook successfully!');

      state = state.copyWith(
        token: authRes.token,
        role: authRes.role,
        redirectUrl: authRes.redirectUrl,
        tokenExpiry: expiry,
        isLoading: false,
      );

      await loadCurrentUser();
    } catch (e) {
      _handleError(e, 'Facebook sign-in failed');
    }
  }

  Future<void> appleSignIn(BuildContext context) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? idToken = credential.identityToken;

      if (idToken == null) {
        ToastUtils.showErrorToast('Apple sign-in failed');
        state = state.copyWith(isLoading: false, error: 'Apple ID token is null');
        return;
      }

      final response = await _dio.post('/auth/social/apple', data: {'token': idToken});
      final authRes = AuthResponse.fromJson(response.data);

      await SecureStorage.saveToken(authRes.token);
      await SecureStorage.saveRole(authRes.role);

      final expiry = await SecureStorage.getTokenExpiry();

      ToastUtils.showSuccessToast('Signed in with Apple successfully!');

      state = state.copyWith(
        token: authRes.token,
        role: authRes.role,
        redirectUrl: authRes.redirectUrl,
        tokenExpiry: expiry,
        isLoading: false,
      );

      await loadCurrentUser();
    } catch (e) {
      _handleError(e, 'Apple sign-in failed');
    }
  }

  // ==================== PROFILE ====================
  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.put(
        '/profile/update',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer ${state.token}'}),
      );

      ToastUtils.showSuccessToast('Profile updated successfully!');
      await loadCurrentUser();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      _handleError(e, 'Failed to update profile');
    }
  }

  Future<String> uploadProfilePicture(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final formData = FormData.fromMap({'file': multipartFile});

      final response = await _dio.post(
        '/profile/upload-profile-picture',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer ${state.token}'}),
      );

      ToastUtils.showSuccessToast('Profile picture uploaded successfully!');
      await loadCurrentUser();

      return response.data['profilePictureUrl']?.toString() ?? '';
    } catch (e) {
      _handleError(e, 'Failed to upload profile picture');
      rethrow;
    }
  }

  // ==================== VERIFICATION ====================
  Future<bool> verifyEmailToken(String verificationToken) async {
    try {
      final response = await _dio.get('/auth/verify/$verificationToken');
      ToastUtils.showSuccessToast('Account verified successfully!');
      return true;
    } catch (e) {
      _handleError(e, 'Verification failed');
      return false;
    }
  }

  Future<bool> resendActivationEmail(String email) async {
    try {
      await _dio.post('/auth/resend-activation', data: {'email': email});
      ToastUtils.showSuccessToast('Activation email resent successfully!');
      return true;
    } catch (e) {
      _handleError(e, 'Failed to resend activation email');
      return false;
    }
  }

  // ==================== ERROR HANDLER ====================
  void _handleError(dynamic e, String defaultMessage) {
    String errorMessage = defaultMessage;

    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        errorMessage = data['message']?.toString() ?? defaultMessage;
      } else if (data is String) {
        errorMessage = data;
      }
    }

    ToastUtils.showErrorToast(errorMessage);
    state = state.copyWith(error: errorMessage, isLoading: false);
  }

  // ==================== UTILITY ====================
  String getDashboardRoute() {
    switch (state.role?.toUpperCase()) {
      case 'CLIENT': return '/dashboard/client';
      case 'HOME_OWNER': return '/dashboard/home-owner';
      case 'ADMIN': return '/dashboard/admin';
      case 'OPERATIONS': return '/dashboard/operations';
      case 'FINANCE': return '/dashboard/finance';
      case 'SUPPORT': return '/dashboard/support';
      default: return '/dashboard/client';
    }
  }

  Future<void> confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SecureStorage.clear();
      state = AuthState();
      ToastUtils.showInfoToast('Logged out successfully');
      if (context.mounted) context.go('/login');
    }
  }
}