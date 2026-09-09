import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:go_router/go_router.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// The 27 nakshatras, in their fixed traditional order. Not localized — these
/// are the same Sanskrit transliterations used throughout the compatibility
/// report (see compatibility_pdf_export.dart) regardless of app language, so
/// the dropdown's stored value always matches what the astrology engine
/// expects.
const List<String> kNakshatraOptions = [
  'Ashwini',
  'Bharani',
  'Krittika',
  'Rohini',
  'Mrigashira',
  'Ardra',
  'Punarvasu',
  'Pushya',
  'Ashlesha',
  'Magha',
  'Purva Phalguni',
  'Uttara Phalguni',
  'Hasta',
  'Chitra',
  'Swati',
  'Vishakha',
  'Anuradha',
  'Jyeshtha',
  'Mula',
  'Purva Ashadha',
  'Uttara Ashadha',
  'Shravana',
  'Dhanishta',
  'Shatabhisha',
  'Purva Bhadrapada',
  'Uttara Bhadrapada',
  'Revati',
];

/// The 12 rashis, in their fixed traditional order — same non-localization
/// reasoning as [kNakshatraOptions].
const List<String> kRashiOptions = [
  'Mesha',
  'Vrishabha',
  'Mithuna',
  'Karka',
  'Simha',
  'Kanya',
  'Tula',
  'Vrishchika',
  'Dhanu',
  'Makara',
  'Kumbha',
  'Meena',
];

/// Wire value (backend enum, matches matrimonial-profile.schema.ts) → the
/// compact label shown on its chip. Order here is the order the chips render
/// in, left to right. Localized at call time (not `const`), so English wire
/// keys always map to the active language's label.
Map<String, String> _marriageIntentionOptionsOf(AppLocalizations t) => {
  'SOON': t.matIntentionSoon,
  'ONE_TO_TWO_YEARS': t.matIntentionOneToTwoYears,
  'NOT_DECIDED': t.matIntentionNotDecided,
};
Map<String, String> _childrenPreferenceOptionsOf(AppLocalizations t) => {
  'WANT_CHILDREN': t.matChildrenWant,
  'DO_NOT_WANT_CHILDREN': t.matChildrenDontWant,
  'OPEN_TO_DISCUSS': t.matChildrenOpen,
};
Map<String, String> _familyPreferenceOptionsOf(AppLocalizations t) => {
  'JOINT_FAMILY': t.matFamilyJoint,
  'NUCLEAR_FAMILY': t.matFamilyNuclear,
  'FLEXIBLE': t.matFamilyFlexible,
};
Map<String, String> _relocationPreferenceOptionsOf(AppLocalizations t) => {
  'YES': t.matRelocationYes,
  'NO': t.matRelocationNo,
  'MAYBE': t.matRelocationMaybe,
};
Map<String, String> _occupationTypeOptionsOf(AppLocalizations t) => {
  'SALARIED': t.matOccupationSalaried,
  'SELF_EMPLOYED': t.matOccupationSelfEmployed,
  'UNEMPLOYED': t.matOccupationUnemployed,
};
Map<String, String> _foodPreferenceOptionsOf(AppLocalizations t) => {
  'VEGETARIAN': t.matFoodVegetarian,
  'NON_VEGETARIAN': t.matFoodNonVegetarian,
  'EGGETARIAN': t.matFoodEggetarian,
  'OTHER': t.matFoodOther,
};
Map<String, String> _interestOptionsOf(AppLocalizations t) => {
  'TRAVEL': t.matInterestTravel,
  'MUSIC': t.matInterestMusic,
  'MOVIES': t.matInterestMovies,
  'FITNESS': t.matInterestFitness,
  'SPORTS': t.matInterestSports,
  'READING': t.matInterestReading,
  'COOKING': t.matInterestCooking,
  'SPIRITUALITY': t.matInterestSpirituality,
};

/// The matrimonial half of a member's profile — career, physical, family,
/// horoscope and what they're looking for.
///
/// Saves as a draft (`PUT /api/matrimonial/me`), so a member can fill it in
/// over several sittings. Nothing here is visible to anyone else until the
/// member publishes; the gate screen owns that step.
class MatrimonialEditScreen extends StatefulWidget {
  const MatrimonialEditScreen({super.key});

  @override
  State<MatrimonialEditScreen> createState() => _MatrimonialEditScreenState();
}

