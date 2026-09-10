import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/gotras.dart';
import '../data/kuladevatas.dart';
import '../data/repository.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/digilocker_card.dart';
import '../widgets/kuladevata_thumb.dart';
import '../widgets/place_field.dart';
import '../widgets/ui_kit.dart';

/// Register screen — mirrors web `src/app/register/page.tsx`.
/// Collects member details (name, phone, gender, gotra, native), verifies the
/// fixed demo OTP (121212), creates a member, then offers Aadhaar identity
/// verification via DigiLocker before landing on the dashboard. Verification is
/// skippable (it's also on the profile); lineage/heritage onboarding stays
/// optional, done later at the member's own pace.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nativeCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  String _gotra = kDaivajnaGotras.first;
  // Optional, unlike Gotra — starts unselected rather than defaulting to the
  // first entry in the list.
  String? _kuladevata;
  String _gender = 'M';
  // Decides matrimonial-hub access after the account exists — 'married'
  // never sees it; 'unmarried'/'divorced' do. Defaulted rather than left
  // unselected, matching how gotra/gender already default on this form.
  String _maritalStatus = 'unmarried';
  bool _isPurohit = false;
  String _step = 'details'; // 'details' | 'otp' | 'identity'
  String _error = '';
  bool _loading = false;
  bool _identityVerified = false;
  // KYC captured by DigiLocker before the account existed (details step); it's
  // written to the profile as soon as registration returns a token.
  Map<String, dynamic>? _kyc;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _nativeCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  /// Validate the details and advance to OTP entry. No SMS is sent — the
  /// backend accepts the fixed demo OTP (matches the web register flow).
  void _handleNext() {
    final t = AppLocalizations.of(context);
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = t.registerErrorName);
      return;
    }
    if (_phoneCtrl.text.length < 10) {
      setState(() => _error = t.registerErrorPhone);
      return;
    }
    setState(() {
      _error = '';
      _step = 'otp';
    });
  }

  /// DigiLocker came back verified. Before the account exists there's nothing to
  /// save it to, so hold it until [_completeRegistration] can attach it.
  void _onKycVerified(Map<String, dynamic> kyc) {
    setState(() {
      _kyc = kyc;
      _identityVerified = true;
      _error = '';
    });
  }

  Future<void> _handleVerify() async {
    if (_otpCtrl.text != '121212') {
      setState(
        () => _error = AppLocalizations.of(context).registerErrorInvalidOtp,
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    await _completeRegistration();
  }

  /// Registers the member in the backend (MongoDB), persists the profile
  /// locally, then advances to the identity step. The account exists (and holds
  /// a bearer token) by that point, which is what the DigiLocker KYC needs to
  /// save against the profile. A phone that's already registered (409) surfaces
  /// an error (matches the web flow).
  Future<void> _completeRegistration() async {
    final auth = context.read<AuthService>();
    final phone = _phoneCtrl.text;
    final native = _nativeCtrl.text.trim().isEmpty
        ? 'Karnataka'
        : _nativeCtrl.text.trim();
    // Assign a random avatar (1–8), as the web register page does.
    final avatar = (Random().nextInt(8) + 1).toString();
    try {
      final res = await Repository.instance.register(
        name: _nameCtrl.text.trim(),
        phone: phone,
        gotra: _gotra,
        native: native,
        avatar: avatar,
        gender: _gender,
        maritalStatus: _maritalStatus,
        isPurohit: _isPurohit,
      );
      final map = res['user'] as Map<String, dynamic>;
      final token = (res['token'] ?? '') as String;
      var user = AppUser.fromMap(map).copyWith(
        gender: _gender,
        avatar: avatar,
        maritalStatus: _maritalStatus,
      );
      // Apply a DigiLocker verification done back on the details step. Aadhaar
      // is authoritative, so its dob/gender win over what was typed.
      final kyc = _kyc;
      final dob = (kyc?['dob'] ?? '').toString();
      final kycGender = (kyc?['gender'] ?? '').toString();
      final address = (kyc?['full_address'] ?? '').toString();
      final masked = (kyc?['masked_aadhaar'] ?? '').toString();
      if (kyc != null) {
        user = user.copyWith(
          dob: dob.isEmpty ? null : dob,
          gender: kycGender.isEmpty ? null : kycGender,
          address: address.isEmpty ? null : address,
          maskedAadhaar: masked.isEmpty ? null : masked,
          verified: true,
        );
      }
      if (!mounted) return;
      await auth.loginWithUser(user, token: token.isEmpty ? null : token);
      // Only now is there a bearer token to save against the Parampara
      // resource too — the Daivagna Parampara compatibility comparison reads
      // its own Gotra/Kuladevata declarations from there, separate from the
      // basic `gotra` just sent to /api/user/register above (see
      // ParamparaProfile's doc comment). Best-effort: never blocks account
      // creation, which has already succeeded by this point.
      try {
        await Repository.instance.saveParamparaGotra(_gotra);
        if (_kuladevata != null) {
          await Repository.instance.saveKuladevata(_kuladevata);
        }
      } catch (_) {
        // Can be completed later from Profile → Edit Profile.
      }
      // Only now is there a bearer token to save the KYC against the profile.
      if (kyc != null) {
        await Repository.instance.updateProfile(
          phone: user.phone,
          dob: dob.isEmpty ? null : dob,
          gender: kycGender.isEmpty ? null : kycGender,
          address: address.isEmpty ? null : address,
          maskedAadhaar: masked.isEmpty ? null : masked,
          verified: true,
        );
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _step = 'identity';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message.isNotEmpty
            ? e.message
            : AppLocalizations.of(context).registerErrorGeneric;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      // Surface *why* it failed — a bare "network error" hides whether this was
      // a timeout, a dead tunnel/DNS failure, or a bad response.
      final detail = e is TimeoutException
          ? t.registerErrorTimeout
          : e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _error = t.registerErrorNetwork(detail);
        _loading = false;
      });
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
                  color: context.onBrightness(
                    light: AppColors.cream,
                    dark: AppColors.darkSurface,
                  ),
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
                  child: Text(
                    AppLocalizations.of(context).registerBackToSignIn,
                    style: body(
                      13,
                      weight: FontWeight.w600,
                      color: AppColors.gold500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() => switch (_step) {
    'details' => _buildDetails(),
    'otp' => _buildOtp(),
    _ => _buildIdentity(),
  };

  Widget _buildDetails() {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.registerJoinTitle,
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
          t.registerJoinSubtitle,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: context.onBrightness(
              light: const Color(0xFFEAF7EE),
              dark: AppColors.darkBg,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            t.registerOtpNotice,
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
        const SizedBox(height: 18),
        _label(t.registerFullName, hint: t.registerAsPerAadhar),
        _field(_nameCtrl, t.registerFullNameHint),
        const SizedBox(height: 14),
        _label(t.registerMobileNumber, hint: t.registerAsPerAadhar),
        _field(
          _phoneCtrl,
          '9876543210',
          keyboardType: TextInputType.phone,
          maxLength: 10,
          digitsOnly: true,
        ),
        const SizedBox(height: 14),
        _label(t.registerGender),
        Row(
          children: [
            _genderButton('M', t.registerMale),
            const SizedBox(width: 10),
            _genderButton('F', t.registerFemale),
          ],
        ),
        const SizedBox(height: 14),
        _label(t.registerMaritalStatus),
        Container(
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
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _maritalStatus,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.hint,
              ),
              style: body(
                14,
                color: context.onBrightness(
                  light: AppColors.ink,
                  dark: AppColors.darkText,
                ),
              ),
              dropdownColor: context.onBrightness(
                light: Colors.white,
                dark: AppColors.darkBg,
              ),
              items:
                  [
                        ('unmarried', t.registerUnmarried),
                        ('divorced', t.registerDivorced),
                        ('married', t.registerMarried),
                      ]
                      .map(
                        (o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)),
                      )
                      .toList(),
              onChanged: (v) =>
                  setState(() => _maritalStatus = v ?? _maritalStatus),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _label(t.registerGotra),
        Container(
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
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _gotra,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.hint,
              ),
              style: body(
                14,
                color: context.onBrightness(
                  light: AppColors.ink,
                  dark: AppColors.darkText,
                ),
              ),
              dropdownColor: context.onBrightness(
                light: Colors.white,
                dark: AppColors.darkBg,
              ),
              items: kDaivajnaGotras
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _gotra = v ?? _gotra),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _label(t.registerKuladevata, hint: t.registerOptional),
        Container(
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
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _kuladevata,
              isExpanded: true,
              hint: Text(
                t.registerSelectKuladevata,
                style: body(14, color: AppColors.hint),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.hint,
              ),
              style: body(
                14,
                color: context.onBrightness(
                  light: AppColors.ink,
                  dark: AppColors.darkText,
                ),
              ),
              dropdownColor: context.onBrightness(
                light: Colors.white,
                dark: AppColors.darkBg,
              ),
              items: kKuladevatas
                  .map(
                    (k) => DropdownMenuItem(
                      value: k,
                      child: kKuladevataImages[k] == null
                          ? Text(k)
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                KuladevataThumb(
                                  assetPath: kKuladevataImages[k]!,
                                  name: k,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    k,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _kuladevata = v),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _label(t.registerIsPurohit),
        Row(
          children: [
            _yesNoButton(true, t.registerYes),
            const SizedBox(width: 10),
            _yesNoButton(false, t.registerNo),
          ],
        ),
        const SizedBox(height: 14),
        PlaceField(
          label: t.registerNativePlace,
          controller: _nativeCtrl,
          hint: t.registerNativePlaceHint,
        ),
        const SizedBox(height: 16),
        // Optional identity check up front. No Aadhaar number is ever typed —
        // it comes back from DigiLocker, already masked. Members who'd rather
        // not stop here get the same card again after the OTP. Once verified,
        // show the result instead of the card so stepping back from the OTP
        // screen doesn't ask them to do it all over again.
        if (_kyc != null)
          _kycConfirmation()
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.onBrightness(
                light: Colors.white,
                dark: AppColors.darkBg,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.onBrightness(
                  light: AppColors.border,
                  dark: AppColors.darkBorder,
                ),
              ),
            ),
            child: DigilockerCard(
              description: t.registerDigilockerDetailsDesc,
              onVerified: _onKycVerified,
            ),
          ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(_error, style: body(13, color: Colors.red)),
        ],
        const SizedBox(height: 18),
        ForestButton(
          label: t.registerContinue,
          icon: Icons.arrow_forward_rounded,
          expand: true,
          onPressed: _handleNext,
        ),
        const SizedBox(height: 14),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              Text(
                t.registerAlreadyMember,
                style: body(
                  13,
                  color: context.onBrightness(
                    light: AppColors.textMuted,
                    dark: AppColors.darkTextMuted,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Text(
                  t.registerSignIn,
                  style: body(
                    13,
                    weight: FontWeight.w700,
                    color: context.onBrightness(
                      light: AppColors.forest800,
                      dark: AppColors.forest300,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtp() {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.registerVerifyNumber,
          style: display(
            26,
            color: context.onBrightness(
              light: AppColors.forest900,
              dark: AppColors.darkText,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            style: body(
              13,
              color: context.onBrightness(
                light: AppColors.textMuted,
                dark: AppColors.darkTextMuted,
              ),
            ),
            children: [
              TextSpan(text: t.registerOtpSentToPrefix),
              TextSpan(
                text: t.registerOtpSentToPhone(_phoneCtrl.text),
                style: body(
                  13,
                  weight: FontWeight.w700,
                  color: context.onBrightness(
                    light: AppColors.forest800,
                    dark: AppColors.forest300,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: context.onBrightness(
              light: const Color(0xFFEAF7EE),
              dark: AppColors.darkBg,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            t.registerOtpHint,
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
        const SizedBox(height: 18),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: display(
            26,
            color: context.onBrightness(
              light: AppColors.forest900,
              dark: AppColors.darkText,
            ),
          ),
          onChanged: (_) => setState(() {
            if (_error.isNotEmpty) _error = '';
          }),
          decoration: InputDecoration(
            hintText: '1 2 1 2 1 2',
            counterText: '',
            filled: true,
            fillColor: context.onBrightness(
              light: Colors.white,
              dark: AppColors.darkBg,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
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
              borderSide: const BorderSide(
                color: AppColors.forest800,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(_error, style: body(13, color: Colors.red)),
        ],
        const SizedBox(height: 14),
        ForestButton(
          label: t.registerCreateAccountContinue,
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
            child: Text(
              t.registerBack,
              style: body(
                13,
                color: context.onBrightness(
                  light: AppColors.textMuted,
                  dark: AppColors.darkTextMuted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Step 3 — Aadhaar identity verification via DigiLocker. The account is
  /// already created, so this is skippable: unverified members can finish it
  /// later from Profile → Verify Identity.
  Widget _buildIdentity() {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.check_circle,
              size: 18,
              color: AppColors.forest700,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.registerAccountCreated,
                style: body(
                  13,
                  weight: FontWeight.w700,
                  color: AppColors.forest700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _identityVerified ? t.registerAllSet : t.registerVerifyIdentity,
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
          _identityVerified
              ? t.registerAadhaarVerifiedSubtitle
              : t.registerAadhaarUnverifiedSubtitle,
          style: body(
            13,
            color: context.onBrightness(
              light: AppColors.textMuted,
              dark: AppColors.darkTextMuted,
            ),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: DigilockerCard(
            description: t.registerDigilockerIdentityDesc,
            onVerified: (_) => setState(() => _identityVerified = true),
          ),
        ),
        const SizedBox(height: 16),
        ForestButton(
          label: _identityVerified
              ? t.registerContinueToDashboard
              : t.registerSkipForNow,
          icon: Icons.arrow_forward_rounded,
          expand: true,
          onPressed: () => context.go('/dashboard'),
        ),
      ],
    );
  }

  /// Stands in for the DigiLocker card once KYC is captured on the details
  /// step — the verification survives until the account is created.
  Widget _kycConfirmation() {
    final t = AppLocalizations.of(context);
    final name = (_kyc?['full_name'] ?? '').toString();
    final masked = (_kyc?['masked_aadhaar'] ?? '').toString();
    final detail = [
      if (name.isNotEmpty) name,
      if (masked.isNotEmpty) masked,
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.onBrightness(
          light: const Color(0xFFF0FBF4),
          dark: AppColors.darkSurface,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.onBrightness(
            light: const Color(0xFFB7E4C7),
            dark: AppColors.darkBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 20,
            color: AppColors.forest700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.registerKycVerifiedTitle,
                  style: body(
                    12,
                    weight: FontWeight.w700,
                    color: context.onBrightness(
                      light: AppColors.forest800,
                      dark: AppColors.forest300,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail.isEmpty ? t.registerKycSavedOnSignup : detail,
                  style: body(
                    11,
                    color: context.onBrightness(
                      light: AppColors.forest700,
                      dark: AppColors.forest300,
                    ),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, {String? hint}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: RichText(
      text: TextSpan(
        style: body(
          13,
          weight: FontWeight.w700,
          color: context.onBrightness(
            light: AppColors.forest800,
            dark: AppColors.forest300,
          ),
        ),
        children: [
          TextSpan(text: text),
          if (hint != null)
            TextSpan(
              text: ' $hint',
              style: body(
                12,
                weight: FontWeight.w500,
                color: context.onBrightness(
                  light: AppColors.textMuted,
                  dark: AppColors.darkTextMuted,
                ),
              ),
            ),
        ],
      ),
    ),
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
            color: active
                ? AppColors.forest800
                : context.onBrightness(
                    light: Colors.white,
                    dark: AppColors.darkBg,
                  ),
            border: Border.all(
              color: active
                  ? AppColors.forest800
                  : context.onBrightness(
                      light: AppColors.border,
                      dark: AppColors.darkBorder,
                    ),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: body(
              13,
              weight: FontWeight.w600,
              color: active
                  ? Colors.white
                  : context.onBrightness(
                      light: AppColors.label,
                      dark: AppColors.darkText,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _yesNoButton(bool value, String label) {
    final active = _isPurohit == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isPurohit = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? AppColors.forest800
                : context.onBrightness(
                    light: Colors.white,
                    dark: AppColors.darkBg,
                  ),
            border: Border.all(
              color: active
                  ? AppColors.forest800
                  : context.onBrightness(
                      light: AppColors.border,
                      dark: AppColors.darkBorder,
                    ),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: body(
              13,
              weight: FontWeight.w600,
              color: active
                  ? Colors.white
                  : context.onBrightness(
                      light: AppColors.label,
                      dark: AppColors.darkText,
                    ),
            ),
          ),
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
      inputFormatters: digitsOnly
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      onChanged: (_) {
        if (_error.isNotEmpty) setState(() => _error = '');
      },
      style: body(
        14,
        color: context.onBrightness(
          light: AppColors.ink,
          dark: AppColors.darkText,
        ),
      ),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: context.onBrightness(
          light: Colors.white,
          dark: AppColors.darkBg,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
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
            t.registerHeroHeadline,
            style: display(24, color: Colors.white, height: 1.25),
          ),
          const SizedBox(height: 10),
          Text(
            t.registerHeroBody,
            style: body(13, color: AppColors.forest300, height: 1.5),
          ),
        ],
      ),
    );
  }
}
