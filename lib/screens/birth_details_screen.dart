import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/place_field.dart';

/// Human-readable labels for the compatibility spec's `birthTimeAccuracy`
/// enum, in the order they should be offered. Localized at call time — the
/// keys are the stable wire values sent to the backend.
Map<String, String> _accuracyOptionsOf(AppLocalizations t) => {
  'EXACT_DOCUMENT_VERIFIED': t.birthAccuracyExactDocument,
  'EXACT_FAMILY_CONFIRMED': t.birthAccuracyExactFamily,
  'APPROXIMATE_15_MINUTES': t.birthAccuracyApprox15,
  'APPROXIMATE_30_MINUTES': t.birthAccuracyApprox30,
  'APPROXIMATE_60_MINUTES': t.birthAccuracyApprox60,
  'UNKNOWN': t.birthAccuracyUnknown,
};
const _accuracyKeys = [
  'EXACT_DOCUMENT_VERIFIED',
  'EXACT_FAMILY_CONFIRMED',
  'APPROXIMATE_15_MINUTES',
  'APPROXIMATE_30_MINUTES',
  'APPROXIMATE_60_MINUTES',
  'UNKNOWN',
];

/// Coarse country → primary IANA timezone, so a member never types a
/// timezone by hand. Covers India (this Samaj's primary audience) plus common
/// NRI destinations seen elsewhere in the app's data; anything unmapped falls
/// back to Asia/Kolkata as the best single default for this community.
const _timezoneByCountryCode = <String, String>{
  'in': 'Asia/Kolkata',
  'us': 'America/New_York',
  'gb': 'Europe/London',
  'ae': 'Asia/Dubai',
  'sg': 'Asia/Singapore',
  'au': 'Australia/Sydney',
  'ca': 'America/Toronto',
  'de': 'Europe/Berlin',
  'my': 'Asia/Kuala_Lumpur',
  'nz': 'Pacific/Auckland',
  'qa': 'Asia/Qatar',
  'sa': 'Asia/Riyadh',
  'kw': 'Asia/Kuwait',
  'om': 'Asia/Muscat',
  'bh': 'Asia/Bahrain',
};

String _timezoneFor(String countryCode) =>
    _timezoneByCountryCode[countryCode.toLowerCase()] ?? 'Asia/Kolkata';

/// Collects the birth data the Marriage Compatibility engine needs
/// (`birth_profiles` in the compatibility spec) — date of birth and gender
/// are reused from the member's existing profile rather than re-asked here;
/// this screen only adds what compatibility specifically needs on top: exact
/// birthplace (auto-geocoded to city/state/country/lat/lon/timezone), time of
/// birth, and how confident that time is.
///
/// No astrology calculation happens here or anywhere in the Flutter app —
/// this only stores the raw inputs; the server-side engine reads them later.
class BirthDetailsScreen extends StatefulWidget {
  const BirthDetailsScreen({super.key});

  @override
  State<BirthDetailsScreen> createState() => _BirthDetailsScreenState();
}

class _BirthDetailsScreenState extends State<BirthDetailsScreen> {
  final _placeCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  String _birthCity = '';
  String _birthState = '';
  String _birthCountry = '';
  double? _latitude;
  double? _longitude;
  String _timezone = '';

