import 'json_utils.dart';

/// Review as returned by /social/reviews/{id}, /social/my-reviews and /social/my-written-reviews.
class ReviewModel {
  ReviewModel(Map<String, dynamic> j)
      : id = strOr(j['id']),
        userId = strOr(j['userId']),
        reviewerName = str(j['reviewerName']),
        reviewerEmail = str(j['reviewerEmail']),
        reviewerPicture = str(j['reviewerProfilePicture']),
        targetId = strOr(j['targetId']),
        rating = intOr(j['rating']),
        comment = str(j['comment']),
        createdAt = dateOrNull(j['createdAt']),
        updatedAt = dateOrNull(j['updatedAt']);

  final String id;
  final String userId;
  final String? reviewerName;
  final String? reviewerEmail;
  final String? reviewerPicture;
  final String targetId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get reviewer => reviewerName ?? 'Former member';
}

/// A row of the public directory. The backend may name fields slightly differently
/// between versions, so several spellings are accepted.
class DirectoryEntry {
  DirectoryEntry(Map<String, dynamic> j)
      : id = strOr(j['id'] ?? j['userId']),
        name = _name(j),
        username = str(j['username']),
        role = str(j['role']),
        country = str(j['country']),
        picture = str(j['profilePictureUrl'] ?? j['profilePicture'] ?? j['avatar']);

  final String id;
  final String name;
  final String? username;
  final String? role;
  final String? country;
  final String? picture;

  static String _name(Map<String, dynamic> j) {
    final direct = str(j['displayName'] ?? j['fullName'] ?? j['name']);
    if (direct != null) return direct;
    final n = '${strOr(j['firstName'])} ${strOr(j['lastName'])}'.trim();
    if (n.isNotEmpty) return n;
    return str(j['username']) ?? 'Premisave member';
  }

  String get initials {
    final bits = name.trim().split(RegExp(r'\s+'));
    if (bits.length > 1 && bits[0].isNotEmpty && bits[1].isNotEmpty) {
      return (bits[0][0] + bits[1][0]).toUpperCase();
    }
    return name.isEmpty ? 'P' : name[0].toUpperCase();
  }
}

/// Counters for a user (likes, followers, reviews, profile views). The field names are
/// read leniently and every numeric field is also exposed through [numbers], so the
/// screen still shows something useful if the backend adds or renames fields.
class StatsModel {
  StatsModel(this.raw);

  final Map<String, dynamic> raw;

  num? pick(List<String> keys) {
    for (final k in keys) {
      final v = raw[k];
      if (v is num) return v;
      if (v is String) {
        final n = num.tryParse(v);
        if (n != null) return n;
      }
    }
    return null;
  }

  num? get likes => pick(['likes', 'likeCount', 'totalLikes', 'likesCount', 'likesReceived']);
  num? get followers => pick(['followers', 'followerCount', 'totalFollowers', 'followersCount']);
  num? get following => pick(['following', 'followingCount', 'totalFollowing']);
  num? get reviews => pick(['reviews', 'reviewCount', 'totalReviews', 'reviewsCount']);
  num? get rating => pick(['averageRating', 'avgRating', 'rating']);
  num? get views => pick(['totalViews', 'views', 'viewCount', 'profileViews']);

  /// Every numeric field as a readable label and value.
  List<MapEntry<String, num>> get numbers {
    final out = <MapEntry<String, num>>[];
    raw.forEach((k, v) {
      if (v is num && k != 'rating' && k != 'averageRating') out.add(MapEntry(humanize(k), v));
    });
    return out;
  }
}

/// One profile view entry (who viewed me, who I viewed).
class ProfileViewEntry {
  ProfileViewEntry(Map<String, dynamic> j)
      : user = _user(j),
        at = dateOrNull(j['viewedAt'] ?? j['at'] ?? j['createdAt'] ?? j['timestamp']),
        count = intOrNull(j['count'] ?? j['viewCount']);

  final DirectoryEntry user;
  final DateTime? at;
  final int? count;

  static DirectoryEntry _user(Map<String, dynamic> j) {
    for (final key in ['viewer', 'user', 'target', 'profile']) {
      final inner = j[key];
      if (inner is Map) return DirectoryEntry(asMap(inner));
    }
    return DirectoryEntry(j);
  }
}

/// "followerCount" becomes "Follower count".
String humanize(String key) {
  final spaced = key
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ')
      .trim()
      .toLowerCase();
  if (spaced.isEmpty) return key;
  return spaced[0].toUpperCase() + spaced.substring(1);
}
