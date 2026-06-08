import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  late final Map<String, TextEditingController> controllers;
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
    _formKey = GlobalKey<FormState>();
    controllers = {
      'username': TextEditingController(),
      'firstName': TextEditingController(),
      'middleName': TextEditingController(),
      'lastName': TextEditingController(),
      'email': TextEditingController(),
      'phone': TextEditingController(),
      'address1': TextEditingController(),
      'address2': TextEditingController(),
      'country': TextEditingController(),
      'language': TextEditingController(text: 'English'),
      'password': TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _togglePasswordVisibility() =>
      setState(() => _obscurePassword = !_obscurePassword);

  void _submitForm(AuthNotifier authNotifier) {
    if (_formKey.currentState!.validate()) {
      authNotifier.signUp({
        'username': controllers['username']!.text.trim(),
        'firstName': controllers['firstName']!.text.trim(),
        'middleName': controllers['middleName']!.text.trim(),
        'lastName': controllers['lastName']!.text.trim(),
        'email': controllers['email']!.text.trim(),
        'phoneNumber': controllers['phone']!.text.trim(),
        'address1': controllers['address1']!.text.trim(),
        'address2': controllers['address2']!.text.trim(),
        'country': controllers['country']!.text.trim(),
        'language': controllers['language']!.text.trim(),
        'password': controllers['password']!.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.shouldRedirectToLogin && !next.isLoading) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) context.go('/login');
        });
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
        Expanded(flex: 4, child: _buildBrandPanel()),
        Expanded(flex: 5, child: _buildFormPanel(authState, authNotifier)),
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
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
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
              const Text('Premisave',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 56),
          const Text('Start Your\nJourney',
              style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -1)),
          const SizedBox(height: 20),
          Text(
            'Join thousands of investors\nbuilding wealth through real estate.',
            style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.75),
                height: 1.6),
          ),
          const SizedBox(height: 48),
          _buildFeatureTile(Icons.verified_user_outlined, 'Verified Platform',
              'KYC-verified investors and listings'),
          const SizedBox(height: 20),
          _buildFeatureTile(Icons.account_balance_outlined, 'Smart Savings',
              'Automated savings plans for property'),
          const SizedBox(height: 20),
          _buildFeatureTile(Icons.bar_chart_rounded, 'Growth Analytics',
              'Track your portfolio performance'),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: _goldLight, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your data is encrypted and secure. We never share your information.',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
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
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
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
                      child: const Icon(Icons.real_estate_agent,
                          size: 24, color: _goldLight),
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
                const Text('Create Account',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1)),
                const SizedBox(height: 8),
                Text('Join Premisave and start investing',
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
          const Text('Create Account',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _green,
                  letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text('Fill in your details to get started',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 28),

          _buildSectionLabel('Personal Information'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildField(
                      controller: controllers['firstName']!,
                      label: 'First Name',
                      icon: Icons.person_outline,
                      enabled: !authState.isLoading,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Required'
                          : null)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildField(
                      controller: controllers['lastName']!,
                      label: 'Last Name',
                      icon: Icons.person_outline,
                      enabled: !authState.isLoading,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Required'
                          : null)),
            ],
          ),
          const SizedBox(height: 12),
          _buildField(
              controller: controllers['middleName']!,
              label: 'Middle Name (Optional)',
              icon: Icons.person_outline,
              enabled: !authState.isLoading),
          const SizedBox(height: 12),
          _buildField(
              controller: controllers['username']!,
              label: 'Username',
              icon: Icons.alternate_email,
              enabled: !authState.isLoading,
              validator: (v) =>
              v == null || v.isEmpty ? 'Username is required' : null),

          const SizedBox(height: 24),
          _buildSectionLabel('Contact Details'),
          const SizedBox(height: 12),
          _buildField(
              controller: controllers['email']!,
              label: 'Email Address',
              icon: Icons.email_outlined,
              enabled: !authState.isLoading,
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
              v == null || !v.contains('@') ? 'Enter a valid email' : null),
          const SizedBox(height: 12),
          _buildField(
              controller: controllers['phone']!,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              enabled: !authState.isLoading,
              keyboardType: TextInputType.phone,
              validator: (v) =>
              v == null || v.isEmpty ? 'Phone number is required' : null),

          const SizedBox(height: 24),
          _buildSectionLabel('Location (Optional)'),
          const SizedBox(height: 12),
          _buildField(
              controller: controllers['address1']!,
              label: 'Address Line 1',
              icon: Icons.home_outlined,
              enabled: !authState.isLoading),
          const SizedBox(height: 12),
          _buildField(
              controller: controllers['address2']!,
              label: 'Address Line 2',
              icon: Icons.home_outlined,
              enabled: !authState.isLoading),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildField(
                      controller: controllers['country']!,
                      label: 'Country',
                      icon: Icons.location_on_outlined,
                      enabled: !authState.isLoading)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildField(
                      controller: controllers['language']!,
                      label: 'Language',
                      icon: Icons.language_outlined,
                      enabled: !authState.isLoading)),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionLabel('Account Security'),
          const SizedBox(height: 12),
          _buildField(
            controller: controllers['password']!,
            label: 'Password',
            icon: Icons.lock_outline,
            enabled: !authState.isLoading,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey[500],
                size: 20,
              ),
              onPressed: _togglePasswordVisibility,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 8) return 'At least 8 characters required';
              if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_])')
                  .hasMatch(v)) {
                return 'Must include upper, lower, number & special char';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Password Requirements',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _green,
                        fontSize: 13)),
                const SizedBox(height: 8),
                _buildReqItem('At least 8 characters'),
                _buildReqItem('Uppercase and lowercase letters'),
                _buildReqItem('At least one number (0–9)'),
                _buildReqItem('At least one special character'),
              ],
            ),
          ),

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
              authState.isLoading ? null : () => _submitForm(authNotifier),
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
                  : const Text('Create Account',
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
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

          const SizedBox(height: 24),
          _buildDivider(),
          const SizedBox(height: 20),
          _buildSocialButtons(authState, authNotifier),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account?',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              TextButton(
                onPressed: () => context.go('/login'),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6)),
                child: const Text('Sign In',
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

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
                color: _gold, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _green,
                letterSpacing: 0.3)),
      ],
    );
  }

  Widget _buildReqItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: _greenLight, size: 15),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(color: Colors.grey[700], fontSize: 12)),
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
          child: Text('or sign up with',
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
            child: _buildSocialBtn('Google', Icons.g_mobiledata,
                const Color(0xFFDB4437), () => authNotifier.googleSignIn(context))),
        const SizedBox(width: 10),
        Expanded(
            child: _buildSocialBtn('Facebook', Icons.facebook,
                const Color(0xFF1877F2), () => authNotifier.facebookSignIn(context))),
        const SizedBox(width: 10),
        Expanded(
            child: _buildSocialBtn('Apple', Icons.apple, Colors.black,
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
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}