import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/json_utils.dart';
import '../../data/repositories/envelope.dart';
import 'resource_form.dart';
import 'service_widgets.dart';

// A small toolkit for screens that list, show, create, change and delete records. A screen describes what to load, how a
// row reads, which forms exist and which calls they make. The list, the detail sheet, the forms, the confirmations and
// the error messages are the same everywhere, so a new resource is a few lines of description instead of a new screen.

typedef Json = Map<String, dynamic>;

/// The list inside an answer: a bare list, a Spring page ({content: []}), or the first list under [key].
List<Json> listOf(Object? body, {String? key}) => rows(body, key: key);

/// The first of [keys] that holds text in [m]. A key may be dotted.
String pick(Json m, List<String> keys, [String fallback = '']) {
  for (final k in keys) {
    final v = digValue(m, k);
    if (v != null && '$v'.trim().isNotEmpty && v is! Map && v is! List) return '$v';
  }
  return fallback;
}

/// "monthlyRent" becomes "Monthly rent".
String humanize(String key) {
  final spaced = key.replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}').replaceAll('_', ' ').replaceAll('.', ' ');
  final t = spaced.trim().toLowerCase();
  return t.isEmpty ? key : '${t[0].toUpperCase()}${t.substring(1)}';
}

final RegExp _isoDateTime = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}');
final RegExp _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// A value as a person reads it: dates in the local format, Yes and No, tidy numbers, words for codes.
String displayValue(Object? v) {
  if (v == null) return 'None';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is int) return '$v';
  if (v is num) {
    final d = v.toDouble();
    return d == d.truncateToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(2);
  }
  if (v is List) return v.isEmpty ? 'None' : v.map(displayValue).join(', ');
  final s = '$v';
  if (_isoDateTime.hasMatch(s)) {
    final d = DateTime.tryParse(s);
    if (d != null) return formatDateTime(d);
  }
  if (_isoDate.hasMatch(s)) {
    final d = DateTime.tryParse(s);
    if (d != null) return formatDate(d);
  }
  if (s.length < 40 && RegExp(r'^[A-Z][A-Z0-9_]+$').hasMatch(s)) return sentence(s);
  return s;
}

const Set<String> _alwaysHidden = <String>{'_id', '__v', '_class', 'password', 'passwordHash', 'secret'};

/// Every field of a record as label and value rows. Nested records are indented under their name.
class MapDetail extends StatelessWidget {
  const MapDetail(this.data, {super.key, this.hidden = const <String>{}, this.depth = 0});

  final Json data;
  final Set<String> hidden;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    data.forEach((key, value) {
      if (_alwaysHidden.contains(key) || hidden.contains(key)) return;
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      if (value is List && value.isEmpty) return;
      if (value is Map) {
        final inner = asMap(value);
        if (inner.isEmpty) return;
        rows.add(_Heading(humanize(key), depth));
        rows.add(MapDetail(inner, hidden: hidden, depth: depth + 1));
        return;
      }
      if (value is List && value.first is Map) {
        rows.add(_Heading(humanize(key), depth));
        var n = 1;
        for (final item in value.take(30)) {
          rows.add(Padding(
            padding: EdgeInsets.only(left: 10.0 * (depth + 1), top: 4),
            child: Text('#$n', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: context.mutedColor)),
          ));
          rows.add(MapDetail(asMap(item), hidden: hidden, depth: depth + 1));
          n++;
        }
        return;
      }
      rows.add(_DetailRow(humanize(key), displayValue(value), depth));
    });
    if (rows.isEmpty) return Text('Nothing to show.', style: TextStyle(color: context.mutedColor));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, this.depth);

  final String text;
  final int depth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 10.0 * depth, top: 12, bottom: 2),
      child: Text(text, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: context.pal.accent)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, this.depth);

  final String label;
  final String value;
  final int depth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10.0 * depth, 4, 0, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: 2, child: Text(label, style: TextStyle(fontSize: 13, color: context.mutedColor))),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: SelectableText(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// How one record reads as a row in a list.
class RowView {
  const RowView({required this.title, this.subtitle, this.status, this.trailing, this.icon = Icons.article_outlined});

  final String Function(Json m) title;
  final String? Function(Json m)? subtitle;
  final String? Function(Json m)? status;
  final String? Function(Json m)? trailing;
  final IconData icon;
}

/// Something a person can do to a record, or from the top of a list when [item] is empty.
///
/// With [fields] it opens a form (filled from the record when [initialFromItem] is set) and passes the values to [run].
/// With [confirm] it asks first. With [page] it opens another screen instead of calling the server.
class ItemAction {
  const ItemAction(
    this.label,
    this.icon, {
    this.run,
    this.fields = const <FieldSpec>[],
    this.confirm,
    this.danger = false,
    this.visible,
    this.page,
    this.initialFromItem = false,
    this.title,
    this.subtitle,
    this.done,
    this.submitLabel,
  });

  final String label;
  final IconData icon;
  final Future<void> Function(Json item, Json values)? run;
  final List<FieldSpec> fields;
  final String? confirm;
  final bool danger;
  final bool Function(Json item)? visible;
  final Widget Function(Json item)? page;
  final bool initialFromItem;
  final String? title;
  final String? subtitle;

  /// The toast shown when the call worked.
  final String? done;
  final String? submitLabel;
}

/// Runs an action. Returns true when something on the server changed, so the caller can reload.
Future<bool> runItemAction(BuildContext context, ItemAction a, Json item) async {
  final page = a.page;
  if (page != null) {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => SubPage(title: a.title ?? a.label, body: page(item))),
    );
    return result == true;
  }
  final run = a.run;
  if (run == null) return false;
  if (a.fields.isNotEmpty) {
    final ok = await showResourceForm(
      context,
      title: a.title ?? a.label,
      subtitle: a.subtitle ?? a.confirm,
      fields: a.fields,
      initial: a.initialFromItem ? item : const <String, dynamic>{},
      submitLabel: a.submitLabel ?? a.label,
      danger: a.danger,
      onSubmit: (values) => run(item, values),
    );
    if (ok && context.mounted) showToast(context, a.done ?? 'Done');
    return ok;
  }
  if (a.confirm != null) {
    final yes = await confirmDialog(context, title: a.label, message: a.confirm!, confirmLabel: a.label, danger: a.danger);
    if (!yes) return false;
  }
  try {
    await run(item, const <String, dynamic>{});
    if (context.mounted) showToast(context, a.done ?? 'Done');
    return true;
  } catch (e) {
    if (context.mounted) showApiError(context, e);
    return false;
  }
}

