import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
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

  String _gender = '';
  DateTime? _dob;
  String _photoUrl = '';
  bool _saving = false;
  bool _uploadingPhoto = false;

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
    _gender = u?.gender ?? '';
    _photoUrl = u?.photoUrl ?? '';
    final dob = u?.dob ?? '';
    if (dob.isNotEmpty) _dob = DateTime.tryParse(dob);
  }

  @override
  void dispose() {
    for (final c in [_name, _gotra, _native, _occupation, _bio, _address]) {
      c.dispose();
    }
    super.dispose();
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
            _sectionLabel('ABOUT'),
            _text(_bio, 'Bio', maxLines: 3, maxLength: 500),
            _text(_address, 'Address', maxLines: 2),

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

  Widget _text(
    TextEditingController c,
    String label, {
    String? hint,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        maxLength: maxLength,
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
