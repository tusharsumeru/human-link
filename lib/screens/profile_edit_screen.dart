import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
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
  late final TextEditingController _gotra;
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
    _gotra = TextEditingController(text: u?.gotra ?? '');
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
  }

  @override
  void dispose() {
    for (final c in [
      _name, _gotra, _native, _occupation, _bio, _address,
      ..._addressFields,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onAddressEdited() {
    if (_fixIsCurrent) setState(() => _fixIsCurrent = false);
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
      _snack(addr.isEmpty
          ? 'Got your position — fill in the address parts'
          : 'Address filled in from your location');
    } on LocationFailure catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Could not read your location');
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
      _snack('Could not pick an image: $e');
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
      _snack('Photo updated');
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Could not upload the photo');
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
      helpText: 'Date of birth',
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
    setState(() => _saving = true);
    try {
      final updated = await Repository.instance.saveProfile(
        name: _name.text.trim(),
        gotra: _gotra.text.trim(),
        native: _native.text.trim(),
        occupation: _occupation.text.trim(),
        bio: _bio.text.trim(),
        address: _address.text.trim(),
        // Sent whole — the server replaces the stored address with this, and
        // geocodes it unless the device fix below travels with it.
        currentAddress:
            _currentAddress.toRequest(includeLocation: _fixIsCurrent),
        gender: _gender.isEmpty ? null : _gender,
        dob: _dobIso.isEmpty ? null : _dobIso,
      );
      if (!mounted) return;
      // Rebuild the session user from the server's response rather than from
      // the form, so what the app holds is exactly what was stored.
      await context.read<AuthService>().updateUser(AppUser.fromMap(updated));
      if (!mounted) return;
      _snack('Profile saved');
      if (context.canPop()) context.pop();
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Could not save your profile');
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

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forest800,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Edit Profile', style: display(18, color: Colors.white)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            _photoField(name),
            const SizedBox(height: 26),

            _sectionLabel('BASIC DETAILS'),
            _text(_name, 'Full name',
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Name must be at least 2 characters'
                    : null),
            _genderField(),
            _dobField(),
            _text(_gotra, 'Gotra'),
            _text(_native, 'Native place', hint: 'e.g. Kumta, Karnataka'),
            _text(_occupation, 'Occupation', hint: 'e.g. Software Engineer'),

            const SizedBox(height: 18),
            _sectionLabel('CURRENT ADDRESS'),
            _locationRow(),
            _text(_country, 'Country', hint: 'e.g. India'),
            _text(_state, 'State', hint: 'e.g. Karnataka'),
            _text(_district, 'District', hint: 'e.g. Bangalore Urban'),
            _text(_taluk, 'Taluk', hint: 'e.g. Bangalore North'),
            _text(_city, 'City / Town / Village', hint: 'e.g. Bangalore'),
            _text(_area, 'Area / Locality', hint: 'e.g. Rajajinagar'),
            _text(_street, 'Street', hint: 'e.g. 3rd Cross, 5th Main'),
            _text(_landmark, 'Landmark', hint: 'e.g. Opposite Navrang Theatre'),
            _text(_pincode, 'PIN code',
                hint: '6 digits',
                keyboardType: TextInputType.number,
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return null;
                  return RegExp(r'^\d{6}$').hasMatch(s)
                      ? null
                      : 'PIN code must be 6 digits';
                }),

            const SizedBox(height: 18),
            _sectionLabel('ABOUT'),
            _text(_bio, 'Bio', maxLines: 3, maxLength: 500),
            _text(_address, 'Address (old, single line)', maxLines: 2),

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
                child: Text(_saving ? 'Saving…' : 'Save changes',
                    style: body(15,
                        weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Aadhaar verification is optional. Every detail here can be entered by hand — verifying only fills some of them in for you.',
              textAlign: TextAlign.center,
              style: body(12, color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoField(String name) {
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
              ? 'Add a profile photo — required for the matrimonial section'
              : 'Tap the camera to change your photo',
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
  Widget _locationRow() {
    final saved = context.read<AuthService>().user?.currentAddress;
    final hasSavedFix = saved?.hasLocation ?? false;
    final status = _fixIsCurrent && _lat != null && _lng != null
        ? 'Pinned at ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}'
        : hasSavedFix
            ? 'Already on the map. Editing the address re-pins it when you save.'
            : 'Coordinates are worked out from the address when you save.';

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
            label: Text(_locating ? 'Locating…' : 'Use my current location',
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

  Widget _genderField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Text('Gender', style: body(14, color: AppColors.label)),
          const SizedBox(width: 16),
          for (final (value, label) in [('M', 'Male'), ('F', 'Female')])
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

  Widget _dobField() {
    final age = _age;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: _pickDob,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date of birth',
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
              Text(_dobIso.isEmpty ? 'Not set' : _dobIso,
                  style: body(14,
                      color: _dobIso.isEmpty
                          ? AppColors.hint
                          : AppColors.ink)),
              const Spacer(),
              if (age != null)
                Text('$age years',
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
