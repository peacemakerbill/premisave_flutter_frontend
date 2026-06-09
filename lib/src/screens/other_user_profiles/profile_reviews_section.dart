import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/social/social_provider.dart';

const _green  = Color(0xFF2D6A4F);
const _greenL = Color(0xFF52B788);
const _greenS = Color(0xFFD8F3DC);
const _amber  = Color(0xFFD4A017);
const _amberS = Color(0xFFFFF3CD);
const _soil   = Color(0xFF5C3D2E);

class ReviewsSection extends ConsumerStatefulWidget {
  final String targetId;
  final bool isOwnProfile;
  const ReviewsSection({super.key, required this.targetId, required this.isOwnProfile});
  @override
  ConsumerState<ReviewsSection> createState() => _State();
}

class _State extends ConsumerState<ReviewsSection> {
  List<UserReview> _reviews = [];
  bool _loading = true;
  String? _myReviewId;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final reviews = await ref.read(socialProvider.notifier).getReviews(widget.targetId);
    if (!mounted) return;
    final me = ref.read(authProvider).currentUser?.id;
    setState(() {
      _reviews = reviews;
      _myReviewId = reviews.where((r) => r.userId == me).map((r) => r.id).firstOrNull;
      _loading = false;
    });
  }

  Future<void> _openDialog({UserReview? existing}) async {
    final ok = await showDialog<bool>(context: context,
        builder: (_) => _ReviewDialog(targetId: widget.targetId, existing: existing));
    if (ok == true) _load();
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete review?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _soil)),
        content: const Text('This can\'t be undone.',
            style: TextStyle(color: Color(0xFF666666))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    final err = await ref.read(socialProvider.notifier).deleteReview(id);
    if (mounted) {
      if (err != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      else _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authProvider).currentUser?.id;
    final hasOwn = _myReviewId != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          const Icon(Icons.star_rounded, color: _amber, size: 20),
          const SizedBox(width: 8),
          const Text('Reviews', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
              color: _soil)),
          const Spacer(),
          if (!widget.isOwnProfile && !hasOwn)
            GestureDetector(
              onTap: _openDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _amberS, borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _amber.withOpacity(0.3))),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.edit_rounded, size: 13, color: _amber),
                  SizedBox(width: 5),
                  Text('Write', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: _amber)),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 14),
        // Body
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2, color: _amber)))
        else if (_reviews.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(children: [
              Icon(Icons.rate_review_outlined, size: 38, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text('No reviews yet',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            ]),
          ))
        else
          ListView.separated(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (_, __) => Divider(height: 20, color: Colors.grey[100]),
            itemBuilder: (_, i) {
              final r = _reviews[i];
              final mine = r.userId == me;
              return _ReviewTile(
                review: r, isMyReview: mine,
                onEdit: mine ? () => _openDialog(existing: r) : null,
                onDelete: mine ? () => _delete(r.id) : null,
              );
            },
          ),
      ]),
    );
  }
}

// ── Review Tile ───────────────────────────────────────────────────────────────

