import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

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
      'education', 'company', 'designation', 'income',
      'fatherOccupation', 'motherOccupation', 'siblings',
      'star', 'rashi', 'timeOfBirth', 'about',
    ])
      k: TextEditingController(),
  };

  final _expectations = TextEditingController();
  final _gotraExclusions = TextEditingController();
  final _preferredLocations = TextEditingController();

  int? _heightCm;
  String _complexion = '';
  String _familyType = '';
  bool? _mangal;
  int? _partnerAgeMin;
  int? _partnerAgeMax;

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
        _expectations.text = _joinLines(p['partnerExpectations']);
        _gotraExclusions.text = _joinCommas(p['partnerGotraExclusions']);
        _preferredLocations.text = _joinCommas(p['partnerPreferredLocations']);
        _heightCm = (p['heightCm'] as num?)?.toInt();
        _complexion = (p['complexion'] ?? '').toString();
        _familyType = (p['familyType'] ?? '').toString();
        _mangal = p['mangal'] as bool?;
        _partnerAgeMin = (p['partnerAgeMin'] as num?)?.toInt();
        _partnerAgeMax = (p['partnerAgeMax'] as num?)?.toInt();
        _marriageIntention = (p['marriageIntention'] ?? '').toString();
        _childrenPreference = (p['childrenPreference'] ?? '').toString();
        _familyPreference = (p['familyPreference'] ?? '').toString();
        _relocationPreference = (p['relocationPreference'] ?? '').toString();
        _foodPreference = (p['foodPreference'] ?? '').toString();
        _interests
          ..clear()
          ..addAll((p['interests'] as List?)?.map((e) => e.toString()) ?? const []);
      }
      setState(() => _loading = false);
    } catch (e) {
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

  List<String> _splitLines(String s) => s
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  List<String> _splitCommas(String s) => s
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_partnerAgeMin != null &&
        _partnerAgeMax != null &&
        _partnerAgeMin! > _partnerAgeMax!) {
      _snack(AppLocalizations.of(context).matAgeFromToError);
      return;
    }

    setState(() => _saving = true);
    try {
      // Only send what has a value — the API treats every field as optional so
      // a half-filled draft saves cleanly.
      await Repository.instance.saveMatrimonialProfile({
        for (final e in _c.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
        if (_heightCm != null) 'heightCm': _heightCm,
        if (_complexion.isNotEmpty) 'complexion': _complexion,
        if (_familyType.isNotEmpty) 'familyType': _familyType,
        if (_mangal != null) 'mangal': _mangal,
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
      _snack(e is ApiException
          ? e.message
          : AppLocalizations.of(context).matCouldNotSaveDetails);
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
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forest800,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(AppLocalizations.of(context).matEditTitle,
            style: display(18, color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: body(14, color: AppColors.textMuted)))
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
          _text('company', t.matCompanyOrg),
          _text('designation', t.matDesignation),
          _text('income', t.matIncomeRange, hint: t.matIncomeRangeHint),

          const SizedBox(height: 16),
          _label(t.matSectionPhysical),
          _heightField(t),
          _choice(
              t.matComplexion,
              [
                t.matComplexionFair,
                t.matComplexionWheatish,
                t.matComplexionDusky,
                t.matComplexionDark,
              ],
              _complexion,
              (v) => setState(() => _complexion = v)),

          const SizedBox(height: 16),
          _label(t.matSectionFamily),
          _choice(t.matFamilyTypeLabel, [t.matFamilyJoint, t.matFamilyNuclear],
              _familyType, (v) => setState(() => _familyType = v)),
          _text('fatherOccupation', t.matFathersOccupation),
          _text('motherOccupation', t.matMothersOccupation),
          _text('siblings', t.matSiblings, hint: t.matSiblingsHint),

          const SizedBox(height: 16),
          _label(t.matSectionHoroscope),
          _text('star', t.matStarNakshatraLabel, hint: t.matStarHint),
          _text('rashi', t.matRashi, hint: t.matRashiHint),
          _text('timeOfBirth', t.matTimeOfBirthLabel, hint: t.matTimeOfBirthHint),
          _mangalField(t),

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
          _multiline(_expectations, t.matPartnerExpectationsLabel,
              hint: t.matOnePerLine),
          _multiline(_preferredLocations, t.matPreferredLocationsOptional,
              hint: t.matPreferredLocationsHint),
          _multiline(_gotraExclusions, t.matGotrasToExcludeOptional,
              hint: t.matGotrasToExcludeHint),

          const SizedBox(height: 16),
          _label(t.matSectionMarriagePreferences),
          _enumChoice(t.matMarriageIntention, _marriageIntentionOptionsOf(t),
              _marriageIntention, (v) => setState(() => _marriageIntention = v)),
          _enumChoice(t.matChildren, _childrenPreferenceOptionsOf(t),
              _childrenPreference, (v) => setState(() => _childrenPreference = v)),
          _enumChoice(t.matFamily2, _familyPreferenceOptionsOf(t), _familyPreference,
              (v) => setState(() => _familyPreference = v)),
          _enumChoice(t.matRelocation, _relocationPreferenceOptionsOf(t),
              _relocationPreference, (v) => setState(() => _relocationPreference = v)),

          const SizedBox(height: 16),
          _label(t.matSectionLifestyle),
          _enumChoice(t.matFoodPreference, _foodPreferenceOptionsOf(t),
              _foodPreference, (v) => setState(() => _foodPreference = v)),

          const SizedBox(height: 16),
          _label(t.matSectionInterests),
          _multiEnumChoice('', _interestOptionsOf(t), _interests),

          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.forest800,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? t.matSaving2 : t.matSaveDetails,
                  style:
                      body(15, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.matSavedAsDraftNote,
            textAlign: TextAlign.center,
            style: body(12, color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t,
            style: body(11,
                weight: FontWeight.w700,
                color: AppColors.gold700,
                letterSpacing: 1.6)),
      );

  InputDecoration _dec(String label, String? hint) => InputDecoration(
        labelText: label,
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

  Widget _text(String key, String label,
          {String? hint, int maxLines = 1, int? maxLength}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: _c[key],
          maxLines: maxLines,
          maxLength: maxLength,
          style: body(14, color: AppColors.ink),
          decoration: _dec(label, hint),
        ),
      );

  Widget _multiline(TextEditingController c, String label, {String? hint}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: c,
          maxLines: 3,
          style: body(14, color: AppColors.ink),
          decoration: _dec(label, hint),
        ),
      );

  Widget _choice(String label, List<String> options, String selected,
      ValueChanged<String> onPick) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: body(13, color: AppColors.label)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in options)
                ChoiceChip(
                  label: Text(o, style: body(13)),
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

  /// Same compact chip look as [_choice], but for a backend enum field: the
  /// map's values are what's shown on each chip, its keys are what's actually
  /// selected/saved — so the wire value (e.g. "ONE_TO_TWO_YEARS") never has
  /// to match the display label (e.g. "1–2 Years").
  Widget _enumChoice(String label, Map<String, String> wireToLabel,
      String selectedWire, ValueChanged<String> onPickWire) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: body(13, color: AppColors.label)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in wireToLabel.entries)
                ChoiceChip(
                  label: Text(entry.value, style: body(13)),
                  selected: selectedWire == entry.key,
                  onSelected: (_) => onPickWire(entry.key),
                  selectedColor: AppColors.forest300,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Multi-select variant of [_enumChoice] — any number of chips may be on at
  /// once, and tapping a selected one turns it back off. [selectedWires] is
  /// mutated in place ([Set.add]/[Set.remove]), matching how the other
  /// collection-backed fields on this screen (expectations, gotra exclusions)
  /// are edited directly rather than replaced wholesale.
  Widget _multiEnumChoice(
      String label, Map<String, String> wireToLabel, Set<String> selectedWires) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(label, style: body(13, color: AppColors.label)),
            const SizedBox(height: 6),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in wireToLabel.entries)
                FilterChip(
                  label: Text(entry.value, style: body(13)),
                  selected: selectedWires.contains(entry.key),
                  onSelected: (on) => setState(() {
                    if (on) {
                      selectedWires.add(entry.key);
                    } else {
                      selectedWires.remove(entry.key);
                    }
                  }),
                  selectedColor: AppColors.forest300,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heightField(AppLocalizations t) {
    // Centimetres, because the server stores a number so height ranges work.
    // The feet/inches echo is just so the value is recognisable.
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: _heightCm?.toString() ?? '',
        keyboardType: TextInputType.number,
        style: body(14, color: AppColors.ink),
        decoration: _dec(t.matHeightCm,
            _heightCm == null ? t.matHeightHint : _feetInches(_heightCm!)),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return null;
          final n = int.tryParse(v.trim());
          if (n == null) return t.matEnterNumberInCm;
          if (n < 120 || n > 250) return t.matHeightRangeError;
          return null;
        },
        onChanged: (v) => setState(() => _heightCm = int.tryParse(v.trim())),
      ),
    );
  }

  String _feetInches(int cm) {
    final inches = (cm / 2.54).round();
    return "${inches ~/ 12}'${inches % 12}\"";
  }

  /// Entry point to the separate, structured birth-data form the
  /// Compatibility engine needs (exact birthplace + coordinates, time of
  /// birth, accuracy) — kept out of this form since it's its own concern with
  /// its own backend resource, not another matrimonial-profile field.
  Widget _compatibilityBirthDetailsLink(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: OutlinedButton.icon(
        onPressed: () => context.push('/matrimonial/birth-details'),
        icon: const Icon(Icons.auto_awesome_rounded, size: 16),
        label: Text(t.matAddBirthDetailsLink,
            style: body(13, weight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forest700,
          side: const BorderSide(color: AppColors.forest700),
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// Entry point to the explicit, purpose-separated consent toggles the
  /// Compatibility engine checks before every calculation — its own screen
  /// for the same reason birth details get one: a distinct concern with its
  /// own backend resource.
  Widget _compatibilityConsentLink(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: OutlinedButton.icon(
        onPressed: () => context.push('/matrimonial/compatibility-consent'),
        icon: const Icon(Icons.privacy_tip_outlined, size: 16),
        label: Text(t.matManageConsentLink,
            style: body(13, weight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forest700,
          side: const BorderSide(color: AppColors.forest700),
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _mangalField(AppLocalizations t) {
    // Wrap, not Row: an unconstrained Row of a label + chips can overflow on
    // narrow devices — Wrap folds onto a second line instead.
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(t.matMangalDosha, style: body(13, color: AppColors.label)),
          ),
          for (final (value, label) in [(true, t.matRelocationYes), (false, t.matRelocationNo)])
            ChoiceChip(
              label: Text(label, style: body(13)),
              selected: _mangal == value,
              onSelected: (_) => setState(() => _mangal = value),
              selectedColor: AppColors.forest300,
            ),
        ],
      ),
    );
  }

  Widget _ageRangeField(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: _partnerAgeMin?.toString() ?? '',
              keyboardType: TextInputType.number,
              style: body(14, color: AppColors.ink),
              decoration: _dec(t.matPartnerAgeFrom, null),
              onChanged: (v) => _partnerAgeMin = int.tryParse(v.trim()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              initialValue: _partnerAgeMax?.toString() ?? '',
              keyboardType: TextInputType.number,
              style: body(14, color: AppColors.ink),
              decoration: _dec(t.matPartnerAgeTo, null),
              onChanged: (v) => _partnerAgeMax = int.tryParse(v.trim()),
            ),
          ),
        ],
      ),
    );
  }
}
