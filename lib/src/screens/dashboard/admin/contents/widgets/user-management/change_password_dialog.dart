import 'package:flutter/material.dart';

const _brand = Color(0xFF1A3C34);
const _gold  = Color(0xFFC9A84C);

class ChangePasswordDialog extends StatefulWidget {
  final String userId;
  final Function(String) onSave;
  const ChangePasswordDialog({super.key, required this.userId, required this.onSave});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pwCtrl  = TextEditingController();
  final _cfCtrl  = TextEditingController();
  bool _obscurePw = true;
  bool _obscureCf = true;

  @override
  void dispose() { _pwCtrl.dispose(); _cfCtrl.dispose(); super.dispose(); }

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
                const _DialogHeader(icon: Icons.lock_reset_rounded, title: 'Change Password',
                    subtitle: 'Set a new secure password'),
                const SizedBox(height: 20),

                const _FieldLabel('New Password', required: true),
                _PwField(
                  controller: _pwCtrl,
                  hint: 'Enter new password',
                  obscure: _obscurePw,
                  onToggle: () => setState(() => _obscurePw = !_obscurePw),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 14),

                _FieldLabel('Confirm Password', required: true),
                _PwField(
                  controller: _cfCtrl,
                  hint: 'Confirm new password',
                  obscure: _obscureCf,
                  onToggle: () => setState(() => _obscureCf = !_obscureCf),
                  validator: (v) => (v != _pwCtrl.text) ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 14),

                // Requirements hint
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _brand.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEAE6DE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Requirements',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                              color: _brand, letterSpacing: 0.2)),
                      const SizedBox(height: 6),
                      for (final req in const [
                        'At least 8 characters',
                        'Uppercase & lowercase letters',
                        'At least one number',
                        'Special character (e.g. @#\$%)',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                size: 13, color: Color(0xFF22C55E)),
                            const SizedBox(width: 6),
                            Text(req, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
                          ]),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brand,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Update',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Must be at least 8 characters';
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_])').hasMatch(v))
      return 'Must include uppercase, lowercase, number & special character';
    return null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context);
      widget.onSave(_pwCtrl.text);
    }
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _PwField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final FormFieldValidator<String>? validator;
  const _PwField({
    required this.controller, required this.hint,
    required this.obscure, required this.onToggle, this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscure,
    validator: validator,
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13),
      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
        onPressed: onToggle,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
      isDense: true,
      errorMaxLines: 2,
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(children: [
      Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: Color(0xFF374151))),
      if (required)
        const Text(' *', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626),
            fontWeight: FontWeight.bold)),
    ]),
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