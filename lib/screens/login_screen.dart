import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' show ClientException;
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/api_config.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// Login screen — mirrors web `src/app/login/page.tsx`.
/// Phone → OTP login: the backend has no OTP-dispatch step (same as
/// registration) — the fixed demo OTP (121212) is entered directly, then
/// `POST /api/user/login` verifies it and signs in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

  /// Validates the number and advances to OTP entry. No network call here —
  /// the backend has no send-otp route; it validates the fixed demo OTP
  /// directly against `/api/user/login` (same as registration).
  void _handlePhoneNext() {
    final t = AppLocalizations.of(context);
    if (_phoneCtrl.text.length < 10) {
      setState(() => _error = t.loginErrorInvalidPhone);
      return;
    }
    setState(() {
      _error = '';
      _phoneStep = 'otp';
    });
  }

  /// Verifies the OTP against the backend (`/api/user/login`) and signs in.
  /// Server fields (name/gotra/native/bio/…) come from MongoDB; local-only
  /// fields (photo/gender/address) are preserved from the existing session.
  Future<void> _handleOtpVerify() async {
    final t = AppLocalizations.of(context);
    if (_otpCtrl.text.length != 6) {
      setState(() => _error = t.loginErrorInvalidOtp);
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    final auth = context.read<AuthService>();
    final existing = auth.user;
    try {
      var user = await auth.login(_phoneCtrl.text, _otpCtrl.text);
      if (existing != null && existing.phone == user.phone) {
        user = user.copyWith(
          photoPath: existing.photoPath.isNotEmpty ? existing.photoPath : null,
          gender: existing.gender.isNotEmpty ? existing.gender : null,
          address: existing.address.isNotEmpty ? existing.address : null,
        );
        await auth.updateUser(user);
      }
      if (!mounted) return;
      context.go(user.isElder ? '/elder' : '/dashboard');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            (e.statusCode == 404 || e.message == 'Phone number not registered')
            ? t.loginErrorNotRegistered
            : e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Name the server we failed to reach. "Network error" alone sent us
        // hunting for a wrong phone number when the real cause was a stale
        // API_BASE_URL pointing at a dead tunnel.
        _error =
            (e is SocketException ||
                e is TimeoutException ||
                e is HttpException ||
                e is ClientException)
            ? t.loginErrorServerUnreachable(ApiConfig.baseUrl)
            : t.loginErrorNetwork;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
              _FormCard(child: _buildForm(t)),
              const SizedBox(height: 16),
              // Read about the community (the landing/about page). Opens on top
              // of login so the back button returns here.
              OutlinedButton.icon(
                onPressed: () => context.push('/'),
                icon: const Icon(Icons.auto_stories_rounded, size: 16),
                label: Text(
                  t.loginAboutCommunity,
                  style: body(
                    14,
                    weight: FontWeight.w600,
                    color: AppColors.gold500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold500,
                  side: const BorderSide(color: AppColors.gold500, width: 1.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      t.loginNewMember,
                      style: body(13, color: AppColors.forest300),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text(
                        t.loginCreateAccount,
                        style: body(
                          13,
                          weight: FontWeight.w700,
                          color: AppColors.gold500,
                        ),
                      ),
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

  Widget _buildForm(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.loginTitle,
          style: display(
            26,
            color: context.onBrightness(
              light: AppColors.forest900,
              dark: AppColors.darkText,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t.loginSubtitle,
          style: body(
            13,
            color: context.onBrightness(
              light: AppColors.textMuted,
              dark: AppColors.darkTextMuted,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _buildPhone(t),
      ],
    );
  }

  Widget _buildPhone(AppLocalizations t) {
    if (_phoneStep == 'phone') {
      return Container(
        decoration: BoxDecoration(
          color: context.onBrightness(
            light: Colors.white,
            dark: AppColors.darkBg,
          ),
          border: Border.all(
            color: context.onBrightness(
              light: AppColors.border,
              dark: AppColors.darkBorder,
            ),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.loginPhoneLabel,
              style: body(
                13,
                weight: FontWeight.w700,
                color: context.onBrightness(
                  light: AppColors.forest800,
                  dark: AppColors.forest300,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: body(
                14,
                color: context.onBrightness(
                  light: AppColors.ink,
                  dark: AppColors.darkText,
                ),
              ),
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
              label: t.loginSendOtp,
              icon: Icons.arrow_forward_rounded,
              expand: true,
              loading: _loading,
              onPressed: _loading ? null : _handlePhoneNext,
            ),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: context.onBrightness(
          light: Colors.white,
          dark: AppColors.darkBg,
        ),
        border: Border.all(
          color: context.onBrightness(
            light: AppColors.border,
            dark: AppColors.darkBorder,
          ),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.loginOtpSentTo(_phoneCtrl.text),
            style: body(
              13,
              color: context.onBrightness(
                light: AppColors.textMuted,
                dark: AppColors.darkTextMuted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.onBrightness(
                light: const Color(0xFFEAF7EE),
                dark: AppColors.darkSurface,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Enter the 6-digit OTP  ·  use 121212 for this demo',
              style: body(
                12,
                weight: FontWeight.w600,
                color: context.onBrightness(
                  light: AppColors.forest700,
                  dark: AppColors.forest300,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: display(
              24,
              color: context.onBrightness(
                light: AppColors.forest900,
                dark: AppColors.darkText,
              ),
            ),
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
            label: t.loginButton,
            icon: Icons.check_circle_outline_rounded,
            expand: true,
            loading: _loading,
            onPressed: _otpCtrl.text.length == 6 ? _handleOtpVerify : null,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _loading ? null : _handlePhoneNext,
                child: Text(
                  'Resend OTP',
                  style: body(
                    13,
                    weight: FontWeight.w600,
                    color: context.onBrightness(
                      light: AppColors.forest800,
                      dark: AppColors.forest300,
                    ),
                  ),
                ),
              ),
              Text(
                '·',
                style: body(
                  13,
                  color: context.onBrightness(
                    light: AppColors.textMuted,
                    dark: AppColors.darkTextMuted,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _phoneStep = 'phone';
                  _error = '';
                  _otpCtrl.clear();
                }),
                child: Text(
                  t.loginChangeNumber,
                  style: body(
                    13,
                    color: context.onBrightness(
                      light: AppColors.textMuted,
                      dark: AppColors.darkTextMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    counterText: '',
    filled: true,
    fillColor: context.onBrightness(
      light: Colors.white,
      dark: AppColors.darkBg,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: context.onBrightness(
          light: AppColors.border,
          dark: AppColors.darkBorder,
        ),
      ),
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
    final t = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.forest950,
            AppColors.forest900,
            AppColors.forest800,
          ],
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
                  child: const Icon(
                    Icons.park_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.appName, style: display(16, color: Colors.white)),
                    Text(
                      t.appTagline,
                      style: body(11, color: AppColors.forest500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            t.loginHeroHeadline,
            style: display(24, color: Colors.white, height: 1.25),
          ),
          const SizedBox(height: 10),
          Text(
            t.loginHeroBody,
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
        color: context.onBrightness(
          light: AppColors.cream,
          dark: AppColors.darkSurface,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}
