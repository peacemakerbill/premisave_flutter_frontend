import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/files/file_chooser.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/json_utils.dart';
import '../../data/repositories/developer_repository.dart';
import '../../data/repositories/messenger_repository.dart' show LocalFile;
import '../../state/providers.dart';
import '../shared/resource_form.dart';
import '../shared/resource_view.dart';

const Map<String, String> _methods = <String, String>{
  'MOBILE_MONEY': 'Mobile money',
  'CARD': 'Card',
  'BANK_TRANSFER': 'Bank transfer',
  'PAYPAL': 'PayPal',
  'CRYPTO': 'Crypto',
  'PREMISAVE_WALLET': 'Premisave wallet',
};

const Map<String, String> _businessTypes = <String, String>{
  'SOLE_PROPRIETOR': 'Sole proprietor',
  'PARTNERSHIP': 'Partnership',
  'LIMITED_COMPANY': 'Limited company',
  'NGO': 'NGO',
  'OTHER': 'Other',
};

const Map<String, String> _documentTypes = <String, String>{
  'BUSINESS_REGISTRATION': 'Business registration',
  'CERTIFICATE_OF_INCORPORATION': 'Certificate of incorporation',
  'TAX_COMPLIANCE': 'Tax compliance',
  'DIRECTOR_ID': 'Director ID',
  'PROOF_OF_ADDRESS': 'Proof of address',
  'BANK_STATEMENT': 'Bank statement',
  'AUTHORISATION_LETTER': 'Authorisation letter',
  'OTHER': 'Other',
};

/// The businesses of the developer account. A business is only needed to take real payments, never for the sandbox.
class DeveloperBusinessesTab extends ConsumerWidget {
  const DeveloperBusinessesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(developerRepositoryProvider);
    return ResourceSection(
      load: () => repo.businesses(),
      onOpen: (context, item) => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => SubPage(title: pick(item, <String>['name'], 'Business'), body: DeveloperBusinessPage(businessId: pick(item, <String>['businessId'])))),
      ),
      intro: 'Only needed to take real payments. Sandbox apps never need a business.',
      emptyTitle: 'No businesses yet',
      emptyMessage: 'Add a business, fill in its application and upload its documents. Once it is approved you can create live apps.',
      emptyIcon: Icons.business_center_outlined,
      row: RowView(
        icon: Icons.business_center_outlined,
        title: (m) => pick(m, <String>['name'], 'Business'),
        subtitle: (m) => '${pick(m, <String>['country'])}  ${pick(m, <String>['merchantNumber'])}  ${pick(m, <String>['nextStep.message'])}'.trim(),
        status: (m) => pick(m, <String>['application.status', 'status.production.status']),
      ),
      headerActions: <ItemAction>[
        ItemAction(
          'Add a business',
          Icons.add_business_outlined,
          title: 'Add a business',
          subtitle: 'Its application is started for you. Complete it from the business page.',
          fields: const <FieldSpec>[
            FieldSpec('name', 'Business name', required: true, maxLength: 160),
            FieldSpec('tradingName', 'Trading name', maxLength: 160),
            FieldSpec('country', 'Country code', required: true, maxLength: 2, hint: 'KE'),
            FieldSpec('currency', 'Currency code', maxLength: 3, hint: 'KES'),
            FieldSpec('paymentMethods', 'Payment methods', kind: FieldKind.multiSelect, options: _methods),
            FieldSpec('contactEmail', 'Contact email', kind: FieldKind.email),
            FieldSpec('contactPhone', 'Contact phone', kind: FieldKind.phone, maxLength: 20),
          ],
          run: (_, v) async {
            await repo.applyForBusiness(<String, dynamic>{
              ...v,
              if (v['country'] is String) 'country': (v['country'] as String).toUpperCase(),
              if (v['currency'] is String) 'currency': (v['currency'] as String).toUpperCase(),
            });
          },
          done: 'Business added',
        ),
      ],
    );
  }
}

/// One business: where it stands, its onboarding application, documents, history and apps.
class DeveloperBusinessPage extends ConsumerStatefulWidget {
  const DeveloperBusinessPage({super.key, required this.businessId});

  final String businessId;

  @override
  ConsumerState<DeveloperBusinessPage> createState() => _DeveloperBusinessPageState();
}

class _DeveloperBusinessPageState extends ConsumerState<DeveloperBusinessPage> {
  int _bump = 0;

