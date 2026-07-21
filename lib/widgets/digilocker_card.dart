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
        await auth.updateUser(user.copyWith(
          dob: dob.isEmpty ? null : dob,
          gender: gender.isEmpty ? null : gender,
          address: address.isEmpty ? null : address,
          maskedAadhaar: masked.isEmpty ? null : masked,
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
      widget.onVerified?.call(kyc);
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
            widget.description ??
                'You\'ll sign in to the official DigiLocker portal and consent '
                    'to share your Aadhaar. We confirm verification automatically.',
            style: body(12, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 10),
          ForestButton(
            label: 'Verify with DigiLocker',
            icon: Icons.shield_outlined,
            expand: true,
            loading: _busy,
            onPressed: _busy ? null : _start,
          ),
        ],
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_error, style: body(12, color: Colors.red)),
        ],
      ],
    );
  }
}
