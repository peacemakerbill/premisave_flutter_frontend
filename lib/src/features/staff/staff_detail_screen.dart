import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/application_models.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/application_repository.dart';
import '../../state/data_providers.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';
import '../application/application_widgets.dart';

/// Moves staff may make from each status (mirrors the backend rules).
const Map<String, List<String>> _transitions = <String, List<String>>{
  'SUBMITTED': <String>['PROCESSING', 'INFO_REQUESTED', 'REJECTED'],
  'PROCESSING': <String>['INFO_REQUESTED', 'VERIFIED', 'REJECTED'],
  'INFO_REQUESTED': <String>['REJECTED'],
  'VERIFIED': <String>['PROCESSING', 'INFO_REQUESTED', 'REJECTED'],
};

class StaffDetailScreen extends ConsumerStatefulWidget {
  const StaffDetailScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  ConsumerState<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends ConsumerState<StaffDetailScreen> {
  bool _busy = false;

  void _reload() {
    ref.invalidate(staffApplicationProvider(widget.applicationId));
    ref.invalidate(staffStatsProvider);
  }

  /// Runs a call that returns the updated application, then refreshes the screen.
  Future<void> _act(Future<Object?> Function() call, String done) async {
    setState(() => _busy = true);
    try {
      await call();
      _reload();
      if (mounted) showToast(context, done);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  ApplicationRepository get _repo => ref.read(applicationRepositoryProvider);

  Future<void> _changeStatus(ApplicationDetail a, String status) async {
    final needsMessage = status == 'INFO_REQUESTED' || status == 'REJECTED';
    final result = await showDialog<_StatusResult>(
      context: context,
      builder: (_) => _StatusDialog(status: status, messageRequired: needsMessage),
    );
    if (result == null) return;
    await _act(
      () => _repo.changeStatus(
        a.id,
        status: status,
        message: result.message,
        internalNote: result.note,
        allowReapply: status == 'REJECTED' ? result.allowReapply : null,
      ),
      'Status updated',
    );
  }

  Future<void> _reviewDocument(ApplicationDetail a, DocumentView d) async {
    final result = await showDialog<_DocReviewResult>(
      context: context,
      builder: (_) => _DocReviewDialog(doc: d),
    );
    if (result == null) return;
    await _act(
      () => _repo.reviewDocument(a.id, d.id, verified: result.verified, reason: result.reason, requestReupload: result.requestReupload),
      result.verified ? 'Document verified' : 'Document rejected',
    );
  }

  Future<void> _addNote(ApplicationDetail a) async {
    final text = await promptDialog(context, title: 'Add an internal note', message: 'Only staff can see notes.', label: 'Note', required: true, confirmLabel: 'Add note');
    if (text == null) return;
    await _act(() => _repo.addNote(a.id, text), 'Note added');
  }

  Future<void> _assign(ApplicationDetail a) async {
    final reviewers = await ref.read(reviewersProvider.future);
    if (!mounted) return;
    final picked = await showModalBottomSheet<StaffMember>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: <Widget>[
          const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text('Assign to', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          for (final r in reviewers)
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: Text(r.name.isEmpty ? r.email : r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${r.email} · ${sentence(r.role)}'),
              trailing: a.reviewer?.id == r.id ? const Icon(Icons.check_rounded) : null,
              onTap: () => Navigator.of(ctx).pop(r),
            ),
        ],
      ),
    );
    if (picked == null) return;
    await _act(() => _repo.assign(a.id, picked.id), 'Assigned to ${picked.name}');
  }

  Future<void> _promote(ApplicationDetail a) async {
    final ok = await confirmDialog(
      context,
      title: 'Approve this application?',
      message: '${a.applicantName} becomes a Home Owner and is notified by email.',
      confirmLabel: 'Approve',
    );
    if (!ok || !mounted) return;
    final note = await promptDialog(context, title: 'Message to the applicant', label: 'Message (optional)', confirmLabel: 'Send');
    if (note == null) return;
    await _act(() => _repo.promote(a.id, message: note), 'Application approved');
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(staffApplicationProvider(widget.applicationId));
    final me = ref.watch(sessionProvider).user;
    final isAdmin = me?.role == Role.admin;

    return SubPage(
      title: 'Review application',
      fallbackRoute: '/staff',
      body: AsyncBody<ApplicationDetail>(
        value: value,
        onRetry: _reload,
        builder: (a) {
          final moves = _transitions[a.status] ?? const <String>[];
          final mine = a.reviewer?.id == me?.id;
          return PageBody(
            maxWidth: 820,
            onRefresh: () async => _reload(),
            children: <Widget>[
              ApplicationStatusPanel(app: a),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  if (!mine && !a.isFinal && !a.isDraft) PButton(label: 'Claim', icon: Icons.back_hand_outlined, small: true, loading: _busy, onPressed: _busy ? null : () => _act(() => _repo.claim(a.id), 'You now own this review')),
                  if (!a.isFinal && !a.isDraft) PButton(label: a.reviewer == null ? 'Assign' : 'Reassign', icon: Icons.person_add_alt_outlined, small: true, kind: PButtonKind.outline, onPressed: _busy ? null : () => _assign(a)),
                  PButton(label: 'Add note', icon: Icons.note_add_outlined, small: true, kind: PButtonKind.outline, onPressed: _busy ? null : () => _addNote(a)),
                ],
              ),
              if (a.reviewer != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text('Reviewer: ${a.reviewer!.name}${mine ? ' (you)' : ''}', style: TextStyle(fontSize: 13, color: context.mutedColor))),
              if (moves.isNotEmpty || (isAdmin && a.status == 'VERIFIED')) ...<Widget>[
                const SectionHeader('Decision'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    for (final s in moves)
                      PButton(
                        label: _moveLabel(s),
                        icon: _moveIcon(s),
                        kind: s == 'REJECTED' ? PButtonKind.danger : (s == 'VERIFIED' ? PButtonKind.primary : PButtonKind.outline),
                        small: true,
                        onPressed: _busy ? null : () => _changeStatus(a, s),
                      ),
                    if (isAdmin && a.status == 'VERIFIED')
                      PButton(label: 'Approve as home owner', icon: Icons.verified_rounded, kind: PButtonKind.accent, small: true, onPressed: _busy ? null : () => _promote(a)),
                  ],
                ),
                if (!isAdmin && a.status == 'VERIFIED')
                  Padding(padding: const EdgeInsets.only(top: 8), child: Text('An administrator gives final approval.', style: TextStyle(fontSize: 12.5, color: context.mutedColor))),
              ],
              const SectionHeader('Applicant'),
              PCard(
                child: Column(
                  children: <Widget>[
                    InfoRow('Name', a.applicantName),
                    InfoRow('Email', a.applicantEmail),
                    InfoRow('Phone', a.text('phoneNumber')),
                    InfoRow('Applying as', sentence(a.ownerType)),
                    if (a.text('companyName') != null) InfoRow('Company', '${a.text('companyName')} ${a.text('companyRegistrationNumber') ?? ''}'.trim()),
                    InfoRow('ID', '${sentence(a.text('idType'))} ${a.text('idNumber') ?? ''}'.trim()),
                    InfoRow('ID country', a.text('idIssuingCountry')),
                    InfoRow('Date of birth', a.text('dateOfBirth')),
                    InfoRow('Nationality', a.text('nationality')),
                    InfoRow('Tax ID', a.text('taxId')),
                    InfoRow('Address', <String>[
                      if (a.text('physicalAddress') != null) a.text('physicalAddress')!,
                      if (a.text('city') != null) a.text('city')!,
                      if (a.text('region') != null) a.text('region')!,
                      if (a.text('country') != null) a.text('country')!,
                    ].join(', ')),
                  ],
                ),
              ),
              const SectionHeader('Properties and payout'),
              PCard(
                child: Column(
                  children: <Widget>[
                    InfoRow('Properties', a.number('numberOfProperties')?.toString()),
                    InfoRow('Units', a.number('estimatedTotalUnits')?.toString()),
                    InfoRow('Types', a.list('propertyTypes').map(sentence).join(', ')),
                    InfoRow('Location', a.text('primaryPropertyLocation')),
                    InfoRow('Management', sentence(a.text('managementPreference'))),
                    InfoRow('Experience', a.number('yearsAsLandlord') == null ? null : '${a.number('yearsAsLandlord')} years'),
                    InfoRow('Payout', sentence(a.text('payoutMethod'))),
                    if (a.text('bankName') != null) InfoRow('Bank', '${a.text('bankName')} · ${a.text('bankAccountNumber') ?? ''}'),
                    if (a.text('mobileMoneyNumber') != null) InfoRow('Mobile money', '${a.text('mobileMoneyProvider') ?? ''} ${a.text('mobileMoneyNumber')}'.trim()),
                    if (a.text('paypalEmail') != null) InfoRow('PayPal', a.text('paypalEmail')),
                    if (a.text('propertyDescription') != null) InfoRow('Description', a.text('propertyDescription')),
                    if (a.text('motivation') != null) InfoRow('Motivation', a.text('motivation')),
                  ],
                ),
              ),
              const SectionHeader('Documents'),
              DocumentList(
                documents: a.documents,
                onReview: a.isFinal || a.isDraft ? null : (d) => _reviewDocument(a, d),
                onPreview: (d) => showImagePreview(context, d.fileName, () => _repo.staffDownloadDocument(a.id, d.id)),
              ),
              if (a.readiness.issues.isNotEmpty) ...<Widget>[
                const SectionHeader('Open issues'),
                for (final i in a.readiness.issues) Padding(padding: const EdgeInsets.only(bottom: 6), child: InlineMessage(i.message, kind: MessageKind.warning)),
              ],
              const SectionHeader('Internal notes'),
              if (a.internalNotes.isEmpty)
                Text('No notes yet.', style: TextStyle(color: context.mutedColor))
              else
                for (final n in a.internalNotes.reversed) ...<Widget>[
                  PCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(n.text, style: const TextStyle(fontSize: 14, height: 1.4)),
                        const SizedBox(height: 6),
                        Text('${n.author}${n.authorRole != null ? ' (${sentence(n.authorRole)})' : ''} · ${timeAgo(n.at)}', style: TextStyle(fontSize: 12, color: context.mutedColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              const SectionHeader('Timeline'),
              ApplicationTimeline(events: a.timeline),
            ],
          );
        },
      ),
    );
  }

  String _moveLabel(String s) {
    switch (s) {
      case 'PROCESSING':
        return 'Start review';
      case 'INFO_REQUESTED':
        return 'Ask for information';
      case 'VERIFIED':
        return 'Mark verified';
      default:
        return 'Reject';
    }
  }

  IconData _moveIcon(String s) {
    switch (s) {
      case 'PROCESSING':
        return Icons.play_arrow_rounded;
      case 'INFO_REQUESTED':
        return Icons.help_outline_rounded;
      case 'VERIFIED':
        return Icons.check_rounded;
      default:
        return Icons.close_rounded;
    }
  }
}

// --------------------------------------------------------------------- dialogs

class _StatusResult {
  const _StatusResult(this.message, this.note, this.allowReapply);

  final String? message;
  final String? note;
  final bool allowReapply;
}

class _StatusDialog extends StatefulWidget {
  const _StatusDialog({required this.status, required this.messageRequired});

  final String status;
  final bool messageRequired;

  @override
  State<_StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<_StatusDialog> {
  final _message = TextEditingController();
  final _note = TextEditingController();
  bool _allowReapply = true;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    _note.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.status) {
      case 'PROCESSING':
        return 'Start review';
      case 'INFO_REQUESTED':
        return 'Ask the applicant for information';
      case 'VERIFIED':
        return 'Mark as verified';
      default:
        return 'Reject application';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.radius(Brand.radiusLarge))),
      title: Text(_title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PTextField(
                label: 'Message to the applicant',
                controller: _message,
                optional: !widget.messageRequired,
                maxLines: 4,
                minLines: 3,
                errorText: _error,
                helper: 'They receive this by email and see it in the app.',
              ),
              const SizedBox(height: 14),
              PTextField(label: 'Internal note', controller: _note, optional: true, maxLines: 3, minLines: 2, helper: 'Only staff can see this.'),
              if (widget.status == 'REJECTED')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: <Widget>[
                      Switch(value: _allowReapply, onChanged: (v) => setState(() => _allowReapply = v)),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Let the applicant correct and reapply', style: TextStyle(fontSize: 13.5))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        PButton(label: 'Cancel', kind: PButtonKind.text, small: true, onPressed: () => Navigator.of(context).pop()),
        PButton(
          label: 'Confirm',
          kind: widget.status == 'REJECTED' ? PButtonKind.danger : PButtonKind.primary,
          small: true,
          onPressed: () {
            final m = _message.text.trim();
            if (widget.messageRequired && m.isEmpty) {
              setState(() => _error = 'A message is required');
              return;
            }
            final n = _note.text.trim();
            Navigator.of(context).pop(_StatusResult(m.isEmpty ? null : m, n.isEmpty ? null : n, _allowReapply));
          },
        ),
      ],
    );
  }
}

