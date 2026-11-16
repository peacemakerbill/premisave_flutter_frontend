import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/social_models.dart';
import '../../state/data_providers.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';
import 'people_screen.dart';
import 'person_tile.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  bool _busy = false;

  void _reload() {
    ref.invalidate(publicProfileProvider(widget.userId));
    ref.invalidate(followingProvider);
    ref.invalidate(myLikesProvider);
    ref.invalidate(reviewsIWroteProvider);
    ref.invalidate(myStatsProvider);
  }

  Future<void> _toggle(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      _reload();
      if (mounted) showToast(context, done);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openReviewSheet(ReviewModel? existing) async {
    final result = await showModalBottomSheet<_ReviewResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ReviewSheet(existing: existing),
    );
    if (result == null) return;
    final social = ref.read(socialRepositoryProvider);
    await _toggle(
      () => existing == null
          ? social.review(targetId: widget.userId, rating: result.rating, comment: result.comment)
          : social.editReview(reviewId: existing.id, rating: result.rating, comment: result.comment),
      existing == null ? 'Review posted' : 'Review updated',
    );
  }

  Future<void> _deleteReview(ReviewModel r) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete your review?',
      message: 'This removes it from their profile.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!ok) return;
    await _toggle(() => ref.read(socialRepositoryProvider).deleteReview(r.id), 'Review deleted');
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(sessionProvider.select((s) => s.user?.id));
    final isMe = myId == widget.userId;
    final value = ref.watch(publicProfileProvider(widget.userId));
    final social = ref.read(socialRepositoryProvider);

    return SubPage(
      title: isMe ? 'My profile' : 'Profile',
      fallbackRoute: '/people',
      body: AsyncBody<PublicProfile>(
        value: value,
        onRetry: _reload,
        builder: (p) {
          final u = p.user;
          ReviewModel? mine;
          for (final r in p.reviews) {
            if (r.userId == myId) mine = r;
          }
          final others = p.reviews.where((r) => r.userId != myId).toList();
          String fmt(num? n) => (n ?? 0).toInt().toString();

          return PageBody(
            maxWidth: 760,
            onRefresh: () async => _reload(),
            children: <Widget>[
              Center(child: UserAvatar(initials: u.initials, imageUrl: u.profilePictureUrl, size: 104, ring: true)),
              const SizedBox(height: 14),
              Center(child: Text(u.displayName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.6))),
              if (u.username.isNotEmpty) Center(child: Text('@${u.username}', style: TextStyle(color: context.mutedColor, fontWeight: FontWeight.w600))),
              const SizedBox(height: 10),
              Center(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    StatusPill(u.role.label, color: context.isDark ? Brand.gold : Brand.green),
                    if (u.verified) const StatusPill('Verified', color: Brand.success, icon: Icons.verified_rounded),
                    if (u.country.isNotEmpty) StatusPill(u.country, color: Brand.info, icon: Icons.public_rounded),
                    if (p.mutual) const StatusPill('You follow each other', color: Brand.gold),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (isMe)
                PButton(label: 'Edit my profile', icon: Icons.edit_outlined, expand: true, kind: PButtonKind.outline, onPressed: () => context.push('/account/profile/edit'))
              else
                Row(
                  children: <Widget>[
                    Expanded(
                      child: PButton(
                        label: p.following ? 'Following' : 'Follow',
                        icon: p.following ? Icons.check_rounded : Icons.person_add_alt_1_outlined,
                        kind: p.following ? PButtonKind.outline : PButtonKind.primary,
                        loading: _busy,
                        onPressed: _busy ? null : () => _toggle(() => p.following ? social.unfollow(u.id) : social.follow(u.id), p.following ? 'Unfollowed' : 'Following'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PButton(
                        label: p.liked ? 'Liked' : 'Like',
                        icon: p.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        kind: p.liked ? PButtonKind.accent : PButtonKind.outline,
                        onPressed: _busy ? null : () => _toggle(() => p.liked ? social.unlike(u.id) : social.like(u.id), p.liked ? 'Like removed' : 'Liked'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 18),
              ResponsiveWrap(
                minItemWidth: 140,
                children: <Widget>[
                  StatTile(label: 'Followers', value: fmt(p.stats.followers), icon: Icons.group_outlined),
                  StatTile(label: 'Likes', value: fmt(p.stats.likes), icon: Icons.favorite_border_rounded, tint: Brand.danger),
                  StatTile(label: 'Reviews', value: fmt(p.stats.reviews), icon: Icons.star_outline_rounded, tint: Brand.warning),
                ],
              ),
              SectionHeader(
                'Reviews',
                action: isMe ? null : (mine == null ? 'Write a review' : null),
                onAction: isMe ? null : () => _openReviewSheet(null),
              ),
              if (mine != null)
                ReviewCard(
                  review: mine,
                  actions: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton.icon(onPressed: _busy ? null : () => _openReviewSheet(mine), icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Edit')),
                      TextButton.icon(
                        onPressed: _busy ? null : () => _deleteReview(mine!),
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Brand.danger),
                        label: const Text('Delete', style: TextStyle(color: Brand.danger)),
                      ),
                    ],
                  ),
                ),
              if (mine != null && others.isNotEmpty) const SizedBox(height: 10),
              if (others.isEmpty && mine == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(isMe ? 'Nobody has reviewed you yet.' : 'No reviews yet. Be the first.', style: TextStyle(color: context.mutedColor)),
                )
              else
                for (final r in others) ...<Widget>[ReviewCard(review: r), const SizedBox(height: 10)],
            ],
          );
        },
      ),
    );
  }
}

class _ReviewResult {
  const _ReviewResult(this.rating, this.comment);

  final int rating;
  final String? comment;
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({this.existing});

  final ReviewModel? existing;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late int _rating = widget.existing?.rating ?? 0;
  late final TextEditingController _comment = TextEditingController(text: widget.existing?.comment);
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(widget.existing == null ? 'Write a review' : 'Edit your review', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Center(child: StarRating(rating: _rating, size: 40, onChanged: (v) => setState(() { _rating = v; _error = null; }))),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Center(child: Text(_error!, style: const TextStyle(color: Brand.danger, fontSize: 13)))),
            const SizedBox(height: 16),
            PTextField(label: 'Comment', controller: _comment, optional: true, maxLines: 4, minLines: 3, maxLength: 1000, hint: 'What was it like?'),
            const SizedBox(height: 16),
            PButton(
              label: widget.existing == null ? 'Post review' : 'Save changes',
              expand: true,
              onPressed: () {
                if (_rating < 1) {
                  setState(() => _error = 'Choose a rating from 1 to 5 stars');
                  return;
                }
                final c = _comment.text.trim();
                Navigator.of(context).pop(_ReviewResult(_rating, c.isEmpty ? null : c));
              },
            ),
          ],
        ),
      ),
    );
  }
}
