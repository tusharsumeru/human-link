import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../services/auth_service.dart';
import '../services/phone_auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// Login screen — ported from web `src/app/login/page.tsx`.
/// Phone → OTP login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _phoneStep = 'phone'; // 'phone' | 'otp'
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _phoneAuth = PhoneAuthService();
  String _error = '';
  bool _loading = false;
  bool _sending = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePhoneNext() async {
    if (_phoneCtrl.text.length < 10) {
      setState(() => _error = 'Enter a valid 10-digit phone number');
      return;
    }
    setState(() {
      _error = '';
      _sending = true;
    });
    try {
      await _phoneAuth.sendCode(
        _phoneCtrl.text,
        onCodeSent: () {
          if (!mounted) return;
          setState(() {
            _sending = false;
            _phoneStep = 'otp';
          });
        },
        onFailed: (msg) {
          if (!mounted) return;
          setState(() {
            _sending = false;
            _error = msg;
          });
        },
        onAutoVerified: () => _completeLogin(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = PhoneAuthService.humanError(e);
      });
    }
  }

  Future<void> _handleOtpVerify() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      await _phoneAuth.verify(_otpCtrl.text);
      await _completeLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = PhoneAuthService.humanError(e);
        _loading = false;
      });
    }
  }

  /// Resolves the member profile for the verified phone and signs in.
  /// Server fields (name/gotra/native/bio/…) come from MongoDB; local-only
  /// fields (photo/gender/address) are preserved from the existing session.
  Future<void> _completeLogin() async {
    final auth = context.read<AuthService>();
    final existing = auth.user;
    final map = await Repository.instance.profileForPhone(_phoneCtrl.text);
    var user = AppUser.fromMap(map);
    if (existing != null && existing.phone == user.phone) {
      user = user.copyWith(
        photoPath: existing.photoPath.isNotEmpty ? existing.photoPath : null,
        gender: existing.gender.isNotEmpty ? existing.gender : null,
        address: existing.address.isNotEmpty ? existing.address : null,
      );
    }
    if (!mounted) return;
    await auth.loginWithUser(user);
    if (!mounted) return;
    context.go(user.isElder ? '/elder' : '/dashboard');
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
          'Login with your registered mobile number.',
          style: body(13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 18),
        _buildPhone(),
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
              loading: _sending,
              onPressed: _sending ? null : _handlePhoneNext,
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
            child: Text('Enter the 6-digit code sent via SMS',
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
            decoration: _inputDecoration('0 0 0 0 0 0'),
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
