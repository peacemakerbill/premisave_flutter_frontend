import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? resetToken;
  const ResetPasswordScreen({super.key, this.resetToken});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _newPwCtrl;
  late final TextEditingController _confirmPwCtrl;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  bool _hideNew = true;
  bool _hideConfirm = true;
  int _strength = 0; // 0-4

  static const _teal = Color(0xFF0D9488);
  static const _tealLight = Color(0xFFCCFBF1);
  static const _tealDark = Color(0xFF0F766E);

  @override
  void initState() {
    super.initState();
    _newPwCtrl = TextEditingController()..addListener(_calcStrength);
    _confirmPwCtrl = TextEditingController();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _calcStrength() {
    final p = _newPwCtrl.text;
    int s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) s++;
    setState(() => _strength = s);
  }

  Future<void> _submit(AuthNotifier notifier) async {
    if (_newPwCtrl.text.isEmpty || _confirmPwCtrl.text.isEmpty) {
      _snack('Please fill in all fields'); return;
    }
    if (_newPwCtrl.text != _confirmPwCtrl.text) {
      _snack('Passwords do not match'); return;
    }
    if (_newPwCtrl.text.length < 8) {
      _snack('Password must be at least 8 characters'); return;
    }
    if (widget.resetToken == null) {
      _snack('Invalid or expired reset link'); return;
    }
    await notifier.confirmResetPassword(widget.resetToken!, _newPwCtrl.text, _confirmPwCtrl.text);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) context.go('/login');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red[600],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Container(
            constraints: BoxConstraints(maxWidth: isWide ? 900 : 420),
            margin: const EdgeInsets.all(20),
            child: isWide ? _wideCard(authState, notifier) : _mobileCard(authState, notifier),
          ),
        ),
      ),
    );
  }

  Widget _wideCard(AuthState s, AuthNotifier n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.teal.shade100)),
      clipBehavior: Clip.antiAlias,
      child: Row(children: [
        _leftPanel(),
        Expanded(child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(48), child: _formContent(s, n)))),
      ]),
    );
  }

  Widget _mobileCard(AuthState s, AuthNotifier n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.teal.shade100)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(children: [_mobileHeader(), const SizedBox(height: 28), _formContent(s, n)]),
      ),
    );
  }

  Widget _leftPanel() {
    return Container(
      width: 340,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0891B2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 28),
          const Text("Set New\nPassword", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
          const SizedBox(height: 16),
          Text("Choose a strong password to keep your account secure.",
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15, height: 1.5)),
          const SizedBox(height: 32),
          ...[
            "At least 8 characters long",
            "Mix uppercase & lowercase",
            "Include numbers & symbols",
          ].map((t) => _featureRow(t)),
        ],
      ),
    );
  }

  Widget _featureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ]),
    );
  }

  Widget _mobileHeader() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _tealLight, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.lock_reset_rounded, color: _teal, size: 40),
      ),
      const SizedBox(height: 16),
      const Text("Set New Password", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF134E4A))),
      const SizedBox(height: 6),
      Text("Create a strong password for your account", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
    ]);
  }

  Widget _formContent(AuthState s, AuthNotifier n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.resetToken != null) _tokenBadge() else _invalidTokenBanner(),
        const SizedBox(height: 20),
        TextField(
          controller: _newPwCtrl,
          obscureText: _hideNew,
          enabled: !s.isLoading && widget.resetToken != null,
          decoration: _inputDeco(label: 'New Password', icon: Icons.lock_outline_rounded).copyWith(
            suffixIcon: IconButton(icon: Icon(_hideNew ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey[500]),
                onPressed: () => setState(() => _hideNew = !_hideNew)),
          ),
        ),
        if (_newPwCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 10),
          _strengthBar(),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPwCtrl,
          obscureText: _hideConfirm,
          enabled: !s.isLoading && widget.resetToken != null,
          decoration: _inputDeco(label: 'Confirm New Password', icon: Icons.lock_clock_outlined).copyWith(
            suffixIcon: IconButton(icon: Icon(_hideConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey[500]),
                onPressed: () => setState(() => _hideConfirm = !_hideConfirm)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: s.isLoading || widget.resetToken == null ? null : () => _submit(n),
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: s.isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text("Reset Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text("Back to Login"),
            style: TextButton.styleFrom(foregroundColor: _tealDark),
          ),
        ),
      ],
    );
  }

  Widget _tokenBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: _tealLight, borderRadius: BorderRadius.circular(12)),
      child: const Row(children: [
        Icon(Icons.verified_rounded, color: _teal, size: 18),
        SizedBox(width: 8),
        Expanded(child: Text("Reset link verified. Set your new password below.",
            style: TextStyle(color: _tealDark, fontSize: 13))),
      ]),
    );
  }

  Widget _invalidTokenBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.error_outline_rounded, color: Colors.red[600], size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Invalid or expired reset link", style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => context.go('/forgot-password'),
            child: Text("Request a new reset link", style: TextStyle(color: _teal, decoration: TextDecoration.underline)),
          ),
        ])),
      ]),
    );
  }

  Widget _strengthBar() {
    final labels = ['Weak', 'Fair', 'Good', 'Strong'];
    final colors = [Colors.red, Colors.orange, Colors.amber, Colors.green];
    final idx = (_strength - 1).clamp(0, 3);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: List.generate(4, (i) => Expanded(
        child: Container(
          height: 4,
          margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
          decoration: BoxDecoration(
            color: i < _strength ? colors[idx] : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ))),
      const SizedBox(height: 6),
      if (_strength > 0)
        Text("${labels[idx]} password", style: TextStyle(color: colors[idx], fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }

  InputDecoration _inputDeco({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[500]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _teal, width: 2)),
      filled: true, fillColor: Colors.white,
    );
  }
}