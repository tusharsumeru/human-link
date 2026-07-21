import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
import '../theme/app_theme.dart';

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
      }
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Could not load your details';
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
      _snack('Preferred partner age: "from" cannot be greater than "to"');
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
      });
      if (!mounted) return;
      _snack('Matrimonial details saved');
      if (context.canPop()) context.pop();
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Could not save your details');
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
        title: Text('Matrimonial Details',
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
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _label('CAREER'),
          _text('education', 'Education',
              hint: 'e.g. MBA Finance, IIM Bangalore'),
          _text('company', 'Company / organisation'),
          _text('designation', 'Designation'),
          _text('income', 'Income range', hint: 'e.g. ₹22–28L'),

          const SizedBox(height: 16),
          _label('PHYSICAL'),
          _heightField(),
          _choice('Complexion', const ['Fair', 'Wheatish', 'Dusky', 'Dark'],
              _complexion, (v) => setState(() => _complexion = v)),

          const SizedBox(height: 16),
          _label('FAMILY'),
          _choice('Family type', const ['Joint', 'Nuclear'], _familyType,
              (v) => setState(() => _familyType = v)),
          _text('fatherOccupation', "Father's occupation"),
          _text('motherOccupation', "Mother's occupation"),
          _text('siblings', 'Siblings', hint: 'e.g. 1 younger brother, B.Tech'),

          const SizedBox(height: 16),
          _label('HOROSCOPE'),
          _text('star', 'Star (nakshatra)', hint: 'e.g. Rohini'),
          _text('rashi', 'Rashi', hint: 'e.g. Vrishabha'),
          _text('timeOfBirth', 'Time of birth', hint: 'e.g. 10:45 AM'),
          _mangalField(),

          const SizedBox(height: 16),
          _label('ABOUT YOU'),
          _text('about', 'About you', maxLines: 4, maxLength: 2000),

          const SizedBox(height: 16),
          _label('WHAT YOU ARE LOOKING FOR'),
          _ageRangeField(),
          _multiline(_expectations, 'Partner expectations',
              hint: 'One per line'),
          _multiline(_preferredLocations, 'Preferred locations (optional)',
              hint: 'Comma separated, e.g. Bengaluru, Mangaluru'),
          _multiline(_gotraExclusions, 'Gotras to exclude (optional)',
              hint: 'Comma separated. Your own gotra is always excluded.'),

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
              child: Text(_saving ? 'Saving…' : 'Save details',
                  style:
                      body(15, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Saved privately as a draft. You publish it from the Matrimonial section once everything is filled in.',
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

  Widget _heightField() {
    // Centimetres, because the server stores a number so height ranges work.
    // The feet/inches echo is just so the value is recognisable.
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: _heightCm?.toString() ?? '',
        keyboardType: TextInputType.number,
        style: body(14, color: AppColors.ink),
        decoration: _dec('Height (cm)',
            _heightCm == null ? 'e.g. 163' : _feetInches(_heightCm!)),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return null;
          final n = int.tryParse(v.trim());
          if (n == null) return 'Enter a number in centimetres';
          if (n < 120 || n > 250) return 'Height must be between 120 and 250 cm';
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

  Widget _mangalField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Text('Mangal dosha', style: body(13, color: AppColors.label)),
          const SizedBox(width: 14),
          for (final (value, label) in [(true, 'Yes'), (false, 'No')])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label, style: body(13)),
                selected: _mangal == value,
                onSelected: (_) => setState(() => _mangal = value),
                selectedColor: AppColors.forest300,
              ),
            ),
        ],
      ),
    );
  }

  Widget _ageRangeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: _partnerAgeMin?.toString() ?? '',
              keyboardType: TextInputType.number,
              style: body(14, color: AppColors.ink),
              decoration: _dec('Partner age from', null),
              onChanged: (v) => _partnerAgeMin = int.tryParse(v.trim()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              initialValue: _partnerAgeMax?.toString() ?? '',
              keyboardType: TextInputType.number,
              style: body(14, color: AppColors.ink),
              decoration: _dec('Partner age to', null),
              onChanged: (v) => _partnerAgeMax = int.tryParse(v.trim()),
            ),
          ),
        ],
      ),
    );
  }
}
