import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/social_models.dart';
import '../../state/data_providers.dart';

class ProfileViewsScreen extends ConsumerWidget {
  const ProfileViewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(myViewStatsProvider);

    return DefaultTabController(
      length: 2,
      child: SubPage(
        title: 'Profile views',
        fallbackRoute: '/account',
        body: Column(
          children: <Widget>[
            stats.maybeWhen(
              data: (s) {
                final numbers = s.numbers.take(4).toList();
                if (numbers.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: ContentWidth(
                    padding: EdgeInsets.zero,
                    child: ResponsiveWrap(
                      minItemWidth: 140,
                      children: <Widget>[
                        for (final n in numbers)
                          StatTile(label: n.key, value: '${n.value.toInt()}', icon: Icons.visibility_outlined, tint: Brand.info),
                      ],
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            const TabBar(
              tabs: <Widget>[Tab(text: 'Viewed me'), Tab(text: 'I viewed')],
            ),
            const Expanded(
              child: TabBarView(
                children: <Widget>[_ViewList(mine: true), _ViewList(mine: false)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewList extends ConsumerWidget {
  const _ViewList({required this.mine});

  final bool mine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = mine ? whoViewedMeProvider : whoIViewedProvider;
    final value = ref.watch(provider);
    return AsyncBody<List<ProfileViewEntry>>(
      value: value,
      onRetry: () => ref.invalidate(provider),
      builder: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.visibility_off_outlined,
            title: mine ? 'No views yet' : 'You have not looked at anyone',
            message: mine
                ? 'When people open your profile they will show up here. A complete profile gets noticed more.'
                : 'Profiles you open will be listed here, so you can find them again.',
            actionLabel: mine ? 'Complete my profile' : 'Browse people',
            onAction: () => context.go(mine ? '/account/profile/edit' : '/people'),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(provider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final v = items[i];
              return ContentWidth(
                maxWidth: 720,
                padding: EdgeInsets.zero,
                child: PCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  onTap: v.user.id.isEmpty ? null : () => context.push('/people/${v.user.id}'),
                  child: Row(
                    children: <Widget>[
                      UserAvatar(initials: v.user.initials, imageUrl: v.user.picture, size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(v.user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            if (v.user.username != null && v.user.username!.isNotEmpty && v.user.username != v.user.name)
                              Text('@${v.user.username}', style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                            RelativeTime(v.at),
                          ],
                        ),
                      ),
                      if (v.count != null && v.count! > 1) StatusPill('${v.count}x', color: Brand.info, dense: true),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
