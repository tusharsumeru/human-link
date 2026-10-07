import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/leaf_backdrop.dart';
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

  // ── UI ────────────────────────────────────────────────────────────────────

  // The palette this screen is drawn with, read off the botanical canvas
  // rather than the default page surface — [LeafCanvas] puts a near-black
  // green under everything in dark mode and a warm ivory in light.
  Color get _ink =>
      context.onBrightness(light: AppColors.forest900, dark: Colors.white);
  Color get _inkMuted => context.onBrightness(
    light: AppColors.textMuted,
    dark: AppColors.darkTextMuted,
  );
  Color get _accent =>
      context.onBrightness(light: AppColors.forest700, dark: AppColors.emerald);

  TextStyle get _valueStyle =>
      body(18, weight: FontWeight.w500, color: _ink, height: 1.35);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final ready = !_loading && _loadError == null;
    return LeafCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          // Just short of opaque, so the leaf the canvas paints up here reads
          // faintly through the band instead of being cut off by it. Only the
          // canvas is behind the bar — the body starts below it — so nothing
          // scrolling can show through.
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
          title: Text(t.birthTitle, style: display(20, color: Colors.white)),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? Center(
                child: Text(_loadError!, style: body(14, color: _inkMuted)),
              )
            : _form(t),
        // Nothing to save while the form is still loading or has failed, so
        // the bar is absent rather than present-and-dead.
        bottomNavigationBar: ready ? _saveBar(t) : null,
      ),
    );
  }

  Widget _form(AppLocalizations t) {
    final user = context.watch<AuthService>().user;
    final dob = user?.dob ?? '';
    final gender = user?.gender ?? '';
    final role = _roleFor(gender);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
      children: [
        Text(t.birthDisclaimer, style: body(14, color: _inkMuted, height: 1.5)),
        const SizedBox(height: 26),

        _label(t.birthFromProfile),
        _readOnlyRow(
          icon: Icons.calendar_today_rounded,
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

        const SizedBox(height: 22),
        _label(t.birthBirthplace),
        _row(
          icon: Icons.place_rounded,
          child: PlaceField(
            label: t.birthCityLabel,
            controller: _placeCtrl,
            hint: t.birthCityHint,
            onPlaceSelected: _onPlaceSelected,
            bare: true,
          ),
        ),
        if (_latitude != null && _longitude != null) _derivedSummary(t),

        const SizedBox(height: 22),
        _label(t.birthTimeOfBirth),
        _timeField(t),
        _accuracyField(t),

        const SizedBox(height: 10),
        const Center(child: LotusOrnament(ruleWidth: 52)),
      ],
    );
  }

  /// The one primary action, held at the foot of the page rather than at the
  /// end of the list. The bar fades to the canvas colour instead of being a
  /// solid block, so the last row slides under it rather than hitting an edge.
  Widget _saveBar(AppLocalizations t) {
    final ground = context.onBrightness(
      light: AppColors.ivoryLift,
      dark: AppColors.darkCanvasLift,
    );
    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        22,
        22,
        14 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ground.withValues(alpha: 0), ground, ground],
          stops: const [0, 0.5, 1],
        ),
      ),
      child: Opacity(
        opacity: _saving ? 0.6 : 1,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.forest600, AppColors.forest500],
            ),
            // A green lift rather than a grey drop, so the one primary action
            // on the page reads as lit from within.
            boxShadow: [
              BoxShadow(
                color: AppColors.forest500.withValues(alpha: 0.34),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: _saving ? null : _save,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _saving ? t.birthSaving : t.birthSaveButton,
                      style: display(17, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    if (_saving)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      // Upper-cased here rather than in the .arb files: Devanagari and
      // Kannada have no case, so this is a no-op in hi/kn.
      label.toUpperCase(),
      style: body(
        11,
        weight: FontWeight.w700,
        color: context.onBrightness(
          light: AppColors.champagneDeep,
          dark: AppColors.champagne,
        ),
        letterSpacing: 2,
      ),
    ),
  );

  /// The round green disc every row opens with.
  ///
  /// It is also the only affordance these rows have — there are no boxes and
  /// no rules on this page — so it carries the field's own subject rather
  /// than a generic glyph.
  Widget _disc(IconData icon) => Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.onBrightness(
        light: AppColors.sage,
        dark: AppColors.emerald.withValues(alpha: 0.12),
      ),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: 19, color: _accent),
  );

  /// Disc on the left, the field's own content filling the rest, and an
  /// optional chevron saying the row opens something.
  Widget _row({
    required IconData icon,
    required Widget child,
    VoidCallback? onTap,
    bool chevron = false,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _disc(icon),
          const SizedBox(width: 14),
          Expanded(child: child),
          if (chevron)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 24,
                color: _inkMuted,
              ),
            ),
        ],
      ),
    );
    return onTap == null
        ? content
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: content,
          );
  }

  /// Caption over value, the shape every row on this page shares.
  Widget _captioned(String label, String value, {bool warn = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: body(14, color: _inkMuted)),
      const SizedBox(height: 2),
      Text(
        value,
        style: warn
            ? _valueStyle.copyWith(
                color: context.onBrightness(
                  light: const Color(0xFFC62828),
                  dark: const Color(0xFFEF9A9A),
                ),
              )
            : _valueStyle,
      ),
    ],
  );

  Widget _readOnlyRow({
    required IconData icon,
    required String label,
    required String value,
    bool warn = false,
  }) => _row(
    icon: icon,
    child: _captioned(label, value, warn: warn),
  );

  /// What the geocoder made of the typed birthplace. Worth showing — these
  /// coordinates are what the Jataka is actually cast from — but as a quiet
  /// note under the city rather than the mint panel it used to be, which was
  /// the only boxed thing left on the page.
  Widget _derivedSummary(AppLocalizations t) => Padding(
    padding: const EdgeInsets.only(left: 54, bottom: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.birthDerivedAutomatically,
          style: body(
            10.5,
            weight: FontWeight.w700,
            color: _accent,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          t.birthLatLon(
            _latitude!.toStringAsFixed(4),
            _longitude!.toStringAsFixed(4),
            _timezone,
          ),
          style: body(12, color: _inkMuted, height: 1.5),
        ),
      ],
    ),
  );

  Widget _timeField(AppLocalizations t) => _row(
    icon: Icons.access_time_rounded,
    onTap: _pickTime,
    chevron: true,
    child: _captioned(
      t.birthTimeOfBirth,
      _timeOfBirth == null ? t.birthNotSet : _timeOfBirth!.format(context),
    ),
  );

  Widget _accuracyField(AppLocalizations t) {
    final picked = _accuracy == null ? null : _accuracyOptionsOf(t)[_accuracy];
    return _row(
      icon: Icons.fact_check_outlined,
      onTap: () => _pickAccuracy(t),
      chevron: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.birthTimeAccuracy, style: body(14, color: _inkMuted)),
          const SizedBox(height: 2),
          Text(
            picked ?? t.birthSelectAccuracy,
            style: picked == null
                ? _valueStyle.copyWith(
                    color: _inkMuted,
                    fontWeight: FontWeight.w400,
                  )
                : _valueStyle,
          ),
        ],
      ),
    );
  }

  /// Centred dialog rather than Material's own dropdown menu.
  ///
  /// That menu anchors itself over the field it was opened from and sizes to
  /// its widest option, so on this page it covered the rows above it and still
  /// had to clip the longest label. Centred, the list is free to be as wide as
  /// the screen allows, every option wraps in full, and nothing underneath it
  /// matters.
  Future<void> _pickAccuracy(AppLocalizations t) async {
    final options = _accuracyOptionsOf(t);
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: context.onBrightness(
          light: Colors.white,
          dark: AppColors.darkSurface,
        ),
        // Keeps a margin on every side at any screen size, so the dialog can
        // never reach an edge however long the translated options run.
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(t.birthTimeAccuracy, style: display(17, color: _ink)),
            ),
            // Flexible + scroll: six options fit on any phone today, but a
            // longer translation shouldn't overflow the dialog.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final e in options.entries)
                      InkWell(
                        onTap: () => Navigator.of(ctx).pop(e.key),
                        child: Container(
                          color: _accuracy == e.key
                              ? _accent.withValues(alpha: 0.10)
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: body(
                                    15.5,
                                    weight: _accuracy == e.key
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    height: 1.35,
                                    color: _ink,
                                  ),
                                ),
                              ),
                              if (_accuracy == e.key)
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 20,
                                    color: _accent,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
    if (chosen != null) setState(() => _accuracy = chosen);
  }
}
