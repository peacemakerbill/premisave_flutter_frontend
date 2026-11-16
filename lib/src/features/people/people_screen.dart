import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/social_models.dart';
import '../../data/models/user_model.dart';
import '../../state/data_providers.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';
import 'person_tile.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      bottom: false,
      child: DefaultTabController(
        length: 5,
        child: Column(
          children: <Widget>[
            ContentWidth(
              child: Align(alignment: Alignment.centerLeft, child: PageTitle('People', subtitle: 'Find, follow and review members.')),
            ),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: <Widget>[
                Tab(text: 'Discover'),
                Tab(text: 'Following'),
                Tab(text: 'Followers'),
                Tab(text: 'Liked'),
                Tab(text: 'Reviews'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _DiscoverTab(),
                  _UserListTab(kind: _ListKind.following),
                  _UserListTab(kind: _ListKind.followers),
                  _UserListTab(kind: _ListKind.liked),
                  _ReviewsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- discover

class _DiscoverTab extends ConsumerStatefulWidget {
  const _DiscoverTab();

  @override
  ConsumerState<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends ConsumerState<_DiscoverTab> with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  List<UserModel>? _results;
  bool _searching = false;
  Object? _searchError;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    setState(() => _query = q);
    if (q.length < 2) {
      setState(() {
        _results = null;
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final found = await ref.read(profileRepositoryProvider).search(q);
      if (mounted && q == _query) setState(() => _results = found);
    } catch (e) {
      if (mounted) setState(() => _searchError = e);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final myId = ref.watch(sessionProvider.select((s) => s.user?.id));
    final directory = ref.watch(directoryProvider);

    return Column(
      children: <Widget>[
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: PTextField(
              label: 'Search',
              controller: _search,
              hint: 'Name, username or email',
              prefixIcon: Icons.search_rounded,
              onChanged: _onChanged,
              suffix: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _search.clear();
                        _onChanged('');
                      },
                    ),
            ),
          ),
        ),
        Expanded(
          child: _query.length >= 2
              ? _searchBody(myId)
              : AsyncBody<List<DirectoryEntry>>(
                  value: directory,
                  onRetry: () => ref.invalidate(directoryProvider),
                  builder: (entries) {
                    final list = entries.where((e) => e.id != myId).toList();
                    if (list.isEmpty) {
                      return const EmptyState(icon: Icons.groups_outlined, title: 'Nobody here yet', message: 'Members will show up as they join.');
                    }
                    return _list(
                      onRefresh: () async => ref.invalidate(directoryProvider),
                      tiles: <Widget>[for (final e in list) PersonTile.fromEntry(e)],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _searchBody(String? myId) {
    if (_searching && _results == null) return const LoadingState();
    if (_searchError != null) return ErrorState(error: _searchError!, onRetry: () => _runSearch(_query));
    final list = (_results ?? <UserModel>[]).where((u) => u.id != myId).toList();
    if (list.isEmpty) {
      return EmptyState(icon: Icons.search_off_rounded, title: 'No matches', message: 'Nobody matched "$_query".');
    }
    return _list(tiles: <Widget>[for (final u in list) PersonTile.fromUser(u)]);
  }
}

Widget _list({required List<Widget> tiles, Future<void> Function()? onRefresh}) {
  final list = ListView.separated(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.only(top: 6, bottom: 24),
    itemCount: tiles.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, i) => ContentWidth(maxWidth: 760, child: tiles[i]),
  );
  return onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh, child: list);
}

// ---------------------------------------------------------------- user lists

enum _ListKind { following, followers, liked }

class _UserListTab extends ConsumerWidget {
  const _UserListTab({required this.kind});

  final _ListKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = switch (kind) {
      _ListKind.following => followingProvider,
      _ListKind.followers => followersProvider,
      _ListKind.liked => myLikesProvider,
    };
    final value = ref.watch(provider);

    final (icon, title, message) = switch (kind) {
      _ListKind.following => (Icons.person_add_alt_1_outlined, 'Not following anyone', 'Follow people from the Discover tab to keep up with them.'),
      _ListKind.followers => (Icons.group_outlined, 'No followers yet', 'When someone follows you they will appear here.'),
      _ListKind.liked => (Icons.favorite_border_rounded, 'No likes yet', 'People you like will be listed here.'),
    };

    return AsyncBody<List<UserModel>>(
      value: value,
      onRetry: () => ref.invalidate(provider),
      builder: (users) {
        if (users.isEmpty) return EmptyState(icon: icon, title: title, message: message);
        return _list(
          onRefresh: () async => ref.invalidate(provider),
          tiles: <Widget>[for (final u in users) PersonTile.fromUser(u)],
        );
      },
    );
  }
}

// -------------------------------------------------------------------- reviews

class _ReviewsTab extends ConsumerStatefulWidget {
  const _ReviewsTab();

  @override
  ConsumerState<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends ConsumerState<_ReviewsTab> {
  bool _aboutMe = true;

  @override
  Widget build(BuildContext context) {
    final provider = _aboutMe ? reviewsAboutMeProvider : reviewsIWroteProvider;
    final value = ref.watch(provider);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const <ButtonSegment<bool>>[
              ButtonSegment<bool>(value: true, label: Text('About me')),
              ButtonSegment<bool>(value: false, label: Text('Written by me')),
            ],
            selected: <bool>{_aboutMe},
            onSelectionChanged: (s) => setState(() => _aboutMe = s.first),
          ),
        ),
        Expanded(
          child: AsyncBody<List<ReviewModel>>(
            value: value,
            onRetry: () => ref.invalidate(provider),
            builder: (reviews) {
              if (reviews.isEmpty) {
                return EmptyState(
                  icon: Icons.star_outline_rounded,
                  title: _aboutMe ? 'No reviews yet' : 'You have not written any reviews',
                  message: _aboutMe ? 'Reviews people write about you show up here.' : 'Open someone\'s profile to leave a review.',
                );
              }
              return _list(
                onRefresh: () async => ref.invalidate(provider),
                tiles: <Widget>[for (final r in reviews) ReviewCard(review: r, showTarget: !_aboutMe)],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One review. [showTarget] links to the reviewed person when it is a review you wrote.
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review, this.showTarget = false, this.actions});

  final ReviewModel review;
  final bool showTarget;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final r = review;
    return PCard(
      onTap: showTarget && r.targetId.isNotEmpty ? () => context.push('/people/${r.targetId}') : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              UserAvatar(
                initials: r.reviewer.isEmpty ? 'P' : r.reviewer[0].toUpperCase(),
                imageUrl: r.reviewerPicture,
                size: 38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(showTarget ? 'Review you wrote' : r.reviewer, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    Text(timeAgo(r.updatedAt ?? r.createdAt), style: TextStyle(fontSize: 12, color: context.mutedColor)),
                  ],
                ),
              ),
              StarRating(rating: r.rating),
            ],
          ),
          if (r.comment != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(r.comment!, style: const TextStyle(fontSize: 14, height: 1.45)),
          ],
          if (actions != null) ...<Widget>[const SizedBox(height: 8), actions!],
        ],
      ),
    );
  }
}
