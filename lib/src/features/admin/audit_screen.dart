import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/utils/audit_labels.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/security_models.dart';
import '../../state/data_providers.dart';
import '../security/security_widgets.dart';
import 'audit_summary.dart';

const String _any = 'ALL';

/// How far back the list goes. The date is worked out when the choice is made, so the list does not shift while it is open.
const List<PChoice<String>> _ranges = <PChoice<String>>[
  PChoice<String>(_any, 'Any time'),
  PChoice<String>('today', 'Today'),
  PChoice<String>('24h', 'Last 24 hours'),
  PChoice<String>('7d', 'Last 7 days'),
  PChoice<String>('30d', 'Last 30 days'),
];

const List<PChoice<String>> _severities = <PChoice<String>>[
  PChoice<String>(_any, 'Any severity'),
  PChoice<String>('INFO', 'Information', description: 'Routine activity'),
  PChoice<String>('WARNING', 'Warning', description: 'Worth a look'),
  PChoice<String>('CRITICAL', 'Critical', description: 'Needs action'),
];

const List<PChoice<String>> _outcomes = <PChoice<String>>[
  PChoice<String>(_any, 'Any result'),
  PChoice<String>('SUCCESS', 'Succeeded'),
  PChoice<String>('FAILURE', 'Failed'),
];

List<PChoice<String>> _eventChoices() {
  final choices = <PChoice<String>>[const PChoice<String>(_any, 'Any event')];
  for (final category in auditCategories) {
    for (final type in auditTypesIn(category)) {
      choices.add(PChoice<String>(type, auditLabel(type).title, description: category));
    }
  }
  return choices;
}

DateTime? _since(String range) {
  final now = DateTime.now();
  switch (range) {
    case 'today':
      return DateTime(now.year, now.month, now.day);
    case '24h':
      return now.subtract(const Duration(hours: 24));
    case '7d':
      return now.subtract(const Duration(days: 7));
    case '30d':
      return now.subtract(const Duration(days: 30));
    default:
      return null;
  }
}

