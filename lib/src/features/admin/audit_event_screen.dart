import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/utils/audit_labels.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/security_models.dart';
import '../../state/data_providers.dart';
import '../security/security_widgets.dart';

/// Administrators: everything recorded about one audit event, grouped by what it answers.
class AuditEventScreen extends ConsumerWidget {
  const AuditEventScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(auditEventProvider(eventId));
    return SubPage(
      title: 'Event',
      fallbackRoute: '/admin/audit',
      body: AsyncBody<SecurityEventView>(
        value: value,
        onRetry: () => ref.invalidate(auditEventProvider(eventId)),
        builder: (e) => PageBody(
          maxWidth: 760,
          onRefresh: () async => ref.invalidate(auditEventProvider(eventId)),
          children: <Widget>[
            _Header(event: e),
            ..._sections(context, e),
          ],
        ),
      ),
    );
  }

  List<Widget> _sections(BuildContext context, SecurityEventView e) {
    final out = <Widget>[];

    void section(String title, List<Widget> rows) {
      if (rows.isEmpty) return;
      out.add(SectionHeader(title));
      out.add(PCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(children: rows),
      ));
    }

    section('What happened', <Widget>[
      ..._row('Event', e.title),
      ..._row('Group', e.category),
      ..._row('Result', outcomeLabel(e.outcome)),
      ..._row('Severity', severityLabel(e.severity)),
      ..._row('Reason', e.reason),
      ..._row('When', formatDateTime(e.createdAt)),
    ]);

    final person = <String>[
      if (e.userName != null) e.userName!,
      if (e.userEmail != null) e.userEmail!,
    ].join('\n');
    final by = <String>[
      if (e.actorLabel != null) e.actorLabel!,
      if (e.actorName != null && e.actorEmail != null) e.actorEmail!,
    ].join('\n');
    section('Who', <Widget>[
      ..._row('Account', person.isNotEmpty ? person : e.subject),
      if (person.isNotEmpty && e.subject != null) ..._row('Recorded as', e.subject),
      ..._row('Done by', by),
      ..._row('Their role', e.actorRole == null ? null : roleLabel(e.actorRole)),
      if (e.userId != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: PButton(
              label: 'See activity on this account',
              icon: Icons.history_rounded,
              kind: PButtonKind.text,
              small: true,
              onPressed: () => context.push('/admin/audit?userId=${Uri.encodeComponent(e.userId!)}'),
            ),
          ),
        ),
    ]);

    section('Device and place', <Widget>[
      ..._row('Device', e.deviceLabel),
      ..._row('Device type', e.deviceType == null ? null : sentence(e.deviceType)),
      ..._row('Browser', e.browser),
      ..._row('System', e.os),
      ..._row('Address', e.ipAddress),
      ..._row('Place', e.place),
      if (e.ipAddress != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: PButton(
              label: 'Other events from this address',
              icon: Icons.public_rounded,
              kind: PButtonKind.text,
              small: true,
              onPressed: () => context.push('/admin/audit?ip=${Uri.encodeComponent(e.ipAddress!)}'),
            ),
          ),
        ),
    ]);

    section('What it touched', <Widget>[
      ..._row('Kind', e.targetType == null ? null : targetTypeLabel(e.targetType)),
      ..._row('Name', e.targetLabel),
      ..._row('Reference', e.targetId),
    ]);

    section('Details', <Widget>[
      for (final entry in e.details.entries)
        ..._row(detailKeyLabel(entry.key), detailValueLabel(entry.key, entry.value)),
    ]);

    section('Technical', <Widget>[
      ..._row('Request', requestLabel(e.requestMethod, e.requestPath)),
      ..._row('Session', e.sessionId),
      ..._row('Device id', e.deviceId),
      ..._row('Browser string', e.userAgent),
      ..._row('Event id', e.id),
    ]);

    return out;
  }

  /// A labelled row, or nothing when there is no value, so empty facts do not fill the screen.
  List<Widget> _row(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const <Widget>[];
    return <Widget>[_CopyRow(label: label, value: value)];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.event});

  final SecurityEventView event;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final tint = e.isFailure ? Brand.danger : severityColor(e.severity);
    return PCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IconBadge(eventIcon(e.type), color: tint),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(e.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text(e.description, style: TextStyle(fontSize: 13.5, color: context.mutedColor, height: 1.35)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    StatusPill(severityLabel(e.severity), color: severityColor(e.severity)),
                    if (outcomeLabel(e.outcome).isNotEmpty)
                      StatusPill(outcomeLabel(e.outcome), color: outcomeColor(e.outcome)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(whenLabel(e.createdAt), style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A label and value. Pressing and holding copies the value, which helps when an address or id goes into a search.
class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied')));
        }
      },
      child: InfoRow(label, value),
    );
  }
}