/// A row of buttons for a list of actions.
class ActionBar extends StatelessWidget {
  const ActionBar({super.key, required this.actions, required this.item, required this.onChanged});

  final List<ItemAction> actions;
  final Json item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final shown = actions.where((a) => a.visible == null || a.visible!(item)).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final a in shown)
          PButton(
            label: a.label,
            icon: a.icon,
            small: true,
            kind: a.danger ? PButtonKind.danger : (a.page != null ? PButtonKind.outline : PButtonKind.primary),
            onPressed: () async {
              final changed = await runItemAction(context, a, item);
              if (changed) onChanged();
            },
          ),
      ],
    );
  }
}

/// A list of records from one call, with a button row for the list, a detail sheet for each record and the actions that
/// belong to it. Pull down to reload. Change [refreshKey] to reload from a parent.
class ResourceSection extends StatefulWidget {
  const ResourceSection({
    super.key,
    required this.load,
    required this.row,
    this.headerActions = const <ItemAction>[],
    this.itemActions = const <ItemAction>[],
    this.detail,
    this.hidden = const <String>{},
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.refreshKey,
    this.intro,
    this.maxWidth = 820,
    this.onOpen,
  });

  final Future<List<Json>> Function() load;
  final RowView row;
  final List<ItemAction> headerActions;
  final List<ItemAction> itemActions;

  /// Loads the whole record when a row is opened, for lists that only carry a summary.
  final Future<Json> Function(Json item)? detail;
  final Set<String> hidden;
  final String emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;
  final Object? refreshKey;

  /// A line of help above the list.
  final String? intro;
  final double maxWidth;

  /// Replaces the detail sheet, for rows that open a screen of their own.
  final void Function(BuildContext context, Json item)? onOpen;

  @override
  State<ResourceSection> createState() => _ResourceSectionState();
}

