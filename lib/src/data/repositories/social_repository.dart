import '../../core/network/api_client.dart';
import '../models/json_utils.dart';
import '../models/social_models.dart';
import '../models/user_model.dart';

/// /social endpoints: likes, follows and reviews.
class SocialRepository {
  SocialRepository(this._api);

  final ApiClient _api;

  String _id(String s) => Uri.encodeComponent(s);

  Future<void> like(String targetId) => _api.post('/social/like', body: {'targetId': targetId});
  Future<void> unlike(String targetId) => _api.delete('/social/unlike/${_id(targetId)}');
  Future<void> follow(String targetId) => _api.post('/social/follow', body: {'targetId': targetId});
  Future<void> unfollow(String targetId) => _api.delete('/social/unfollow/${_id(targetId)}');

  Future<void> review({required String targetId, required int rating, String? comment}) =>
      _api.post('/social/review', body: compact({'targetId': targetId, 'rating': rating, 'comment': comment}));

  Future<void> editReview({required String reviewId, required int rating, String? comment}) =>
      _api.put('/social/review', body: compact({'reviewId': reviewId, 'rating': rating, 'comment': comment}));

  Future<void> deleteReview(String reviewId) => _api.delete('/social/review/${_id(reviewId)}');

  Future<List<ReviewModel>> reviewsFor(String targetId) async =>
      mapList(await _api.get('/social/reviews/${_id(targetId)}')).map(ReviewModel.new).toList();

  Future<List<ReviewModel>> myReviews() async =>
      mapList(await _api.get('/social/my-reviews')).map(ReviewModel.new).toList();

  Future<List<ReviewModel>> myWrittenReviews() async =>
      mapList(await _api.get('/social/my-written-reviews')).map(ReviewModel.new).toList();

  Future<List<UserModel>> myLikes() async =>
      mapList(await _api.get('/social/my-likes')).map(UserModel.fromJson).toList();

  Future<List<UserModel>> myLikers() async =>
      mapList(await _api.get('/social/my-likers')).map(UserModel.fromJson).toList();

  Future<List<UserModel>> myFollowing() async =>
      mapList(await _api.get('/social/my-following')).map(UserModel.fromJson).toList();

  Future<List<UserModel>> myFollowers() async =>
      mapList(await _api.get('/social/my-followers')).map(UserModel.fromJson).toList();

  Future<StatsModel> stats(String userId) async =>
      StatsModel(asMap(await _api.get('/social/stats/${_id(userId)}')));

  Future<bool> likeStatus(String targetId) async =>
      boolOr(asMap(await _api.get('/social/like/status/${_id(targetId)}'))['liked']);

  Future<bool> followStatus(String targetId) async =>
      boolOr(asMap(await _api.get('/social/follow/status/${_id(targetId)}'))['following']);

  Future<bool> reviewStatus(String targetId) async =>
      boolOr(asMap(await _api.get('/social/review/status/${_id(targetId)}'))['reviewed']);

  Future<bool> mutualFollow(String targetId) async =>
      boolOr(asMap(await _api.get('/social/follow/mutual/${_id(targetId)}'))['mutual']);
}