  TimeOfDay? _timeOfBirth;
  String? _accuracy;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _placeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // Flat shape from BirthProfileService.findByUser — always 200, with
      // blank/UNKNOWN defaults for a member who hasn't filled this in yet.
      final profile = await Repository.instance.myBirthProfile();
      if (!mounted) return;
      setState(() {
        _birthCity = (profile['city'] ?? '').toString();
        _birthState = (profile['state'] ?? '').toString();
        _birthCountry = (profile['country'] ?? '').toString();
        _latitude = (profile['latitude'] as num?)?.toDouble();
        _longitude = (profile['longitude'] as num?)?.toDouble();
        _timezone = (profile['timezone'] ?? '').toString();
        _placeCtrl.text = [
          _birthCity,
          _birthState,
          _birthCountry,
        ].where((s) => s.isNotEmpty).join(', ');
        _timeOfBirth = _parseTime((profile['timeOfBirth'] ?? '').toString());
        final accuracy = (profile['birthTimeAccuracy'] ?? '').toString();
        _accuracy = _accuracyKeys.contains(accuracy) ? accuracy : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e is ApiException
            ? e.message
            : AppLocalizations.of(context).birthCouldNotLoad;
        _loading = false;
      });
    }
  }

  TimeOfDay? _parseTime(String hhmmss) {
    final parts = hhmmss.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  void _onPlaceSelected(Map<String, dynamic> place) {
    setState(() {
      _birthCity = (place['city'] ?? '').toString();
      _birthState = (place['state'] ?? '').toString();
      _birthCountry = (place['country'] ?? '').toString();
      _latitude = place['latitude'] as double?;
      _longitude = place['longitude'] as double?;
      _timezone = _timezoneFor((place['countryCode'] ?? '').toString());
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOfBirth ?? const TimeOfDay(hour: 12, minute: 0),
      helpText: AppLocalizations.of(context).birthTimePickerHelp,
    );
    if (picked != null) setState(() => _timeOfBirth = picked);
  }

  String get _timeIso => _timeOfBirth == null
      ? ''
      : '${_timeOfBirth!.hour.toString().padLeft(2, '0')}:'
            '${_timeOfBirth!.minute.toString().padLeft(2, '0')}:00';

  /// GROOM/BRIDE is derived from the existing profile gender rather than
  /// asked again — 'M' → GROOM, 'F' → BRIDE, matching how gender is stored
  /// everywhere else in this app (register/profile-edit screens).
  String? _roleFor(String gender) => switch (gender) {
    'M' => 'GROOM',
    'F' => 'BRIDE',
    _ => null,
  };

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    final user = context.read<AuthService>().user;
    final dob = user?.dob ?? '';
    final gender = user?.gender ?? '';
    final role = _roleFor(gender);

    if (dob.isEmpty) {
      _snack(t.birthAddDob);
      return;
    }
    if (role == null) {
      _snack(t.birthAddGender);
      return;
    }
    if (_birthCity.isEmpty ||
        _birthCountry.isEmpty ||
        _latitude == null ||
        _longitude == null) {
      _snack(t.birthSearchPlace);
      return;
    }
    if (_latitude! < -90 || _latitude! > 90) {
      _snack(t.birthInvalidLatitude);
      return;
    }
    if (_longitude! < -180 || _longitude! > 180) {
      _snack(t.birthInvalidLongitude);
      return;
    }
    if (_timezone.isEmpty) {
      _snack(t.birthNoTimezone);
      return;
    }
    if (_accuracy == null) {
      _snack(t.birthChooseAccuracy);
      return;
    }
    if (_accuracy != 'UNKNOWN' && _timeOfBirth == null) {
      _snack(t.birthAddTimeOrUnknown);
      return;
    }

    setState(() => _saving = true);
    try {
      // Flat, matching UpsertBirthProfileDto exactly. dateOfBirth and
      // traditionalRole are deliberately not sent: the server reads DOB live
      // off the account (validated above against the same value) and does
      // not store a role at all — GROOM/BRIDE is derived from gender
      // wherever the compatibility engine needs it, not persisted here.
      await Repository.instance.saveBirthProfile({
        if (_timeIso.isNotEmpty) 'timeOfBirth': _timeIso,
        'city': _birthCity,
        if (_birthState.isNotEmpty) 'state': _birthState,
        'country': _birthCountry,
        'latitude': _latitude,
        'longitude': _longitude,
        'timezone': _timezone,
        'birthTimeAccuracy': _accuracy,
      });
      if (!mounted) return;
      _snack(t.birthSaved);
      if (context.canPop()) context.pop();
    } catch (e) {
      _snack(e is ApiException ? e.message : t.birthCouldNotSave);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.onBrightness(
        light: AppColors.cream,
        dark: AppColors.darkBg,
      ),
      appBar: AppBar(
        backgroundColor: AppColors.forest800,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(t.birthTitle, style: display(18, color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Text(
                _loadError!,
                style: body(
                  14,
                  color: context.onBrightness(
                    light: AppColors.textMuted,
                    dark: AppColors.darkTextMuted,
                  ),
                ),
              ),
            )
          : _form(t),
    );
  }

  Widget _form(AppLocalizations t) {
    final user = context.watch<AuthService>().user;
    final dob = user?.dob ?? '';
    final gender = user?.gender ?? '';
    final role = _roleFor(gender);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text(
          t.birthDisclaimer,
          style: body(
            12,
            color: context.onBrightness(
              light: AppColors.textMuted,
              dark: AppColors.darkTextMuted,
            ),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),

        _label(t.birthFromProfile),
        _readOnlyRow(
          icon: Icons.cake_outlined,
          label: t.birthDateOfBirth,
          value: dob.isEmpty ? t.birthNotSet : dob,
          warn: dob.isEmpty,
        ),
        _readOnlyRow(
          icon: Icons.people_outline_rounded,
          label: t.birthTraditionalRole,
          value: role ?? t.birthSetGender,
          warn: role == null,
        ),

        const SizedBox(height: 16),
        _label(t.birthBirthplace),
        PlaceField(
          label: t.birthCityLabel,
          controller: _placeCtrl,
          hint: t.birthCityHint,
          onPlaceSelected: _onPlaceSelected,
        ),
        if (_latitude != null && _longitude != null) ...[
          const SizedBox(height: 10),
          _derivedSummary(t),
        ],

        const SizedBox(height: 16),
        _label(t.birthTimeOfBirth),
        _timeField(t),
        const SizedBox(height: 14),
        _accuracyField(t),

        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.forest800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? t.birthSaving : t.birthSaveButton,
              style: body(15, weight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      label,
      style: body(
        11,
        weight: FontWeight.w700,
        color: context.onBrightness(
          light: AppColors.gold700,
          dark: AppColors.goldSoft,
        ),
        letterSpacing: 1.6,
      ),
    ),
  );

  Widget _readOnlyRow({
    required IconData icon,
    required String label,
    required String value,
    bool warn = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.gold700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: body(
                    11,
                    color: context.onBrightness(
                      light: AppColors.textMuted,
                      dark: AppColors.darkTextMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: body(
                    14,
                    weight: FontWeight.w600,
                    color: warn
                        ? Colors.red.shade700
                        : context.onBrightness(
                            light: AppColors.ink,
                            dark: AppColors.darkText,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _derivedSummary(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FBF4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.birthDerivedAutomatically,
            style: body(
              11,
              weight: FontWeight.w700,
              color: AppColors.forest700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.birthLatLon(
              _latitude!.toStringAsFixed(4),
              _longitude!.toStringAsFixed(4),
              _timezone,
            ),
            style: body(12, color: AppColors.forest800, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _timeField(AppLocalizations t) {
    return InkWell(
      onTap: _pickTime,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 18,
              color: AppColors.gold700,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _timeOfBirth == null
                    ? t.birthNotSet
                    : _timeOfBirth!.format(context),
                style: body(
                  14,
                  weight: FontWeight.w600,
                  color: _timeOfBirth == null ? AppColors.hint : AppColors.ink,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.hint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _accuracyField(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.birthTimeAccuracy,
          style: body(
            12,
            weight: FontWeight.w600,
            color: context.onBrightness(
              light: AppColors.forest800,
              dark: AppColors.forest300,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _accuracy,
              isExpanded: true,
              hint: Text(
                t.birthSelectAccuracy,
                style: body(14, color: AppColors.hint),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.hint,
              ),
              style: body(13, color: AppColors.ink),
              // The field itself is always white — pin the popup to match
              // rather than let it inherit the app's dark theme surface,
              // which would leave this same ink-colored text unreadable
              // when open.
              dropdownColor: Colors.white,
              items: _accuracyOptionsOf(t).entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _accuracy = v),
            ),
          ),
        ),
      ],
    );
  }
}
