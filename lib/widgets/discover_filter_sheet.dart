import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ui_kit.dart';

/// Wire value (backend enum) → chip label, in render order. Kept in sync with
/// the matrimonial profile's own enums (matrimonial_edit_screen.dart) since
/// discover filters query the same fields.
const _marriageIntentionOptions = <String, String>{
  'SOON': 'Soon',
  'ONE_TO_TWO_YEARS': '1–2 Years',
  'NOT_DECIDED': 'Not Decided',
};
const _foodPreferenceOptions = <String, String>{
  'VEGETARIAN': 'Vegetarian',
  'NON_VEGETARIAN': 'Non-Vegetarian',
  'EGGETARIAN': 'Eggetarian',
  'OTHER': 'Other',
};
const _interestOptions = <String, String>{
  'TRAVEL': 'Travel',
  'MUSIC': 'Music',
  'MOVIES': 'Movies',
  'FITNESS': 'Fitness',
  'SPORTS': 'Sports',
  'READING': 'Reading',
  'COOKING': 'Cooking',
  'SPIRITUALITY': 'Spirituality',
};
const _minMatchOptions = <int, String>{
  60: '60%+',
  70: '70%+',
  80: '80%+',
  90: '90%+',
};

/// Temporary, session-only Discover Matches filters — distinct from the
/// member's saved matrimonial profile/preferences, which this never touches.
@immutable
class DiscoverFilters {
  const DiscoverFilters({
    this.minAge,
    this.maxAge,
    this.location,
    this.minMatchPercentage,
    this.marriageIntention,
    this.foodPreference,
    this.interests = const {},
  });

  final int? minAge;
  final int? maxAge;
  final String? location;
  final int? minMatchPercentage;
  final String? marriageIntention;
  final String? foodPreference;
  final Set<String> interests;

  bool get isEmpty =>
      minAge == null &&
      maxAge == null &&
      (location == null || location!.isEmpty) &&
      minMatchPercentage == null &&
      (marriageIntention == null || marriageIntention!.isEmpty) &&
      (foodPreference == null || foodPreference!.isEmpty) &&
      interests.isEmpty;

  /// One count per filter *group* left on (age, location, match, intention,
  /// food, interests) — picking several interests still counts as a single
  /// group, matching the "Filter (3)" badge asked for rather than a raw tally
  /// of every selected value.
  int get activeGroupCount => [
        minAge != null || maxAge != null,
        location != null && location!.isNotEmpty,
        minMatchPercentage != null,
        marriageIntention != null && marriageIntention!.isNotEmpty,
        foodPreference != null && foodPreference!.isNotEmpty,
        interests.isNotEmpty,
      ].where((on) => on).length;

  DiscoverFilters copyWith({
    int? minAge,
    bool clearMinAge = false,
    int? maxAge,
    bool clearMaxAge = false,
    String? location,
    int? minMatchPercentage,
    bool clearMinMatchPercentage = false,
    String? marriageIntention,
    String? foodPreference,
    Set<String>? interests,
  }) {
    return DiscoverFilters(
      minAge: clearMinAge ? null : (minAge ?? this.minAge),
      maxAge: clearMaxAge ? null : (maxAge ?? this.maxAge),
      location: location ?? this.location,
      minMatchPercentage: clearMinMatchPercentage
          ? null
          : (minMatchPercentage ?? this.minMatchPercentage),
      marriageIntention: marriageIntention ?? this.marriageIntention,
      foodPreference: foodPreference ?? this.foodPreference,
      interests: interests ?? this.interests,
    );
  }
}

/// Opens the Discover Matches filter bottom sheet, seeded with [initial].
/// Returns the filters to apply (possibly empty, from "Clear All"), or null
/// if the sheet was dismissed without a decision.
Future<DiscoverFilters?> showDiscoverFilterSheet(
  BuildContext context, {
  required DiscoverFilters initial,
}) {
  return showModalBottomSheet<DiscoverFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _DiscoverFilterSheet(initial: initial),
  );
}

class _DiscoverFilterSheet extends StatefulWidget {
  const _DiscoverFilterSheet({required this.initial});
  final DiscoverFilters initial;