  void _reload() => setState(() => _bump++);

  /// The application with its form fields lifted to the top, so the edit form can start from them. Starts the
  /// application when the business has none yet.
  Future<Json> _loadApplication(DeveloperRepository repo) async {
    Json app;
    try {
      app = await repo.application(widget.businessId);
    } catch (e) {
      if (!ApiException.from(e).isNotFound) rethrow;
      app = await repo.startApplication(widget.businessId);
    }
    final flat = Map<String, dynamic>.of(app);
    flat.addAll(asMap(flat.remove('form')));
    return flat;
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(developerRepositoryProvider);
    final id = widget.businessId;
    return DefaultTabController(
      length: 5,
      child: Column(
        children: <Widget>[
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: <Tab>[Tab(text: 'Overview'), Tab(text: 'Application'), Tab(text: 'Documents'), Tab(text: 'Timeline'), Tab(text: 'Apps')],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                ResourceView(refreshKey: _bump, load: () => repo.business(id)),
                ResourceView(
                  refreshKey: _bump,
                  load: () => _loadApplication(repo),
                  hidden: const <String>{'documents', 'requiredDocuments', 'returnItems'},
                  intro: 'Fill in the form, upload the documents, then submit. A reviewer decides, and may send it back with questions.',
                  actions: _applicationActions(repo, id),
                ),
                _DocumentsTab(businessId: id, refreshKey: _bump, onChanged: _reload, loader: () => _loadApplication(repo)),
                ResourceSection(
                  refreshKey: _bump,
                  load: () => repo.applicationTimeline(id),
                  emptyTitle: 'No events yet',
                  emptyIcon: Icons.timeline_rounded,
                  row: RowView(
                    icon: Icons.timeline_rounded,
                    title: (m) => sentence(pick(m, <String>['type'], 'Event')),
                    subtitle: (m) => '${displayValue(m['at'])}  ${pick(m, <String>['message'])}'.trim(),
                    status: (m) => pick(m, <String>['toStatus']),
                  ),
                ),
                ResourceSection(
                  refreshKey: _bump,
                  load: () => repo.appsRaw(businessId: id),
                  intro: 'Apps created for this business. Create one from the Apps menu once the business is approved.',
                  emptyTitle: 'No apps for this business',
                  emptyIcon: Icons.extension_outlined,
                  row: RowView(
                    icon: Icons.extension_outlined,
                    title: (m) => pick(m, <String>['name'], 'App'),
                    subtitle: (m) => pick(m, <String>['environment']),
                    status: (m) => pick(m, <String>['status']),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<ItemAction> _applicationActions(DeveloperRepository repo, String id) {
    bool editable(Json m) => const <String>{'DRAFT', 'RETURNED'}.contains(pick(m, <String>['status']));
    return <ItemAction>[
      ItemAction(
        'Edit the form',
        Icons.edit_outlined,
        title: 'Business details',
        initialFromItem: true,
        visible: editable,
        fields: const <FieldSpec>[
          FieldSpec('businessType', 'Type of business', kind: FieldKind.select, options: _businessTypes),
          FieldSpec('registeredName', 'Registered name', maxLength: 160),
          FieldSpec('tradingName', 'Trading name', maxLength: 160),
          FieldSpec('registrationNumber', 'Registration number', maxLength: 60),
          FieldSpec('taxPin', 'Tax PIN', maxLength: 30),
          FieldSpec('country', 'Country code', maxLength: 2),
          FieldSpec('city', 'City', maxLength: 80),
          FieldSpec('physicalAddress', 'Physical address', maxLength: 300),
          FieldSpec('website', 'Website', maxLength: 200),
          FieldSpec('industry', 'Industry', maxLength: 120),
          FieldSpec('businessDescription', 'What the business does', kind: FieldKind.multiline, maxLength: 2000),
          FieldSpec('expectedMonthlyVolumeUsd', 'Expected monthly volume (USD)', kind: FieldKind.integer),
          FieldSpec('contactName', 'Contact name', maxLength: 120),
          FieldSpec('contactEmail', 'Contact email', kind: FieldKind.email),
          FieldSpec('contactPhone', 'Contact phone', kind: FieldKind.phone, maxLength: 20),
          FieldSpec('walletAccountNumber', 'Premisave wallet email for payouts', kind: FieldKind.email),
          FieldSpec('onBehalf', 'I am applying on behalf of this business', kind: FieldKind.toggle),
          FieldSpec('applicantRole', 'My role in the business', maxLength: 80),
        ],
        run: (_, v) async {
          await repo.saveApplication(id, v);
        },
        done: 'Application saved',
      ),
      ItemAction(
        'Add a director',
        Icons.person_add_alt_outlined,
        title: 'Add a director',
        visible: editable,
        fields: const <FieldSpec>[
          FieldSpec('fullName', 'Full name', required: true, maxLength: 160),
          FieldSpec('idNumber', 'ID number', maxLength: 40),
          FieldSpec('role', 'Role', maxLength: 60, hint: 'Director, shareholder'),
          FieldSpec('ownershipPercent', 'Ownership (percent)', kind: FieldKind.integer),
        ],
        run: (item, v) async {
          // Directors sent to the service replace the whole list, so the existing ones are sent back with the new one.
          final directors = <Json>[...listOf(item['directors']), v];
          await repo.saveApplication(id, <String, dynamic>{'directors': directors});
        },
        done: 'Director added',
      ),
      ItemAction(
        'Remove a director',
        Icons.person_remove_outlined,
        title: 'Remove a director',
        danger: true,
        visible: (m) => editable(m) && listOf(m['directors']).isNotEmpty,
        fields: const <FieldSpec>[FieldSpec('number', 'Director number', kind: FieldKind.integer, required: true, helper: '1 is the first director in the list above.')],
        run: (item, v) async {
          final directors = <Json>[...listOf(item['directors'])];
          final n = (v['number'] as num).toInt();
          if (n < 1 || n > directors.length) throw ApiException('There is no director number $n.');
          directors.removeAt(n - 1);
          await repo.saveApplication(id, <String, dynamic>{'directors': directors});
        },
        done: 'Director removed',
      ),
      ItemAction(
        'Upload a document',
        Icons.upload_file_outlined,
        title: 'Upload a document',
        visible: editable,
        page: (_) => _UploadDocumentPage(businessId: id),
      ),
      ItemAction(
        'Submit',
        Icons.send_rounded,
        title: 'Submit the application',
        visible: editable,
        page: (item) => _SubmitPage(businessId: id, application: item),
      ),
    ];
  }
}

class _DocumentsTab extends ConsumerWidget {
  const _DocumentsTab({required this.businessId, required this.refreshKey, required this.onChanged, required this.loader});

  final String businessId;
  final Object refreshKey;
  final VoidCallback onChanged;
  final Future<Json> Function() loader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(developerRepositoryProvider);
    return ResourceSection(
      refreshKey: refreshKey,
      load: () async => listOf((await loader())['documents']),
      intro: 'Files attached to the application. PDF, PNG or JPEG.',
      emptyTitle: 'No documents yet',
      emptyMessage: 'Upload the registration certificate, tax certificate and director IDs from the Application menu.',
      emptyIcon: Icons.folder_open_outlined,
      row: RowView(
        icon: Icons.description_outlined,
        title: (m) => sentence(pick(m, <String>['type'], 'Document')),
        subtitle: (m) => pick(m, <String>['fileName']),
        status: (m) => pick(m, <String>['verdict']),
      ),
      itemActions: <ItemAction>[
        ItemAction(
          'View',
          Icons.visibility_outlined,
          run: (m, _) async {
            final bytes = await repo.downloadApplicationDocument(businessId, pick(m, <String>['documentId']));
            final type = pick(m, <String>['contentType']);
            if (!context.mounted) return;
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(pick(m, <String>['fileName'], 'Document')),
                content: type.startsWith('image/')
                    ? InteractiveViewer(child: Image.memory(bytes, errorBuilder: (_, __, ___) => const Text('This image could not be shown.')))
                    : Text('${formatBytesShort(bytes.length)} downloaded. A $type file cannot be previewed here.'),
                actions: <Widget>[TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
              ),
            );
          },
        ),
        ItemAction(
          'Remove',
          Icons.delete_outline_rounded,
          danger: true,
          confirm: 'The document is taken off the application.',
          run: (m, _) => repo.removeApplicationDocument(businessId, pick(m, <String>['documentId'])),
          done: 'Document removed',
        ),
      ],
    );
  }
}

String formatBytesShort(int n) {
  if (n < 1024) return '$n B';
  if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(1)} KB';
  return '${(n / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class _UploadDocumentPage extends ConsumerStatefulWidget {
  const _UploadDocumentPage({required this.businessId});

  final String businessId;

  @override
  ConsumerState<_UploadDocumentPage> createState() => _UploadDocumentPageState();
}

class _UploadDocumentPageState extends ConsumerState<_UploadDocumentPage> {
  String _type = 'BUSINESS_REGISTRATION';
  ChosenFile? _file;
  bool _busy = false;
  String? _error;

  Future<void> _choose() async {
    final picked = await chooseFiles(extensions: const <String>['pdf', 'png', 'jpg', 'jpeg'], withData: true);
    if (picked.isNotEmpty) setState(() => _file = picked.first);
  }

  Future<void> _upload() async {
    final f = _file;
    if (f == null) {
      setState(() => _error = 'Choose a file first.');
      return;
    }
    if (f.size > 8 * 1024 * 1024) {
      setState(() => _error = 'The file is over 8 MB. Choose a smaller one.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(developerRepositoryProvider).uploadApplicationDocument(
            widget.businessId,
            LocalFile(name: f.name, bytes: f.bytes, path: f.path, size: f.size),
            type: _type,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showToast(context, 'Document uploaded');
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      maxWidth: 560,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PSelectField<String>(
                label: 'What is it?',
                value: _type,
                options: <PChoice<String>>[for (final e in _documentTypes.entries) PChoice<String>(e.key, e.value)],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 14),
              PButton(label: _file == null ? 'Choose a file' : _file!.name, icon: Icons.attach_file_rounded, kind: PButtonKind.outline, onPressed: _choose),
              const SizedBox(height: 6),
              Text('PDF, PNG or JPEG, up to 8 MB.', style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
              if (_error != null) ...<Widget>[const SizedBox(height: 12), InlineMessage(_error!, kind: MessageKind.error)],
              const SizedBox(height: 18),
              PButton(label: 'Upload', icon: Icons.cloud_upload_outlined, loading: _busy, onPressed: _upload),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubmitPage extends ConsumerStatefulWidget {
  const _SubmitPage({required this.businessId, required this.application});

  final String businessId;
  final Json application;

  @override
  ConsumerState<_SubmitPage> createState() => _SubmitPageState();
}

class _SubmitPageState extends ConsumerState<_SubmitPage> {
  final _message = TextEditingController();
  final Map<String, TextEditingController> _answers = <String, TextEditingController>{};
  bool _busy = false;
  String? _error;

  List<Json> get _items => listOf(widget.application['returnItems']).where((i) => i['addressed'] != true).toList();

  @override
  void dispose() {
    _message.dispose();
    for (final c in _answers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final responses = <Json>[
        for (final i in _items)
          if ((_answers[pick(i, <String>['itemId'])]?.text ?? '').trim().isNotEmpty)
            <String, dynamic>{'itemId': pick(i, <String>['itemId']), 'response': _answers[pick(i, <String>['itemId'])]!.text.trim()},
      ];
      await ref.read(developerRepositoryProvider).submitApplication(
            widget.businessId,
            message: _message.text.trim().isEmpty ? null : _message.text.trim(),
            responses: responses.isEmpty ? null : responses,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showToast(context, 'Application submitted');
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final missing = stringList(widget.application['missing']);
    return PageBody(
      maxWidth: 620,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (missing.isNotEmpty) InlineMessage('Still missing: ${missing.join(', ')}.', kind: MessageKind.warning),
              if (_items.isNotEmpty) ...<Widget>[
                const BlockTitle('Questions from the reviewer'),
                for (final i in _items) ...<Widget>[
                  Text(pick(i, <String>['message']), style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  PTextField(
                    label: 'Your answer about ${humanize(pick(i, <String>['field'], 'this'))}',
                    controller: _answers.putIfAbsent(pick(i, <String>['itemId']), TextEditingController.new),
                    maxLines: 3,
                    minLines: 2,
                  ),
                  const SizedBox(height: 14),
                ],
              ],
              PTextField(label: 'Note to the reviewer', controller: _message, optional: true, maxLines: 4, minLines: 3, maxLength: 2000),
              if (_error != null) ...<Widget>[const SizedBox(height: 12), InlineMessage(_error!, kind: MessageKind.error)],
              const SizedBox(height: 18),
              PButton(label: 'Submit for review', icon: Icons.send_rounded, loading: _busy, onPressed: _submit),
            ],
          ),
        ),
      ],
    );
  }
}
