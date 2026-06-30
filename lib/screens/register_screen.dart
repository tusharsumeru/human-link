import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
import '../services/auth_service.dart';
import '../services/phone_auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/place_field.dart';
import '../widgets/ui_kit.dart';

/// Register screen — ported from web `src/app/register/page.tsx`.
/// Collects member details (name, phone, gotra, native, optional Aadhaar),
/// creates a member [AppUser] and flows into onboarding.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

const _gotras = [
  'Kashyap',
  'Bharadwaja',
  'Vasishtha',
  'Atreya',
  'Kaundinya',
  'Vishwamitra',
  'Gautama',
];

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nativeCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _phoneAuth = PhoneAuthService();
  String _gotra = 'Kashyap';
  String _gender = 'M';
  String _step = 'details'; // 'details' | 'otp'
  String _error = '';
  bool _loading = false;
  bool _sending = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _nativeCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your full name');
      return;
    }
    if (_phoneCtrl.text.length < 10) {
      setState(() => _error = 'Please enter a valid 10-digit phone number');
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
            _step = 'otp';
          });
        },
        onFailed: (msg) {
          if (!mounted) return;
          setState(() {
            _sending = false;
            _error = msg;
          });
        },
        onAutoVerified: () => _completeRegistration(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = PhoneAuthService.humanError(e);
      });
    }
  }

  Future<void> _handleVerify() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      await _phoneAuth.verify(_otpCtrl.text);
      await _completeRegistration();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : PhoneAuthService.humanError(e);
        _loading = false;
      });
    }
  }

  /// Registers the member in the backend (MongoDB) after the phone number is
  /// verified, then persists the profile locally (with the chosen gender).
  /// If the phone is already registered (409), signs the existing user in.
  Future<void> _completeRegistration() async {
    final auth = context.read<AuthService>();
    final phone = _phoneCtrl.text;
    final native =
        _nativeCtrl.text.trim().isEmpty ? 'Karnataka' : _nativeCtrl.text.trim();
    try {
      final map = await Repository.instance.register(
        name: _nameCtrl.text.trim(),
        phone: phone,
        gotra: _gotra,
        native: native,
      );
      final user = AppUser.fromMap(map)
          .copyWith(gender: _gender, onboardingComplete: false);
      if (!mounted) return;
      await auth.loginWithUser(user);
      if (!mounted) return;
      context.go('/onboarding/identity');
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        // Already registered — fetch the existing profile and sign in.
        final map = await Repository.instance.profileForPhone(phone);
        final user = AppUser.fromMap(map).copyWith(gender: _gender);
        if (!mounted) return;
        await auth.loginWithUser(user);
        if (!mounted) return;
        context.go('/dashboard');
      } else {
        rethrow;
      }
    }
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
              _Header(onLogoTap: () => context.go('/')),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppShadows.card,
                ),
                padding: const EdgeInsets.all(20),
                child: _buildForm(),
              ),
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text('← Back to Sign in',
                      style: body(13,
                          weight: FontWeight.w600, color: AppColors.gold500)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() =>
      _step == 'details' ? _buildDetails() : _buildOtp();

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Join the Samaj',
            style: display(26, color: AppColors.forest900)),
        const SizedBox(height: 6),
        Text('Create your account and begin documenting your lineage',
            style: body(13, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7EE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('An OTP will be sent to your mobile via SMS',
              style: body(12,
                  weight: FontWeight.w600, color: AppColors.forest700)),
        ),
        const SizedBox(height: 18),
        _label('Full Name'),
        _field(_nameCtrl, 'e.g. Aditi Shanbhag Rao'),
        const SizedBox(height: 14),
        _label('Mobile Number'),
        _field(_phoneCtrl, '9876543210',
            keyboardType: TextInputType.phone,
            maxLength: 10,
            digitsOnly: true),
        const SizedBox(height: 14),
        _label('Gender'),
        Row(
          children: [
            _genderButton('M', 'Male'),
            const SizedBox(width: 10),
            _genderButton('F', 'Female'),
          ],
        ),
        const SizedBox(height: 14),
        _label('Gotra'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _gotra,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.hint),
              style: body(14, color: AppColors.ink),
              items: _gotras
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _gotra = v ?? _gotra),
            ),
          ),
        ),
        const SizedBox(height: 14),
        PlaceField(
          label: 'Native Place (optional)',
          controller: _nativeCtrl,
          hint: 'e.g. Kundapura, Udupi, Karnataka',
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(_error, style: body(13, color: Colors.red)),
        ],
        const SizedBox(height: 18),
        ForestButton(
          label: 'Continue',
          icon: Icons.arrow_forward_rounded,
          expand: true,
          loading: _sending,
          onPressed: _sending ? null : _handleNext,
        ),
        const SizedBox(height: 14),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              Text('Already a member?  ',
                  style: body(13, color: AppColors.textMuted)),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Text('Sign in',
                    style: body(13,
                        weight: FontWeight.w700, color: AppColors.forest800)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Verify your number',
            style: display(26, color: AppColors.forest900)),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            style: body(13, color: AppColors.textMuted),
            children: [
              const TextSpan(text: 'OTP sent to '),
              TextSpan(
                text: '+91 ${_phoneCtrl.text}',
                style: body(13,
                    weight: FontWeight.w700, color: AppColors.forest800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7EE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('Enter the 6-digit code sent via SMS',
              style: body(12,
                  weight: FontWeight.w600, color: AppColors.forest700)),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: display(26, color: AppColors.forest900),
          onChanged: (_) => setState(() {
            if (_error.isNotEmpty) _error = '';
          }),
          decoration: InputDecoration(
            hintText: '0 0 0 0 0 0',
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.forest800, width: 1.5),
            ),
          ),
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(_error, style: body(13, color: Colors.red)),
        ],
        const SizedBox(height: 14),
        ForestButton(
          label: 'Create Account & Continue',
          icon: Icons.check_circle_outline_rounded,
          expand: true,
          loading: _loading,
          onPressed: _otpCtrl.text.length == 6 ? _handleVerify : null,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _step = 'details';
              _error = '';
              _otpCtrl.clear();
            }),
            child: Text('← Back',
                style: body(13, color: AppColors.textMuted)),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: body(13, weight: FontWeight.w700, color: AppColors.forest800)),
      );

  Widget _genderButton(String value, String label) {
    final active = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.forest800 : Colors.white,
            border: Border.all(
                color: active ? AppColors.forest800 : AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label,
              style: body(13,
                  weight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.label)),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    int? maxLength,
    bool digitsOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters:
          digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
      onChanged: (_) {
        if (_error.isNotEmpty) setState(() => _error = '');
      },
      style: body(14, color: AppColors.ink),
      decoration: InputDecoration(
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
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.onLogoTap});
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
          Text('Begin your lineage journey today.',
              style: display(24, color: Colors.white, height: 1.25)),
          const SizedBox(height: 10),
          Text(
            'Join 1,428 families who have documented their heritage and '
            'connected with their ancestral roots.',
            style: body(13, color: AppColors.forest300, height: 1.5),
          ),
        ],
      ),
    );
  }
}
