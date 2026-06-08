import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _pwCtrl;
  late final GlobalKey<FormState> _formKey;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  bool _hidePassword = true;

  static const _green = Color(0xFF1B5E20);
  static const _greenMid = Color(0xFF2E7D32);
  static const _gold = Color(0xFFB8860B);
  static const _goldLight = Color(0xFFD4A017);
  static const _cream = Color(0xFFFAF7F0);
  static const _surface = Color(0xFFFFFFFF);
  static const _ink = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController();
    _pwCtrl = TextEditingController();
    _formKey = GlobalKey<FormState>();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _submit(AuthNotifier n) {
    if (_formKey.currentState!.validate()) {
      n.signIn(_emailCtrl.text.trim(), _pwCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);
    final isWide = MediaQuery.of(context).size.width > 900;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.token != null && next.role != null && !next.isLoading) {
        context.go(ref.read(authProvider.notifier).getDashboardRoute());
      }
    });

    return Scaffold(
      backgroundColor: _cream,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: isWide
            ? _wideLayout(authState, notifier)
            : _mobileLayout(authState, notifier),
      ),
    );
  }

  Widget _wideLayout(AuthState s, AuthNotifier n) {
    return Row(children: [
      Expanded(flex: 5, child: _brandPanel()),
      Expanded(flex: 4, child: _formPanel(s, n)),
    ]);
  }

  Widget _mobileLayout(AuthState s, AuthNotifier n) {
    return SingleChildScrollView(
      child: Column(children: [
        _mobileHero(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(key: _formKey, child: _formBody(s, n)),
        ),
      ]),
    );
  }

  Widget _brandPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_green, _greenMid], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _logo(),
          const SizedBox(height: 56),
          const Text('Welcome\nBack', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -1)),
          const SizedBox(height: 20),
          Text('Your smart real estate investment\nplatform. Sign in to continue.',
              style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.75), height: 1.6)),
          const SizedBox(height: 52),
          _featureTile(Icons.trending_up_rounded, 'Portfolio Tracking', 'Monitor all your property investments in real time'),
          const SizedBox(height: 20),
          _featureTile(Icons.shield_outlined, 'Secure Platform', 'Bank-grade encryption for all your data'),
          const SizedBox(height: 20),
          _featureTile(Icons.notifications_outlined, 'Smart Alerts', 'Never miss a critical property update'),
        ],
      ),
    );
  }

  Widget _logo() {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _gold.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _goldLight.withOpacity(0.5)),
        ),
        child: const Icon(Icons.real_estate_agent, size: 36, color: _goldLight),
      ),
      const SizedBox(width: 16),
      const Text('Premisave', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
    ]);
  }

  Widget _featureTile(IconData icon, String title, String subtitle) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: _goldLight, size: 20),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
      ]),
    ]);
  }

  Widget _mobileHero() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_green, _greenMid], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      padding: const EdgeInsets.fromLTRB(28, 64, 28, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _gold.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.real_estate_agent, size: 24, color: _goldLight)),
          const SizedBox(width: 10),
          const Text('Premisave', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 28),
        const Text('Welcome Back', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -0.5)),
        const SizedBox(height: 10),
        Text('Sign in to your investment platform', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 15)),
      ]),
    );
  }

  Widget _formPanel(AuthState s, AuthNotifier n) {
    return Container(
      color: _surface,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(key: _formKey, child: _formBody(s, n)),
          ),
        ),
      ),
    );
  }

  Widget _formBody(AuthState s, AuthNotifier n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sign in', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 6),
        Text('Enter your credentials to access your account', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        const SizedBox(height: 32),

        _field(ctrl: _emailCtrl, label: 'Email Address', icon: Icons.email_outlined,
            enabled: !s.isLoading, keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null),
        const SizedBox(height: 16),

        _field(
          ctrl: _pwCtrl,
          label: 'Password',
          icon: Icons.lock_outline,
          enabled: !s.isLoading,
          obscureText: _hidePassword,
          suffix: IconButton(
            icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey[400], size: 20),
            onPressed: () => setState(() => _hidePassword = !_hidePassword),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
          onFieldSubmitted: (_) => _submit(n),
        ),
        const SizedBox(height: 8),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go('/forgot-password'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
            child: const Text('Forgot Password?', style: TextStyle(color: _gold, fontSize: 13)),
          ),
        ),

        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () => context.go('/resend-activation'),
            icon: const Icon(Icons.email_outlined, size: 18),
            label: const Text('Resend Activation Email'),
            style: TextButton.styleFrom(
              foregroundColor: _green,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ),

        const SizedBox(height: 20),

        _primaryBtn(label: 'Sign In', loading: s.isLoading, onPressed: () => _submit(n)),

        if (s.error != null) ...[
          const SizedBox(height: 14),
          _errorBanner(s.error!),
        ],

        const SizedBox(height: 28),
        _divider('or continue with'),
        const SizedBox(height: 20),
        _socialRow(s, n),
        const SizedBox(height: 28),
        _switchRow(
          question: "Don't have an account?",
          action: 'Sign Up',
          onTap: () => context.go('/signup'),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool enabled = true,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
    String? Function(String?)? validator,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: ctrl,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: _ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red[300]!)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red[400]!, width: 1.5)),
      ),
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
    );
  }

  Widget _primaryBtn({required String label, required bool loading, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          disabledBackgroundColor: _green.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red[200]!)),
      child: Row(children: [
        Icon(Icons.error_outline, color: Colors.red[700], size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: TextStyle(color: Colors.red[700], fontSize: 13))),
      ]),
    );
  }

  Widget _divider(String label) {
    return Row(children: [
      Expanded(child: Divider(color: Colors.grey[200])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12))),
      Expanded(child: Divider(color: Colors.grey[200])),
    ]);
  }

  Widget _socialRow(AuthState s, AuthNotifier n) {
    return Row(children: [
      Expanded(child: _socialBtn('Google', Icons.g_mobiledata, const Color(0xFFDB4437), () => n.googleSignIn(context))),
      const SizedBox(width: 10),
      Expanded(child: _socialBtn('Facebook', Icons.facebook, const Color(0xFF1877F2), () => n.facebookSignIn(context))),
      const SizedBox(width: 10),
      Expanded(child: _socialBtn('Apple', Icons.apple, Colors.black, () => n.appleSignIn(context))),
    ]);
  }

  Widget _socialBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _switchRow({required String question, required String action, required VoidCallback onTap}) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(question, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
        child: Text(action, style: const TextStyle(color: _green, fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    ]);
  }
}