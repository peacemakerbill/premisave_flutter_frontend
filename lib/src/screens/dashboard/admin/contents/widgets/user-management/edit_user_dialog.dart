import 'package:flutter/material.dart';
import '../../../../../../models/auth/user_model.dart';

const _brand = Color(0xFF1A3C34);
const _gold  = Color(0xFFC9A84C);

class EditUserDialog extends StatefulWidget {
  final UserModel user;
  final Function(Map<String, dynamic>) onSave;
  const EditUserDialog({super.key, required this.user, required this.onSave});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _c;
  late Role _role;

  @override
  void initState() {
    super.initState();
    _role = widget.user.role;
    _c = {
      'username':    TextEditingController(text: widget.user.username),
      'email':       TextEditingController(text: widget.user.email),
      'firstName':   TextEditingController(text: widget.user.firstName),
      'lastName':    TextEditingController(text: widget.user.lastName),
      'phoneNumber': TextEditingController(text: widget.user.phoneNumber),
      'address1':    TextEditingController(text: widget.user.address1),
      'address2':    TextEditingController(text: widget.user.address2),
      'country':     TextEditingController(text: widget.user.country),
    };
  }

  @override
  void dispose() { _c.values.forEach((c) => c.dispose()); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                _DialogHeader(icon: Icons.edit_outlined, title: 'Edit User',
                    subtitle: '${widget.user.firstName} ${widget.user.lastName}'),
                const SizedBox(height: 20),

                _SectionTitle('Personal Information'),
                const SizedBox(height: 12),
                _Row2([
                  _FormField('Username',   _c['username']!,   Icons.person_outline_rounded, required: true),
                  _FormField('Email',      _c['email']!,      Icons.email_outlined, required: true, type: TextInputType.emailAddress, validationKey: 'email'),
                ]),
                const SizedBox(height: 10),
                _Row2([
                  _FormField('First Name', _c['firstName']!,  Icons.person_outline_rounded, required: true),
                  _FormField('Last Name',  _c['lastName']!,   Icons.person_outline_rounded, required: true),
                ]),
                const SizedBox(height: 16),

                _SectionTitle('Contact'),
                const SizedBox(height: 12),
                _Row2([
                  _FormField('Phone',   _c['phoneNumber']!, Icons.phone_outlined, type: TextInputType.phone),
                  _FormField('Country', _c['country']!,     Icons.location_on_outlined),
                ]),
                const SizedBox(height: 10),
                _FormField('Address Line 1', _c['address1']!, Icons.home_outlined),
                const SizedBox(height: 10),
                _FormField('Address Line 2', _c['address2']!, Icons.home_outlined),
                const SizedBox(height: 16),

                _SectionTitle('Role'),
                const SizedBox(height: 10),
                _RoleChips(selected: _role, onChanged: (r) => setState(() => _role = r)),
                const SizedBox(height: 20),

                _ActionButtons(
                  onCancel: () => Navigator.pop(context),
                  onSave: _save,
                  saveLabel: 'Save Changes',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context);
      widget.onSave({
        'username':    _c['username']!.text,
        'email':       _c['email']!.text,
        'firstName':   _c['firstName']!.text,
        'lastName':    _c['lastName']!.text,
        'phoneNumber': _c['phoneNumber']!.text,
        'address1':    _c['address1']!.text,
        'address2':    _c['address2']!.text,
        'country':     _c['country']!.text,
        'role':        _role.name.toUpperCase(),
      });
    }
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool required;
  final TextInputType type;
  final String? validationKey;
  const _FormField(this.label, this.controller, this.icon, {
    this.required = false, this.type = TextInputType.text, this.validationKey,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FieldLabel(label, required: required),
      TextFormField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(fontSize: 13),
        validator: required ? (v) {
          if (v == null || v.isEmpty) return '$label is required';
          if (validationKey == 'email' && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v))
            return 'Enter a valid email';
          return null;
        } : null,
        decoration: InputDecoration(
          hintText: 'Enter $label',
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFD1CBC0)),
          prefixIcon: Icon(icon, size: 17, color: const Color(0xFF9CA3AF)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _brand),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          isDense: true,
          errorMaxLines: 2,
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
    children: children
        .asMap()
        .entries
        .expand((e) => [Expanded(child: e.value), if (e.key < children.length - 1) const SizedBox(width: 10)])
        .toList(),
  );
}

class _RoleChips extends StatelessWidget {
  final Role selected;
  final ValueChanged<Role> onChanged;
  const _RoleChips({required this.selected, required this.onChanged});

  String _label(Role r) =>
      r == Role.homeOwner ? 'Home Owner' : r.name[0].toUpperCase() + r.name.substring(1);

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 7, runSpacing: 7,
    children: Role.values.map((r) {
      final active = r == selected;
      return GestureDetector(
        onTap: () => onChanged(r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? _brand : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? _brand : const Color(0xFFEAE6DE)),
          ),
          child: Text(_label(r),
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: active ? Colors.white : const Color(0xFF6B7280),
              )),
        ),
      );
    }).toList(),
  );
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onCancel, onSave;
  final String saveLabel;
  const _ActionButtons({required this.onCancel, required this.onSave, required this.saveLabel});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(
      child: OutlinedButton(
        onPressed: onCancel,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFEAE6DE)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Cancel',
            style: TextStyle(color: _brand, fontWeight: FontWeight.w600)),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: ElevatedButton(
        onPressed: onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: _brand,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(saveLabel,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    ),
  ]);
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(children: [
      Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      if (required)
        const Text(' *', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
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
      Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
          color: _brand, letterSpacing: 0.3)),
      const SizedBox(height: 6),
      const Divider(height: 1, color: Color(0xFFF3EFE6)),
    ],
  );
}

class _DialogHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const _DialogHeader({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: _brand.withOpacity(0.08), borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, size: 18, color: _brand),
    ),
    const SizedBox(width: 11),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.4)),
      if (subtitle != null)
        Text(subtitle!, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
    ]),
  ]);
}