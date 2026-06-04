import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/app_config.dart';
import '../auth/auth_provider.dart';

final socialProvider = StateNotifierProvider<SocialNotifier, SocialState>(
      (ref) => SocialNotifier(ref),
);

// ====================== MODELS ======================

class PublicUserProfile {
  final String id;
  final String username;
  final String firstName;
  final String middleName;
  final String lastName;
  final String? profilePictureUrl;
  final String role;
  final bool verified;
  final String? country;
  final String? phoneNumber;

  const PublicUserProfile({
    required this.id,
    required this.username,
    required this.firstName,
    this.middleName = '',
    required this.lastName,
    this.profilePictureUrl,
    required this.role,
    required this.verified,
    this.country,
    this.phoneNumber,
  });

  String get fullName => '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName'.trim();
  String get displayRole => role.replaceAll('_', ' ').toLowerCase().capitalize();

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) {
    return PublicUserProfile(
      id: json['id'] ?? '',
      username: json['username'] ?? json['displayUsername'] ?? '',
      firstName: json['firstName'] ?? '',
      middleName: json['middleName'] ?? '',
      lastName: json['lastName'] ?? '',
      profilePictureUrl: json['profilePictureUrl'],
      role: (json['role'] ?? 'CLIENT').toString(),
      verified: json['verified'] ?? false,
      country: json['country'],
      phoneNumber: json['phoneNumber'],
    );
  }
}

extension StringExtension on String {
  String capitalize() => isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

class UserStats {
  final int followerCount;
  final int followingCount;
  final int likeCount;
  final double averageRating;
  final int totalReviews;
  final int totalProfileViews;

  const UserStats({
    this.followerCount = 0,
    this.followingCount = 0,
    this.likeCount = 0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.totalProfileViews = 0,
  });

  factory UserStats.fromSocialAndViews(Map<String, dynamic> social, Map<String, dynamic> views) {
    return UserStats(
      followerCount: (social['followerCount'] ?? 0) as int,
      followingCount: (social['followingCount'] ?? 0) as int,
      likeCount: (social['likeCount'] ?? 0) as int,
      averageRating: (social['averageRating'] ?? 0.0).toDouble(),
      totalReviews: (social['totalReviews'] ?? 0) as int,
      totalProfileViews: (views['totalViews'] ?? 0) as int,
    );
  }
}

class ProfileViewEntry {
  final String viewerId;
  final String viewerName;
  final String? viewerProfilePicture;
  final DateTime? viewedAt;
  final String? deviceType;
  final String? source;

  const ProfileViewEntry({
    required this.viewerId,
    required this.viewerName,
    this.viewerProfilePicture,
    this.viewedAt,
    this.deviceType,
    this.source,
  });

