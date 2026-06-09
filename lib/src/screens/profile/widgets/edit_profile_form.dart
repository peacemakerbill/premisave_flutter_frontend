import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth/auth_provider.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);
const _border = Color(0xFFE2DDD6);

class EditProfileForm extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  final Map<String, String> initialData;
  final ScrollController? scrollController;

  const EditProfileForm({
    Key? key,
    required this.onSuccess,
    required this.initialData,
    this.scrollController,
  }) : super(key: key);

  @override
  ConsumerState<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = {
      for (final k in ['username','firstName','middleName','lastName','phoneNumber','address1','address2','country','language'])
        k: TextEditingController(text: widget.initialData[k] ?? ''),
    };
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) c.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(authProvider.notifier).updateProfile({
      for (final e in _ctrl.entries) e.key: e.value.text.trim(),
    });
    widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('Basic Information', Icons.person_outline_rounded),
            _row(
              _field('firstName', 'First Name', Icons.badge_outlined, required: true),
              _field('lastName', 'Last Name', Icons.badge_outlined, required: true),
            ),
            const SizedBox(height: 12),
            _field('username', 'Username', Icons.alternate_email_rounded),
            const SizedBox(height: 12),
            _field('middleName', 'Middle Name (optional)', Icons.person_outline_rounded),
            const SizedBox(height: 24),
            _section('Contact', Icons.contact_phone_outlined),
            _field('phoneNumber', 'Phone Number', Icons.phone_outlined, type: TextInputType.phone),
            const SizedBox(height: 24),
            _section('Address', Icons.home_outlined),
            _field('address1', 'Address Line 1', Icons.location_on_outlined),
            const SizedBox(height: 12),
            _field('address2', 'Address Line 2 (optional)', Icons.add_location_alt_outlined),
            const SizedBox(height: 12),
            _row(
              _field('country', 'Country', Icons.public_outlined),
              _field('language', 'Language', Icons.language_rounded),
            ),
            const SizedBox(height: 36),
            _Buttons(onCancel: () => Navigator.pop(context), onSave: _submit),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Icon(icon, size: 15, color: _gold),
        const SizedBox(width: 7),
        Text(title.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _gold, letterSpacing: 1.1)),
      ]),
    );
  }

  Widget _row(Widget left, Widget right) {
    return Row(children: [
      Expanded(child: left),
      const SizedBox(width: 12),
      Expanded(child: right),
    ]);
  }

  Widget _field(String key, String label, IconData icon, {bool required = false, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: _PremField(
        controller: _ctrl[key]!,
        label: label,
        icon: icon,
        keyboardType: type,
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      ),
    );
  }
}

// ── Clean field that owns its own decoration ──────────────────────────────

class _PremField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _PremField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  State<_PremField> createState() => _PremFieldState();
}

class _PremFieldState extends State<_PremField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        child: TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          style: const TextStyle(fontSize: 14, color: _brand, fontWeight: FontWeight.w500),
          cursorColor: _brand,
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              fontSize: 13,
              color: _focused ? _brand : _slate,
              fontWeight: _focused ? FontWeight.w500 : FontWeight.normal,
            ),
            floatingLabelStyle: const TextStyle(fontSize: 12, color: _gold, fontWeight: FontWeight.w600),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(widget.icon, size: 17, color: _focused ? _brand : _slate),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _brand, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            errorStyle: const TextStyle(fontSize: 11, color: Colors.red),
          ),
        ),
      ),
    );
  }
}

// ── Buttons ───────────────────────────────────────────────────────────────

class _Buttons extends StatelessWidget {
  final VoidCallback onCancel, onSave;
  const _Buttons({required this.onCancel, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: _slate,
            side: const BorderSide(color: _border),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w500)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: _brand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    ]);
  }
}