/// Administrators: the account activity trail across the platform, optionally for one user or one address.
class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key, this.userId, this.q, this.type, this.ip, this.severity, this.staff = false, this.range});

  /// Pre-filters, filled by the router from `?userId=`, `?q=`, `?type=`, `?ip=`, `?severity=`, `?group=staff` and `?range=`.
  final String? userId;
  final String? q;
  final String? type;
  final String? ip;
  final String? severity;
  final bool staff;

  /// How far back to look: today, 24h, 7d or 30d. Anything else means any time.
  final String? range;

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  late String? _type = widget.type;
  late String? _severity = widget.severity;
  late bool _staff = widget.staff;
  late String? _ip = widget.ip;
  late String? _userId = widget.userId;
  late String? _q = (widget.q == null || widget.q!.trim().isEmpty) ? null : widget.q!.trim();
  late final TextEditingController _search = TextEditingController(text: _q ?? '');
  Timer? _debounce;
  String? _outcome;
  late String _range = const <String>{'today', '24h', '7d', '30d'}.contains(widget.range) ? widget.range! : _any;
  late DateTime? _from = _since(_range);

  /// How many pages of 50 are loaded.
  int _pages = 1;

  late final List<PChoice<String>> _eventOptions = _eventChoices();

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Searches as the person types, a moment after they stop, so each key does not send a request.
  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _applySearch(text));
  }

  void _applySearch(String text) {
    if (!mounted) return;
    final clean = text.trim();
    _change(() => _q = clean.isEmpty ? null : clean);
  }

  AuditFilter _filterFor(int page) => AuditFilter(
        q: _q,
        type: _type,
        staff: _staff,
        userId: _userId,
        severity: _severity,
        outcome: _outcome,
        ip: _ip,
        from: _from,
        page: page,
      );

  bool get _narrowed => _filterFor(0).narrowed || _userId != null;

  void _change(VoidCallback update) => setState(() {
        update();
        _pages = 1;
      });

  void _clear() => _change(() {
        _debounce?.cancel();
        _search.clear();
        _q = null;
        _type = null;
        _staff = false;
        _severity = null;
        _outcome = null;
        _ip = null;
        _userId = null;
        _range = _any;
        _from = null;
      });

  Future<void> _refresh() async {
    for (var p = 0; p < _pages; p++) {
      ref.invalidate(auditEventsProvider(_filterFor(p)));
    }
    ref.invalidate(auditSummaryProvider(24));
    await ref.read(auditEventsProvider(_filterFor(0)).future);
  }

  @override
  Widget build(BuildContext context) {
    final events = <SecurityEventView>[];
    Object? error;
    var loading = false;
    var hasMore = false;
    for (var p = 0; p < _pages; p++) {
      final page = ref.watch(auditEventsProvider(_filterFor(p)));
      if (page.hasError) {
        error ??= page.error;
      } else if (page.hasValue) {
        final items = page.value!;
        events.addAll(items);
        hasMore = items.length >= auditPageSize;
      } else {
        loading = true;
        hasMore = false;
      }
    }

    return SubPage(
      title: _userId == null ? 'Audit trail' : 'User activity',
      fallbackRoute: '/admin/security',
      body: PageBody(
        maxWidth: 820,
        onRefresh: _refresh,
        children: <Widget>[
          if (_userId == null && !_narrowed) ...<Widget>[
            AuditSummaryStrip(
              onEvents: () => _change(() {
                _range = '24h';
                _from = _since(_range);
              }),
            ),
            const SectionHeader('All events'),
          ],
          PTextField(
            // The key keeps the field, and its focus, when the summary above it appears or goes away while typing.
            key: const ValueKey<String>('audit-search'),
            label: 'Search',
            controller: _search,
            hint: 'Name, username, email, IP address, device, event, anything',
            prefixIcon: Icons.search_rounded,
            textInputAction: TextInputAction.search,
            onChanged: _onSearchChanged,
            onSubmitted: (v) {
              _debounce?.cancel();
              _applySearch(v);
            },
            suffix: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _debounce?.cancel();
                      _search.clear();
                      _applySearch('');
                    },
                  ),
            helper: 'Use several words to narrow it down, for example "john failed" or "nairobi chrome".',
          ),
          const SizedBox(height: 14),
          _Filters(
            range: _range,
            severity: _severity ?? _any,
            outcome: _outcome ?? _any,
            type: _type ?? _any,
            eventOptions: _eventOptions,
            onRange: (v) => _change(() {
              _range = v ?? _any;
              _from = _since(_range);
            }),
            onSeverity: (v) => _change(() => _severity = (v == null || v == _any) ? null : v),
            onOutcome: (v) => _change(() => _outcome = (v == null || v == _any) ? null : v),
            onType: (v) => _change(() {
              _type = (v == null || v == _any) ? null : v;
              if (_type != null) _staff = false;
            }),
          ),
          if (_ip != null || _userId != null || (_staff && _type == null)) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (_userId != null)
                  InputChip(
                    avatar: const Icon(Icons.person_outline_rounded, size: 18),
                    label: const Text('One account'),
                    onDeleted: () => _change(() => _userId = null),
                  ),
                if (_staff && _type == null)
                  InputChip(
                    avatar: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                    label: const Text('Staff changes only'),
                    onDeleted: () => _change(() => _staff = false),
                  ),
                if (_ip != null)
                  InputChip(
                    avatar: const Icon(Icons.public_rounded, size: 18),
                    label: Text('Address $_ip'),
                    onDeleted: () => _change(() => _ip = null),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          if (error != null && events.isEmpty)
            ErrorState(error: error, onRetry: _refresh)
          else if (events.isEmpty && loading)
            const SkeletonList(kind: SkeletonKind.row, count: 6, shrink: true, padding: EdgeInsets.symmetric(vertical: 8))
          else if (events.isEmpty)
            EmptyState(
              icon: Icons.list_alt_rounded,
              title: 'Nothing recorded',
              message: _narrowed ? 'No events match these filters.' : 'Events will appear here as people use the platform.',
              actionLabel: _narrowed ? 'Clear filters' : null,
              onAction: _narrowed ? _clear : null,
            )
          else ...<Widget>[
            ..._days(context, events),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InlineMessage('Could not load more events.', kind: MessageKind.error, actionLabel: 'Try again', onAction: _refresh),
              ),
            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: SkeletonList(kind: SkeletonKind.row, count: 2, shrink: true, padding: EdgeInsets.symmetric(vertical: 4)),
              )
            else if (hasMore)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: PButton(label: 'Show more', kind: PButtonKind.outline, expand: true, onPressed: () => setState(() => _pages++)),
              ),
          ],
        ],
      ),
    );
  }

  /// One card per day, newest first, each under a heading such as "Today" or "12 Nov 2026".
  List<Widget> _days(BuildContext context, List<SecurityEventView> events) {
    final out = <Widget>[];
    String? day;
    var group = <SecurityEventView>[];

    void flush() {
      if (group.isEmpty) return;
      out.add(SectionHeader(day ?? 'Earlier', padding: EdgeInsets.only(top: out.isEmpty ? 0 : 22, bottom: 10)));
      out.add(MenuGroup(children: <Widget>[for (final e in group) _EventTile(event: e)]));
      group = <SecurityEventView>[];
    }

    for (final e in events) {
      final label = _dayLabel(e.createdAt);
      if (label != day) {
        flush();
        day = label;
      }
      group.add(e);
    }
    flush();
    return out;
  }
}

