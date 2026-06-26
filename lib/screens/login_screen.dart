import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/avatars.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';

/// Login screen — ported from web `src/app/login/page.tsx`.
/// Two tabs: "Demo Profiles" and "My Account" (phone → OTP).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _DemoProfile {
  const _DemoProfile({
    required this.user,
    required this.label,
    required this.description,
    required this.subDesc,
    required this.badge,
    required this.color,
    required this.accent,
    required this.features,
    required this.avatarKey,
    required this.isElder,
  });
  final AppUser user;
  final String label;
  final String description;
  final String subDesc;
  final String badge;
  final Color color;
  final Color accent;
  final List<String> features;
  final String avatarKey;
  final bool isElder;
}

const _demoProfiles = [
  _DemoProfile(
    user: AppUser(
      name: 'Priya Kamat',
      phone: '9876543210',
      role: 'member',
      gotra: 'Kashyap',
      native: 'Bengaluru, Karnataka',
      avatar: '6',
    ),
    label: 'Member Login',
    description: 'Priya Kamat',
    subDesc: 'UX Designer · Bengaluru',
    badge: 'Community Member',
    color: AppColors.forest800,
    accent: AppColors.gold500,
    features: ['Family Tree', 'Matrimonial Hub', 'Welfare Campaigns', 'Member Directory'],
    avatarKey: '6',
    isElder: false,
  ),
  _DemoProfile(
    user: AppUser(
      name: 'Shri Narayanarao Shet',
      phone: '9999999999',
      role: 'elder',
      gotra: 'Bharadwaja',
      native: 'Kumta, Uttara Kannada',
      avatar: 'elder',
    ),
    label: 'Elder / Admin Login',
    description: 'Shri Narayanarao Shet',
    subDesc: 'Elder Committee · Kumta Branch',
    badge: 'Elder & Administrator',
    color: AppColors.gold700,
    accent: AppColors.gold500,
    features: ['Member Verification', 'Lineage Management', 'Community Oversight', 'Full Admin Access'],
    avatarKey: 'elder',
    isElder: true,
  ),
];

class _LoginScreenState extends State<LoginScreen> {
  String _mode = 'demo'; // 'demo' | 'phone'
  int? _demoLoading;

  String _phoneStep = 'phone'; // 'phone' | 'otp'
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  String _error = '';
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleDemoLogin(int idx) async {
    setState(() => _demoLoading = idx);
    final profile = _demoProfiles[idx];
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    await context.read<AuthService>().loginWithUser(profile.user);
    if (!mounted) return;
    context.go(profile.isElder ? '/elder' : '/dashboard');
  }

  void _handlePhoneNext() {
    if (_phoneCtrl.text.length < 10) {
      setState(() => _error = 'Enter a valid 10-digit phone number');
      return;
    }
    setState(() {
      _error = '';
      _phoneStep = 'otp';
    });
  }

