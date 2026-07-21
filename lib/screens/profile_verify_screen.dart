import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/digilocker_card.dart';
import '../widgets/ui_kit.dart';

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
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    // Reflect an already-verified member.
    _verified = context.read<AuthService>().user?.verified ?? false;
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
          AppCard(
            child: DigilockerCard(
              onVerified: (_) => setState(() => _verified = true),
            ),
          ),
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
