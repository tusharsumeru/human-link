import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/digilocker_card.dart';
import '../widgets/leaf_backdrop.dart';
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

  // ── UI ────────────────────────────────────────────────────────────────────

  // The palette this screen is drawn with, read off the botanical canvas
  // rather than the default page surface.
  Color get _ink =>
      context.onBrightness(light: AppColors.forest900, dark: Colors.white);
  Color get _gold => context.onBrightness(
    light: AppColors.champagneDeep,
    dark: AppColors.champagne,
  );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return LeafCanvas(
      // Two cards and then empty space: the bottom half of this page is the
      // backdrop, so the backdrop is worth painting properly.
      lush: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          // Just short of opaque, so the leaves the canvas paints up here read
          // faintly through the band. Only the canvas is behind the bar — the
          // body starts below it — so nothing scrolling can show through.
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.forest800.withValues(alpha: 0.93),
                  AppColors.forest700.withValues(alpha: 0.93),
                ],
              ),
            ),
          ),
          shape: Border(
            bottom: BorderSide(
              color: AppColors.forest600.withValues(alpha: 0.55),
            ),
          ),
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
          title: Text(
            t.verifyIdentityTitle,
            style: display(20, color: Colors.white),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 32),
          children: [
            _heading(t.verifyIdentityHeading),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: LotusOrnament(ruleWidth: 56),
            ),
            const SizedBox(height: 26),
            _panel(
              child: DigilockerCard(
                onVerified: (_) => setState(() => _verified = true),
              ),
            ),
            const SizedBox(height: 16),
            _trustPanel(t),
            if (_verified) ...[
              const SizedBox(height: 24),
              PillButton(
                label: t.verifyBackToDashboard,
                onPressed: () => context.go('/dashboard'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The page title, with its last word in champagne.
  ///
  /// Split on the final space rather than carried as two strings per locale:
  /// "Identity Verification", "पहचान सत्यापन" and "ಗುರುತಿನ ಪರಿಶೀಲನೆ" all land
  /// the same way, and a heading that has no space in it simply stays one
  /// colour instead of breaking.
  Widget _heading(String text) {
    final cut = text.trimRight().lastIndexOf(' ');
    final white = display(29, color: _ink);
    if (cut <= 0) return Text(text, style: white);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, cut + 1), style: white),
          TextSpan(
            text: text.substring(cut + 1),
            style: display(29, color: _gold),
          ),
        ],
      ),
    );
  }

  /// The card both panels are built on: a wash barely off the ground with a
  /// green hairline, rather than the opaque surface [AppCard] uses — on the
  /// botanical canvas a solid block would cover the leaves it is sitting on.
  Widget _panel({required Widget child, EdgeInsets? padding}) => Container(
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: context.onBrightness(
        light: Colors.white.withValues(alpha: 0.75),
        dark: AppColors.emerald.withValues(alpha: 0.05),
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: context.onBrightness(
          light: AppColors.sageEdge,
          dark: AppColors.emerald.withValues(alpha: 0.18),
        ),
      ),
    ),
    child: child,
  );

  /// The ringed gold disc every line in the trust panel opens with. Gold
  /// rather than the green used on the form screens: this panel is about what
  /// is being safeguarded, and the green discs elsewhere mean "a field".
  Widget _disc(IconData icon, {double size = 40}) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _gold.withValues(alpha: 0.10),
      border: Border.all(color: _gold.withValues(alpha: 0.38)),
    ),
    child: Icon(icon, size: size * 0.46, color: _gold),
  );

  Widget _hairline() => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color: context.onBrightness(
      light: AppColors.sageEdge,
      dark: AppColors.emerald.withValues(alpha: 0.12),
    ),
  );

  /// What we do and don't keep, said plainly next to the button that asks for
  /// it. Ruled rather than spaced: three one-line promises run together as a
  /// block of text, and the rules make each one a separate statement.
  Widget _trustPanel(AppLocalizations t) {
    final items = [
      (Icons.lock_outline, t.verifyTrustGovBacked),
      (Icons.verified_user_outlined, t.verifyTrustNeverStored),
      (Icons.visibility_off_outlined, t.verifyTrustMaskedOnly),
    ];
    return _panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _disc(Icons.shield_outlined, size: 42),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    t.identityTrustSecurity,
                    style: display(18, color: _ink),
                  ),
                ),
              ],
            ),
          ),
          for (final (icon, text) in items) ...[
            _hairline(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  _disc(icon),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      text,
                      style: body(14.5, height: 1.4, color: _ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
