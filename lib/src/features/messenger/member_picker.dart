import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/palette.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/messenger_models.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';
import 'messenger_common.dart';

/// A searchable list of members. With [multi] it shows check boxes and reports every pick through
/// [onSelectionChanged]; otherwise a tap calls [onPick] straight away.
class MemberPicker extends ConsumerStatefulWidget {
  const MemberPicker({
    super.key,
    this.multi = false,
    this.excludeIds = const <String>{},
    this.selected = const <String>{},
    this.onSelectionChanged,
    this.onPick,
    this.emptyMessage = 'No members found.',
  });

  final bool multi;
  final Set<String> excludeIds;
  final Set<String> selected;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final ValueChanged<MUser>? onPick;
  final String emptyMessage;

  @override
  ConsumerState<MemberPicker> createState() => _MemberPickerState();
}

class _MemberPickerState extends ConsumerState<MemberPicker> {
  final TextEditingController _query = TextEditingController();
  Timer? _debounce;
  List<MUser> _people = const <MUser>[];
  final Map<String, MUser> _known = <String, MUser>{};
  late final Set<String> _selected = <String>{...widget.selected};
  bool _loading = true;
  Object? _error;
  int _ticket = 0;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _load(String q) async {
    final ticket = ++_ticket;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(messengerRepositoryProvider);
      final list = q.isEmpty ? await repo.users() : await repo.searchUsers(q);
      if (!mounted || ticket != _ticket) return;
      final me = ref.read(sessionProvider).user?.id;
      final shown = list.where((u) => u.id != me && !widget.excludeIds.contains(u.id)).toList();
      for (final u in shown) {
        _known[u.id] = u;
      }
      setState(() {
        _people = shown;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || ticket != _ticket) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _onQuery(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load(v.trim()));
  }

  void _toggle(MUser u) {
    if (!widget.multi) {
      widget.onPick?.call(u);
      return;
    }
    setState(() {
      if (!_selected.add(u.id)) _selected.remove(u.id);
    });
    widget.onSelectionChanged?.call(<String>{..._selected});
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final chosen = <MUser>[for (final id in _selected) if (_known[id] != null) _known[id]!];

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _query,
            onChanged: _onQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search by name or email',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _query.clear();
                        _load('');
                      },
                    ),
            ),
          ),
        ),
        if (widget.multi && chosen.isNotEmpty)
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: chosen.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final u = chosen[i];
                return GestureDetector(
                  onTap: () => _toggle(u),
                  child: SizedBox(
                    width: 60,
                    child: Column(children: <Widget>[
                      Stack(clipBehavior: Clip.none, children: <Widget>[
                        MessengerAvatar(initials: u.initials, imageUrl: u.profilePictureUrl, size: 46),
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            decoration: BoxDecoration(color: pal.panel2, shape: BoxShape.circle, border: Border.all(color: pal.bg, width: 2)),
                            child: Icon(Icons.close_rounded, size: 15, color: pal.ink2),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(u.name.split(' ').first, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5)),
                    ]),
                  ),
                );
              },
            ),
          ),
        Expanded(child: _body(context)),
      ],
    );
  }

  Widget _body(BuildContext context) {
    if (_loading && _people.isEmpty) return const SkeletonList(kind: SkeletonKind.row, count: 6);
    if (_error != null && _people.isEmpty) return ErrorState(error: _error ?? 'Error', onRetry: () => _load(_query.text.trim()));
    if (_people.isEmpty) return EmptyState(icon: Icons.person_search_outlined, title: widget.emptyMessage);
    return ListView.builder(
      itemCount: _people.length,
      itemBuilder: (context, i) {
        final u = _people[i];
        final on = _selected.contains(u.id);
        return ListTile(
          leading: MessengerAvatar(initials: u.initials, imageUrl: u.profilePictureUrl, size: 44, online: u.online),
          title: Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: u.username.isNotEmpty && !u.username.contains('@') ? Text('@${u.username}', maxLines: 1, overflow: TextOverflow.ellipsis) : null,
          trailing: widget.multi ? Checkbox(value: on, onChanged: (_) => _toggle(u)) : null,
          onTap: () => _toggle(u),
        );
      },
    );
  }
}
