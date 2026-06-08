import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  late final Map<String, TextEditingController> ctrl;
  late final GlobalKey<FormState> _formKey;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  bool _hidePassword = true;
  int _pwStrength = 0;

  static const _green     = Color(0xFF1B5E20);
  static const _greenMid  = Color(0xFF2E7D32);
  static const _gold      = Color(0xFFB8860B);
  static const _goldLight = Color(0xFFD4A017);
  static const _cream     = Color(0xFFFAF7F0);
  static const _surface   = Color(0xFFFFFFFF);
  static const _ink       = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _formKey  = GlobalKey<FormState>();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    ctrl = {
      'username':   TextEditingController(),
      'firstName':  TextEditingController(),
      'middleName': TextEditingController(),
      'lastName':   TextEditingController(),
      'email':      TextEditingController(),
      'phone':      TextEditingController(),
      'address1':   TextEditingController(),
      'address2':   TextEditingController(),
      'country':    TextEditingController(),
      'language':   TextEditingController(text: 'English'),
      'password':   TextEditingController()..addListener(_calcStrength),
    };
  }

  @override
  void dispose() {
    for (final c in ctrl.values) c.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _calcStrength() {
    final p = ctrl['password']!.text;
    int s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) s++;
    setState(() => _pwStrength = s);
  }

  void _submit(AuthNotifier n) {
    if (_formKey.currentState!.validate()) {
      n.signUp({
        'username':    ctrl['username']!.text.trim(),
        'firstName':   ctrl['firstName']!.text.trim(),
        'middleName':  ctrl['middleName']!.text.trim(),
        'lastName':    ctrl['lastName']!.text.trim(),
        'email':       ctrl['email']!.text.trim(),
        'phoneNumber': ctrl['phone']!.text.trim(),
        'address1':    ctrl['address1']!.text.trim(),
        'address2':    ctrl['address2']!.text.trim(),
        'country':     ctrl['country']!.text.trim(),
        'language':    ctrl['language']!.text.trim(),
        'password':    ctrl['password']!.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final notifier  = ref.read(authProvider.notifier);
    final isWide    = MediaQuery.of(context).size.width > 900;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.shouldRedirectToLogin && !next.isLoading) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) context.go('/login');
        });
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

  // ── LAYOUTS ──────────────────────────────────────────────────────────────────

  Widget _wideLayout(AuthState s, AuthNotifier n) {
    return Row(children: [
      Expanded(flex: 4, child: _brandPanel()),
      Expanded(flex: 5, child: _formPanel(s, n)),
    ]);
  }

  Widget _mobileLayout(AuthState s, AuthNotifier n) {
    return SingleChildScrollView(child: Column(children: [
      _mobileHero(),
      Container(color: _surface, padding: const EdgeInsets.all(28),
          child: Form(key: _formKey, child: _formBody(s, n))),
    ]));
  }

  // ── BRAND PANEL ──────────────────────────────────────────────────────────────

  Widget _brandPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_green, _greenMid], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _logo(),
          const SizedBox(height: 56),
          const Text('Start Your\nJourney', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -1)),
          const SizedBox(height: 20),
          Text('Join thousands of investors\nbuilding wealth through real estate.',
              style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.75), height: 1.6)),
          const SizedBox(height: 48),
          _featureTile(Icons.verified_user_outlined,    'Verified Platform',  'KYC-verified investors and listings'),
          const SizedBox(height: 20),
          _featureTile(Icons.account_balance_outlined,  'Smart Savings',      'Automated savings plans for property'),
          const SizedBox(height: 20),
          _featureTile(Icons.bar_chart_rounded,         'Growth Analytics',   'Track your portfolio performance'),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.15))),
            child: Row(children: [
              const Icon(Icons.lock_outline, color: _goldLight, size: 20), const SizedBox(width: 10),
              Expanded(child: Text('Your data is encrypted and secure. We never share your information.',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, height: 1.5))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _logo() {
    return Row(children: [
      Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _gold.withOpacity(0.2), borderRadius: BorderRadius.circular(14), border: Border.all(color: _goldLight.withOpacity(0.5))),
          child: const Icon(Icons.real_estate_agent, size: 36, color: _goldLight)),
      const SizedBox(width: 16),
      const Text('Premisave', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
    ]);
  }

  Widget _featureTile(IconData icon, String title, String subtitle) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: _goldLight, size: 20)),
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
          const Text('Premisave', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
        const SizedBox(height: 28),
        const Text('Create Account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
        const SizedBox(height: 8),
        Text('Join Premisave and start investing', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 15)),
      ]),
    );
  }

  // ── FORM PANEL ───────────────────────────────────────────────────────────────

  Widget _formPanel(AuthState s, AuthNotifier n) {
    return Container(
      color: _surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(key: _formKey, child: _formBody(s, n)),
          ),
        ),
      ),
    );
  }

  Widget _formBody(AuthState s, AuthNotifier n) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Create Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _green, letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text('Fill in your details to get started', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      const SizedBox(height: 28),

      // Personal
      _sectionLabel('Personal Information'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _field(ctrl: ctrl['firstName']!, label: 'First Name', icon: Icons.person_outline, enabled: !s.isLoading,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
        const SizedBox(width: 12),
        Expanded(child: _field(ctrl: ctrl['lastName']!, label: 'Last Name', icon: Icons.person_outline, enabled: !s.isLoading,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
      ]),
      const SizedBox(height: 12),
      _field(ctrl: ctrl['middleName']!, label: 'Middle Name (Optional)', icon: Icons.person_outline, enabled: !s.isLoading),
      const SizedBox(height: 12),
      _field(ctrl: ctrl['username']!, label: 'Username', icon: Icons.alternate_email, enabled: !s.isLoading,
          validator: (v) => v == null || v.isEmpty ? 'Username is required' : null),

      const SizedBox(height: 24),
      // Contact
      _sectionLabel('Contact Details'),
      const SizedBox(height: 12),
      _field(ctrl: ctrl['email']!, label: 'Email Address', icon: Icons.email_outlined, enabled: !s.isLoading,
          keyboardType: TextInputType.emailAddress,
          validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null),
      const SizedBox(height: 12),
      _field(ctrl: ctrl['phone']!, label: 'Phone Number', icon: Icons.phone_outlined, enabled: !s.isLoading,
          keyboardType: TextInputType.phone,
          validator: (v) => v == null || v.isEmpty ? 'Phone number is required' : null),

      const SizedBox(height: 24),
      // Location
      _sectionLabel('Location (Optional)'),
      const SizedBox(height: 12),
      _field(ctrl: ctrl['address1']!, label: 'Address Line 1', icon: Icons.home_outlined, enabled: !s.isLoading),
      const SizedBox(height: 12),
      _field(ctrl: ctrl['address2']!, label: 'Address Line 2', icon: Icons.home_outlined, enabled: !s.isLoading),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _field(ctrl: ctrl['country']!,  label: 'Country',  icon: Icons.location_on_outlined, enabled: !s.isLoading)),
        const SizedBox(width: 12),
        Expanded(child: _field(ctrl: ctrl['language']!, label: 'Language', icon: Icons.language_outlined,    enabled: !s.isLoading)),
      ]),

      const SizedBox(height: 24),
      // Security
      _sectionLabel('Account Security'),
      const SizedBox(height: 12),
      _field(
        ctrl: ctrl['password']!, label: 'Password', icon: Icons.lock_outline, enabled: !s.isLoading,
        obscureText: _hidePassword,
        suffix: IconButton(
          icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey[500], size: 20),
          onPressed: () => setState(() => _hidePassword = !_hidePassword),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Password is required';
          if (v.length < 8) return 'At least 8 characters required';
          if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_])').hasMatch(v)) {
            return 'Must include upper, lower, number & special char';
          }
          return null;
        },
      ),
      if (ctrl['password']!.text.isNotEmpty) ...[
        const SizedBox(height: 10),
        _strengthBar(),
      ],
      const SizedBox(height: 12),
      _pwRequirementsBox(),

      const SizedBox(height: 28),
      _primaryBtn(label: 'Create Account', loading: s.isLoading, onPressed: () => _submit(n)),

      if (s.error != null) ...[
        const SizedBox(height: 14),
        _errorBanner(s.error!),
      ],

      const SizedBox(height: 24),
      _divider('or sign up with'),
      const SizedBox(height: 20),
      _socialRow(s, n),
      const SizedBox(height: 24),
      _switchRow(question: 'Already have an account?', action: 'Sign In', onTap: () => context.go('/login')),
    ]);
  }

  // ── SHARED WIDGETS ───────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) {
    return Row(children: [
      Container(width: 3, height: 16, decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _green, letterSpacing: 0.3)),
    ]);
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
        border:             OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 1.5)),
        errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red[300]!)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red[400]!, width: 1.5)),
      ),
      validator: validator,
    );
  }

  Widget _strengthBar() {
    final labels = ['Weak', 'Fair', 'Good', 'Strong'];
    final colors = [Colors.red, Colors.orange, Colors.amber, Colors.green];
    final idx    = (_pwStrength - 1).clamp(0, 3);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: List.generate(4, (i) => Expanded(child: Container(height: 4, margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
          decoration: BoxDecoration(color: i < _pwStrength ? colors[idx] : Colors.grey.shade200, borderRadius: BorderRadius.circular(4)))))),
      const SizedBox(height: 5),
      if (_pwStrength > 0) Text('${labels[idx]} password', style: TextStyle(color: colors[idx], fontSize: 11, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _pwRequirementsBox() {
    const reqs = ['At least 8 characters', 'Uppercase and lowercase letters', 'At least one number (0–9)', 'At least one special character'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF0F7F0), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFC8E6C9))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Password Requirements', style: TextStyle(fontWeight: FontWeight.w600, color: _green, fontSize: 13)),
        const SizedBox(height: 8),
        ...reqs.map((t) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
          const Icon(Icons.check_circle_outline, color: _greenMid, size: 15), const SizedBox(width: 6),
          Text(t, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
        ]))),
      ]),
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
      Expanded(child: _socialBtn('Google',   Icons.g_mobiledata, const Color(0xFFDB4437), () => n.googleSignIn(context))),
      const SizedBox(width: 10),
      Expanded(child: _socialBtn('Facebook', Icons.facebook,     const Color(0xFF1877F2), () => n.facebookSignIn(context))),
      const SizedBox(width: 10),
      Expanded(child: _socialBtn('Apple',    Icons.apple,        Colors.black,             () => n.appleSignIn(context))),
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