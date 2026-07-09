import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import 'digilocker_webview_screen.dart';

/// Verify Identity — real Aadhaar KYC via SurePass DigiLocker.
///
/// Mirrors the web's DigiLocker verification (`/onboarding/identity`): initialize
/// a DigiLocker session → open the hosted consent page in a WebView → download
/// the verified Aadhaar → persist the masked KYC to MongoDB and the local
/// session. No mock data — the profile's verified badge reflects a real check.
class ProfileVerifyScreen extends StatefulWidget {
  const ProfileVerifyScreen({super.key});

  @override
  State<ProfileVerifyScreen> createState() => _ProfileVerifyScreenState();
}

class _ProfileVerifyScreenState extends State<ProfileVerifyScreen> {
  bool _busy = false;
  String _error = '';
  bool _verified = false;
  String _verifiedName = '';
  String _maskedAadhaar = '';

  @override
  void initState() {
    super.initState();
    // Reflect an already-verified member.
    final user = context.read<AuthService>().user;
    if (user?.verified ?? false) {
      _verified = true;
      _maskedAadhaar = user?.maskedAadhaar ?? '';
    }
  }

  /// Starts SurePass DigiLocker: init → open the hosted page in a WebView →
  /// on completion, download and persist the verified Aadhaar data.
  Future<void> _startDigilocker() async {
    final auth = context.read<AuthService>();
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      final init = await Repository.instance.digilockerInitialize();
      final url = (init['url'] ?? '').toString();
      final clientId = (init['client_id'] ?? '').toString();
      final redirect = (init['redirect_url'] ?? '').toString();
      if (url.isEmpty || clientId.isEmpty) {
        throw ApiException('DigiLocker link unavailable');
      }
      if (!mounted) return;
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              DigilockerWebViewScreen(url: url, redirectUrl: redirect),
        ),
      );
      if (ok != true) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final data = await Repository.instance.digilockerAadhaar(clientId);
      final fullName = (data['full_name'] ?? '').toString();
      final dob = (data['dob'] ?? '').toString();
      final gender = (data['gender'] ?? '').toString();
      final masked = (data['masked_aadhaar'] ?? '').toString();
      final address = (data['full_address'] ?? '').toString();

      final user = auth.user;
      if (user != null) {
        await Repository.instance.updateProfile(
          phone: user.phone,
          dob: dob,
          gender: gender,
          address: address,
          maskedAadhaar: masked,
          verified: true,
        );
        await auth.updateUser(user.copyWith(
          dob: dob,
          gender: gender.isEmpty ? null : gender,
          address: address,
          maskedAadhaar: masked,
          verified: true,
        ));
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _verified = true;
        _verifiedName = fullName;
        _maskedAadhaar = masked;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            e is ApiException ? e.message : 'DigiLocker verification failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forest800,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text('Verify Identity', style: display(18, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          Text('Identity Verification',
              style: display(24, color: AppColors.forest900)),
          const SizedBox(height: 6),
          Text(
            'Verify your Aadhaar securely through the government DigiLocker. Your '
            'profile stays Not Verified until this is complete. We never see or '
            'store your full Aadhaar number — only a masked reference.',
            style: body(13, color: AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 18),
          AppCard(child: _digilockerCard()),
          const SizedBox(height: 14),
          _trustPanel(),
          const SizedBox(height: 20),
          if (_verified)
            ForestButton(
              label: 'Back to Dashboard',
              icon: Icons.check_circle_outline_rounded,
              expand: true,
              onPressed: () => context.go('/dashboard'),
            ),
        ],
      ),
    );
  }

  Widget _digilockerCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.verified_user_outlined,
                size: 18, color: AppColors.forest700),
            const SizedBox(width: 8),
            Text('Aadhaar via DigiLocker',
                style: display(16, color: AppColors.forest900)),
            const Spacer(),
            if (_verified)
              Pill('Verified',
                  icon: Icons.check_circle,
                  bg: AppColors.forest600.withValues(alpha: 0.14),
                  fg: AppColors.forest700),
          ],
        ),
        const SizedBox(height: 12),
        if (_verified)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FBF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFB7E4C7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 18, color: AppColors.forest700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _verifiedName.isNotEmpty
                        ? 'Verified: $_verifiedName'
                        : _maskedAadhaar.isNotEmpty
                            ? 'Aadhaar verified · $_maskedAadhaar'
                            : 'Aadhaar verified successfully.',
                    style: body(13,
                        weight: FontWeight.w600, color: AppColors.forest700),
                  ),
                ),
              ],
            ),
          )
        else ...[
          Text(
            'You\'ll sign in to the official DigiLocker portal and consent to '
            'share your Aadhaar. We confirm verification automatically.',
            style: body(12, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 10),
          ForestButton(
            label: 'Verify with DigiLocker',
            icon: Icons.shield_outlined,
            expand: true,
            loading: _busy,
            onPressed: _busy ? null : _startDigilocker,
          ),
        ],
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_error, style: body(12, color: Colors.red)),
        ],
      ],
    );
  }

  Widget _trustPanel() {
    const items = [
      (Icons.lock_outline, 'Government-backed DigiLocker consent'),
      (Icons.visibility_off_outlined, 'Full Aadhaar number is never stored'),
      (Icons.verified_user_outlined, 'Only a masked reference is kept'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.deepForest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  size: 16, color: AppColors.gold500),
              const SizedBox(width: 8),
              Text('Trust & Security',
                  style: body(13,
                      weight: FontWeight.w700, color: AppColors.gold500)),
            ],
          ),
          const SizedBox(height: 12),
          for (final (icon, text) in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(icon, size: 14, color: AppColors.forest500),
                  const SizedBox(width: 8),
                  Expanded(
                    child:
                        Text(text, style: body(12, color: AppColors.forest300)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
