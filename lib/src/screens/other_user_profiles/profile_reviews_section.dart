import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/social/social_provider.dart';

const _kForestGreen = Color(0xFF2D6A4F);
const _kGreenLight = Color(0xFF52B788);
const _kGreenSurface = Color(0xFFD8F3DC);
const _kAmber = Color(0xFFD4A017);
const _kAmberSurface = Color(0xFFFFF8E1);
const _kSoil = Color(0xFF6B4F3A);

// ─── Reviews Section ──────────────────────────────────────────────────────────

class ReviewsSection extends ConsumerStatefulWidget {
  final String targetId;
  final bool isOwnProfile;

  const ReviewsSection({
    super.key,
    required this.targetId,
    required this.isOwnProfile,
  });

  @override
  ConsumerState<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends ConsumerState<ReviewsSection> {
  List<UserReview> _reviews = [];
  bool _loading = true;
  String? _myReviewId;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loading = true);
    final reviews = await ref.read(socialProvider.notifier).getReviews(widget.targetId);
    if (!mounted) return;

    final currentUserId = ref.read(authProvider).currentUser?.id;
    setState(() {
      _reviews = reviews;
      _myReviewId = reviews
          .where((r) => r.userId == currentUserId)
          .map((r) => r.id)
          .firstOrNull;
      _loading = false;
    });
  }

  void _openReviewDialog({UserReview? existing}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _ReviewDialog(
        targetId: widget.targetId,
        existing: existing,
      ),
    );
    if (result == true) _loadReviews();
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete your review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final err = await ref.read(socialProvider.notifier).deleteReview(reviewId);
    if (mounted) {
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      } else {
        _loadReviews();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authProvider).currentUser?.id;
    final hasMyReview = _myReviewId != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: _kAmber, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _kSoil,
                ),
              ),
              const Spacer(),
              if (!widget.isOwnProfile && !hasMyReview)
                GestureDetector(
                  onTap: () => _openReviewDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kAmberSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kAmber.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.rate_review_rounded, size: 14, color: _kAmber),
                        SizedBox(width: 5),
                        Text('Write Review',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kAmber)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2, color: _kAmber),
              ),
            )
          else if (_reviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.reviews_rounded, size: 40, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text('No reviews yet',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.length,
              separatorBuilder: (_, __) => Divider(height: 20, color: Colors.grey[100]),
              itemBuilder: (_, i) {
                final review = _reviews[i];
                final isMyReview = review.userId == currentUserId;
                return _ReviewTile(
                  review: review,
                  isMyReview: isMyReview,
                  onEdit: isMyReview ? () => _openReviewDialog(existing: review) : null,
                  onDelete: isMyReview ? () => _deleteReview(review.id) : null,
                );
              },
            ),
        ],
      ),
    );
  }
}

// ─── Review Tile ──────────────────────────────────────────────────────────────

class _ReviewTile extends StatelessWidget {
  final UserReview review;
  final bool isMyReview;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ReviewTile({
    required this.review,
    required this.isMyReview,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: isMyReview ? _kGreenSurface : Colors.grey[100],
          child: Icon(Icons.person_rounded,
              size: 18,
              color: isMyReview ? _kForestGreen : Colors.grey[400]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isMyReview)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: _kGreenSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('You',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _kForestGreen)),
                    ),
                  _StarRow(rating: review.rating),
                  const Spacer(),
                  if (review.createdAt != null)
                    Text(
                      _formatDate(review.createdAt!),
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                ],
              ),
              if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  review.comment!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
                ),
              ],
              if (isMyReview && (onEdit != null || onDelete != null)) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (onEdit != null)
                      GestureDetector(
                        onTap: onEdit,
                        child: const Text('Edit',
                            style: TextStyle(
                                fontSize: 12,
                                color: _kForestGreen,
                                fontWeight: FontWeight.w600)),
                      ),
                    if (onEdit != null && onDelete != null)
                      Text('  ·  ', style: TextStyle(color: Colors.grey[300])),
                    if (onDelete != null)
                      GestureDetector(
                        onTap: onDelete,
                        child: Text('Delete',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[400],
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Star Row ─────────────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  final int rating;
  final double size;

  const _StarRow({required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: i < rating ? _kAmber : Colors.grey[300],
        );
      }),
    );
  }
}

// ─── Review Dialog ────────────────────────────────────────────────────────────

class _ReviewDialog extends ConsumerStatefulWidget {
  final String targetId;
  final UserReview? existing;

  const _ReviewDialog({required this.targetId, this.existing});

  @override
  ConsumerState<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<_ReviewDialog> {
  late int _rating;
  late TextEditingController _commentCtrl;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rating = widget.existing?.rating ?? 0;
    _commentCtrl = TextEditingController(text: widget.existing?.comment ?? '');
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Please select a rating');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final notifier = ref.read(socialProvider.notifier);
    String? err;

    if (widget.existing != null) {
      err = await notifier.editReview(
        reviewId: widget.existing!.id,
        rating: _rating,
        comment: _commentCtrl.text,
      );
    } else {
      err = await notifier.submitReview(
        targetId: widget.targetId,
        rating: _rating,
        comment: _commentCtrl.text,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (err != null) {
      setState(() => _error = err);
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded, color: _kAmber, size: 26),
                const SizedBox(width: 10),
                Text(
                  isEditing ? 'Edit Review' : 'Write a Review',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Your rating', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = star),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        key: ValueKey('$star-$_rating'),
                        size: 36,
                        color: star <= _rating ? _kAmber : Colors.grey[300],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            const Text('Comment (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kGreenLight),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kForestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : Text(isEditing ? 'Update' : 'Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}