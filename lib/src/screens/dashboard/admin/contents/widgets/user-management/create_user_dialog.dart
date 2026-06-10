import 'package:flutter/material.dart';
import '../../../../../../models/auth/user_model.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);

class CreateUserDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onCreate;
  const CreateUserDialog({super.key, required this.onCreate});

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _c = {
    'username': TextEditingController(),
    'email': TextEditingController(),
    'firstName': TextEditingController(),
    'lastName': TextEditingController(),
    'phoneNumber': TextEditingController(),
    'password': TextEditingController(),
    'address1': TextEditingController(),
    'address2': TextEditingController(),
    'country': TextEditingController(),
  };
  Role _role = Role.client;
  bool _obscurePw = true;

  @override
  void dispose() {
    for (final ctrl in _c.values) ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: _stone, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.person_add_rounded, color: _brand, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Text('Create New User',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _brand, letterSpacing: -0.4)),
                  ]),
                  const SizedBox(height: 24),

                  _SectionTitle('Personal Information'),
                  const SizedBox(height: 12),
                  _Row2([
                    _FormField('First Name', _c['firstName']!, Icons.person_outline_rounded, required: true),
                    _FormField('Last Name', _c['lastName']!, Icons.person_outline_rounded, required: true),
                  ]),
                  const SizedBox(height: 12),
                  _Row2([
                    _FormField('Username', _c['username']!, Icons.alternate_email_rounded, required: true),
                    _FormField('Email', _c['email']!, Icons.email_outlined, required: true, type: TextInputType.emailAddress, validationKey: 'email'),
                  ]),

                  const SizedBox(height: 24),
                  _SectionTitle('Contact'),
                  const SizedBox(height: 12),
                  _Row2([
                    _FormField('Phone', _c['phoneNumber']!, Icons.phone_outlined, type: TextInputType.phone),
                    _FormField('Country', _c['country']!, Icons.public_outlined),
                  ]),
                  const SizedBox(height: 12),
                  _FormField('Address Line 1', _c['address1']!, Icons.home_outlined),
                  const SizedBox(height: 12),
                  _FormField('Address Line 2', _c['address2']!, Icons.home_outlined),

                  const SizedBox(height: 24),
                  _SectionTitle('Security'),
                  const SizedBox(height: 12),
                  const _FieldLabel('Password', required: true),
                  _PasswordField(
                    controller: _c['password']!,
                    obscure: _obscurePw,
                    onToggle: () => setState(() => _obscurePw = !_obscurePw),
                  ),
                  const SizedBox(height: 12),
                  _buildRequirements(_c['password']!.text),

                  const SizedBox(height: 24),
                  _SectionTitle('Role'),
                  const SizedBox(height: 12),
                  _RoleChips(selected: _role, onChanged: (r) => setState(() => _role = r)),

                  const SizedBox(height: 32),
                  _ActionButtons(
                    onCancel: () => Navigator.pop(context),
                    onSave: _create,
                    saveLabel: 'Create User',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _create() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context);
      widget.onCreate({
        'username': _c['username']!.text.trim(),
        'email': _c['email']!.text.trim(),
        'firstName': _c['firstName']!.text.trim(),
        'lastName': _c['lastName']!.text.trim(),
        'phoneNumber': _c['phoneNumber']!.text.trim(),
        'address1': _c['address1']!.text.trim(),
        'address2': _c['address2']!.text.trim(),
        'country': _c['country']!.text.trim(),
        'password': _c['password']!.text,
        'role': _role == Role.homeOwner ? 'HOME_OWNER' : _role.name.toUpperCase(),
      });
    }
  }

  Widget _buildRequirements(String pw) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _stone, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Password Requirements', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _brand)),
          const SizedBox(height: 10),
          _req('At least 8 characters', pw.length >= 8),
          _req('Uppercase & lowercase letters', RegExp(r'(?=.*[a-z])(?=.*[A-Z])').hasMatch(pw)),
          _req('At least one number', RegExp(r'\d').hasMatch(pw)),
          _req('Special character', RegExp(r'[\W_]').hasMatch(pw)),
        ],
      ),
    );
  }

  Widget _req(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        Icon(met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 15, color: met ? const Color(0xFF22C55E) : const Color(0xFFD1D5DB)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 12.5, color: met ? const Color(0xFF16A34A) : _slate)),
      ]),
    );
  }
}

// ── Reusable Components ─────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({required this.controller, required this.obscure, required this.onToggle});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscure,
    style: const TextStyle(fontSize: 14, color: _brand),
    validator: (v) {
      if (v == null || v.isEmpty) return 'Required';
      if (v.length < 8) return 'At least 8 characters';
      if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_])').hasMatch(v))
        return 'Uppercase, number & symbol required';
      return null;
    },
    decoration: InputDecoration(
      labelText: 'Secure Password',
      labelStyle: const TextStyle(fontSize: 13, color: _slate),
      filled: true,
      fillColor: _stone,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _brand, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: _slate), onPressed: onToggle),
    ),
  );
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool required;
  final TextInputType type;
  final String? validationKey;

  const _FormField(this.label, this.controller, this.icon, {this.required = false, this.type = TextInputType.text, this.validationKey});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FieldLabel(label, required: required),
      TextFormField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(fontSize: 14, color: _brand),
        validator: required
            ? (v) {
          if (v == null || v.trim().isEmpty) return 'Required';
          if (validationKey == 'email' && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v))
            return 'Valid email required';
          return null;
        }
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: _slate),
          filled: true,
          fillColor: _stone,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _brand, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ],
  );
}

class _Row2 extends StatelessWidget {
  final List<Widget> children;
  const _Row2(this.children);
  @override
  Widget build(BuildContext context) => Row(
    children: children.asMap().entries.expand((e) => [Expanded(child: e.value), if (e.key < children.length - 1) const SizedBox(width: 12)]).toList(),
  );
}

class _RoleChips extends StatelessWidget {
  final Role selected;
  final ValueChanged<Role> onChanged;
  const _RoleChips({required this.selected, required this.onChanged});

  String _label(Role r) => r == Role.homeOwner ? 'Home Owner' : r.name[0].toUpperCase() + r.name.substring(1);

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: Role.values.map((r) {
      final active = r == selected;
      return GestureDetector(
        onTap: () => onChanged(r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: active ? _brand : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? _brand : const Color(0xFFEAE6DE)),
          ),
          child: Text(_label(r), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : _brand)),
        ),
      );
    }).toList(),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {this.required = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      if (required) const Text(' *', style: TextStyle(fontSize: 12.5, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _brand, letterSpacing: 0.4)),
      const SizedBox(height: 6),
      const Divider(height: 1, color: Color(0xFFF3EFE6)),
    ],
  );
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String saveLabel;
  const _ActionButtons({required this.onCancel, required this.onSave, required this.saveLabel});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(
      child: OutlinedButton(
        onPressed: onCancel,
        style: OutlinedButton.styleFrom(foregroundColor: _slate, side: const BorderSide(color: Color(0xFFEAE6DE)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: ElevatedButton(
        onPressed: onSave,
        style: ElevatedButton.styleFrom(backgroundColor: _brand, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
        child: Text(saveLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    ),
  ]);
}