import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/country.dart';
import '../../data/models/place.dart';
import '../../data/models/user_model.dart';
import '../../roles/role.dart';
import '../../state/data_providers.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';
import '../places/address_search_field.dart';
import '../places/country_field.dart';
import '../places/phone_field.dart';

/// Administrators: change every detail of one account in a single form.
class AdminEditUserScreen extends ConsumerWidget {
  const AdminEditUserScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(adminUserProvider(userId));
    return SubPage(
      title: 'Edit user',
      fallbackRoute: '/admin/users/$userId',
      body: AsyncBody<UserModel>(
        value: value,
        onRetry: () => ref.invalidate(adminUserProvider(userId)),
        builder: (u) => _EditForm(user: u),
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({required this.user});

  final UserModel user;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  static const List<PChoice<String>> _languages = <PChoice<String>>[
    PChoice<String>('ENGLISH', 'English'),
    PChoice<String>('SPANISH', 'Spanish'),
    PChoice<String>('SWAHILI', 'Swahili'),
  ];

  final _form = GlobalKey<FormState>();
  late final TextEditingController _username;
  late final TextEditingController _first;
  late final TextEditingController _middle;
  late final TextEditingController _last;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address1;
  late final TextEditingController _address2;
  late final TextEditingController _country;
  final TextEditingController _password = TextEditingController();

  String? _countryCode;
  late String _language;
  late Role _role;
  late bool _active;
  late bool _verified;
  late bool _archived;
  bool _showPassword = false;
  bool _saving = false;
  String? _error;
  Map<String, String> _fieldErrors = <String, String>{};

  UserModel get _user => widget.user;

  @override
  void initState() {
    super.initState();
    final u = _user;
    _username = TextEditingController(text: u.username);
    _first = TextEditingController(text: u.firstName);
    _middle = TextEditingController(text: u.middleName);
    _last = TextEditingController(text: u.lastName);
    _email = TextEditingController(text: u.email);
    _phone = TextEditingController(text: u.phoneNumber);
    _address1 = TextEditingController(text: u.address1);
    _address2 = TextEditingController(text: u.address2);
    _country = TextEditingController(text: u.country);
    _countryCode = Country.byName(u.country)?.code;
    final lang = u.language.toUpperCase();
    _language = _languages.any((c) => c.value == lang) ? lang : 'ENGLISH';
    _role = u.role;
    _active = u.active;
    _verified = u.verified;
    _archived = u.archived;
  }

  @override
  void dispose() {
    for (final c in <TextEditingController>[_username, _first, _middle, _last, _email, _phone, _address1, _address2, _country, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _self => ref.read(sessionProvider).user?.id == _user.id;

  void _usePlace(Place p) {
    if (p.localityLine.isNotEmpty) _address2.text = p.localityLine;
    final country = p.country;
    if (country != null && country.isNotEmpty) _country.text = country;
    setState(() => _countryCode = p.countryCode ?? _countryCode);
  }

  /// Phone numbers are only checked when something is typed, so an older account without one can still be saved.
  String? _phoneRule(String? v) => (v == null || v.trim().isEmpty) ? null : Validators.phone(v);

  String? _passwordRule(String? v) {
    if (v == null || v.isEmpty) return null;
    if (v.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Add a capital letter';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Add a small letter';
    if (!RegExp(r'\d').hasMatch(v)) return 'Add a digit';
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final emailChanged = _email.text.trim().toLowerCase() != _user.email.toLowerCase();
    final passwordSet = _password.text.isNotEmpty;
    if (emailChanged || passwordSet) {
      final what = <String>[
        if (emailChanged) 'The email changes to ${_email.text.trim()}.',
        if (passwordSet) 'The password is replaced.',
      ].join(' ');
      final ok = await confirmDialog(
        context,
        title: 'Sign ${_user.displayName} out everywhere?',
        message: '$what They are signed out of every device and sign in again with the new details.',
        confirmLabel: 'Save changes',
      );
      if (!ok || !mounted) return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
      _fieldErrors = <String, String>{};
    });
    try {
      await ref.read(adminRepositoryProvider).update(
            _user.id,
            username: _username.text,
            firstName: _first.text,
            middleName: _middle.text,
            lastName: _last.text,
            email: _email.text,
            phoneNumber: _phone.text,
            country: _country.text,
            address1: _address1.text,
            address2: _address2.text,
            language: _language,
            role: _role,
            active: _active,
            verified: _verified,
            archived: _archived,
            password: passwordSet ? _password.text : null,
          );
      ref.invalidate(adminUserProvider(_user.id));
      ref.invalidate(adminUsersProvider);
      if (!mounted) return;
      showToast(context, 'Details saved');
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/admin/users/${_user.id}');
      }
    } catch (e) {
      final err = ApiException.from(e);
      if (mounted) {
        setState(() {
          _error = err.fieldErrors.isEmpty ? err.message : 'Please fix the highlighted fields.';
          _fieldErrors = err.fieldErrors;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final self = _self;
    final u = _user;
    return PageBody(
      maxWidth: 680,
      children: <Widget>[
        Center(child: UserAvatar(initials: u.initials, imageUrl: u.profilePictureUrl, size: 80, ring: true)),
        const SizedBox(height: 6),
        Center(child: Text('Profile photos are changed by the account owner.', style: TextStyle(fontSize: 12, color: context.mutedColor))),
        const SizedBox(height: 18),
        if (self)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: InlineMessage('This is your own account. Email, role, status and password are locked here so you cannot lock yourself out. Use Account for those.'),
          ),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_error != null) ...<Widget>[InlineMessage(_error!, kind: MessageKind.error), const SizedBox(height: 16)],
              const SectionHeader('Name'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: PTextField(
                      label: 'First name',
                      controller: _first,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => Validators.required(v, 'First name'),
                      errorText: _fieldErrors['firstName'],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PTextField(
                      label: 'Last name',
                      controller: _last,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => Validators.required(v, 'Last name'),
                      errorText: _fieldErrors['lastName'],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              PTextField(label: 'Middle name', controller: _middle, optional: true, textCapitalization: TextCapitalization.words),
              const SizedBox(height: 14),
              PTextField(
                label: 'Username',
                controller: _username,
                prefixIcon: Icons.alternate_email_rounded,
                validator: Validators.username,
                errorText: _fieldErrors['username'],
              ),
              const SectionHeader('Contact'),
              PTextField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                readOnly: self,
                prefixIcon: self ? Icons.lock_outline_rounded : Icons.mail_outline_rounded,
                validator: Validators.email,
                errorText: _fieldErrors['email'],
                helper: self ? null : 'They sign in with this address. Changing it signs them out everywhere.',
              ),
              const SizedBox(height: 14),
              PhoneField(
                controller: _phone,
                optional: true,
                countryCode: _countryCode,
                validator: _phoneRule,
                errorText: _fieldErrors['phoneNumber'],
              ),
              const SectionHeader('Location'),
              CountryField(
                controller: _country,
                optional: true,
                onCountry: (c) => setState(() => _countryCode = c?.code),
              ),
              const SizedBox(height: 14),
              AddressSearchField(
                label: 'Address line 1',
                controller: _address1,
                optional: true,
                countryCode: _countryCode,
                mapTitle: 'Choose the address',
                onPlace: _usePlace,
              ),
              const SizedBox(height: 14),
              PTextField(label: 'Address line 2', controller: _address2, optional: true, hint: 'Town, region and postcode'),
              const SizedBox(height: 14),
              PSelectField<String>(
                label: 'Language',
                value: _language,
                options: _languages,
                onChanged: (v) => setState(() => _language = v ?? _language),
              ),
              const SectionHeader('Access'),
              PSelectField<Role>(
                label: 'Role',
                value: _role,
                enabled: !self,
                options: <PChoice<Role>>[for (final r in Role.values) PChoice<Role>(r, r.label)],
                onChanged: (r) => setState(() => _role = r ?? _role),
              ),
              const SizedBox(height: 6),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                subtitle: const Text('Off blocks sign in and ends their sessions'),
                value: _active,
                onChanged: self ? null : (v) => setState(() => _active = v),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Email verified'),
                subtitle: const Text('Off makes them confirm their email again'),
                value: _verified,
                onChanged: self ? null : (v) => setState(() => _verified = v),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Archived'),
                subtitle: const Text('Hides the account and blocks sign in'),
                value: _archived,
                onChanged: self ? null : (v) => setState(() => _archived = v),
              ),
              if (!self) ...<Widget>[
                const SectionHeader('Password'),
                PTextField(
                  label: 'New password',
                  controller: _password,
                  optional: true,
                  obscure: !_showPassword,
                  prefixIcon: Icons.lock_reset_rounded,
                  suffix: IconButton(
                    tooltip: _showPassword ? 'Hide' : 'Show',
                    icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                  validator: _passwordRule,
                  errorText: _fieldErrors['password'],
                  helper: 'Leave empty to keep it. At least 8 characters with a capital letter, a small letter and a digit. To let them choose, use Send password reset.',
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: PButton(
                      label: 'Cancel',
                      kind: PButtonKind.outline,
                      onPressed: _saving ? null : () => context.canPop() ? context.pop() : context.go('/admin/users/${u.id}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: PButton(label: 'Save changes', loading: _saving, onPressed: _saving ? null : _save)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
