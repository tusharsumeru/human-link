import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
import '../screens/digilocker_webview_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'ui_kit.dart';

/// Aadhaar KYC via DigiLocker — the whole flow in a single card.
///
/// initialize (`/api/adhar/initialize`) → the hosted consent page in a WebView →
/// download (`/api/adhar/download`) → persist the masked KYC to MongoDB and the
/// local session. Shared by registration, onboarding step 1 and the profile's
/// Verify Identity screen so all three behave identically.
///
/// Neither `/api/adhar` route needs a bearer token, so this also works *before*
/// an account exists (registration step 1): with nobody signed in there is
/// nothing to persist to, so the KYC is handed to [onVerified] and the caller
/// saves it against the account once it's created.
class DigilockerCard extends StatefulWidget {
  const DigilockerCard({super.key, this.description, this.onVerified});

  /// Copy shown above the button; each host screen frames the step differently.
  final String? description;

  /// Fires once the Aadhaar is verified, with the KYC map: `full_name`, `dob`,
  /// `gender`, `masked_aadhaar`, `full_address`.
  final ValueChanged<Map<String, dynamic>>? onVerified;

  @override
  State<DigilockerCard> createState() => _DigilockerCardState();
}

class _DigilockerCardState extends State<DigilockerCard> {
  bool _busy = false;
  bool _verified = false;
  String _verifiedName = '';
  String _maskedAadhaar = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    // Reflect an already-verified member instead of asking them to redo KYC.
    final user = context.read<AuthService>().user;
    if (user?.verified ?? false) {
      _verified = true;
      _maskedAadhaar = user?.maskedAadhaar ?? '';
    }
  }

  Future<void> _start() async {
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
      if (!mounted) return;
      final consented = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              DigilockerWebViewScreen(url: url, redirectUrl: redirect),
        ),
      );
      // Backed out of the consent page — leave the card untouched.
      if (consented != true) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final kyc = await Repository.instance.digilockerAadhaar(clientId);
      final fullName = (kyc['full_name'] ?? '').toString();
      final dob = (kyc['dob'] ?? '').toString();
      final gender = (kyc['gender'] ?? '').toString();
      final masked = (kyc['masked_aadhaar'] ?? '').toString();
      final address = (kyc['full_address'] ?? '').toString();

      final user = auth.user;
      // No session yet (registration step 1) — the caller persists this once the
      // account exists. Otherwise save to MongoDB (best-effort) and the local
      // session. Only the masked reference is ever stored, never the full number.
      if (user != null) {
        await Repository.instance.updateProfile(
          phone: user.phone,
          dob: dob.isEmpty ? null : dob,
          gender: gender.isEmpty ? null : gender,
          address: address.isEmpty ? null : address,
          maskedAadhaar: masked.isEmpty ? null : masked,
          verified: true,
        );
        await auth.updateUser(
          user.copyWith(
            dob: dob.isEmpty ? null : dob,
            gender: gender.isEmpty ? null : gender,
            address: address.isEmpty ? null : address,
            maskedAadhaar: masked.isEmpty ? null : masked,
            verified: true,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _verified = true;
        _verifiedName = fullName;
        _maskedAadhaar = masked;
      });
      widget.onVerified?.call(kyc);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is ApiException
            ? e.message
            : 'DigiLocker verification failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = context.onBrightness(
      light: AppColors.forest900,
      dark: Colors.white,
    );
    final inkMuted = context.onBrightness(
      light: AppColors.textMuted,
      dark: AppColors.darkTextMuted,
    );
    final accent = context.onBrightness(
      light: AppColors.forest700,
      dark: AppColors.emerald,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                // A white disc on a white card needs an edge; on the dark one
                // the disc is already the brightest thing in the card.
                border: Border.all(
                  color: context.onBrightness(
                    light: AppColors.border,
                    dark: Colors.transparent,
                  ),
                ),
              ),
              // A stand-in, not DigiLocker's own mark — the brand asset isn't
              // bundled, and inventing one would be worse than suggesting the
              // idea: documents pulled down from a government locker.
              child: const Icon(
                Icons.cloud_download_rounded,
                size: 24,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Aadhaar via DigiLocker',
                          style: display(19, color: ink),
                        ),
                      ),
                      if (_verified)
                        Pill(
                          'Verified',
                          icon: Icons.check_circle,
                          bg: AppColors.forest600.withValues(alpha: 0.16),
                          fg: accent,
                        ),
                    ],
                  ),
                  // No fallback copy: a host that wants the step framed
                  // passes its own line, and one that doesn't gets a card that
                  // is just the title and the button.
                  if (!_verified && widget.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.description!,
                      style: body(14, color: inkMuted, height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (_verified)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              // The fixed mint was a soft panel on cream and a lit slab on
              // near-black; it follows the theme now like everything else.
              color: context.onBrightness(
                light: const Color(0xFFF0FBF4),
                dark: AppColors.emerald.withValues(alpha: 0.10),
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.onBrightness(
                  light: const Color(0xFFB7E4C7),
                  dark: AppColors.emerald.withValues(alpha: 0.28),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 18, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _verifiedName.isNotEmpty
                        ? 'Verified: $_verifiedName'
                        : _maskedAadhaar.isNotEmpty
                        ? 'Aadhaar verified · $_maskedAadhaar'
                        : 'Aadhaar verified successfully.',
                    style: body(13.5, weight: FontWeight.w600, color: accent),
                  ),
                ),
              ],
            ),
          )
        else
          PillButton(
            label: 'Verify with DigiLocker',
            loading: _busy,
            onPressed: _busy ? null : _start,
          ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            _error,
            style: body(
              12.5,
              color: context.onBrightness(
                light: const Color(0xFFC62828),
                dark: const Color(0xFFEF9A9A),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
