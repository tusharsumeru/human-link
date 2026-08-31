import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/gotras.dart';
import '../data/kuladevatas.dart';
import '../data/models/parampara.dart';
import '../data/repository.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/location_picker_sheet.dart';
import '../widgets/pexels_image.dart';

/// Edit every detail on your own profile, by hand.
///
/// Aadhaar/DigiLocker is optional — it fills some of these in for you when you
/// use it, but it is not a prerequisite for any of them. Everything here is
/// typed in directly, so a member who never verifies can still complete their
/// profile and reach the matrimonial hub.
///
/// `userName` and `phone` are absent on purpose: the handle is fixed at
/// registration and the phone is the login identity. The server rejects both,
/// so offering the fields would be a lie.
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _native;
  late final TextEditingController _occupation;
  late final TextEditingController _bio;
  late final TextEditingController _address;

  // Current address, part by part — the shape the server stores under
  // `currentAddress` and geocodes into coordinates when it saves.
  late final TextEditingController _country;
  late final TextEditingController _state;
  late final TextEditingController _district;
  late final TextEditingController _taluk;
  late final TextEditingController _city;
  late final TextEditingController _area;
  late final TextEditingController _street;
  late final TextEditingController _landmark;
  late final TextEditingController _pincode;
  late final List<TextEditingController> _addressFields;

  String _gender = '';
  // Nullable so an incomplete profile shows an unselected dropdown rather
  // than a fabricated default. A legacy/custom value that isn't one of
  // [kDaivajnaGotras] is still kept selectable (see [_gotraOptions]) — never
  // silently dropped just because it predates this fixed list.
  String? _gotra;
  late List<String> _gotraOptions;

  // Kuladevata lives on a separate backend resource (Parampara profile, see
  // ../data/models/parampara.dart) fetched asynchronously — unlike the rest
  // of this screen's fields, it isn't available synchronously from
  // AuthService at initState time, so it starts unloaded and fills in once
  // [_loadKuladevata] resolves. [_kuladevataLoaded] gates saving it: if the
  // fetch never completed (or failed), _save() skips it entirely rather
  // than risk overwriting an existing declaration with a blank one.
  String? _kuladevata;
  List<String> _kuladevataOptions = kKuladevatas;
  bool _kuladevataLoaded = false;

  DateTime? _dob;
  String _photoUrl = '';
  bool _saving = false;
  bool _uploadingPhoto = false;
  bool _locating = false;

  // A position read from the device this session, and whether it still matches
  // what is in the fields. Editing any part clears it, because coordinates that
  // belong to the address the member has since typed over are worse than none —
  // the server geocodes the parts instead.
  double? _lat;
  double? _lng;
  bool _fixIsCurrent = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthService>().user;
    _name = TextEditingController(text: u?.name ?? '');
    final existingGotra = (u?.gotra ?? '').trim();
    _gotra = existingGotra.isEmpty ? null : existingGotra;
    _gotraOptions = existingGotra.isEmpty || kDaivajnaGotras.contains(existingGotra)
        ? kDaivajnaGotras
        : [existingGotra, ...kDaivajnaGotras];
    _native = TextEditingController(text: u?.native ?? '');
    _occupation = TextEditingController(text: u?.occupation ?? '');
    _bio = TextEditingController(text: u?.bio ?? '');
    _address = TextEditingController(text: u?.address ?? '');

    final addr = u?.currentAddress ?? CurrentAddress.empty;
    _country = TextEditingController(text: addr.country);
    _state = TextEditingController(text: addr.state);
    _district = TextEditingController(text: addr.district);
    _taluk = TextEditingController(text: addr.taluk);
    _city = TextEditingController(text: addr.city);
    _area = TextEditingController(text: addr.area);
    _street = TextEditingController(text: addr.street);
    _landmark = TextEditingController(text: addr.landmark);
    _pincode = TextEditingController(text: addr.pincode);
    _lat = addr.latitude;
    _lng = addr.longitude;
    _fixIsCurrent = false;
    // _fixIsCurrent = addr.hasLocation;
    _addressFields = [
      _country, _state, _district, _taluk, _city,
      _area, _street, _landmark, _pincode,
    ];
    for (final c in _addressFields) {
      c.addListener(_onAddressEdited);
    }

    _gender = u?.gender ?? '';
    _photoUrl = u?.photoUrl ?? '';
    final dob = u?.dob ?? '';
    if (dob.isNotEmpty) _dob = DateTime.tryParse(dob);

    _loadKuladevata();
  }

  Future<void> _loadKuladevata() async {
    try {
      final profile = await Repository.instance.myParampara();
      if (!mounted) return;
      final existing = profile.kuladevata.status == ParamparaValueStatus.provided
          ? (profile.kuladevata.customValue ?? '').trim()
          : '';
      setState(() {
        _kuladevata = existing.isEmpty ? null : existing;
        _kuladevataOptions =
            existing.isEmpty || kKuladevatas.contains(existing) ? kKuladevatas : [existing, ...kKuladevatas];
        _kuladevataLoaded = true;
      });
    } catch (_) {
      // Best-effort — the field just starts unselected if this fails, and
      // _save() skips saving it in that case too (see _kuladevataLoaded).
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name, _native, _occupation, _bio, _address,
      ..._addressFields,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onAddressEdited() {
    // if (_fixIsCurrent) setState(() => _fixIsCurrent = false);
  }

  CurrentAddress get _currentAddress => CurrentAddress(
        country: _country.text.trim(),
        state: _state.text.trim(),
        district: _district.text.trim(),
        taluk: _taluk.text.trim(),
        city: _city.text.trim(),
        area: _area.text.trim(),
        street: _street.text.trim(),
        landmark: _landmark.text.trim(),
        pincode: _pincode.text.trim(),
        latitude: _lat,
        longitude: _lng,
      );

  // ── Current location ──────────────────────────────────────────────────────

  /// Fills the address fields from the device's GPS position (reverse-geocoded
  /// via OpenStreetMap). Only fills parts that come back — anything the lookup
  /// doesn't name is left as the member typed it.
  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final parts = await currentAddressParts();
      if (!mounted) return;
      final addr = CurrentAddress.fromMap(parts);

      void fill(TextEditingController c, String value) {
        if (value.isNotEmpty) c.text = value;
      }

      fill(_country, addr.country);
      fill(_state, addr.state);
      fill(_district, addr.district);
      fill(_taluk, addr.taluk);
      fill(_city, addr.city);
      fill(_area, addr.area);
      fill(_street, addr.street);
      fill(_pincode, addr.pincode);

      // After the fills, so the listeners they triggered don't clear it again.
      setState(() {
        _lat = addr.latitude;
        _lng = addr.longitude;
        _fixIsCurrent = addr.hasLocation;
      });
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      _snack(addr.isEmpty
          ? t.editGotPositionFillParts
          : t.editAddressFilledFromLocation);
    } on LocationFailure catch (e) {
      _snack(e.message);
    } catch (_) {
      if (mounted) _snack(AppLocalizations.of(context).editCouldNotReadLocation);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  // ── Photo ─────────────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    String? path;
    try {
      final result =
          await FilePicker.platform.pickFiles(type: FileType.image);
      path = result?.files.single.path;
    } catch (e) {
      if (mounted) {
        _snack(AppLocalizations.of(context).editCouldNotPickImage('$e'));
      }
      return;
    }
    if (path == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final updated = await Repository.instance.uploadProfilePhoto(path);
      if (!mounted) return;
      final url = (updated['profileUrl'] ?? '').toString();
      setState(() => _photoUrl = url);
      // Persist straight away — the upload already changed it server-side, so
      // leaving the local session stale would misreport the profile as
      // photo-less until the next login.
      final auth = context.read<AuthService>();
      final u = auth.user;
      if (u != null) await auth.updateUser(u.copyWith(photoUrl: url));
      _snack(AppLocalizations.of(context).editPhotoUpdated);
    } catch (e) {
      if (mounted) {
        _snack(e is ApiException
            ? e.message
            : AppLocalizations.of(context).editCouldNotUploadPhoto);
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  // ── Date of birth ─────────────────────────────────────────────────────────

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25, now.month, now.day),
      // 100 years back to today: a future date of birth is never valid, and the
      // matrimonial age check is computed from whatever is chosen here.
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: AppLocalizations.of(context).editDobHelpText,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  String get _dobIso => _dob == null
      ? ''
      : '${_dob!.year.toString().padLeft(4, '0')}-'
          '${_dob!.month.toString().padLeft(2, '0')}-'
          '${_dob!.day.toString().padLeft(2, '0')}';

  int? get _age {
    if (_dob == null) return null;
    final now = DateTime.now();
    var age = now.year - _dob!.year;
    if (now.month < _dob!.month ||
        (now.month == _dob!.month && now.day < _dob!.day)) {
      age -= 1;
    }
    return age;
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final t = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      final updated = await Repository.instance.saveProfile(
        name: _name.text.trim(),
        gotra: _gotra ?? '',
        native: _native.text.trim(),
        occupation: _occupation.text.trim(),
        bio: _bio.text.trim(),
        address: _address.text.trim(),
        // Sent whole — the server replaces the stored address with this, and
        // geocodes it unless the device fix below travels with it.
       currentAddress:
    _currentAddress.toRequest(
      includeLocation: _lat != null && _lng != null,
    ),
        gender: _gender.isEmpty ? null : _gender,
        dob: _dobIso.isEmpty ? null : _dobIso,
      );
      if (!mounted) return;
      // Rebuild the session user from the server's response rather than from
      // the form, so what the app holds is exactly what was stored.
      await context.read<AuthService>().updateUser(AppUser.fromMap(updated));
      if (!mounted) return;
      // Also declared on the separate Parampara resource the Daivagna
      // Parampara compatibility comparison actually reads — `_gotra` comes
      // from the synchronous basic-profile value (see initState), so unlike
      // Kuladevata below there's no async-load race to guard against here.
      await Repository.instance.saveParamparaGotra(_gotra);
      if (!mounted) return;
      // Only if the existing declaration actually loaded — otherwise a slow
      // or failed fetch could send a blank value and clobber whatever was
      // already saved.
      if (_kuladevataLoaded) {
        await Repository.instance.saveKuladevata(_kuladevata);
      }
      if (!mounted) return;
      _snack(t.editProfileSaved);
      if (context.canPop()) context.pop();
    } catch (e) {
      _snack(e is ApiException ? e.message : t.editCouldNotSaveProfile);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthService>().user?.name ?? '';
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forest800,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(t.editProfileTitle, style: display(18, color: Colors.white)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            _photoField(name, t),
            const SizedBox(height: 26),

            _sectionLabel(t.editSectionBasicDetails),
            _text(_name, t.editFullName,
                validator: (v) => (v == null || v.trim().length < 2)
                    ? t.editNameTooShort
                    : null),
            _genderField(t),
            _dobField(t),
            _gotraField(t),
            _kuladevataField(t),
            _text(_native, t.editNativePlace, hint: t.editNativePlaceHint),
            _text(_occupation, t.editOccupation, hint: t.editOccupationHint),

            const SizedBox(height: 18),
            _sectionLabel(t.editSectionCurrentAddress),
            _locationRow(t),
            _text(_country, t.editCountry, hint: t.editCountryHint),
            _text(_state, t.editState, hint: t.editStateHint),
            _text(_district, t.editDistrict, hint: t.editDistrictHint),
            _text(_taluk, t.editTaluk, hint: t.editTalukHint),
            _text(_city, t.editCity, hint: t.editCityHint),
            _text(_area, t.editArea, hint: t.editAreaHint),
            _text(_street, t.editStreet, hint: t.editStreetHint),
            _text(_landmark, t.editLandmark, hint: t.editLandmarkHint),
            _text(_pincode, t.editPincode,
                hint: t.editPincodeHint,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return null;
                  return RegExp(r'^\d{6}$').hasMatch(s)
                      ? null
                      : t.editPincodeInvalid;
                }),

            const SizedBox(height: 18),
            _sectionLabel(t.editSectionAbout),
            _text(_bio, t.editBio, maxLines: 3, maxLength: 500),
            _text(_address, t.editAddressOldSingleLine, maxLines: 2),

            const SizedBox(height: 26),
            SizedBox(
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.forest800,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? t.editSaving : t.editSaveChanges,
                    style: body(15,
                        weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              t.editAadhaarOptionalNote,
              textAlign: TextAlign.center,
              style: body(12, color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoField(String name, AppLocalizations t) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            SizedBox(
              width: 104,
              height: 104,
              child: ClipOval(
                child: _photoUrl.isNotEmpty
                    ? Image.network(_photoUrl, fit: BoxFit.cover)
                    : PexelsImage(url: '', name: name, size: 104),
              ),
            ),
            Material(
              color: AppColors.forest800,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _uploadingPhoto ? null : _pickPhoto,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _uploadingPhoto
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.photo_camera_rounded,
                          size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _photoUrl.isEmpty
              ? t.editAddPhotoRequired
              : t.editTapCameraToChange,
          textAlign: TextAlign.center,
          style: body(12,
              color: _photoUrl.isEmpty ? AppColors.gold700 : AppColors.textMuted,
              weight: _photoUrl.isEmpty ? FontWeight.w600 : FontWeight.w400),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: body(11,
                weight: FontWeight.w700,
                color: AppColors.gold700,
                letterSpacing: 1.6)),
      );

  /// "Use my current location", plus what came of it. The coordinates matter
  /// enough to show: they are what the navigation feature routes to, and a
  /// member should be able to see whether their address has them.
  Widget _locationRow(AppLocalizations t) {
    final saved = context.read<AuthService>().user?.currentAddress;
    final hasSavedFix = saved?.hasLocation ?? false;
    final status = _fixIsCurrent && _lat != null && _lng != null
        ? t.editPinnedAt(_lat!.toStringAsFixed(4), _lng!.toStringAsFixed(4))
        : hasSavedFix
            ? t.editAlreadyOnMap
            : t.editCoordinatesFromAddress;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: _locating ? null : _useCurrentLocation,
            icon: _locating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded, size: 18),
            label: Text(_locating ? t.editLocating : t.editUseCurrentLocation,
                style: body(13, weight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.forest800,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 6),
          Text(status, style: body(11, color: AppColors.textMuted, height: 1.4)),
        ],
      ),
    );
  }

  Widget _text(
    TextEditingController c,
    String label, {
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        validator: validator,
        style: body(14, color: AppColors.ink),
        decoration: InputDecoration(
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
        ),
      ),
    );
  }

  Widget _gotraField(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: _gotra,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.hint),
        style: body(14, color: AppColors.ink),
        decoration: InputDecoration(
          labelText: t.editGotra,
          hintText: t.editSelectGotra,
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
        items: _gotraOptions
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (v) => setState(() => _gotra = v),
      ),
    );
  }

  static const _kuladevataNotSet = '';

  Widget _kuladevataField(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: _kuladevata ?? _kuladevataNotSet,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.hint),
        style: body(14, color: AppColors.ink),
        decoration: InputDecoration(
          labelText: t.editKuladevata,
          hintText: t.editSelectKuladevata,
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
        items: [
          DropdownMenuItem(
            value: _kuladevataNotSet,
            child: Text(t.editNotSet, style: body(14, color: AppColors.hint)),
          ),
          for (final k in _kuladevataOptions) DropdownMenuItem(value: k, child: Text(k)),
        ],
        onChanged: (v) =>
            setState(() => _kuladevata = (v == null || v == _kuladevataNotSet) ? null : v),
      ),
    );
  }

  Widget _genderField(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Text(t.editGender, style: body(14, color: AppColors.label)),
          const SizedBox(width: 16),
          for (final (value, label) in [('M', t.editMale), ('F', t.editFemale)])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label, style: body(13)),
                selected: _gender == value,
                onSelected: (_) => setState(() => _gender = value),
                selectedColor: AppColors.forest300,
              ),
            ),
        ],
      ),
    );
  }

  Widget _dobField(AppLocalizations t) {
    final age = _age;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: _pickDob,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: t.editDobHelpText,
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
          child: Row(
            children: [
              Text(_dobIso.isEmpty ? t.editNotSet : _dobIso,
                  style: body(14,
                      color: _dobIso.isEmpty
                          ? AppColors.hint
                          : AppColors.ink)),
              const Spacer(),
              if (age != null)
                Text(t.editAgeYears(age),
                    style: body(12,
                        weight: FontWeight.w600, color: AppColors.textMuted)),
              const SizedBox(width: 8),
              const Icon(Icons.calendar_today_rounded,
                  size: 16, color: AppColors.hint),
            ],
          ),
        ),
      ),
    );
  }
}