  @override
  State<_DiscoverFilterSheet> createState() => _DiscoverFilterSheetState();
}

class _DiscoverFilterSheetState extends State<_DiscoverFilterSheet> {
  late final _minAgeCtrl = TextEditingController(
      text: widget.initial.minAge?.toString() ?? '');
  late final _maxAgeCtrl = TextEditingController(
      text: widget.initial.maxAge?.toString() ?? '');
  late final _locationCtrl =
      TextEditingController(text: widget.initial.location ?? '');

  int? _minMatchPercentage;
  String? _marriageIntention;
  String? _foodPreference;
  late Set<String> _interests;

  @override
  void initState() {
    super.initState();
    _minMatchPercentage = widget.initial.minMatchPercentage;
    _marriageIntention = widget.initial.marriageIntention;
    _foodPreference = widget.initial.foodPreference;
    _interests = {...widget.initial.interests};
  }

  @override
  void dispose() {
    _minAgeCtrl.dispose();
    _maxAgeCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _clearAll() {
    Navigator.of(context).pop(const DiscoverFilters());
  }

  void _apply() {
    final minAge = int.tryParse(_minAgeCtrl.text.trim());
    final maxAge = int.tryParse(_maxAgeCtrl.text.trim());
    Navigator.of(context).pop(DiscoverFilters(
      minAge: minAge,
      maxAge: maxAge,
      location: _locationCtrl.text.trim(),
      minMatchPercentage: _minMatchPercentage,
      marriageIntention: _marriageIntention,
      foodPreference: _foodPreference,
      interests: _interests,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scroll) => Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text('Filters', style: display(18, color: AppColors.forest900)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.hint),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('AGE'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _ageField(_minAgeCtrl, 'Age From')),
                        const SizedBox(width: 12),
                        Expanded(child: _ageField(_maxAgeCtrl, 'Age To')),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('LOCATION'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationCtrl,
                      style: body(14, color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: 'Preferred location',
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
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('MINIMUM MATCH'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _choiceChip('Any', _minMatchPercentage == null,
                            () => setState(() => _minMatchPercentage = null)),
                        for (final entry in _minMatchOptions.entries)
                          _choiceChip(
                              entry.value,
                              _minMatchPercentage == entry.key,
                              () => setState(
                                  () => _minMatchPercentage = entry.key)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('MARRIAGE INTENTION'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _choiceChip(
                            'Any',
                            _marriageIntention == null ||
                                _marriageIntention!.isEmpty,
                            () => setState(() => _marriageIntention = null)),
                        for (final entry in _marriageIntentionOptions.entries)
                          _choiceChip(
                              entry.value,
                              _marriageIntention == entry.key,
                              () => setState(
                                  () => _marriageIntention = entry.key)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('FOOD PREFERENCE'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _choiceChip(
                            'Any',
                            _foodPreference == null || _foodPreference!.isEmpty,
                            () => setState(() => _foodPreference = null)),
                        for (final entry in _foodPreferenceOptions.entries)
                          _choiceChip(
                              entry.value,
                              _foodPreference == entry.key,
                              () => setState(() => _foodPreference = entry.key)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('INTERESTS'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in _interestOptions.entries)
                          FilterChip(
                            label: Text(entry.value, style: body(13)),
                            selected: _interests.contains(entry.key),
                            onSelected: (on) => setState(() {
                              if (on) {
                                _interests.add(entry.key);
                              } else {
                                _interests.remove(entry.key);
                              }
                            }),
                            selectedColor: AppColors.forest300,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlineButtonX(
                        label: 'Clear All',
                        onPressed: _clearAll,
                        expand: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ForestButton(
                          label: 'Apply Filters',
                          onPressed: _apply,
                          expand: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: body(11,
          weight: FontWeight.w700, color: AppColors.gold700, letterSpacing: 1.6));

  Widget _ageField(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        style: body(14, color: AppColors.ink),
        decoration: InputDecoration(
          labelText: label,
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
        ),
      );

  Widget _choiceChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label, style: body(13)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.forest300,
    );
  }
}
