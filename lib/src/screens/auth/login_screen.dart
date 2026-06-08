import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final GlobalKey<FormState> _formKey;
  bool _obscurePassword = true;

  static const _green = Color(0xFF1B5E20);
  static const _greenLight = Color(0xFF2E7D32);
  static const _gold = Color(0xFFB8860B);
  static const _goldLight = Color(0xFFD4A017);
  static const _cream = Color(0xFFFAF7F0);
  static const _surface = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() =>
      setState(() => _obscurePassword = !_obscurePassword);

  void _submitForm(AuthNotifier authNotifier) {
    if (_formKey.currentState!.validate()) {
      authNotifier.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.token != null && next.role != null && !next.isLoading) {
        context.go(ref.read(authProvider.notifier).getDashboardRoute());
      }
    });

    return Scaffold(
      backgroundColor: _cream,
      body: isWideScreen
          ? _buildWideLayout(authState, authNotifier)
          : _buildMobileLayout(authState, authNotifier),
    );
  }

  // ── WIDE LAYOUT ──────────────────────────────────────────────────────────────

  Widget _buildWideLayout(AuthState authState, AuthNotifier authNotifier) {
    return Row(
      children: [
        Expanded(flex: 5, child: _buildBrandPanel()),
        Expanded(flex: 4, child: _buildFormPanel(authState, authNotifier)),
      ],
    );
  }

  Widget _buildBrandPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_green, _greenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
              const Text(
                'Premisave',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 56),
          const Text(
            'Welcome\nBack',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your smart real estate investment\nplatform. Sign in to continue.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.75),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 56),
          _buildFeatureTile(Icons.trending_up_rounded, 'Portfolio Tracking', 'Monitor all your property investments in real time'),
          const SizedBox(height: 20),
          _buildFeatureTile(Icons.shield_outlined, 'Secure Platform', 'Bank-grade encryption for all your data'),
          const SizedBox(height: 20),
          _buildFeatureTile(Icons.notifications_outlined, 'Smart Alerts', 'Never miss a critical property update'),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _goldLight, size: 20),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildFormPanel(AuthState authState, AuthNotifier authNotifier) {
    return Container(
      color: _surface,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _buildFormContent(authState, authNotifier),
          ),
        ),
      ),
    );
  }

  // ── MOBILE LAYOUT ────────────────────────────────────────────────────────────

  Widget _buildMobileLayout(AuthState authState, AuthNotifier authNotifier) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_green, _greenLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(28, 64, 28, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.real_estate_agent, size: 24, color: _goldLight),
                    ),
                    const SizedBox(width: 10),
                    const Text('Premisave',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 28),
                const Text('Welcome Back',
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1)),
                const SizedBox(height: 8),
                Text('Sign in to your account',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75), fontSize: 15)),
              ],
            ),
          ),
          Container(
            color: _surface,
            padding: const EdgeInsets.all(28),
            child: _buildFormContent(authState, authNotifier),
          ),
        ],
      ),
    );
  }

  // ── SHARED FORM CONTENT ──────────────────────────────────────────────────────

  Widget _buildFormContent(AuthState authState, AuthNotifier authNotifier) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sign In',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _green,
                  letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text('Enter your credentials to access your dashboard',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 32),
          _buildField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            enabled: !authState.isLoading,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
            v == null || !v.contains('@') ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            enabled: !authState.isLoading,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.grey[500],
                size: 20,
              ),
              onPressed: _togglePasswordVisibility,
            ),
            validator: (v) =>
            v == null || v.isEmpty ? 'Password is required' : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/forgot-password'),
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 36)),
              child: const Text('Forgot Password?',
                  style: TextStyle(color: _gold, fontSize: 13)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: authState.isLoading
                  ? null
                  : () => _submitForm(authNotifier),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                disabledBackgroundColor: _green.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: authState.isLoading
                  ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
                  : const Text('Sign In',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
          if (authState.error != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(authState.error!,
                          style: TextStyle(
                              color: Colors.red[700], fontSize: 13))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          _buildDivider(),
          const SizedBox(height: 20),
          _buildSocialButtons(authState, authNotifier),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don't have an account?",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              TextButton(
                onPressed: () => context.go('/signup'),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                child: const Text('Sign Up',
                    style: TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[200])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or continue with',
              style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ),
        Expanded(child: Divider(color: Colors.grey[200])),
      ],
    );
  }

  Widget _buildSocialButtons(AuthState authState, AuthNotifier authNotifier) {
    return Row(
      children: [
        Expanded(
            child: _buildSocialBtn(
                'Google', Icons.g_mobiledata, const Color(0xFFDB4437),
                    () => authNotifier.googleSignIn(context))),
        const SizedBox(width: 10),
        Expanded(
            child: _buildSocialBtn(
                'Facebook', Icons.facebook, const Color(0xFF1877F2),
                    () => authNotifier.facebookSignIn(context))),
        const SizedBox(width: 10),
        Expanded(
            child: _buildSocialBtn(
                'Apple', Icons.apple, Colors.black,
                    () => authNotifier.appleSignIn(context))),
      ],
    );
  }

  Widget _buildSocialBtn(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}