import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/application_models.dart';
import '../../data/models/place.dart';
import '../../state/data_providers.dart';
import '../../state/providers.dart';
import '../places/address_search_field.dart';
import 'application_widgets.dart';

class ApplicationWizardScreen extends ConsumerWidget {
  const ApplicationWizardScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(applicationProvider(applicationId));
    final meta = ref.watch(appMetaProvider);

    return SubPage(
      title: 'Application',
      fallbackRoute: '/application',
      body: app.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(applicationProvider(applicationId))),
        data: (a) => meta.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(appMetaProvider)),
          data: (m) => a.editable ? _WizardBody(initial: a, meta: m) : _ReadOnlyView(app: a, meta: m),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- read only

class _ReadOnlyView extends ConsumerWidget {
  const _ReadOnlyView({required this.app, required this.meta});

  final ApplicationDetail app;
  final AppMeta meta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? opt(List<Option> list, String key) {
      final v = app.text(key);
      return v == null ? null : meta.labelFor(list, v);
    }

    return PageBody(
      maxWidth: 760,
      onRefresh: () async => ref.invalidate(applicationProvider(app.id)),
      children: <Widget>[
        ApplicationStatusPanel(app: app),
        const SectionHeader('Details'),
        PCard(
          child: Column(
            children: <Widget>[
              InfoRow('Applying as', opt(meta.ownerTypes, 'ownerType')),
              if (app.text('companyName') != null) InfoRow('Company', app.text('companyName')),
              InfoRow('ID type', opt(meta.idTypes, 'idType')),
              InfoRow('ID number', app.text('idNumber')),
              InfoRow('Phone', app.text('phoneNumber')),
              InfoRow('Country', meta.labelFor(meta.countries, app.text('country'))),
              InfoRow('Region', app.text('region')),
              InfoRow('City', app.text('city')),
              InfoRow('Properties', app.number('numberOfProperties')?.toString()),
              InfoRow('Property types', app.list('propertyTypes').map((t) => meta.labelFor(meta.propertyTypes, t)).join(', ')),
              InfoRow('Payout', opt(meta.payoutMethods, 'payoutMethod')),
              InfoRow('Submitted', formatDateTime(app.submittedAt)),
              InfoRow('Decided', formatDateTime(app.decidedAt)),
            ],
          ),
        ),
        const SectionHeader('Documents'),
        DocumentList(
          documents: app.documents,
          onPreview: (d) => showImagePreview(context, d.fileName, () => ref.read(applicationRepositoryProvider).downloadDocument(app.id, d.id)),
        ),
        const SectionHeader('Timeline'),
        ApplicationTimeline(events: app.timeline),
      ],
    );
  }
}

// -------------------------------------------------------------------- wizard

const List<String> _stepTitles = <String>[
  'About you',
  'Contact and address',
  'Your properties',
  'Getting paid',
  'Documents',
  'Review and submit',
];

const List<List<String>> _stepKeys = <List<String>>[
  <String>['ownerType', 'companyName', 'companyRegistrationNumber', 'idType', 'idNumber', 'idIssuingCountry', 'dateOfBirth', 'nationality', 'taxId'],
  <String>['phoneNumber', 'alternatePhoneNumber', 'country', 'region', 'city', 'physicalAddress', 'postalAddress'],
  <String>['numberOfProperties', 'estimatedTotalUnits', 'propertyTypes', 'primaryPropertyLocation', 'propertyDescription', 'managementPreference', 'yearsAsLandlord'],
  <String>['payoutMethod', 'mobileMoneyProvider', 'mobileMoneyNumber', 'paypalEmail', 'bankName', 'bankAccountName', 'bankAccountNumber', 'bankSwiftCode', 'bankBranch'],
  <String>[],
  <String>['motivation', 'referralSource', 'termsAccepted', 'privacyConsent', 'declarationAccepted'],
];

const Set<String> _textKeys = <String>{
  'companyName', 'companyRegistrationNumber', 'idNumber', 'taxId', 'phoneNumber', 'alternatePhoneNumber', 'region', 'city',
  'physicalAddress', 'postalAddress', 'numberOfProperties', 'estimatedTotalUnits', 'primaryPropertyLocation',
  'propertyDescription', 'yearsAsLandlord', 'mobileMoneyProvider', 'mobileMoneyNumber', 'paypalEmail', 'bankName',
  'bankAccountName', 'bankAccountNumber', 'bankSwiftCode', 'bankBranch', 'motivation', //
};