class _MatrimonialEditScreenState extends State<MatrimonialEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _c = <String, TextEditingController>{
    for (final k in [
      'education',
      'company',
      'designation',
      'income',
      'fatherOccupation',
      'motherOccupation',
      'siblings',
      'about',
    ])
      k: TextEditingController(),
  };

  final _expectations = TextEditingController();
  final _gotraExclusions = TextEditingController();
  final _preferredLocations = TextEditingController();

  int? _heightCm;
  // Feet/inches are what the member actually types; _heightCm (still what the
  // server stores) is derived from them. Kept as separate fields rather than
  // parsed out of a single string so each box can validate independently.
  int? _heightFeet;
  int? _heightInches;
  String _occupationType = '';
  String _complexion = '';
  String _familyType = '';
  // Dropdown-backed, unlike the rest of [_c] — see [kNakshatraOptions]/
  // [kRashiOptions]. Null means nothing valid is picked (including a saved
  // free-text value from before this was a dropdown that doesn't match any
  // canonical option — see the guard in [_load]).
  String? _star;
  String? _rashi;
  int? _partnerAgeMin;
  int? _partnerAgeMax;

  // Two boxes are what the member actually fills in; _c['income'] (still
  // what's actually saved — the server only has a single free-text income
  // field, not structured min/max) is recomputed from both every time either
  // one changes, same pattern as [_heightFeet]/[_heightInches] → [_heightCm].
  int? _incomeMin;
  int? _incomeMax;

  // STEP 16 — Marriage Preferences (compact chips, wire enum values).
  String _marriageIntention = '';
  String _childrenPreference = '';
  String _familyPreference = '';
  String _relocationPreference = '';

  // STEP 17 — Lifestyle (compact chips, wire enum values).
  String _foodPreference = '';

  // STEP 18 — Interests (multi-select, wire enum values).
  final Set<String> _interests = {};

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    _expectations.dispose();
    _gotraExclusions.dispose();
    _preferredLocations.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await Repository.instance.myMatrimonialProfile();
      final p = res['profile'];
      if (!mounted) return;
      if (p is Map) {
        for (final entry in _c.entries) {
          entry.value.text = (p[entry.key] ?? '').toString();
        }
        // Best-effort split of whatever free-text income was saved before
        // ("₹22-28L", "10lpa", ...) into the two boxes — the numbers found,
        // first as "from" and second (if any) as "to". Leaves the boxes
        // blank rather than guessing when nothing numeric is there; the
        // original text stays in _c['income'] untouched until either box is
        // actually edited.
        final incomeDigits = RegExp(
          r'\d+(\.\d+)?',
        ).allMatches(_c['income']!.text).toList();
        if (incomeDigits.isNotEmpty) {
          _incomeMin = double.tryParse(incomeDigits[0].group(0)!)?.round();
        }
        if (incomeDigits.length > 1) {
          _incomeMax = double.tryParse(incomeDigits[1].group(0)!)?.round();
        }
        _expectations.text = _joinLines(p['partnerExpectations']);
        _gotraExclusions.text = _joinCommas(p['partnerGotraExclusions']);
        _preferredLocations.text = _joinCommas(p['partnerPreferredLocations']);
        _heightCm = (p['heightCm'] as num?)?.toInt();
        if (_heightCm != null) {
          final totalInches = (_heightCm! / 2.54).round();
          _heightFeet = totalInches ~/ 12;
          _heightInches = totalInches % 12;
        }
        _occupationType = (p['occupationType'] ?? '').toString();
        _complexion = (p['complexion'] ?? '').toString();
        _familyType = (p['familyType'] ?? '').toString();
        // A saved value that predates the dropdown (free text, or a
        // different transliteration) won't be one of the fixed options —
        // falling back to unset instead of passing it as initialValue
        // avoids a hard crash from DropdownButtonFormField.
        _star = kNakshatraOptions.contains(p['star'])
            ? p['star'] as String
            : null;
        _rashi = kRashiOptions.contains(p['rashi'])
            ? p['rashi'] as String
            : null;
        _partnerAgeMin = (p['partnerAgeMin'] as num?)?.toInt();
        _partnerAgeMax = (p['partnerAgeMax'] as num?)?.toInt();
        _marriageIntention = (p['marriageIntention'] ?? '').toString();
        _childrenPreference = (p['childrenPreference'] ?? '').toString();
        _familyPreference = (p['familyPreference'] ?? '').toString();
        _relocationPreference = (p['relocationPreference'] ?? '').toString();
        _foodPreference = (p['foodPreference'] ?? '').toString();
        _interests
          ..clear()
          ..addAll(
            (p['interests'] as List?)?.map((e) => e.toString()) ?? const [],
          );
      }
      setState(() => _loading = false);
    } catch (e, stackTrace) {
      debugPrint('MatrimonialEditScreen._load failed: $e');
      debugPrint('$stackTrace');
      if (!mounted) return;
      setState(() {
        _error = e is ApiException
            ? e.message
            : AppLocalizations.of(context).matCouldNotLoadDetails;
        _loading = false;
      });
    }
  }

  String _joinLines(dynamic v) =>
      v is List ? v.map((e) => e.toString()).join('\n') : '';
  String _joinCommas(dynamic v) =>
      v is List ? v.map((e) => e.toString()).join(', ') : '';

  List<String> _splitLines(String s) =>
      s.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  List<String> _splitCommas(String s) =>
      s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  /// Keeps _c['income'] — the field the server actually stores — in sync with
  /// whatever's currently in the from/to boxes. Blank when both are empty, so
  /// income stays a fully optional field like it was before.
  void _recomputeIncome() {
    final min = _incomeMin;
    final max = _incomeMax;
    if (min == null && max == null) {
      _c['income']!.text = '';
    } else if (min != null && max != null) {
      _c['income']!.text = '₹$min - ₹$max LPA';
    } else {
      _c['income']!.text = '₹${min ?? max} LPA';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_incomeMin != null && _incomeMax != null && _incomeMin! > _incomeMax!) {
      _snack(AppLocalizations.of(context).matIncomeFromToError);
      return;
    }
    if (_partnerAgeMin != null &&
        _partnerAgeMax != null &&
        _partnerAgeMin! > _partnerAgeMax!) {
      _snack(AppLocalizations.of(context).matAgeFromToError);
      return;
    }

    setState(() => _saving = true);
    try {
      // Only send what has a value — the API treats every field as optional so
      // a half-filled draft saves cleanly. Company/designation are also
      // gated on occupation type here, not just hidden in the form — a
      // leftover value from a previous "Salaried" save shouldn't resave
      // itself once the member picks something else.
      const jobOnlyFields = {'company', 'designation'};
      final isSalaried = _occupationType == 'SALARIED';
      await Repository.instance.saveMatrimonialProfile({
        for (final e in _c.entries)
          if (e.value.text.trim().isNotEmpty &&
              (isSalaried || !jobOnlyFields.contains(e.key)))
            e.key: e.value.text.trim(),
        if (_heightCm != null) 'heightCm': _heightCm,
        if (_occupationType.isNotEmpty) 'occupationType': _occupationType,
        if (_complexion.isNotEmpty) 'complexion': _complexion,
        if (_familyType.isNotEmpty) 'familyType': _familyType,
        if (_star != null) 'star': _star,
        if (_rashi != null) 'rashi': _rashi,
        if (_partnerAgeMin != null) 'partnerAgeMin': _partnerAgeMin,
        if (_partnerAgeMax != null) 'partnerAgeMax': _partnerAgeMax,
        if (_expectations.text.trim().isNotEmpty)
          'partnerExpectations': _splitLines(_expectations.text),
        if (_gotraExclusions.text.trim().isNotEmpty)
          'partnerGotraExclusions': _splitCommas(_gotraExclusions.text),
        if (_preferredLocations.text.trim().isNotEmpty)
          'partnerPreferredLocations': _splitCommas(_preferredLocations.text),
        if (_marriageIntention.isNotEmpty)
          'marriageIntention': _marriageIntention,
        if (_childrenPreference.isNotEmpty)
          'childrenPreference': _childrenPreference,
        if (_familyPreference.isNotEmpty) 'familyPreference': _familyPreference,
        if (_relocationPreference.isNotEmpty)
          'relocationPreference': _relocationPreference,
        if (_foodPreference.isNotEmpty) 'foodPreference': _foodPreference,
        if (_interests.isNotEmpty) 'interests': _interests.toList(),
      });
      if (!mounted) return;
      _snack(AppLocalizations.of(context).matDetailsSaved);
      if (context.canPop()) context.pop();
    } catch (e) {
      _snack(
        e is ApiException
            ? e.message
            : AppLocalizations.of(context).matCouldNotSaveDetails,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          AppLocalizations.of(context).matEditTitle,
          style: display(18, color: Colors.white),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: body(
                  14,
                  color: context.onBrightness(
                    light: AppColors.textMuted,
                    dark: AppColors.darkTextMuted,
                  ),
                ),
              ),
            )
          : _form(),
    );
  }

  Widget _form() {
    final t = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _label(t.matSectionCareer),
          _text('education', t.matEducation, hint: t.matEducationHint),
          _enumDropdown(
            t.matOccupationType,
            _occupationTypeOptionsOf(t),
            _occupationType,
            (v) => setState(() {
              _occupationType = v;
              // Company/designation only make sense for a salaried job —
              // clear them on any other choice so a value entered while
              // "Salaried" was picked can't linger and get saved once
              // they're hidden again.
              if (v != 'SALARIED') {
                _c['company']!.clear();
                _c['designation']!.clear();
              }
            }),
          ),
          if (_occupationType == 'SALARIED') ...[
            _text('company', t.matCompanyOrg),
            _text('designation', t.matDesignation),
          ],
          _incomeRangeField(t),

          const SizedBox(height: 16),
          _label(t.matSectionPhysical),
          _heightFields(t),
          _complexionField(t),

          const SizedBox(height: 16),
          _label(t.matSectionFamily),
          _choice(
            t.matFamilyTypeLabel,
            [t.matFamilyJoint, t.matFamilyNuclear],
            _familyType,
            (v) => setState(() => _familyType = v),
          ),
          _text('fatherOccupation', t.matFathersOccupation),
          _text('motherOccupation', t.matMothersOccupation),
          _siblingsField(t),

          const SizedBox(height: 16),
          _label(t.matSectionHoroscope),
          _stringDropdown(
            t.matStarNakshatraLabel,
            t.matStarHint,
            kNakshatraOptions,
            _star,
            (v) => setState(() => _star = v),
          ),
          _stringDropdown(
            t.matRashi,
            t.matRashiHint,
            kRashiOptions,
            _rashi,
            (v) => setState(() => _rashi = v),
          ),

          const SizedBox(height: 16),
          _label(t.matSectionCompatibility),
          _compatibilityBirthDetailsLink(t),
          _compatibilityConsentLink(t),

          const SizedBox(height: 16),
          _label(t.matSectionAboutYou),
          _text('about', t.matAboutYouLabel, maxLines: 4, maxLength: 2000),

          const SizedBox(height: 16),
          _label(t.matSectionLookingFor),
          _ageRangeField(t),
          _multiline(
            _expectations,
            t.matPartnerExpectationsLabel,
            hint: t.matOnePerLine,
          ),
          _multiline(
            _preferredLocations,
            t.matPreferredLocationsOptional,
            hint: t.matPreferredLocationsHint,
          ),
          _multiline(
            _gotraExclusions,
            t.matGotrasToExcludeOptional,
            hint: t.matGotrasToExcludeHint,
          ),

          const SizedBox(height: 16),
          _label(t.matSectionMarriagePreferences),
          _enumDropdown(
            t.matMarriageIntention,
            _marriageIntentionOptionsOf(t),
            _marriageIntention,
            (v) => setState(() => _marriageIntention = v),
          ),
          _enumDropdown(
            t.matChildren,
            _childrenPreferenceOptionsOf(t),
            _childrenPreference,
            (v) => setState(() => _childrenPreference = v),
          ),
          _enumDropdown(
            t.matFamily2,
            _familyPreferenceOptionsOf(t),
            _familyPreference,
            (v) => setState(() => _familyPreference = v),
          ),
          _enumDropdown(
            t.matRelocation,
            _relocationPreferenceOptionsOf(t),
            _relocationPreference,
            (v) => setState(() => _relocationPreference = v),
          ),

          const SizedBox(height: 16),
          _label(t.matSectionLifestyle),
          _enumDropdown(
            t.matFoodPreference,
            _foodPreferenceOptionsOf(t),
            _foodPreference,
            (v) => setState(() => _foodPreference = v),
          ),

          const SizedBox(height: 16),
          _label(t.matSectionInterests),
          _multiEnumDropdown(t.matInterests, _interestOptionsOf(t), _interests),

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
                _saving ? t.matSaving2 : t.matSaveDetails,
                style: body(15, weight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.matSavedAsDraftNote,
            textAlign: TextAlign.center,
            style: body(
              12,
              height: 1.4,
              color: context.onBrightness(
                light: AppColors.textMuted,
                dark: AppColors.darkTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      t,
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

  InputDecoration _dec(String? hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
  );

  /// Per-field caption sitting above a box, never floating onto its border —
  /// the same look [_choice]/[_enumChoice]/[_complexionField] already use for
  /// their own labels, just applied to the plain text/dropdown fields too.
  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: body(
        13,
        color: context.onBrightness(
          light: AppColors.label,
          dark: AppColors.darkText,
        ),
      ),
    ),
  );

  Widget _text(
    String key,
    String label, {
    String? hint,
    int maxLines = 1,
    int? maxLength,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        TextFormField(
          controller: _c[key],
          maxLines: maxLines,
          maxLength: maxLength,
          style: body(14, color: AppColors.ink),
          decoration: _dec(hint),
        ),
      ],
    ),
  );

  /// A plain count, not the old free-text "1 younger brother, B.Tech" field —
  /// still backed by `_c['siblings']` (a string controller, like every other
  /// field in [_c]) so it saves through the same generic loop in [_save],
  /// just constrained to digits only.
  Widget _siblingsField(AppLocalizations t) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(t.matSiblings),
        TextFormField(
          controller: _c['siblings'],
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: body(14, color: AppColors.ink),
          decoration: _dec(t.matSiblingsHint),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            final n = int.tryParse(v.trim());
            if (n == null || n < 0 || n > 20) return t.matSiblingsRangeError;
            return null;
          },
        ),
      ],
    ),
  );

  Widget _multiline(TextEditingController c, String label, {String? hint}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel(label),
            TextFormField(
              controller: c,
              maxLines: 3,
              style: body(14, color: AppColors.ink),
              decoration: _dec(hint),
            ),
          ],
        ),
      );

  Widget _choice(
    String label,
    List<String> options,
    String selected,
    ValueChanged<String> onPick,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: body(
              13,
              color: context.onBrightness(
                light: AppColors.label,
                dark: AppColors.darkText,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in options)
                ChoiceChip(
                  label: Text(
                    o,
                    style: body(
                      13,
                      color: context.onBrightness(
                        light: AppColors.ink,
                        dark: AppColors.darkText,
                      ),
                    ),
                  ),
                  selected: selected == o,
                  onSelected: (_) => onPick(o),
                  selectedColor: AppColors.forest300,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bigger, tappable cards rather than compact chips — each carries a large
  /// person emoji at that shade's actual skin-tone modifier (rendered by the
  /// system's own emoji font, so it looks like a real face rather than a
  /// flat colour dot or a monochrome icon glyph) above its label, so the
  /// shade is recognisable at a glance rather than only by word.
  Widget _complexionField(AppLocalizations t) {
    final options = [
      (t.matComplexionFair, '🧑🏻'),
      (t.matComplexionWheatish, '🧑🏼'),
      (t.matComplexionDusky, '🧑🏾'),
      (t.matComplexionDark, '🧑🏿'),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.matComplexion,
            style: body(
              13,
              color: context.onBrightness(
                light: AppColors.label,
                dark: AppColors.darkText,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final (label, face) in options)
                _ComplexionOption(
                  face: face,
                  label: label,
                  selected: _complexion == label,
                  onTap: () => setState(() => _complexion = label),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Dropdown for a backend enum field: the map's values are what's shown on
  /// each menu item, its keys are what's actually selected/saved — so the
  /// wire value (e.g. "ONE_TO_TWO_YEARS") never has to match the display
  /// label (e.g. "1–2 Years").
  Widget _enumDropdown(
    String label,
    Map<String, String> wireToLabel,
    String selectedWire,
    ValueChanged<String> onPickWire,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          DropdownButtonFormField<String>(
            initialValue: selectedWire.isEmpty ? null : selectedWire,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.hint,
            ),
            style: body(14, color: AppColors.ink),
            // The field itself is always white — pin the popup to match
            // rather than let it inherit the app's dark theme surface (which
            // would leave this same ink-colored text unreadable when open).
            dropdownColor: Colors.white,
            decoration: _dec(null),
            items: [
              for (final entry in wireToLabel.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (v) {
              if (v != null) onPickWire(v);
            },
          ),
        ],
      ),
    );
  }

  /// Same look as [_enumDropdown], for a fixed list of plain strings where
  /// the option shown on each menu item is also the value stored — e.g.
  /// [kNakshatraOptions]/[kRashiOptions], which have no separate wire code.
  /// Nullable throughout: unlike [_enumDropdown]'s enum fields, nothing was
  /// ever required here, so "nothing picked" has to stay representable.
  Widget _stringDropdown(
    String label,
    String? hint,
    List<String> options,
    String? selected,
    ValueChanged<String?> onPick,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          DropdownButtonFormField<String>(
            initialValue: selected,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.hint,
            ),
            style: body(14, color: AppColors.ink),
            dropdownColor: Colors.white,
            decoration: _dec(hint),
            items: [
              for (final o in options)
                DropdownMenuItem(value: o, child: Text(o)),
            ],
            onChanged: onPick,
          ),
        ],
      ),
    );
  }

  /// Multi-select variant of [_enumDropdown] — tapping the field opens a
  /// sheet of checkable chips (any number on at once) instead of a
  /// single-value menu; the closed field shows the picked labels joined by
  /// commas, same "tap to open, see the result inline" shape as every other
  /// dropdown on this form. [selectedWires] is mutated in place
  /// ([Set.clear]/[Set.addAll]), matching how the other collection-backed
  /// fields on this screen (expectations, gotra exclusions) are edited
  /// directly rather than replaced wholesale.
  Widget _multiEnumDropdown(
    String label,
    Map<String, String> wireToLabel,
    Set<String> selectedWires,
  ) {
    final summary = selectedWires.isEmpty
        ? null
        : selectedWires.map((w) => wireToLabel[w] ?? w).join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _pickMultiEnum(label, wireToLabel, selectedWires),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      summary ??
                          AppLocalizations.of(context).matSelectInterests,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: body(
                        14,
                        color: summary == null ? AppColors.hint : AppColors.ink,
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
          ),
        ],
      ),
    );
  }

  /// Sheet behind [_multiEnumDropdown]: every option as a toggle chip, picked
  /// state confirmed with Done rather than closing on every tap — closing
  /// immediately would make it read as a single-select despite allowing
  /// several.
  Future<void> _pickMultiEnum(
    String title,
    Map<String, String> wireToLabel,
    Set<String> selectedWires,
  ) async {
    final t = AppLocalizations.of(context);
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final picked = Set<String>.from(selectedWires);
        return StatefulBuilder(
          builder: (ctx, setSheetState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(title, style: display(17, color: AppColors.forest900)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in wireToLabel.entries)
                        FilterChip(
                          label: Text(
                            entry.value,
                            style: body(13, color: AppColors.ink),
                          ),
                          selected: picked.contains(entry.key),
                          onSelected: (on) => setSheetState(() {
                            if (on) {
                              picked.add(entry.key);
                            } else {
                              picked.remove(entry.key);
                            }
                          }),
                          selectedColor: AppColors.forest300,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ForestButton(
                    label: t.commonDone,
                    expand: true,
                    onPressed: () => Navigator.of(ctx).pop(picked),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        selectedWires
          ..clear()
          ..addAll(result);
      });
    }
  }

  Widget _heightFields(AppLocalizations t) {
    // Two independent boxes are what the member actually fills in; _heightCm
    // (still what the server stores — see the field's own doc comment) is
    // recomputed from both every time either one changes.
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel(t.matHeightFeet),
                TextFormField(
                  initialValue: _heightFeet?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  style: body(14, color: AppColors.ink),
                  decoration: _dec(t.matHeightFeetHint),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = int.tryParse(v.trim());
                    if (n == null) return t.matEnterNumberInCm;
                    if (n < 3 || n > 8) return t.matHeightFeetRangeError;
                    return null;
                  },
                  onChanged: (v) => setState(() {
                    _heightFeet = int.tryParse(v.trim());
                    _recomputeHeightCm();
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel(t.matHeightInches),
                TextFormField(
                  initialValue: _heightInches?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  style: body(14, color: AppColors.ink),
                  decoration: _dec(t.matHeightInchesHint),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = int.tryParse(v.trim());
                    if (n == null) return t.matEnterNumberInCm;
                    if (n < 0 || n > 11) return t.matHeightInchesRangeError;
                    return null;
                  },
                  onChanged: (v) => setState(() {
                    _heightInches = int.tryParse(v.trim());
                    _recomputeHeightCm();
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Keeps [_heightCm] — the field the server actually stores — in sync with
  /// whatever's currently in the feet/inches boxes. Null when both are
  /// empty, so the height stays a fully optional field like it was before.
  void _recomputeHeightCm() {
    if (_heightFeet == null && _heightInches == null) {
      _heightCm = null;
      return;
    }
    final totalInches = (_heightFeet ?? 0) * 12 + (_heightInches ?? 0);
    _heightCm = (totalInches * 2.54).round();
  }

  /// Entry point to the separate, structured birth-data form the
  /// Compatibility engine needs (exact birthplace + coordinates, time of
  /// birth, accuracy) — kept out of this form since it's its own concern with
  /// its own backend resource, not another matrimonial-profile field.
  Widget _compatibilityBirthDetailsLink(AppLocalizations t) {
    final color = context.onBrightness(
      light: AppColors.forest700,
      dark: AppColors.forest300,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: OutlinedButton.icon(
        onPressed: () => context.push('/matrimonial/birth-details'),
        icon: Icon(Icons.auto_awesome_rounded, size: 16, color: color),
        label: Text(
          t.matAddBirthDetailsLink,
          style: body(13, weight: FontWeight.w600, color: color),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Entry point to the explicit, purpose-separated consent toggles the
  /// Compatibility engine checks before every calculation — its own screen
  /// for the same reason birth details get one: a distinct concern with its
  /// own backend resource.
  Widget _compatibilityConsentLink(AppLocalizations t) {
    final color = context.onBrightness(
      light: AppColors.forest700,
      dark: AppColors.forest300,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: OutlinedButton.icon(
        onPressed: () => context.push('/matrimonial/compatibility-consent'),
        icon: Icon(Icons.privacy_tip_outlined, size: 16, color: color),
        label: Text(
          t.matManageConsentLink,
          style: body(13, weight: FontWeight.w600, color: color),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _ageRangeField(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel(t.matPartnerAgeFrom),
                TextFormField(
                  initialValue: _partnerAgeMin?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  style: body(14, color: AppColors.ink),
                  decoration: _dec(null),
                  onChanged: (v) => _partnerAgeMin = int.tryParse(v.trim()),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel(t.matPartnerAgeTo),
                TextFormField(
                  initialValue: _partnerAgeMax?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  style: body(14, color: AppColors.ink),
                  decoration: _dec(null),
                  onChanged: (v) => _partnerAgeMax = int.tryParse(v.trim()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "From" and "to" as two separate boxes rather than one free-text field,
  /// with the LPA unit shown once, outside both boxes, instead of typed into
  /// either of them.
  Widget _incomeRangeField(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(t.matIncomeRange),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel(t.matIncomeFrom),
                    TextFormField(
                      initialValue: _incomeMin?.toString() ?? '',
                      keyboardType: TextInputType.number,
                      style: body(14, color: AppColors.ink),
                      decoration: _dec(null),
                      onChanged: (v) => setState(() {
                        _incomeMin = int.tryParse(v.trim());
                        _recomputeIncome();
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel(t.matIncomeTo),
                    TextFormField(
                      initialValue: _incomeMax?.toString() ?? '',
                      keyboardType: TextInputType.number,
                      style: body(14, color: AppColors.ink),
                      decoration: _dec(null),
                      onChanged: (v) => setState(() {
                        _incomeMax = int.tryParse(v.trim());
                        _recomputeIncome();
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                // Lines up with the boxes themselves, not their labels above.
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  'LPA',
                  style: body(
                    14,
                    weight: FontWeight.w600,
                    color: context.onBrightness(
                      light: AppColors.label,
                      dark: AppColors.darkText,
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
}

/// One tappable card in [_MatrimonialEditScreenState._complexionField] — a
/// big emoji face plus its label, both switching to the selected look
/// together so the pick is obvious without relying on a checkmark alone.
class _ComplexionOption extends StatelessWidget {
  const _ComplexionOption({
    required this.face,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String face;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.forest300 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.forest700 : AppColors.creamDark,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(face, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: body(
                12,
                weight: selected ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.label,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
