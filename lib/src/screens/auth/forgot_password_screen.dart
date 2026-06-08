import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _emailController;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  bool _emailSent = false;

  static const _teal = Color(0xFF0D9488);
  static const _tealLight = Color(0xFFCCFBF1);
  static const _tealDark = Color(0xFF0F766E);

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthNotifier notifier) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) { _snack('Please enter your email address'); return; }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) { _snack('Enter a valid email address'); return; }

    await notifier.forgotPassword(email);
    setState(() => _emailSent = true);

    await Future.delayed(const Duration(seconds: 3));
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
            child: isWide
                ? _wideCard(authState, notifier)
                : _mobileCard(authState, notifier),
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
      child: Row(
        children: [
          _leftPanel(),
          Expanded(child: Padding(padding: const EdgeInsets.all(48), child: _emailSent ? _successContent() : _formContent(s, n))),
        ],
      ),
    );
  }

  Widget _mobileCard(AuthState s, AuthNotifier n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.teal.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(children: [
          _mobileHeader(),
          const SizedBox(height: 28),
          _emailSent ? _successContent() : _formContent(s, n),
        ]),
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
          const Text("Forgot\nPassword?", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
          const SizedBox(height: 16),
          Text("No worries — we'll send a secure reset link to your inbox.",
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15, height: 1.5)),
          const SizedBox(height: 32),
          ...[
            ("shield_outlined", "Secure 256-bit reset link"),
            ("schedule_outlined", "Expires in 24 hours"),
            ("mark_email_read_outlined", "Check spam if needed"),
          ].map((item) => _featureRow(item.$2)),
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
      const Text("Forgot Password?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF134E4A))),
      const SizedBox(height: 6),
      Text("We'll email you a secure reset link", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
    ]);
  }

  Widget _formContent(AuthState s, AuthNotifier n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Reset your password", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF134E4A))),
        const SizedBox(height: 6),
        Text("Enter your registered email address below.", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 28),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !s.isLoading,
          decoration: _inputDeco(label: 'Email Address', hint: 'you@example.com', icon: Icons.email_outlined),
        ),
        const SizedBox(height: 16),
        _infoBox(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: s.isLoading ? null : () => _submit(n),
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: s.isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text("Send Reset Link", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _successContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88, height: 88,
          decoration: BoxDecoration(color: _tealLight, shape: BoxShape.circle,
              border: Border.all(color: _teal.withOpacity(0.3), width: 3)),
          child: const Icon(Icons.mark_email_read_rounded, color: _teal, size: 44),
        ),
        const SizedBox(height: 24),
        const Text("Check your inbox!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF134E4A))),
        const SizedBox(height: 10),
        Text("A password reset link has been sent.\nRedirecting to login in a moment...",
            style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        TextButton(onPressed: () => context.go('/login'), child: const Text("Go to Login now")),
      ],
    );
  }

  Widget _infoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _tealLight, borderRadius: BorderRadius.circular(12)),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_rounded, color: _teal, size: 18),
        SizedBox(width: 10),
        Expanded(child: Text("The reset link is valid for 24 hours. Check your spam folder if you don't receive it.",
            style: TextStyle(color: _tealDark, fontSize: 13, height: 1.4))),
      ]),
    );
  }

  InputDecoration _inputDeco({required String label, required String hint, required IconData icon}) {
    return InputDecoration(
      labelText: label, hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey[500]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _teal, width: 2)),
      filled: true, fillColor: Colors.white,
    );
  }
}