const Set<String> _numberKeys = <String>{'numberOfProperties', 'estimatedTotalUnits', 'yearsAsLandlord'};
const Set<String> _boolKeys = <String>{'termsAccepted', 'privacyConsent', 'declarationAccepted'};

class _WizardBody extends ConsumerStatefulWidget {
  const _WizardBody({required this.initial, required this.meta});

  final ApplicationDetail initial;
  final AppMeta meta;

  @override
  ConsumerState<_WizardBody> createState() => _WizardBodyState();
}

class _WizardBodyState extends ConsumerState<_WizardBody> {
  late ApplicationDetail _app = widget.initial;
  int _step = 0;
  bool _saving = false;
  bool _uploading = false;
  Map<String, String> _errors = <String, String>{};
  String? _banner;

  final Map<String, TextEditingController> _c = <String, TextEditingController>{};
  final Map<String, dynamic> _v = <String, dynamic>{};

  final _docNumber = TextEditingController();
  String? _docType;
  DateTime? _docExpiry;

  AppMeta get _meta => widget.meta;

  @override
  void initState() {
    super.initState();
    for (final k in _textKeys) {
      _c[k] = TextEditingController(text: _app.text(k) ?? '');
    }
    for (final k in <String>['ownerType', 'idType', 'idIssuingCountry', 'nationality', 'country', 'managementPreference', 'payoutMethod', 'referralSource']) {
      _v[k] = _app.text(k);
    }
    _v['propertyTypes'] = List<String>.from(_app.list('propertyTypes'));
    final dob = _app.text('dateOfBirth');
    _v['dateOfBirth'] = dob == null ? null : DateTime.tryParse(dob);
    for (final k in _boolKeys) {
      _v[k] = _app.flag(k);
    }
    // Jump to the first step that still has something missing.
    _step = _firstIncompleteStep();
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    _docNumber.dispose();
    super.dispose();
  }

  /// Opens on the first step with an empty required field, so a returning applicant lands where work is left.
  int _firstIncompleteStep() {
    final r = _app.readiness;
    if (r.issues.isEmpty) return 0;
    var best = _stepKeys.length;
    for (final i in r.issues) {
      final s = _stepForField(i.field);
      if (s < best) best = s;
    }
    return best >= _stepKeys.length ? 0 : best;
  }

  // ---------------------------------------------------------------- values

  String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _collect(List<String> keys) {
    final out = <String, dynamic>{};
    for (final k in keys) {
      if (_c.containsKey(k)) {
        final t = _c[k]!.text.trim();
        if (t.isEmpty) continue;
        out[k] = _numberKeys.contains(k) ? (int.tryParse(t) ?? t) : t;
      } else if (_boolKeys.contains(k)) {
        out[k] = _v[k] == true;
      } else {
        final v = _v[k];
        if (v == null) continue;
        if (v is DateTime) {
          out[k] = _iso(v);
        } else if (v is List && v.isEmpty) {
          continue;
        } else {
          out[k] = v;
        }
      }
    }
    return out;
  }