String _dayLabel(DateTime? d) {
  if (d == null) return 'Earlier';
  final l = d.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(l.year, l.month, l.day);
  final diff = today.difference(that).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return formatDate(l);
}

String _clock(DateTime? d) {
  if (d == null) return '';
  final l = d.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.range,
    required this.severity,
    required this.outcome,
    required this.type,
    required this.eventOptions,
    required this.onRange,
    required this.onSeverity,
    required this.onOutcome,
    required this.onType,
  });

  final String range;
  final String severity;
  final String outcome;
  final String type;
  final List<PChoice<String>> eventOptions;
  final ValueChanged<String?> onRange;
  final ValueChanged<String?> onSeverity;
  final ValueChanged<String?> onOutcome;
  final ValueChanged<String?> onType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ResponsiveWrap(
          minItemWidth: 150,
          maxColumns: 4,
          children: <Widget>[
            PSelectField<String>(label: 'When', options: _ranges, value: range, onChanged: onRange),
            PSelectField<String>(label: 'Severity', options: _severities, value: severity, onChanged: onSeverity),
            PSelectField<String>(label: 'Result', options: _outcomes, value: outcome, onChanged: onOutcome),
            PSelectField<String>(label: 'Event', options: eventOptions, value: type, onChanged: onType),
          ],
        ),
      ],
    );
  }
}

/// One line in the trail: what happened, to whom and by whom, from where, and when.
class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final SecurityEventView event;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final who = <String>[
      if (e.personLabel != null) e.personLabel!,
      if (e.actorLabel != null && e.actor != e.userId) 'by ${e.actorLabel}',
    ].join(' ');
    final where = <String>[
      _clock(e.createdAt),
      if (e.deviceLabel != null) e.deviceLabel!,
      if (e.ipAddress != null) e.ipAddress!,
      if (e.place.isNotEmpty) e.place,
    ].join(' · ');
    final lines = <String>[
      if (who.isNotEmpty) who,
      where,
      if (e.reason != null) e.reason!,
    ];
    return MenuTile(
      icon: eventIcon(e.type),
      tint: e.isFailure ? Brand.danger : severityColor(e.severity),
      title: e.title,
      subtitle: lines.join('\n'),
      trailing: e.isCritical
          ? const StatusPill('Critical', dense: true, color: Brand.danger)
          : e.isFailure
              ? const StatusPill('Failed', dense: true, color: Brand.danger)
              : (e.isWarning ? const StatusPill('Warning', dense: true, color: Brand.warning) : const SizedBox.shrink()),
      onTap: e.id == null ? null : () => context.push('/admin/audit/${Uri.encodeComponent(e.id!)}'),
    );
  }
}
