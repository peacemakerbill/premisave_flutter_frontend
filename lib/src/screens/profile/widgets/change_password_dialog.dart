import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth/auth_provider.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() => _State();
}

class _State extends ConsumerState<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _obscure = [true, true, true];

  @override
  void dispose() { _oldCtrl.dispose(); _newCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  String? _validate(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (v.length < 8) return 'At least 8 characters';
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_])').hasMatch(v))
      return 'Add uppercase, number & symbol';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).changePassword(_oldCtrl.text, _newCtrl.text, _confirmCtrl.text);
    final s = ref.read(authProvider);
    if (!s.isLoading && s.error == null && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).isLoading;
    final error = ref.watch(authProvider).error;
    final pw = _newCtrl.text;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _stone, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.lock_outline_rounded, color: _brand, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Change Password',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _brand, letterSpacing: -0.4)),
                ]),
                const SizedBox(height: 20),
                _pwField(_oldCtrl, 'Current password', 0, (v) => (v == null || v.isEmpty) ? 'Required' : null),
                const SizedBox(height: 12),
                _pwField(_newCtrl, 'New password', 1, _validate),
                const SizedBox(height: 12),
                _pwField(_confirmCtrl, 'Confirm password', 2, (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v != _newCtrl.text) return 'Passwords do not match';
                  return null;
                }),
                const SizedBox(height: 14),
                // requirements
                StatefulBuilder(builder: (_, set) {
                  _newCtrl.addListener(() => set(() {}));
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _stone, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Requirements', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _brand)),
                        const SizedBox(height: 8),
                        _req('8+ characters', pw.length >= 8),
                        _req('Uppercase letter', RegExp(r'[A-Z]').hasMatch(pw)),
                        _req('Lowercase letter', RegExp(r'[a-z]').hasMatch(pw)),
                        _req('Number', RegExp(r'\d').hasMatch(pw)),
                        _req('Special character', RegExp(r'[\W_]').hasMatch(pw)),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
                if (error != null) ...[
                  Text(error, style: const TextStyle(fontSize: 12, color: Colors.red)),
                  const SizedBox(height: 10),
                ],
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _slate,
                        side: const BorderSide(color: Color(0xFFEAE6DE)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Update', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _pwField(TextEditingController ctrl, String label, int idx, String? Function(String?) validator) {
    return TextFormField(
      controller: ctrl,
      obscureText: _obscure[idx],
      validator: validator,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 14, color: _brand),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _slate),
        filled: true,
        fillColor: _stone,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _brand, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        suffixIcon: IconButton(
          icon: Icon(_obscure[idx] ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: _slate),
          onPressed: () => setState(() => _obscure[idx] = !_obscure[idx]),
        ),
      ),
    );
  }

  Widget _req(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 13, color: met ? const Color(0xFF22C55E) : const Color(0xFFD1D5DB)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 11, color: met ? const Color(0xFF16A34A) : _slate)),
      ]),
    );
  }
}