class _DocReviewResult {
  const _DocReviewResult({required this.verified, this.reason, this.requestReupload = false});

  final bool verified;
  final String? reason;
  final bool requestReupload;
}

class _DocReviewDialog extends StatefulWidget {
  const _DocReviewDialog({required this.doc});

  final DocumentView doc;

  @override
  State<_DocReviewDialog> createState() => _DocReviewDialogState();
}

class _DocReviewDialogState extends State<_DocReviewDialog> {
  final _reason = TextEditingController();
  bool _rejecting = false;
  bool _reupload = true;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.radius(Brand.radiusLarge))),
      title: Text(widget.doc.typeLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(widget.doc.fileName, style: TextStyle(color: context.mutedColor, fontSize: 13)),
              if (widget.doc.documentNumber != null) Text('Number: ${widget.doc.documentNumber}', style: TextStyle(color: context.mutedColor, fontSize: 13)),
              if (widget.doc.expiryDate != null) Text('Expires: ${widget.doc.expiryDate}', style: TextStyle(color: context.mutedColor, fontSize: 13)),
              if (_rejecting) ...<Widget>[
                const SizedBox(height: 16),
                PTextField(label: 'Why is it being rejected?', controller: _reason, maxLines: 3, minLines: 2, errorText: _error, helper: 'The applicant sees this.'),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Switch(value: _reupload, onChanged: (v) => setState(() => _reupload = v)),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Ask for a new upload', style: TextStyle(fontSize: 13.5))),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        PButton(label: 'Cancel', kind: PButtonKind.text, small: true, onPressed: () => Navigator.of(context).pop()),
        if (!_rejecting) ...<Widget>[
          PButton(label: 'Reject', kind: PButtonKind.outline, small: true, onPressed: () => setState(() => _rejecting = true)),
          PButton(label: 'Verify', small: true, onPressed: () => Navigator.of(context).pop(const _DocReviewResult(verified: true))),
        ] else
          PButton(
            label: 'Reject document',
            kind: PButtonKind.danger,
            small: true,
            onPressed: () {
              final r = _reason.text.trim();
              if (r.isEmpty) {
                setState(() => _error = 'Give the applicant a reason');
                return;
              }
              Navigator.of(context).pop(_DocReviewResult(verified: false, reason: r, requestReupload: _reupload));
            },
          ),
      ],
    );
  }
}
