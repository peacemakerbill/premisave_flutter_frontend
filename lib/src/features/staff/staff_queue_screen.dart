import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/application_models.dart';
import '../../state/data_providers.dart';
import '../../state/providers.dart';
import '../application/application_widgets.dart';

/// The review queue for staff: counters, filters and a paged list of applications.
class StaffQueueScreen extends ConsumerStatefulWidget {
  const StaffQueueScreen({super.key});

  @override
  ConsumerState<StaffQueueScreen> createState() => _StaffQueueScreenState();
}

class _StaffQueueScreenState extends ConsumerState<StaffQueueScreen> {
  static const _statusFilters = <(String?, String)>[
    (null, 'All open'),
    ('SUBMITTED', 'Submitted'),
    ('PROCESSING', 'In review'),
    ('INFO_REQUESTED', 'Action needed'),
    ('VERIFIED', 'Verified'),
    ('ACCEPTED', 'Accepted'),
    ('REJECTED', 'Rejected'),
  ];

  final _search = TextEditingController();
  Timer? _debounce;

  final List<ApplicationSummary> _items = <ApplicationSummary>[];
  String? _status;
  String? _assignee;
  String _sort = 'oldest';
  String _q = '';
  int _page = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _total = 0;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 0;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final res = await ref.read(applicationRepositoryProvider).staffSearch(
            q: _q,
            statuses: _status == null ? null : <String>[_status!],
            assignee: _assignee,
            sort: _sort,
            page: _page,
          );
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(res.items);
        _hasMore = res.hasMore;
        _total = res.totalElements;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _refilter() => _load(reset: true);

  Future<void> _refresh() async {
    ref.invalidate(staffStatsProvider);
    await _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(staffStatsProvider);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: ContentWidth(
                maxWidth: 900,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const PageTitle('Applications', subtitle: 'Home owner applications waiting for review.'),
                    const SizedBox(height: 6),
                    stats.maybeWhen(
                      data: (s) => ResponsiveWrap(
                        minItemWidth: 130,
                        children: <Widget>[
                          StatTile(label: 'Awaiting review', value: '${s.awaitingReview}', icon: Icons.hourglass_top_rounded, tint: Brand.info),
                          StatTile(label: 'Unassigned', value: '${s.unassigned}', icon: Icons.person_search_outlined, tint: Brand.warning),
                          StatTile(label: 'Mine', value: '${s.assignedToMe}', icon: Icons.assignment_ind_outlined),
                          StatTile(label: 'Ready to approve', value: '${s.readyToPromote}', icon: Icons.task_alt_rounded, tint: Brand.success),
                        ],
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),
                    PTextField(
                      label: 'Search',
                      controller: _search,
                      hint: 'Name, email, number, ID or phone',
                      prefixIcon: Icons.search_rounded,
                      onChanged: (v) {
                        _debounce?.cancel();
                        _debounce = Timer(const Duration(milliseconds: 450), () {
                          _q = v.trim();
                          _refilter();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: <Widget>[
                          for (final f in _statusFilters)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(f.$2),
                                selected: _status == f.$1,
                                showCheckmark: false,
                                onSelected: (_) {
                                  _status = f.$1;
                                  _refilter();
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: <Widget>[
                              FilterChip(
                                label: const Text('Assigned to me'),
                                selected: _assignee == 'me',
                                showCheckmark: false,
                                onSelected: (on) {
                                  _assignee = on ? 'me' : null;
                                  _refilter();
                                },
                              ),
                              FilterChip(
                                label: const Text('Unassigned'),
                                selected: _assignee == 'none',
                                showCheckmark: false,
                                onSelected: (on) {
                                  _assignee = on ? 'none' : null;
                                  _refilter();
                                },
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Sort',
                          icon: const Icon(Icons.sort_rounded),
                          initialValue: _sort,
                          onSelected: (v) {
                            _sort = v;
                            _refilter();
                          },
                          itemBuilder: (_) => const <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(value: 'oldest', child: Text('Oldest first')),
                            PopupMenuItem<String>(value: 'newest', child: Text('Newest first')),
                            PopupMenuItem<String>(value: 'updated', child: Text('Recently updated')),
                          ],
                        ),
                      ],
                    ),
                    if (!_loading && _error == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 10),
                        child: Text(plural(_total, 'application'), style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                      ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(hasScrollBody: false, child: Padding(padding: EdgeInsets.only(top: 60), child: LoadingState()))
            else if (_error != null)
              SliverFillRemaining(hasScrollBody: false, child: ErrorState(error: _error!, onRetry: _refilter))
            else if (_items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(icon: Icons.inbox_outlined, title: 'Nothing here', message: 'No applications match these filters.'),
              )
            else ...<Widget>[
              SliverList.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => ContentWidth(maxWidth: 900, child: _ApplicationTile(item: _items[i])),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: _hasMore
                        ? PButton(
                            label: 'Load more',
                            kind: PButtonKind.outline,
                            small: true,
                            loading: _loadingMore,
                            onPressed: _loadingMore
                                ? null
                                : () {
                                    _page++;
                                    _load();
                                  },
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  const _ApplicationTile({required this.item});

  final ApplicationSummary item;

  @override
  Widget build(BuildContext context) {
    final c = statusTint(item.statusColor);
    final place = <String>[if (item.region != null) item.region!, if (item.country != null) item.country!].join(', ');
    return PCard(
      onTap: () => context.push('/staff/${item.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(item.applicantName.isEmpty ? item.applicantEmail : item.applicantName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5))),
              const SizedBox(width: 8),
              StatusPill(item.statusLabel, color: c, dense: true),
            ],
          ),
          const SizedBox(height: 3),
          Text('${item.applicationNumber}${place.isEmpty ? '' : ' · $place'}', style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Icon(Icons.description_outlined, size: 15, color: context.mutedColor),
              const SizedBox(width: 4),
              Text('${item.verifiedDocumentCount}/${item.documentCount} verified', style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
              if (item.rejectedDocumentCount > 0) ...<Widget>[const SizedBox(width: 8), StatusPill('${item.rejectedDocumentCount} rejected', color: Brand.danger, dense: true)],
              const Spacer(),
              if (item.submittedAt != null && (item.status == 'SUBMITTED' || item.status == 'PROCESSING'))
                Text('Waiting ${waitingLabel(item.waitingHours)}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: item.waitingHours > 48 ? Brand.warning : context.mutedColor)),
            ],
          ),
          if (item.reviewer != null) ...<Widget>[
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Icon(Icons.assignment_ind_outlined, size: 15, color: context.mutedColor),
                const SizedBox(width: 4),
                Text(item.reviewer!.name, style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