class _ResourceSectionState extends State<ResourceSection> {
  late Future<List<Json>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  @override
  void didUpdateWidget(ResourceSection old) {
    super.didUpdateWidget(old);
    if (old.refreshKey != widget.refreshKey) _reload();
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _future = widget.load());
  }

  Future<void> _open(Json item) async {
    final onOpen = widget.onOpen;
    if (onOpen != null) {
      onOpen(context, item);
      return;
    }
    var shown = item;
    final loadDetail = widget.detail;
    if (loadDetail != null) {
      try {
        shown = await loadDetail(item);
      } catch (e) {
        if (mounted) showApiError(context, e);
        return;
      }
    }
    if (!mounted) return;
    await showFormSheet<void>(
      context,
      title: widget.row.title(shown),
      subtitle: widget.row.subtitle?.call(shown),
      child: _ItemSheet(item: shown, actions: widget.itemActions, hidden: widget.hidden, onChanged: _reload),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      maxWidth: widget.maxWidth,
      onRefresh: () async {
        _reload();
        try {
          await _future;
        } catch (_) {}
      },
      children: <Widget>[
        if (widget.intro != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(widget.intro!, style: TextStyle(fontSize: 13.5, height: 1.4, color: context.mutedColor)),
          ),
        if (widget.headerActions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ActionBar(actions: widget.headerActions, item: const <String, dynamic>{}, onChanged: _reload),
          ),
        FutureBuilder<List<Json>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SkeletonList(count: 3, height: 76, shrink: true, padding: EdgeInsets.symmetric(horizontal: 16));
            }
            if (snap.hasError) return ErrorState(error: snap.error!, onRetry: _reload);
            final items = snap.data ?? <Json>[];
            if (items.isEmpty) {
              return SizedBox(
                height: 300,
                child: EmptyState(icon: widget.emptyIcon, title: widget.emptyTitle, message: widget.emptyMessage ?? ''),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: <Widget>[
                  for (final item in items)
                    _RowCard(row: widget.row, item: item, onTap: () => _open(item)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({required this.row, required this.item, required this.onTap});

  final RowView row;
  final Json item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = row.subtitle?.call(item);
    final status = row.status?.call(item);
    final trailing = row.trailing?.call(item);
    return PCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: context.pal.accent.op(0.12), borderRadius: BorderRadius.circular(context.radius(12))),
            child: Icon(row.icon, size: 21, color: context.pal.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(row.title(item), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                if (subtitle != null && subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                  ),
              ],
            ),
          ),
          if (trailing != null && trailing.isNotEmpty) ...<Widget>[
            const SizedBox(width: 8),
            Text(trailing, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
          ],
          if (status != null && status.isNotEmpty) ...<Widget>[const SizedBox(width: 8), StatusChip(status)],
        ],
      ),
    );
  }
}

class _ItemSheet extends StatelessWidget {
  const _ItemSheet({required this.item, required this.actions, required this.hidden, required this.onChanged});

  final Json item;
  final List<ItemAction> actions;
  final Set<String> hidden;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MapDetail(item, hidden: hidden),
        const SizedBox(height: 16),
        ActionBar(
          actions: actions,
          item: item,
          onChanged: () {
            Navigator.of(context).pop();
            onChanged();
          },
        ),
      ],
    );
  }
}

/// One record from one call, shown in full, with actions. For screens such as a report, a profile or a settings page.
class ResourceView extends StatefulWidget {
  const ResourceView({
    super.key,
    required this.load,
    this.actions = const <ItemAction>[],
    this.hidden = const <String>{},
    this.title,
    this.intro,
    this.refreshKey,
    this.maxWidth = 820,
    this.summary,
    this.emptyMessage = 'Nothing to show yet.',
  });

  final Future<Json> Function() load;
  final List<ItemAction> actions;
  final Set<String> hidden;
  final String? title;
  final String? intro;
  final Object? refreshKey;
  final double maxWidth;

  /// Something to show above the fields, such as a balance.
  final Widget Function(Json data)? summary;
  final String emptyMessage;

  @override
  State<ResourceView> createState() => _ResourceViewState();
}

class _ResourceViewState extends State<ResourceView> {
  late Future<Json> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  @override
  void didUpdateWidget(ResourceView old) {
    super.didUpdateWidget(old);
    if (old.refreshKey != widget.refreshKey) _reload();
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _future = widget.load());
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      maxWidth: widget.maxWidth,
      onRefresh: () async {
        _reload();
        try {
          await _future;
        } catch (_) {}
      },
      children: <Widget>[
        if (widget.intro != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(widget.intro!, style: TextStyle(fontSize: 13.5, height: 1.4, color: context.mutedColor)),
          ),
        FutureBuilder<Json>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SkeletonList(count: 2, height: 90, shrink: true, padding: EdgeInsets.symmetric(horizontal: 16));
            }
            if (snap.hasError) return ErrorState(error: snap.error!, onRetry: _reload);
            final data = snap.data ?? <String, dynamic>{};
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (widget.summary != null) ...<Widget>[widget.summary!(data), const SizedBox(height: 12)],
                  if (data.isEmpty)
                    Text(widget.emptyMessage, style: TextStyle(color: context.mutedColor))
                  else
                    PCard(child: MapDetail(data, hidden: widget.hidden)),
                  if (widget.actions.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 14),
                    ActionBar(actions: widget.actions, item: data, onChanged: _reload),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Runs [action], shows the error when it fails and tells whether it worked.
Future<bool> attempt(BuildContext context, Future<void> Function() action, {String? done}) async {
  try {
    await action();
    if (done != null && context.mounted) showToast(context, done);
    return true;
  } catch (e) {
    if (context.mounted) showApiError(context, ApiException.from(e));
    return false;
  }
}

/// A short bold line above a block of a screen.
class BlockTitle extends StatelessWidget {
  const BlockTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(text, style: context.display(size: 16, weight: FontWeight.w800)),
    );
  }
}