  Future<bool> _saveStep(int step) async {
    final keys = _stepKeys[step];
    if (keys.isEmpty) return true;
    setState(() {
      _saving = true;
      _errors = <String, String>{};
      _banner = null;
    });
    try {
      final body = _collect(keys);
      final updated = await ref.read(applicationRepositoryProvider).save(_app.id, body);
      if (mounted) setState(() => _app = updated);
      ref.invalidate(myApplicationProvider);
      return true;
    } catch (e) {
      final err = ApiException.from(e);
      if (mounted) {
        setState(() {
          _errors = err.fieldErrors;
          _banner = err.fieldErrors.isEmpty ? err.message : 'Please fix the highlighted fields.';
        });
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _next() async {
    if (!await _saveStep(_step)) return;
    if (!mounted) return;
    if (_step < _stepTitles.length - 1) setState(() => _step++);
  }

  Future<void> _saveDraft() async {
    if (await _saveStep(_step) && mounted) showToast(context, 'Draft saved');
  }

  Future<void> _submit() async {
    if (!await _saveStep(5)) return;
    setState(() {
      _saving = true;
      _banner = null;
    });
    try {
      await ref.read(applicationRepositoryProvider).submit(_app.id);
      ref.invalidate(myApplicationProvider);
      ref.invalidate(myApplicationsProvider);
      ref.invalidate(applicationProvider(_app.id));
      if (!mounted) return;
      showToast(context, 'Application submitted. We will keep you posted.');
      context.go('/application');
    } catch (e) {
      final err = ApiException.from(e);
      if (mounted) {
        setState(() {
          _errors = err.fieldErrors;
          _banner = err.message;
        });
      }
      // The server may have new readiness details.
      try {
        final fresh = await ref.read(applicationRepositoryProvider).get(_app.id);
        if (mounted) setState(() => _app = fresh);
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // --------------------------------------------------------------- widgets

  String? _err(String key) => _errors[key];

  Widget _text(
    String key,
    String label, {
    String? hint,
    TextInputType? keyboard,
    bool optional = false,
    int maxLines = 1,
    int? maxLength,
    String? helper,
    TextCapitalization caps = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PTextField(
        label: label,
        controller: _c[key],
        hint: hint,
        keyboardType: keyboard,
        optional: optional,
        maxLines: maxLines,
        minLines: maxLines > 1 ? 3 : null,
        maxLength: maxLength,
        helper: helper,
        textCapitalization: caps,
        errorText: _err(key),
        textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      ),
    );
  }

  /// An address box with search. Choosing a result fills the text and calls [onPlace].
  Widget _address(
    String key,
    String label, {
    String? hint,
    IconData icon = Icons.home_outlined,
    AddressFill fill = AddressFill.street,
    ValueChanged<Place>? onPlace,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AddressSearchField(
        label: label,
        hint: hint ?? 'Start typing a street, building or area',
        prefixIcon: icon,
        fill: fill,
        controller: _c[key]!,
        errorText: _err(key),
        countryCode: _v['country'] as String?,
        onPlace: onPlace ?? (_) {},
      ),
    );
  }

  /// Fills the region, town, postcode and country from a chosen address. All of them stay editable.
  void _fillFromPlace(Place p) {
    final region = p.state;
    if (region != null) _c['region']!.text = region;
    final town = p.city ?? p.district;
    if (town != null) _c['city']!.text = town;
    final post = p.postcode;
    if (post != null) _c['postalAddress']!.text = post;
    final code = p.countryCode;
    setState(() {
      if (code != null && _meta.countries.any((o) => o.value == code)) _v['country'] = code;
    });
  }

  Widget _select(String key, String label, List<Option> options, {bool optional = false, bool searchable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PSelectField<String>(
        label: label,
        optional: optional,
        searchable: searchable,
        options: <PChoice<String>>[for (final o in options) PChoice<String>(o.value, o.label, description: o.description)],
        value: _v[key] as String?,
        errorText: _err(key),
        onChanged: (v) => setState(() => _v[key] = v),
      ),
    );
  }

  Widget _date(String key, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PDateField(
        label: label,
        value: _v[key] as DateTime?,
        errorText: _err(key),
        lastDate: DateTime.now(),
        onChanged: (d) => setState(() => _v[key] = d),
      ),
    );
  }

  Widget _check(String key, String text) {
    final error = _err(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _v[key] = !(_v[key] == true)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Checkbox(value: _v[key] == true, onChanged: (v) => setState(() => _v[key] = v ?? false)),
                Expanded(child: Padding(padding: const EdgeInsets.only(top: 12), child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.4)))),
              ],
            ),
          ),
          if (error != null) Padding(padding: const EdgeInsets.only(left: 12, bottom: 6), child: Text(error, style: const TextStyle(color: Brand.danger, fontSize: 12.5))),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- steps

  List<Widget> _stepAbout() {
    final owner = _v['ownerType'] as String?;
    final company = owner != null && owner != 'INDIVIDUAL';
    return <Widget>[
      _select('ownerType', 'Applying as', _meta.ownerTypes),
      if (company) ...<Widget>[
        _text('companyName', 'Company or organisation name', caps: TextCapitalization.words),
        _text('companyRegistrationNumber', 'Registration number', optional: owner != 'COMPANY'),
      ],
      _select('idType', 'ID type', _meta.idTypes),
      _text('idNumber', 'ID number', helper: 'Exactly as printed on the document.'),
      _select('idIssuingCountry', 'Country that issued the ID', _meta.countries, searchable: true),
      _date('dateOfBirth', 'Date of birth'),
      _select('nationality', 'Nationality', _meta.countries, searchable: true),
      _text('taxId', 'Tax ID', optional: true, helper: 'If your country issues one.'),
    ];
  }

  List<Widget> _stepContact() => <Widget>[
        _text('phoneNumber', 'Phone number', keyboard: TextInputType.phone, hint: '+1 555 123 4567', helper: 'Include the country code.'),
        _text('alternatePhoneNumber', 'Alternate phone', keyboard: TextInputType.phone, optional: true),
        _select('country', 'Country', _meta.countries, searchable: true),
        _address('physicalAddress', 'Street address', onPlace: _fillFromPlace),
        _text('region', 'Region, state or county', caps: TextCapitalization.words),
        _text('city', 'City or town', caps: TextCapitalization.words),
        _text('postalAddress', 'Postal address or ZIP code', optional: true),
      ];

  List<Widget> _stepProperties() {
    final selected = (_v['propertyTypes'] as List<String>);
    return <Widget>[
      _text('numberOfProperties', 'Number of properties', keyboard: TextInputType.number),
      _text('estimatedTotalUnits', 'Estimated total units', keyboard: TextInputType.number, helper: 'Apartments, rooms or plots you would list.'),
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Property types', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final o in _meta.propertyTypes)
                  FilterChip(
                    label: Text(o.label),
                    selected: selected.contains(o.value),
                    showCheckmark: false,
                    onSelected: (on) => setState(() {
                      if (on) {
                        selected.add(o.value);
                      } else {
                        selected.remove(o.value);
                      }
                    }),
                  ),
              ],
            ),
            if (_err('propertyTypes') != null)
              Padding(padding: const EdgeInsets.only(top: 6), child: Text(_err('propertyTypes')!, style: const TextStyle(color: Brand.danger, fontSize: 12.5))),
          ],
        ),
      ),
      _address('primaryPropertyLocation', 'Main property location',
          hint: 'Neighbourhood and city', icon: Icons.location_on_outlined, fill: AddressFill.summary),
      _text('propertyDescription', 'Describe your properties', maxLines: 4, maxLength: 600, optional: true),
      _select('managementPreference', 'How will you manage them?', _meta.managementPreferences),
      _text('yearsAsLandlord', 'Years as a landlord', keyboard: TextInputType.number, optional: true),
    ];
  }

  List<Widget> _stepPayout() {
    final method = _v['payoutMethod'] as String?;
    return <Widget>[
      _select('payoutMethod', 'Payout method', _meta.payoutMethods),
      if (method == 'MOBILE_MONEY') ...<Widget>[
        _text('mobileMoneyProvider', 'Mobile money provider'),
        _text('mobileMoneyNumber', 'Mobile money number', keyboard: TextInputType.phone),
      ],
      if (method == 'PAYPAL') _text('paypalEmail', 'PayPal email', keyboard: TextInputType.emailAddress),
      if (method == 'BANK_TRANSFER') ...<Widget>[
        _text('bankName', 'Bank name', caps: TextCapitalization.words),
        _text('bankAccountName', 'Account holder name', caps: TextCapitalization.words),
        _text('bankAccountNumber', 'Account number or IBAN'),
        _text('bankSwiftCode', 'SWIFT or BIC code', optional: true, caps: TextCapitalization.characters, helper: '8 or 11 characters.'),
        _text('bankBranch', 'Branch', optional: true),
      ],
      if (method == null) Text('Choose how you would like to be paid.', style: TextStyle(color: context.mutedColor)),
    ];
  }

  // -------------------------------------------------------------- documents

  Future<void> _upload({required bool camera}) async {
    if (_docType == null) {
      showToast(context, 'Choose the document type first', error: true);
      return;
    }
    final limits = _meta.limits;
    try {
      List<int> bytes;
      String name;
      if (camera) {
        final x = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 2400, imageQuality: 90);
        if (x == null) return;
        bytes = await x.readAsBytes();
        name = x.name;
      } else {
        final exts = (limits.allowedExtensions.isEmpty ? <String>['pdf', 'jpg', 'jpeg', 'png'] : limits.allowedExtensions)
            .map((e) => e.replaceAll('.', '').toLowerCase())
            .toList();
        final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: exts, withData: true);
        if (res == null || res.files.isEmpty) return;
        final f = res.files.single;
        bytes = f.bytes ?? <int>[];
        name = f.name;
        if (bytes.isEmpty) throw ApiException('Could not read that file. Try another one.');
      }
      if (bytes.length > limits.maxFileSizeBytes) {
        throw ApiException('That file is larger than ${limits.maxFileSizeLabel}.');
      }
      setState(() => _uploading = true);
      final updated = await ref.read(applicationRepositoryProvider).uploadDocument(
            _app.id,
            type: _docType!,
            bytes: bytes,
            fileName: name,
            documentNumber: _docNumber.text.trim(),
            expiryDate: _docExpiry == null ? null : _iso(_docExpiry!),
          );
      if (!mounted) return;
      setState(() {
        _app = updated;
        _docNumber.clear();
        _docExpiry = null;
      });
      ref.invalidate(myApplicationProvider);
      showToast(context, 'Document uploaded');
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteDoc(DocumentView d) async {
    final ok = await confirmDialog(context, title: 'Remove this document?', message: d.fileName, confirmLabel: 'Remove', danger: true);
    if (!ok) return;
    try {
      final updated = await ref.read(applicationRepositoryProvider).deleteDocument(_app.id, d.id);
      if (mounted) setState(() => _app = updated);
      ref.invalidate(myApplicationProvider);
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  List<Widget> _stepDocuments() {
    final reqs = _app.readiness.requirements;
    final needsId = _docType == 'GOVERNMENT_ID_FRONT' || _docType == 'PASSPORT_BIO_PAGE' || _docType == 'DRIVING_LICENCE';
    return <Widget>[
      const InlineMessage('Clear photos or scans work best. Files must be readable and not cropped.'),
      const SizedBox(height: 14),
      for (final r in reqs) ...<Widget>[
        PCard(
          padding: const EdgeInsets.all(14),
          borderColor: r.needsAttention ? Brand.danger.op(0.5) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    r.verified ? Icons.verified_rounded : (r.uploaded ? Icons.hourglass_top_rounded : Icons.radio_button_unchecked_rounded),
                    size: 20,
                    color: r.verified ? Brand.success : (r.needsAttention ? Brand.danger : (r.uploaded ? Brand.warning : context.mutedColor)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5))),
                  if (!r.required) const StatusPill('Optional', color: Brand.muted, dense: true),
                ],
              ),
              if (r.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4, left: 30), child: Text(r.description, style: TextStyle(fontSize: 12.5, height: 1.4, color: context.mutedColor))),
              if (r.stillNeeded.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 26),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: <Widget>[
                      for (final t in r.stillNeeded)
                        ActionChip(
                          label: Text('Add ${_meta.documentType(t)?.label ?? sentence(t)}'),
                          onPressed: () => setState(() => _docType = t),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
      const SectionHeader('Add a document'),
      PCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PSelectField<String>(
              label: 'Document type',
              searchable: true,
              options: <PChoice<String>>[for (final d in _meta.documentTypes) PChoice<String>(d.value, d.label, description: d.category)],
              value: _docType,
              onChanged: (v) => setState(() => _docType = v),
            ),
            if (_docType != null && _meta.documentType(_docType!) != null) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_meta.documentType(_docType!)!.description, style: TextStyle(fontSize: 12.5, height: 1.4, color: context.mutedColor)),
            ),
            if (needsId) ...<Widget>[
              const SizedBox(height: 14),
              PTextField(label: 'Document number', controller: _docNumber, optional: true),
              const SizedBox(height: 14),
              PDateField(
                label: 'Expiry date',
                optional: true,
                value: _docExpiry,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
                initialDate: DateTime.now().add(const Duration(days: 365)),
                onChanged: (d) => setState(() => _docExpiry = d),
              ),
            ],
            const SizedBox(height: 16),
            PButton(label: 'Choose a file', icon: Icons.upload_file_rounded, loading: _uploading, onPressed: _uploading ? null : () => _upload(camera: false)),
            if (!kIsWeb) ...<Widget>[
              const SizedBox(height: 10),
              PButton(label: 'Take a photo', icon: Icons.photo_camera_outlined, kind: PButtonKind.outline, onPressed: _uploading ? null : () => _upload(camera: true)),
            ],
            const SizedBox(height: 8),
            Text(
              'Up to ${_meta.limits.maxFileSizeLabel}. ${_meta.limits.allowedExtensions.isEmpty ? 'PDF, JPG or PNG.' : _meta.limits.allowedExtensions.map((e) => e.replaceAll('.', '').toUpperCase()).join(', ')}.',
              style: TextStyle(fontSize: 12, color: context.mutedColor),
            ),
          ],
        ),
      ),
      const SectionHeader('Your documents'),
      DocumentList(
        documents: _app.documents,
        onDelete: _deleteDoc,
        onPreview: (d) => showImagePreview(context, d.fileName, () => ref.read(applicationRepositoryProvider).downloadDocument(_app.id, d.id)),
      ),
    ];
  }

  // ------------------------------------------------------------------ review

  int _stepForField(String field) {
    for (var i = 0; i < _stepKeys.length; i++) {
      if (_stepKeys[i].contains(field)) return i;
    }
    return 4;
  }

  List<Widget> _stepReview() {
    final r = _app.readiness;
    return <Widget>[
      PCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(r.canSubmit ? Icons.check_circle_rounded : Icons.pending_outlined, color: r.canSubmit ? Brand.success : Brand.warning),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(r.canSubmit ? 'Ready to submit' : 'A few things are missing', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                Text('${r.percent}%', style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            if (r.issues.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              for (final i in r.issues)
                InkWell(
                  onTap: () => setState(() => _step = _stepForField(i.field)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(Icons.error_outline_rounded, size: 18, color: Brand.warning),
                        const SizedBox(width: 8),
                        Expanded(child: Text(i.message, style: const TextStyle(fontSize: 13.5, height: 1.35))),
                        Icon(Icons.chevron_right_rounded, size: 18, color: context.mutedColor),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 18),
      _text('motivation', 'Why do you want to host on Premisave?', maxLines: 4, maxLength: 1000, optional: true),
      _select('referralSource', 'How did you hear about us?', _meta.referralSources, optional: true),
      _check('termsAccepted', 'I accept the Terms of Service.'),
      _check('privacyConsent', 'I consent to Premisave processing my personal data to review this application.'),
      _check('declarationAccepted', 'I declare that the information and documents I provided are true and belong to me.'),
    ];
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final last = _step == _stepTitles.length - 1;
    final List<Widget> content;
    switch (_step) {
      case 0:
        content = _stepAbout();
        break;
      case 1:
        content = _stepContact();
        break;
      case 2:
        content = _stepProperties();
        break;
      case 3:
        content = _stepPayout();
        break;
      case 4:
        content = _stepDocuments();
        break;
      default:
        content = _stepReview();
    }

    return Column(
      children: <Widget>[
        ContentWidth(
          maxWidth: 720,
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text('Step ${_step + 1} of ${_stepTitles.length}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.mutedColor)),
                    const Spacer(),
                    TextButton(onPressed: _saving ? null : _saveDraft, child: const Text('Save draft')),
                  ],
                ),
                Text(_stepTitles[_step], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: (_step + 1) / _stepTitles.length, minHeight: 6, backgroundColor: context.borderColor, color: Brand.gold),
                ),
                if (_app.latestMessage != null && _app.status == 'INFO_REQUESTED') ...<Widget>[
                  const SizedBox(height: 12),
                  InlineMessage(_app.latestMessage!, kind: MessageKind.warning),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            child: ContentWidth(
              maxWidth: 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (_banner != null) ...<Widget>[InlineMessage(_banner!, kind: MessageKind.error), const SizedBox(height: 16)],
                  ...content,
                ],
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(color: context.surfaceColor, border: Border(top: BorderSide(color: context.borderColor))),
          child: SafeArea(
            top: false,
            child: ContentWidth(
              maxWidth: 720,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: <Widget>[
                    if (_step > 0) ...<Widget>[
                      PButton(label: 'Back', kind: PButtonKind.outline, icon: Icons.arrow_back_rounded, onPressed: _saving ? null : () => setState(() => _step--)),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: PButton(
                        label: last ? 'Submit application' : 'Save and continue',
                        icon: last ? Icons.send_rounded : Icons.arrow_forward_rounded,
                        kind: last ? PButtonKind.accent : PButtonKind.primary,
                        expand: true,
                        loading: _saving,
                        onPressed: _saving ? null : (last ? _submit : _next),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
