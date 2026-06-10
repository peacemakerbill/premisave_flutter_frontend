import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);

class ChangePasswordDialog extends ConsumerStatefulWidget {
  final String userId;
  final Function(String) onSave;

  const ChangePasswordDialog({
    super.key,
    required this.userId,
    required this.onSave,
  });

  @override
  ConsumerState<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pwCtrl = TextEditingController();
  final _cfCtrl = TextEditingController();
  bool _obscurePw = true;
  bool _obscureCf = true;

  @override
  void dispose() {
    _pwCtrl.dispose();
    _cfCtrl.dispose();
    super.dispose();
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (v.length < 8) return 'At least 8 characters';
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_])').hasMatch(v))
      return 'Uppercase, lowercase, number & symbol';
    return null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context);
      widget.onSave(_pwCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _stone,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: _brand, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _brand,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildField('New Password', _pwCtrl, 0, _validatePassword),
                const SizedBox(height: 16),
                _buildField('Confirm Password', _cfCtrl, 1, (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v != _pwCtrl.text) return 'Passwords do not match';
                  return null;
                }),

                const SizedBox(height: 20),
                _buildRequirements(_pwCtrl.text),

                const SizedBox(height: 28),
                _ActionButtons(
                  onCancel: () => Navigator.pop(context),
                  onSave: _submit,
                  saveLabel: 'Update Password',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, int idx, String? Function(String?) validator) {
    return TextFormField(
      controller: ctrl,
      obscureText: idx == 0 ? _obscurePw : _obscureCf,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: _brand),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _slate),
        filled: true,
        fillColor: _stone,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _brand, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(
            idx == 0
                ? (_obscurePw ? Icons.visibility_outlined : Icons.visibility_off_outlined)
                : (_obscureCf ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            size: 18,
            color: _slate,
          ),
          onPressed: () => setState(() {
            if (idx == 0) _obscurePw = !_obscurePw;
            else _obscureCf = !_obscureCf;
          }),
        ),
      ),
    );
  }

  Widget _buildRequirements(String pw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _stone,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Requirements', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _brand)),
          const SizedBox(height: 10),
          _req('At least 8 characters', pw.length >= 8),
          _req('Uppercase & lowercase', RegExp(r'(?=.*[a-z])(?=.*[A-Z])').hasMatch(pw)),
          _req('At least one number', RegExp(r'\d').hasMatch(pw)),
          _req('Special character', RegExp(r'[\W_]').hasMatch(pw)),
        ],
      ),
    );
  }

  Widget _req(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 15, color: met ? const Color(0xFF22C55E) : const Color(0xFFD1D5DB)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 12.5, color: met ? const Color(0xFF16A34A) : _slate)),
      ]),
    );
  }
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
        style: OutlinedButton.styleFrom(
          foregroundColor: _slate,
          side: const BorderSide(color: Color(0xFFEAE6DE)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(saveLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    ),
  ]);
}