import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth/auth_provider.dart';
import '../../utils/toast_utils.dart';
import '../shared/contact_content.dart';

class VerifyScreen extends ConsumerStatefulWidget {
  final String? verificationToken;
  const VerifyScreen({super.key, this.verificationToken});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailCtrl = TextEditingController();
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  bool _isVerified = false;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;

  static const _teal = Color(0xFF0D9488);
  static const _tealLight = Color(0xFFCCFBF1);
  static const _tealDark = Color(0xFF0F766E);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.verificationToken != null) _verifyToken();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyToken() async {
    if (_isVerifying || widget.verificationToken == null) return;
    setState(() { _isVerifying = true; _error = null; });
    try {
      final success = await ref.read(authProvider.notifier).verifyEmailToken(widget.verificationToken!);
      if (success) {
        setState(() { _isVerified = true; _isVerifying = false; });
        ToastUtils.showSuccessToast('Account verified successfully!');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/login');
      } else {
        throw Exception('Verification failed');
      }
    } catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '');
      if (msg.contains('Invalid or expired')) msg = 'Invalid or expired verification link';
      else if (msg.contains('already verified')) msg = 'Account already verified';
      else if (msg.contains('Connection timeout')) msg = 'Connection timeout. Please check your internet.';
      else if (msg.contains('Cannot connect')) msg = 'Cannot connect to server. Please try again later.';
      setState(() { _error = msg; _isVerifying = false; });
      ToastUtils.showErrorToast(msg);
    }
  }

  Future<void> _resendActivation() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) { ToastUtils.showErrorToast('Please enter your email address'); return; }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) { ToastUtils.showErrorToast('Enter a valid email address'); return; }

    setState(() => _isResending = true);
    try {
      final success = await ref.read(authProvider.notifier).resendActivationEmail(email);
      if (success) _emailCtrl.clear();
    } catch (e) {
      ToastUtils.showErrorToast(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isResending = false);
    }
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9, maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Contact Support', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 20),
              const ContactContent(),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Container(
            constraints: BoxConstraints(maxWidth: isWide ? 900 : 420),
            margin: const EdgeInsets.all(20),
            child: isWide ? _wideCard() : _mobileCard(),
          ),
        ),
      ),
    );
  }

  Widget _wideCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.teal.shade100)),
      clipBehavior: Clip.antiAlias,
      child: Row(children: [
        _leftPanel(),
        Expanded(child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(48), child: _stateContent()))),
      ]),
    );
  }

  Widget _mobileCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.teal.shade100)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(children: [_mobileHeader(), const SizedBox(height: 28), _stateContent()]),
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
            child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 28),
          const Text("Email\nVerification", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
          const SizedBox(height: 16),
          Text("Verify your email to activate your account and access all features.",
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15, height: 1.5)),
          const SizedBox(height: 32),
          ...[
            "One-click email verification",
            "Instant account activation",
            "Secure token validation",
          ].map((t) => _featureRow(t)),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _showContactDialog,
            icon: const Icon(Icons.support_agent_outlined, color: Colors.white70),
            label: const Text("Contact Support", style: TextStyle(color: Colors.white70)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.4)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
          ),
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
        child: const Icon(Icons.mark_email_read_rounded, color: _teal, size: 40),
      ),
      const SizedBox(height: 16),
      const Text("Email Verification", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF134E4A))),
      const SizedBox(height: 6),
      Text("Confirm your email to activate your account", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
    ]);
  }

  Widget _stateContent() {
    if (_isVerifying) return _loadingState();
    if (_isVerified) return _successState();
    if (_error != null) return _errorState();
    return _pendingState();
  }

  Widget _loadingState() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 20),
      const CircularProgressIndicator(color: _teal, strokeWidth: 3),
      const SizedBox(height: 28),
      const Text("Verifying your email...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF134E4A))),
      const SizedBox(height: 10),
      Text("Please wait a moment.", style: TextStyle(color: Colors.grey[600])),
      const SizedBox(height: 20),
    ]);
  }

  Widget _successState() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _statusCircle(icon: Icons.check_circle_rounded, iconColor: _teal, bgColor: _tealLight),
      const SizedBox(height: 24),
      const Text("Email Verified!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF134E4A))),
      const SizedBox(height: 10),
      Text("Your account is now active. Redirecting to login...", style: TextStyle(color: Colors.grey[600], height: 1.5), textAlign: TextAlign.center),
      const SizedBox(height: 28),
      _primaryBtn(label: "Go to Login", onPressed: () => context.go('/login')),
    ]);
  }

  Widget _errorState() {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: _statusCircle(icon: Icons.error_rounded, iconColor: Colors.red.shade600, bgColor: Colors.red.shade50)),
      const SizedBox(height: 24),
      const Center(child: Text("Verification Failed", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF134E4A)))),
      const SizedBox(height: 10),
      Center(child: Text(_error ?? 'An error occurred during verification',
          style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center)),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity, height: 48,
        child: OutlinedButton.icon(
          onPressed: _verifyToken,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text("Try Again"),
          style: OutlinedButton.styleFrom(foregroundColor: _teal, side: const BorderSide(color: _teal), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ),
      const SizedBox(height: 28),
      const Divider(),
      const SizedBox(height: 20),
      Text("Need a new verification link?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
      const SizedBox(height: 6),
      Text("Enter your email to receive a new link", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      const SizedBox(height: 16),
      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: _inputDeco(label: 'Email Address', hint: 'you@example.com', icon: Icons.email_outlined),
      ),
      const SizedBox(height: 16),
      _primaryBtn(
        label: "Send New Verification Link",
        icon: Icons.send_rounded,
        loading: _isResending,
        onPressed: _isResending ? null : _resendActivation,
      ),
      const SizedBox(height: 12),
      _backToLoginBtn(),
    ]);
  }

  Widget _pendingState() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _statusCircle(icon: Icons.hourglass_top_rounded, iconColor: Colors.amber.shade700, bgColor: Colors.amber.shade50),
      const SizedBox(height: 24),
      const Text("Check Your Email", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF134E4A))),
      const SizedBox(height: 10),
      Text("A verification link was sent to your email. Click it to activate your account.",
          style: TextStyle(color: Colors.grey[600], height: 1.5), textAlign: TextAlign.center),
      const SizedBox(height: 28),
      const Divider(),
      const SizedBox(height: 20),
      Text("Didn't receive the email?", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[800])),
      const SizedBox(height: 12),
      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: _inputDeco(label: 'Your Email Address', hint: 'you@example.com', icon: Icons.email_outlined),
      ),
      const SizedBox(height: 16),
      _primaryBtn(label: "Resend Verification Link", icon: Icons.send_rounded, loading: _isResending, onPressed: _isResending ? null : _resendActivation),
      const SizedBox(height: 12),
      _backToLoginBtn(),
    ]);
  }

  Widget _statusCircle({required IconData icon, required Color iconColor, required Color bgColor}) {
    return Container(
      width: 88, height: 88,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle, border: Border.all(color: iconColor.withOpacity(0.3), width: 3)),
      child: Icon(icon, color: iconColor, size: 44),
    );
  }

  Widget _primaryBtn({required String label, IconData? icon, bool loading = false, VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _backToLoginBtn() {
    return Center(
      child: TextButton.icon(
        onPressed: () => context.go('/login'),
        icon: const Icon(Icons.arrow_back_rounded, size: 16),
        label: const Text("Back to Login"),
        style: TextButton.styleFrom(foregroundColor: _tealDark),
      ),
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