  factory ProfileViewEntry.fromJson(Map<String, dynamic> json) {
    return ProfileViewEntry(
      viewerId: json['viewerId'] ?? '',
      viewerName: json['viewerName'] ?? '',
      viewerProfilePicture: json['viewerProfilePicture'],
      viewedAt: json['viewedAt'] != null ? DateTime.tryParse(json['viewedAt'].toString()) : null,
      deviceType: json['deviceType'],
      source: json['source'],
    );
  }
}

class UserReview {
  final String id;
  final String userId;
  final String targetId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserReview({
    required this.id,
    required this.userId,
    required this.targetId,
    required this.rating,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  factory UserReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return UserReview(
      id: json['id'] ?? '',
      userId: (user is Map ? user['id'] : json['userId']) ?? '',
      targetId: json['targetId'] ?? '',
      rating: (json['rating'] ?? 0) as int,
      comment: json['comment'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }
}

// ====================== STATE ======================

class SocialState {
  final List<PublicUserProfile> users;
  final List<PublicUserProfile> searchResults;
  final bool isLoadingUsers;
  final bool isSearching;
  final String? error;
  final Set<String> likedUserIds;
  final Set<String> followingUserIds;

  const SocialState({
    this.users = const [],
    this.searchResults = const [],
    this.isLoadingUsers = false,
    this.isSearching = false,
    this.error,
    this.likedUserIds = const {},
    this.followingUserIds = const {},
  });

  SocialState copyWith({
    List<PublicUserProfile>? users,
    List<PublicUserProfile>? searchResults,
    bool? isLoadingUsers,
    bool? isSearching,
    String? error,
    Set<String>? likedUserIds,
    Set<String>? followingUserIds,
  }) {
    return SocialState(
      users: users ?? this.users,
      searchResults: searchResults ?? this.searchResults,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      isSearching: isSearching ?? this.isSearching,
      error: error,
      likedUserIds: likedUserIds ?? this.likedUserIds,
      followingUserIds: followingUserIds ?? this.followingUserIds,
    );
  }
}

// ====================== NOTIFIER ======================

class SocialNotifier extends StateNotifier<SocialState> {
  final Ref _ref;
  late final Dio _dio;

  SocialNotifier(this._ref) : super(const SocialState()) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
  }

  String? get _token => _ref.read(authProvider).token;
  Options get _auth => Options(headers: {'Authorization': 'Bearer $_token'});

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      textColor: Colors.white,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  // ==================== BASIC METHODS ====================
  Future<void> loadAllUsers() async {
    state = state.copyWith(isLoadingUsers: true, error: null);
    try {
      final res = await _dio.get('/profile/all', options: _auth);
      final users = (res.data as List)
          .map((e) => PublicUserProfile.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(users: users, isLoadingUsers: false);
    } catch (e) {
      state = state.copyWith(isLoadingUsers: false, error: _err(e));
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }
    state = state.copyWith(isSearching: true, error: null);
    try {
      final res = await _dio.get('/profile/search', queryParameters: {'query': query.trim()}, options: _auth);
      final results = (res.data as List)
          .map((e) => PublicUserProfile.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(searchResults: results, isSearching: false);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: _err(e));
    }
  }

  void clearSearch() => state = state.copyWith(searchResults: []);

  Future<PublicUserProfile?> getUserProfile(String userId) async {
    try {
      final res = await _dio.get('/profile/user/$userId', options: _auth);
      return PublicUserProfile.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<UserStats> getUserStats(String userId) async {
    try {
      final results = await Future.wait([
        _dio.get('/social/stats/$userId', options: _auth),
        _dio.get('/profile/views/stats', queryParameters: {'userId': userId}, options: _auth),
      ]);
      return UserStats.fromSocialAndViews(results[0].data as Map<String, dynamic>, results[1].data as Map<String, dynamic>);
    } catch (_) {
      return const UserStats();
    }
  }

  Future<void> recordProfileView(String targetId) async {
    try {
      await _dio.post('/profile/views/$targetId', options: _auth);
    } catch (_) {}
  }

  // ==================== SOCIAL ACTIONS ====================
  Future<void> toggleLike(String targetId) async {
    final isLiked = state.likedUserIds.contains(targetId);
    final updated = Set<String>.from(state.likedUserIds);
    isLiked ? updated.remove(targetId) : updated.add(targetId);
    state = state.copyWith(likedUserIds: updated);

    try {
      final Response res = isLiked
          ? await _dio.delete('/social/unlike/$targetId', options: _auth)
          : await _dio.post('/social/like', data: {'targetId': targetId}, options: _auth);

      final data = res.data as Map<String, dynamic>;
      final success = data['success'] ?? true;
      final message = data['message']?.toString() ?? (isLiked ? 'Unliked' : 'Liked');

      if (success) {
        _showToast(message);
      } else {
        _rollbackLike(targetId, isLiked);
        _showToast(message, isError: true);
      }
    } catch (e) {
      _rollbackLike(targetId, isLiked);
      _showToast(_err(e), isError: true);
    }
  }

  void _rollbackLike(String targetId, bool wasLiked) {
    final rb = Set<String>.from(state.likedUserIds);
    wasLiked ? rb.add(targetId) : rb.remove(targetId);
    state = state.copyWith(likedUserIds: rb);
  }

  Future<void> toggleFollow(String targetId) async {
    final isFollowing = state.followingUserIds.contains(targetId);
    final updated = Set<String>.from(state.followingUserIds);
    isFollowing ? updated.remove(targetId) : updated.add(targetId);
    state = state.copyWith(followingUserIds: updated);

    try {
      final Response res = isFollowing
          ? await _dio.delete('/social/unfollow/$targetId', options: _auth)
          : await _dio.post('/social/follow', data: {'targetId': targetId}, options: _auth);

      final data = res.data as Map<String, dynamic>;
      final success = data['success'] ?? true;
      final message = data['message']?.toString() ?? (isFollowing ? 'Unfollowed' : 'Following');

      if (success) {
        _showToast(message);
      } else {
        _rollbackFollow(targetId, isFollowing);
        _showToast(message, isError: true);
      }
    } catch (e) {
      _rollbackFollow(targetId, isFollowing);
      _showToast(_err(e), isError: true);
    }
  }

  void _rollbackFollow(String targetId, bool wasFollowing) {
    final rb = Set<String>.from(state.followingUserIds);
    wasFollowing ? rb.add(targetId) : rb.remove(targetId);
    state = state.copyWith(followingUserIds: rb);
  }

  // ==================== REVIEWS ====================
  Future<List<UserReview>> getReviews(String targetId) async {
    try {
      final res = await _dio.get('/social/reviews/$targetId', options: _auth);
      return (res.data as List).map((e) => UserReview.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> submitReview({required String targetId, required int rating, String? comment}) async {
    return _performReviewAction('/social/review', 'POST', {
      'targetId': targetId,
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    });
  }

  Future<String?> editReview({required String reviewId, required int rating, String? comment}) async {
    return _performReviewAction('/social/review', 'PUT', {
      'reviewId': reviewId,
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    });
  }

  Future<String?> deleteReview(String reviewId) async {
    return _performReviewAction('/social/review/$reviewId', 'DELETE', null);
  }

  Future<String?> _performReviewAction(String endpoint, String method, Map<String, dynamic>? data) async {
    try {
      Response res;
      if (method == 'POST') {
        res = await _dio.post(endpoint, data: data, options: _auth);
      } else if (method == 'PUT') {
        res = await _dio.put(endpoint, data: data, options: _auth);
      } else {
        res = await _dio.delete(endpoint, options: _auth);
      }

      final responseData = res.data as Map<String, dynamic>;
      final success = responseData['success'] ?? true;
      final message = responseData['message']?.toString() ?? 'Action completed';

      _showToast(message, isError: !success);
      return success ? null : message;
    } catch (e) {
      final msg = _err(e);
      _showToast(msg, isError: true);
      return msg;
    }
  }

  String _err(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final d = e.response!.data;
      if (d is Map<String, dynamic>) return d['message']?.toString() ?? 'Error';
      if (d is String) return d;
    }
    return 'An error occurred';
  }
}