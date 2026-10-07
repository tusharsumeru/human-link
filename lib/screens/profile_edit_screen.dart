import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/blood_groups.dart';
import '../data/gotras.dart';
import '../data/kuladevatas.dart';
import '../data/master_data.dart';
import '../data/models/parampara.dart';
import '../data/repository.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kuladevata_thumb.dart';
import '../widgets/leaf_backdrop.dart';
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

  // Same reasoning as [_gotra] — an unset profile shows an unselected
  // dropdown, and a legacy value that isn't one of the groups on offer just
  // starts unselected too rather than crashing DropdownButtonFormField.
  String? _bloodGroup;

  // The three admin-managed lists on this screen. Each starts as the list
  // bundled in the app so the form is usable on the first frame, and is
  // replaced once /api/master/<route> answers — see [MasterData], which falls
  // back to these same constants when the endpoint isn't there.
  List<String> _bloodGroupOptions = kBloodGroups;
  List<String> _occupationOptions = const [];

  // Same reasoning as [_bloodGroup] — an unset or unrecognized value just
  // starts unselected rather than crashing DropdownButtonFormField.
  String? _maritalStatus;
  static const _maritalStatusOptions = ['unmarried', 'divorced', 'married'];

  /// Occupation is admin-managed now, but it has always been free text on the
  /// server and this app has never shipped a list of its own. So the field
  /// adapts: a dropdown once the admin has defined options, the text box it
  /// has always been until then.
  ///
  /// The alternative — a dropdown with nothing in it — is a field a member
  /// simply cannot fill in, which is worse than the behaviour being replaced.
  String? _occupation;
  late final TextEditingController _occupationCtrl;

  // Kuladevata lives on a separate backend resource (Parampara profile, see
  // ../data/models/parampara.dart) fetched asynchronously — unlike the rest
  // of this screen's fields, it isn't available synchronously from
  // AuthService at initState time, so it starts unloaded and fills in once
  // [_loadKuladevata] resolves. [_kuladevataLoaded] gates saving it: if the
  // fetch never completed (or failed), _save() skips it entirely rather
  // than risk overwriting an existing declaration with a blank one.
  String? _kuladevata;
  List<String> _kuladevataOptions = kKuladevatas;

  /// Deity name → picture URL, as the admin set them. Empty until the list
  /// loads, at which point it replaces the bundled [kKuladevataImages] asset
  /// map for any entry the admin gave a picture.
  Map<String, String> _kuladevataImages = const {};
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
    _gotraOptions =
        existingGotra.isEmpty || kDaivajnaGotras.contains(existingGotra)
        ? kDaivajnaGotras
        : [existingGotra, ...kDaivajnaGotras];
    final existingBloodGroup = (u?.bloodGroup ?? '').trim();
    // Unlike gotra this does not pre-seed the options with the saved value:
    // _loadPickLists does that for all three lists at once, once they arrive.
    _bloodGroup = existingBloodGroup.isEmpty ? null : existingBloodGroup;
    final existingMaritalStatus = (u?.maritalStatus ?? '').trim();
    _maritalStatus = _maritalStatusOptions.contains(existingMaritalStatus)
        ? existingMaritalStatus
        : null;
    _native = TextEditingController(text: u?.native ?? '');
    final existingOccupation = (u?.occupation ?? '').trim();
    _occupation = existingOccupation.isEmpty ? null : existingOccupation;
    _occupationCtrl = TextEditingController(text: existingOccupation);
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
      _country,
      _state,
      _district,
      _taluk,
      _city,
      _area,
      _street,
      _landmark,
      _pincode,
    ];
    for (final c in _addressFields) {
      c.addListener(_onAddressEdited);
    }

    _gender = u?.gender ?? '';
    _photoUrl = u?.photoUrl ?? '';
    final dob = u?.dob ?? '';
    if (dob.isNotEmpty) _dob = DateTime.tryParse(dob);

    _loadKuladevata();
    _loadPickLists();
  }

  /// Pulls the admin-managed options for the three pick lists on this screen.
  ///
  /// Best-effort and unawaited: [MasterData] already answers with the bundled
  /// list when the server has nothing, so there is no failure case to handle
  /// and nothing to block the form on.
  Future<void> _loadPickLists() async {
    final blood = await MasterData.instance.list(
      MasterLists.bloodGroups,
      fallback: kBloodGroups,
    );
    final occupations = await MasterData.instance.list(
      MasterLists.occupations,
      fallback: const [],
    );
    if (!mounted) return;
    setState(() {
      _bloodGroupOptions = namesWith(blood, _bloodGroup);
      _occupationOptions = namesWith(occupations, _occupation);
    });
  }

  Future<void> _loadKuladevata() async {
    try {
      final profile = await Repository.instance.myParampara();
      // The suggestions are admin-managed; the member's own declaration is
      // not, and still comes from Parampara as free text.
      final suggestions = await MasterData.instance.list(
        MasterLists.kuladevatas,
        fallback: kKuladevatas,
      );
      if (!mounted) return;
      final existing =
          profile.kuladevata.status == ParamparaValueStatus.provided
          ? (profile.kuladevata.customValue ?? '').trim()
          : '';
      setState(() {
        _kuladevata = existing.isEmpty ? null : existing;
        _kuladevataOptions = namesWith(suggestions, existing);
        _kuladevataImages = {
          for (final i in suggestions)
            if (i.image.isNotEmpty) i.name: i.image,
        };
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
      _name,
      _native,
      _occupationCtrl,
      _bio,
      _address,
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
      _snack(
        addr.isEmpty
            ? t.editGotPositionFillParts
            : t.editAddressFilledFromLocation,
      );
    } on LocationFailure catch (e) {
      _snack(e.message);
    } catch (_) {
      if (mounted)
        _snack(AppLocalizations.of(context).editCouldNotReadLocation);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  // ── Photo ─────────────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    String? path;
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
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
        _snack(
          e is ApiException
              ? e.message
              : AppLocalizations.of(context).editCouldNotUploadPhoto,
        );
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
        bloodGroup: _bloodGroup,
        maritalStatus: _maritalStatus,
        native: _native.text.trim(),
        occupation: (_occupation ?? '').trim(),
        bio: _bio.text.trim(),
        address: _address.text.trim(),
        // Sent whole — the server replaces the stored address with this, and
        // geocodes it unless the device fix below travels with it.
        currentAddress: _currentAddress.toRequest(
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

  // The palette this screen is drawn with. Read off the botanical canvas
  // rather than the default page surface — [LeafCanvas] puts a near-black
  // green under everything in dark mode and a warm ivory in light, and the
  // ordinary `darkBg`/`cream` text tones are tuned for neither.
  Color get _ink =>
      context.onBrightness(light: AppColors.forest900, dark: Colors.white);
  Color get _inkMuted => context.onBrightness(
    light: AppColors.textMuted,
    dark: AppColors.darkTextMuted,
  );
  Color get _inkFaint => context.onBrightness(
    light: AppColors.hint,
    dark: AppColors.darkTextMuted.withValues(alpha: 0.7),
  );
  Color get _gold => context.onBrightness(
    light: AppColors.champagneDeep,
    dark: AppColors.champagne,
  );

  /// The accent a field takes while the keyboard is pointing at it.
  Color get _accent =>
      context.onBrightness(light: AppColors.forest700, dark: AppColors.emerald);

  /// Material's default error red is tuned for a light surface; against the
  /// near-black canvas it goes brown.
  Color get _error => context.onBrightness(
    light: const Color(0xFFC62828),
    dark: const Color(0xFFEF9A9A),
  );

  /// The hairline that closes each field off. Low enough to read as texture
  /// rather than as a box, high enough that a tap target still has an edge.
  Color get _rule => context.onBrightness(
    light: AppColors.sageEdge,
    dark: AppColors.emerald.withValues(alpha: 0.16),
  );

  TextStyle get _valueStyle =>
      body(18, weight: FontWeight.w500, color: _ink, height: 1.3);

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthService>().user?.name ?? '';
    final t = AppLocalizations.of(context);

    // The canvas wraps the Scaffold rather than sitting inside `body`, so the
    // bottom save bar is painted on the same ground as the form instead of on
    // the flat surface the Scaffold would otherwise supply under it.
    return LeafCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          // The header takes its ink from the canvas under it rather than
          // always sitting on a dark band. On ivory a forest-green block is
          // the heaviest thing on an otherwise airy page, so there the title
          // is dark on the canvas itself and only the near-black canvas gets
          // the gradient.
          foregroundColor: _ink,
          elevation: 0,
          // Status-bar glyphs follow the same split; white ones over ivory are
          // the thing you can only see is wrong on a device.
          systemOverlayStyle: context.isDarkMode
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          // Container, not DecoratedBox: flexibleSpace is laid out with loose
          // constraints and a childless DecoratedBox takes `constraints
          // .smallest` there, so the band collapses to nothing and never
          // paints. Container expands to fill instead.
          flexibleSpace: context.isDarkMode
              ? Container(
                  decoration: const BoxDecoration(
                    gradient: AppGradients.forest,
                  ),
                )
              : null,
          // A hairline instead of a shadow: the header meets the canvas
          // without a Material drop falling across the avatar below it.
          shape: Border(
            bottom: BorderSide(
              color: context.onBrightness(
                light: AppColors.sageEdge,
                dark: AppColors.forest600.withValues(alpha: 0.55),
              ),
            ),
          ),
          title: Text(t.editProfileTitle, style: display(20, color: _ink)),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
            children: [
              _photoField(name, t),
              const SizedBox(height: 30),

              _sectionLabel(t.editSectionBasicDetails),
              _text(
                _name,
                t.editFullName,
                validator: (v) => (v == null || v.trim().length < 2)
                    ? t.editNameTooShort
                    : null,
              ),
              _genderField(t),
              _maritalStatusField(t),
              _dobField(t),
              _bloodGroupField(t),
              _gotraField(t),
              _kuladevataField(t),
              _text(_native, t.editNativePlace, hint: t.editNativePlaceHint),
              _occupationField(t),

              const SizedBox(height: 14),
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
              _text(
                _pincode,
                t.editPincode,
                hint: t.editPincodeHint,
                keyboardType: TextInputType.number,
                validator: _validatePincode,
              ),

              const SizedBox(height: 14),
              _sectionLabel(t.editSectionAbout),
              _text(_bio, t.editBio, maxLines: 3, maxLength: 500),
              _text(_address, t.editAddressOldSingleLine, maxLines: 2),

              const SizedBox(height: 10),
              const Center(child: LotusOrnament(ruleWidth: 52)),
              const SizedBox(height: 14),
              Text(
                t.editAadhaarOptionalNote,
                textAlign: TextAlign.center,
                style: body(12, height: 1.5, color: _inkMuted),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _saveBar(t),
      ),
    );
  }

  String? _validatePincode(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    return RegExp(r'^\d{6}$').hasMatch(s)
        ? null
        : AppLocalizations.of(context).editPincodeInvalid;
  }

  /// The one primary action, held at the foot of a form long enough that an
  /// inline button would spend most of the session scrolled off screen.
  ///
  /// The bar is a fade to the canvas colour rather than a solid block, so the
  /// last field slides under it instead of hitting a hard edge.
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
            // on the page reads as lit from within against the dark ground.
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
                      _saving ? t.editSaving : t.editSaveChanges,
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

  Widget _photoField(String name, AppLocalizations t) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _gold.withValues(alpha: 0.85),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.onBrightness(
                      light: Colors.black.withValues(alpha: 0.10),
                      dark: AppColors.champagne.withValues(alpha: 0.16),
                    ),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SizedBox(
                width: 112,
                height: 112,
                child: ClipOval(
                  child: _photoUrl.isNotEmpty
                      ? Image.network(_photoUrl, fit: BoxFit.cover)
                      : PexelsImage(url: '', name: name, size: 112),
                ),
              ),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Material(
                color: AppColors.forest600,
                shape: CircleBorder(
                  side: BorderSide(
                    color: context.onBrightness(
                      light: AppColors.ivory,
                      dark: AppColors.darkCanvas,
                    ),
                    width: 2,
                  ),
                ),
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
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.photo_camera_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _photoUrl.isEmpty ? t.editAddPhotoRequired : t.editTapCameraToChange,
          textAlign: TextAlign.center,
          style: body(
            12.5,
            color: _photoUrl.isEmpty ? _gold : _inkMuted,
            weight: _photoUrl.isEmpty ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Text(
      // Upper-cased here rather than in the .arb files: Devanagari and
      // Kannada have no case, so this is a no-op in hi/kn and the strings stay
      // sentence-case for anything else that shows them.
      text.toUpperCase(),
      style: body(11, weight: FontWeight.w700, color: _gold, letterSpacing: 2),
    ),
  );

  /// Per-field caption sitting above the value, never floating onto a border —
  /// unlike Material's `labelText`, which shrinks onto the border line and
  /// reads poorly wherever it lands. Small caps so it never competes with the
  /// value underneath it, which is the thing actually being read.
  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text.toUpperCase(),
      style: body(
        10.5,
        weight: FontWeight.w700,
        color: _inkMuted,
        letterSpacing: 1.5,
      ),
    ),
  );

  /// Every field on this page is the same shape: a caption in small caps, the
  /// value at reading size under it, and a hairline closing it off.
  ///
  /// No boxes. On a form this long a stack of outlined rectangles is all the
  /// eye ends up seeing, and it buries the botanical ground the page is drawn
  /// on; the rules alone say where one field ends and the next begins.
  Widget _field({required String label, required Widget child}) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_fieldLabel(label), child],
    ),
  );

  /// Borderless but for the underline, which is the only thing that moves when
  /// a field takes focus — so where the keyboard is pointing is never in doubt
  /// on a page with no filled boxes to highlight.
  InputDecoration _bare(String? hint) => InputDecoration(
    hintText: hint,
    hintStyle: _valueStyle.copyWith(
      color: _inkFaint,
      fontWeight: FontWeight.w400,
    ),
    isDense: true,
    filled: false,
    contentPadding: const EdgeInsets.only(top: 4, bottom: 10),
    border: UnderlineInputBorder(borderSide: BorderSide(color: _rule)),
    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _rule)),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: _accent, width: 1.6),
    ),
    errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: _error)),
    focusedErrorBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: _error, width: 1.6),
    ),
    errorStyle: body(11.5, weight: FontWeight.w600, color: _error),
    counterStyle: body(10.5, color: _inkFaint),
  );

  Widget _text(
    TextEditingController c,
    String label, {
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => _field(
    label: label,
    child: TextFormField(
      controller: c,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      cursorColor: _accent,
      style: _valueStyle,
      decoration: _bare(hint),
    ),
  );

  /// The shared dropdown. Same caption/value/hairline shape as [_text], so a
  /// picked value and a typed one sit on the page identically — the chevron is
  /// the only thing that says which is which.
  Widget _dropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) => _field(
    label: label,
    child: DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: _inkMuted),
      style: _valueStyle,
      // The closed field and the open popup share a background here, so they
      // always match regardless of theme — unlike the "pin the popup to a
      // fixed white" workaround used by fields whose fill stays light-only.
      dropdownColor: context.onBrightness(
        light: Colors.white,
        dark: AppColors.darkSurface,
      ),
      borderRadius: BorderRadius.circular(16),
      decoration: _bare(hint),
      items: items,
      onChanged: onChanged,
    ),
  );

  Widget _gotraField(AppLocalizations t) => _dropdown<String>(
    label: t.editGotra,
    hint: t.editSelectGotra,
    value: _gotra,
    items: _gotraOptions
        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
        .toList(),
    onChanged: (v) => setState(() => _gotra = v),
  );

  Widget _bloodGroupField(AppLocalizations t) => _dropdown<String>(
    label: t.editBloodGroup,
    hint: t.editSelectBloodGroup,
    value: _bloodGroup,
    items: _bloodGroupOptions
        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
        .toList(),
    onChanged: (v) => setState(() => _bloodGroup = v),
  );

  /// Occupation — the admin's list when there is one, the original text box
  /// when there isn't. See [_occupation] for why it works both ways.
  Widget _occupationField(AppLocalizations t) {
    if (_occupationOptions.isEmpty) {
      return _field(
        label: t.editOccupation,
        child: TextFormField(
          controller: _occupationCtrl,
          cursorColor: _accent,
          style: _valueStyle,
          decoration: _bare(t.editOccupationHint),
          onChanged: (v) => _occupation = v,
        ),
      );
    }
    return _dropdown<String>(
      label: t.editOccupation,
      hint: t.editOccupationHint,
      value: _occupation,
      items: _occupationOptions
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: (v) => setState(() => _occupation = v),
    );
  }

  /// Decides matrimonial-hub access — a married member never sees it, so a
  /// change here can widen or close off that tab the moment this save lands.
  Widget _maritalStatusField(AppLocalizations t) {
    final labels = {
      'unmarried': t.editUnmarried,
      'divorced': t.editDivorced,
      'married': t.editMarried,
    };
    return _dropdown<String>(
      label: t.editMaritalStatus,
      hint: t.editSelectMaritalStatus,
      value: _maritalStatus,
      items: _maritalStatusOptions
          .map((v) => DropdownMenuItem(value: v, child: Text(labels[v]!)))
          .toList(),
      onChanged: (v) => setState(() => _maritalStatus = v),
    );
  }

  static const _kuladevataNotSet = '';

  Widget _kuladevataField(AppLocalizations t) => _dropdown<String>(
    label: t.editKuladevata,
    hint: t.editSelectKuladevata,
    value: _kuladevata ?? _kuladevataNotSet,
    items: [
      DropdownMenuItem(
        value: _kuladevataNotSet,
        child: Text(
          t.editNotSet,
          style: _valueStyle.copyWith(
            color: _inkFaint,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      for (final k in _kuladevataOptions)
        DropdownMenuItem(
          value: k,
          // The admin's uploaded picture wins; the bundled asset is what an
          // entry without one falls back to.
          child: (_kuladevataImages[k] ?? kKuladevataImages[k]) == null
              ? Text(k)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    KuladevataThumb(
                      source: (_kuladevataImages[k] ?? kKuladevataImages[k])!,
                      name: k,
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: Text(k, overflow: TextOverflow.ellipsis)),
                  ],
                ),
        ),
    ],
    onChanged: (v) => setState(
      () => _kuladevata = (v == null || v == _kuladevataNotSet) ? null : v,
    ),
  );

  /// Two choices, so a segmented pair rather than a dropdown: both options stay
  /// visible and picking either is one tap. The filled pill is the entire
  /// selection indicator — no tick, which would shift both widths as it
  /// appears.
  Widget _genderField(AppLocalizations t) => _field(
    label: t.editGender,
    child: Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          for (final (value, label) in [('M', t.editMale), ('F', t.editFemale)])
            _genderPill(value, label),
        ],
      ),
    ),
  );

  Widget _genderPill(String value, String label) {
    final selected = _gender == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.forest700, AppColors.forest600],
                  )
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.forest500.withValues(alpha: 0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: body(
              15,
              weight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : _inkMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dobField(AppLocalizations t) {
    final age = _age;
    final unset = _dobIso.isEmpty;
    return _field(
      label: t.editDobHelpText,
      child: InkWell(
        onTap: _pickDob,
        child: Container(
          padding: const EdgeInsets.only(top: 4, bottom: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: _rule)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  unset ? t.editNotSet : _dobIso,
                  style: unset
                      ? _valueStyle.copyWith(
                          color: _inkFaint,
                          fontWeight: FontWeight.w400,
                        )
                      : _valueStyle,
                ),
              ),
              if (age != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    t.editAgeYears(age),
                    style: body(
                      12.5,
                      weight: FontWeight.w600,
                      color: _inkMuted,
                    ),
                  ),
                ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 24,
                color: _inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: _locating ? null : _useCurrentLocation,
            icon: _locating
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _accent,
                    ),
                  )
                : const Icon(Icons.my_location_rounded, size: 18),
            label: Text(
              _locating ? t.editLocating : t.editUseCurrentLocation,
              // Text's own style.color always wins over the button's
              // foregroundColor — body()'s default (AppColors.ink) is
              // unreadable dark-on-dark, so it has to be set explicitly here
              // too, matching the icon.
              style: body(13.5, weight: FontWeight.w600, color: _accent),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,
              side: BorderSide(color: _accent.withValues(alpha: 0.45)),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: body(
              11.5,
              height: 1.4,
              // The full-contrast tone rather than the usual muted one — this
              // status line is the only feedback the member gets after tapping
              // "Use current location", so it has to actually be legible.
              color: context.onBrightness(
                light: AppColors.textMuted,
                dark: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