  Future<void> _handleOtpVerify() async {
    if (_otpCtrl.text != '121212') {
      setState(() => _error = 'Invalid OTP. Use 121212 for this demo.');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final user =
          await context.read<AuthService>().login(_phoneCtrl.text, _otpCtrl.text);
      if (!mounted) return;
      context.go(user.isElder ? '/elder' : '/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _humanError(e);
        _loading = false;
      });
    }
  }

  /// Extracts a human-readable message from an exception.
  /// Handles `ApiException($code): message` and `Exception: message` forms.
  String _humanError(Object e) {
    var s = e.toString();
    final colon = s.indexOf('): ');
    if (colon != -1) {
      s = s.substring(colon + 3);
    } else if (s.startsWith('Exception: ')) {
      s = s.substring('Exception: '.length);
    }
    return s.isEmpty ? 'Login failed.' : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forest900,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderCard(onLogoTap: () => context.go('/')),
              const SizedBox(height: 16),
              _FormCard(child: _buildForm()),
              const SizedBox(height: 18),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text('New member?  ',
                        style: body(13, color: AppColors.forest300)),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text('Create an account',
                          style: body(13,
                              weight: FontWeight.w700,
                              color: AppColors.gold500)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Access the Portal',
            style: display(26, color: AppColors.forest900)),
        const SizedBox(height: 6),
        Text(
          'Use demo profiles for a quick tour, or login with your registered '
          'number.',
          style: body(13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 18),
        // Tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE8DF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _tab('demo', 'Demo Profiles', Icons.person_outline_rounded),
              _tab('phone', 'My Account', Icons.phone_rounded),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_mode == 'demo') _buildDemo() else _buildPhone(),
      ],
    );
  }

  Widget _tab(String key, String label, IconData icon) {
    final active = _mode == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _mode = key;
          _error = '';
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: active ? AppColors.forest900 : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: body(13,
                      weight: FontWeight.w600,
                      color: active
                          ? AppColors.forest900
                          : AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemo() {
    return Column(
      children: [
        for (var i = 0; i < _demoProfiles.length; i++) ...[
          _DemoCard(
            profile: _demoProfiles[i],
            loading: _demoLoading == i,
            highlight: i == 0,
            onTap: _demoLoading == null ? () => _handleDemoLogin(i) : null,
          ),
          if (i != _demoProfiles.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildPhone() {
    if (_phoneStep == 'phone') {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registered Mobile Number',
                style: body(13,
                    weight: FontWeight.w700, color: AppColors.forest800)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) {
                if (_error.isNotEmpty) setState(() => _error = '');
              },
              decoration: _inputDecoration('9876543210'),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(_error, style: body(13, color: Colors.red)),
            ],
            const SizedBox(height: 14),
            ForestButton(
              label: 'Send OTP',
              icon: Icons.arrow_forward_rounded,
              expand: true,
              onPressed: _handlePhoneNext,
            ),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OTP sent to +91 ${_phoneCtrl.text}',
              style: body(13, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Demo OTP: 121212',
                style: body(12,
                    weight: FontWeight.w600, color: AppColors.forest700)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: display(24, color: AppColors.forest900),
            onChanged: (_) => setState(() {
              if (_error.isNotEmpty) _error = '';
            }),
            decoration: _inputDecoration('1 2 1 2 1 2'),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_error, style: body(13, color: Colors.red)),
          ],
          const SizedBox(height: 14),
          ForestButton(
            label: 'Login',
            icon: Icons.check_circle_outline_rounded,
            expand: true,
            loading: _loading,
            onPressed: _otpCtrl.text.length == 6 ? _handleOtpVerify : null,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _phoneStep = 'phone';
                _error = '';
                _otpCtrl.clear();
              }),
              child: Text('← Change number',
                  style: body(13, color: AppColors.textMuted)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.forest800, width: 1.5),
        ),
      );
}

// ─── Header card ─────────────────────────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.onLogoTap});
  final VoidCallback onLogoTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.forest950, AppColors.forest900, AppColors.forest800],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.forestGlow,
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onLogoTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppGradients.gold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.park_rounded,
                      size: 20, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daivajna Samaja',
                        style: display(16, color: Colors.white)),
                    Text('Heritage Portal · Bangalore',
                        style: body(11, color: AppColors.forest500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Your lineage.\nYour legacy. One portal.',
              style: display(24, color: Colors.white, height: 1.25)),
          const SizedBox(height: 10),
          Text(
            'Connect with 1,428 families, trace your ancestral roots, and '
            'contribute to community welfare.',
            style: body(13, color: AppColors.forest300, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── Form card ───────────────────────────────────────────────────────────────
class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

// ─── Demo profile card ───────────────────────────────────────────────────────
class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.profile,
    required this.loading,
    required this.highlight,
    required this.onTap,
  });
  final _DemoProfile profile;
  final bool loading;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: highlight
                    ? const Color(0xFFD8F3DC)
                    : const Color(0xFFF7EDDA),
                width: 2),
            boxShadow: AppShadows.soft,
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [profile.color, profile.accent],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 52,
                              height: 52,
                              child: loading
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: profile.color,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        ),
                                      ),
                                    )
                                  : PexelsImage(
                                      url: avatarUrl(profile.avatarKey),
                                      name: profile.description,
                                      size: 52,
                                      radius: BorderRadius.circular(12),
                                      borderColor: profile.accent,
                                      borderWidth: 2,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(profile.label,
                                      style: body(15,
                                          weight: FontWeight.w800,
                                          color: AppColors.forest900)),
                                  Text(profile.description,
                                      style: body(13,
                                          weight: FontWeight.w600,
                                          color: profile.color)),
                                  Text(profile.subDesc,
                                      style:
                                          body(11, color: AppColors.hint)),
                                  const SizedBox(height: 4),
                                  Pill(profile.badge,
                                      bg: highlight
                                          ? const Color(0xFFD1FAE5)
                                          : const Color(0xFFFBF6EE),
                                      fg: highlight
                                          ? const Color(0xFF065F46)
                                          : const Color(0xFF92400E)),
                                ],
                              ),
                            ),
                            Icon(
                              loading
                                  ? Icons.check_circle_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 20,
                              color: profile.color,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: profile.features
                              .map((f) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: highlight
                                          ? const Color(0xFFF0FBF4)
                                          : const Color(0xFFFBF6EE),
                                      borderRadius:
                                          BorderRadius.circular(999),
                                      border: Border.all(
                                          color: highlight
                                              ? const Color(0xFFB7E4C7)
                                              : const Color(0xFFF0DDBA)),
                                    ),
                                    child: Text(f,
                                        style: body(11,
                                            color: highlight
                                                ? AppColors.forest800
                                                : AppColors.gold700)),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