class _ReviewTile extends StatelessWidget {
  final UserReview review;
  final bool isMyReview;
  final VoidCallback? onEdit, onDelete;
  const _ReviewTile({required this.review, required this.isMyReview, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CircleAvatar(
        radius: 17,
        backgroundColor: isMyReview ? _greenS : Colors.grey[100],
        child: Icon(Icons.person_rounded, size: 16,
            color: isMyReview ? _green : Colors.grey[400]),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (isMyReview) ...[
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: _greenS, borderRadius: BorderRadius.circular(6)),
                child: const Text('You', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: _green))),
          ],
          _Stars(review.rating),
          const Spacer(),
          if (review.createdAt != null)
            Text(_fmt(review.createdAt!),
                style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))),
        ]),
        if (review.comment?.trim().isNotEmpty ?? false) ...[
          const SizedBox(height: 5),
          Text(review.comment!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.45)),
        ],
        if (isMyReview && (onEdit != null || onDelete != null)) ...[
          const SizedBox(height: 6),
          Row(children: [
            if (onEdit != null)
              GestureDetector(onTap: onEdit,
                  child: const Text('Edit', style: TextStyle(fontSize: 12, color: _green,
                      fontWeight: FontWeight.w600))),
            if (onEdit != null && onDelete != null)
              const Text('  ·  ', style: TextStyle(color: Color(0xFFCCCCCC))),
            if (onDelete != null)
              GestureDetector(onTap: onDelete,
                  child: const Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red,
                      fontWeight: FontWeight.w600))),
          ]),
        ],
      ])),
    ]);
  }

  String _fmt(DateTime dt) {
    final d = DateTime.now().difference(dt).inDays;
    if (d == 0) return 'Today';
    if (d == 1) return 'Yesterday';
    if (d < 7)  return '${d}d ago';
    if (d < 30) return '${d ~/ 7}w ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _Stars extends StatelessWidget {
  final int rating;
  const _Stars(this.rating);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) => Icon(
      i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
      size: 13, color: i < rating ? _amber : Colors.grey[300],
    )),
  );
}

// ── Review Dialog ─────────────────────────────────────────────────────────────

class _ReviewDialog extends ConsumerStatefulWidget {
  final String targetId;
  final UserReview? existing;
  const _ReviewDialog({required this.targetId, this.existing});
  @override
  ConsumerState<_ReviewDialog> createState() => _DialogState();
}

class _DialogState extends ConsumerState<_ReviewDialog> {
  late int _rating;
  late TextEditingController _ctrl;
  bool _submitting = false;
  String? _error;
  int _hoverRating = 0;

  @override
  void initState() {
    super.initState();
    _rating = widget.existing?.rating ?? 0;
    _ctrl = TextEditingController(text: widget.existing?.comment ?? '');
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Please select a rating');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    final n = ref.read(socialProvider.notifier);
    final err = widget.existing != null
        ? await n.editReview(reviewId: widget.existing!.id, rating: _rating, comment: _ctrl.text)
        : await n.submitReview(targetId: widget.targetId, rating: _rating, comment: _ctrl.text);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (err != null) setState(() => _error = err);
    else Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    final activeRating = _hoverRating > 0 ? _hoverRating : _rating;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _amberS,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.star_rounded, color: _amber, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  editing ? 'Edit review' : 'Write a review',
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _soil,
                  ),
                ),
              ]),
              const SizedBox(height: 22),

              // Rating label
              const Text('Your rating',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: Color(0xFF888888))),
              const SizedBox(height: 10),

              // Stars — hover-aware
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final s = i + 1;
                  final filled = s <= activeRating;
                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoverRating = s),
                    onExit: (_) => setState(() => _hoverRating = 0),
                    child: GestureDetector(
                      onTap: () => setState(() { _rating = s; _error = null; }),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 120),
                          child: Icon(
                            filled ? Icons.star_rounded : Icons.star_outline_rounded,
                            key: ValueKey('$s-$filled'),
                            size: 36,
                            color: filled ? _amber : const Color(0xFFDDDDDD),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),

              // Comment label
              Row(children: const [
                Text('Comment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: Color(0xFF888888))),
                SizedBox(width: 4),
                Text('(optional)', style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB))),
              ]),
              const SizedBox(height: 8),

              // Text field
              TextField(
                controller: _ctrl,
                maxLines: 3,
                maxLength: 1000,
                style: const TextStyle(fontSize: 13, color: _soil),
                decoration: InputDecoration(
                  hintText: 'Share your experience…',
                  hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  counterStyle: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _greenL, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.info_outline_rounded, size: 13, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(_error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12)),
                ]),
              ],
              const SizedBox(height: 20),

              // Actions
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Color(0xFFDDDDDD)),
                    foregroundColor: const Color(0xFF888888),
                    backgroundColor: Colors.transparent,
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                )),
                const SizedBox(width: 10),
                Expanded(child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    disabledBackgroundColor: Color(0xFF2D6A4F80),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(editing ? 'Update' : 'Submit',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}