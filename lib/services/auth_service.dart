import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/api_client.dart';
import '../data/chat_service.dart';
import '../data/repository.dart';

/// Where the member currently stays, in the parts the server stores under
/// `currentAddress` — country → state → district → taluk → city → area, then
/// the street-level detail.
///
/// [latitude]/[longitude] come back under `location`: the server geocodes the
/// written address with OpenStreetMap when it saves it, so they are usually
/// present but never guaranteed — an address it could not place has none.
///
/// Every part is a plain String, empty when unknown, because that is what the
/// server returns for a part it has nothing for.
class CurrentAddress {
  const CurrentAddress({
    this.country = '',
    this.state = '',
    this.district = '',
    this.taluk = '',
    this.city = '',
    this.area = '',
    this.street = '',
    this.landmark = '',
    this.pincode = '',
    this.latitude,
    this.longitude,
  });

  final String country;
  final String state;
  final String district;
  final String taluk;
  final String city;
  final String area;
  final String street;
  final String landmark;
  final String pincode;
  final double? latitude;
  final double? longitude;

  static const empty = CurrentAddress();

  List<String> get _parts =>
      [street, landmark, area, city, taluk, district, state, pincode, country];

  bool get isEmpty => _parts.every((p) => p.trim().isEmpty);
  bool get isNotEmpty => !isEmpty;
  bool get hasLocation => latitude != null && longitude != null;

  /// The whole address on one line, narrowest part first.
  String get oneLine =>
      _parts.map((p) => p.trim()).where((p) => p.isNotEmpty).join(', ');

  /// The half of it a member is happy to show — no street, landmark or pincode.
  String get shortLine => [area, city, district, state]
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .join(', ');

  factory CurrentAddress.fromMap(dynamic raw) {
    if (raw is! Map) return empty;
    final m = Map<String, dynamic>.from(raw);
    final loc = m['location'];
    double? coord(String key) {
      if (loc is! Map) return null;
      final v = loc[key];
      if (v is num) return v.toDouble();
      return double.tryParse((v ?? '').toString());
    }

    String part(String key) => (m[key] ?? '').toString();

    return CurrentAddress(
      country: part('country'),
      state: part('state'),
      district: part('district'),
      taluk: part('taluk'),
      city: part('city'),
      area: part('area'),
      street: part('street'),
      landmark: part('landmark'),
      pincode: part('pincode'),
      latitude: coord('latitude'),
      longitude: coord('longitude'),
    );
  }

  /// Full shape, for persisting the session locally.
  Map<String, dynamic> toMap() => {
        'country': country,
        'state': state,
        'district': district,
        'taluk': taluk,
        'city': city,
        'area': area,
        'street': street,
        'landmark': landmark,
        'pincode': pincode,
        if (hasLocation)
          'location': {'latitude': latitude, 'longitude': longitude},
      };

  /// What to send to the server — empty parts left out entirely, and null when
  /// there is no address at all, so a blank form doesn't overwrite a stored
  /// address with nothing.
  ///
  /// `location` is sent only when the device actually fixed the position (the
  /// "use my current location" path). Otherwise it is omitted so the server
  /// geocodes the parts below itself, rather than us echoing back coordinates
  /// that belong to whatever address was there before.
  Map<String, dynamic>? toRequest({bool includeLocation = false}) {
    if (isEmpty) return null;
    final m = <String, dynamic>{};
    void put(String key, String value) {
      final v = value.trim();
      if (v.isNotEmpty) m[key] = v;
    }

    put('country', country);
    put('state', state);
    put('district', district);
    put('taluk', taluk);
    put('city', city);
    put('area', area);
    put('street', street);
    put('landmark', landmark);
    put('pincode', pincode);
    if (includeLocation && hasLocation) {
      m['location'] = {'latitude': latitude, 'longitude': longitude};
    }
    return m;
  }

  CurrentAddress copyWith({
    String? country,
    String? state,
    String? district,
    String? taluk,
    String? city,
    String? area,
    String? street,
    String? landmark,
    String? pincode,
    double? latitude,
    double? longitude,
  }) =>
      CurrentAddress(
        country: country ?? this.country,
        state: state ?? this.state,
        district: district ?? this.district,
        taluk: taluk ?? this.taluk,
        city: city ?? this.city,
        area: area ?? this.area,
        street: street ?? this.street,
        landmark: landmark ?? this.landmark,
        pincode: pincode ?? this.pincode,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
      );
}

/// Authenticated user — mirrors the web app's VVUser shape, plus a few
/// mobile-only fields (gender/bio/address/photo) the backend doesn't store.
class AppUser {
  final String id; // backend users._id (needed to key chats/messages)
  final String samajId; // permanent membership number, e.g. "DS-0013467"
  final String name;
  final String userName; // backend handle (unique, e.g. "priya_test")
  final String phone;
  final String role; // "member" | "elder"
  final String gotra;
  final String native;
  final String avatar;
  // Extras — backend supports `bio`/`matrimonialOptIn`; the rest are local-only.
  final String gender;
  final String bio;
  final String occupation;
  // The old single-line address. Superseded by [currentAddress], kept because
  // Aadhaar KYC still hands back one line and older accounts only have this.
  final String address;
  final CurrentAddress currentAddress;
  final bool matrimonialOptIn;
  final String photoPath; // local file path to the user's photo/selfie
  final String photoUrl; // remote (MongoDB-served) photo URL
  final bool onboardingComplete; // false only for a brand-new registration
  // Aadhaar (DigiLocker) verified KYC — never store the full Aadhaar number.
  final String dob;
  final String maskedAadhaar;
  final bool verified;

  const AppUser({
    this.id = '',
    this.samajId = '',
    required this.name,
    this.userName = '',
    required this.phone,
    required this.role,
    required this.gotra,
    required this.native,
    required this.avatar,
    this.gender = '',
    this.bio = '',
    this.occupation = '',
    this.address = '',
    this.currentAddress = CurrentAddress.empty,
    this.matrimonialOptIn = false,
    this.photoPath = '',
    this.photoUrl = '',
    this.onboardingComplete = true,
    this.dob = '',
    this.maskedAadhaar = '',
    this.verified = false,
  });

  bool get isElder => role == 'elder';

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: (m['_id'] ?? m['id'] ?? '').toString(),
        samajId: (m['samajId'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        userName: (m['userName'] ?? '') as String,
        phone: (m['phone'] ?? '') as String,
        role: (m['role'] ?? 'member') as String,
        gotra: (m['gotra'] ?? '') as String,
        native: (m['native'] ?? '') as String,
        avatar: (m['avatar'] ?? '6') as String,
        gender: (m['gender'] ?? '') as String,
        bio: (m['bio'] ?? '') as String,
        occupation: (m['occupation'] ?? '') as String,
        address: (m['address'] ?? '') as String,
        currentAddress: CurrentAddress.fromMap(m['currentAddress']),
        matrimonialOptIn: (m['matrimonialOptIn'] ?? false) as bool,
        photoPath: (m['photoPath'] ?? '') as String,
        // Login/register return the remote photo as `profileUrl`.
        photoUrl: (m['photoUrl'] ?? m['profileUrl'] ?? '') as String,
        onboardingComplete: (m['onboardingComplete'] ?? true) as bool,
        dob: (m['dob'] ?? '') as String,
        maskedAadhaar: (m['masked_aadhaar'] ?? m['maskedAadhaar'] ?? '') as String,
        verified: (m['verified'] ?? false) as bool,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'samajId': samajId,
        'name': name,
        'userName': userName,
        'phone': phone,
        'role': role,
        'gotra': gotra,
        'native': native,
        'avatar': avatar,
        'gender': gender,
        'bio': bio,
        'occupation': occupation,
        'address': address,
        'currentAddress': currentAddress.toMap(),
        'matrimonialOptIn': matrimonialOptIn,
        'photoPath': photoPath,
        'photoUrl': photoUrl,
        'onboardingComplete': onboardingComplete,
        'dob': dob,
        'masked_aadhaar': maskedAadhaar,
        'verified': verified,
      };

  AppUser copyWith({
    String? id,
    String? samajId,
    String? name,
    String? userName,
    String? phone,
    String? role,
    String? gotra,
    String? native,
    String? avatar,
    String? gender,
    String? bio,
    String? occupation,
    String? address,
    CurrentAddress? currentAddress,
    bool? matrimonialOptIn,
    String? photoPath,
    String? photoUrl,
    bool? onboardingComplete,
    String? dob,
    String? maskedAadhaar,
    bool? verified,
  }) =>
      AppUser(
        id: id ?? this.id,
        samajId: samajId ?? this.samajId,
        name: name ?? this.name,
        userName: userName ?? this.userName,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        gotra: gotra ?? this.gotra,
        native: native ?? this.native,
        avatar: avatar ?? this.avatar,
        gender: gender ?? this.gender,
        bio: bio ?? this.bio,
        occupation: occupation ?? this.occupation,
        address: address ?? this.address,
        currentAddress: currentAddress ?? this.currentAddress,
        matrimonialOptIn: matrimonialOptIn ?? this.matrimonialOptIn,
        photoPath: photoPath ?? this.photoPath,
        photoUrl: photoUrl ?? this.photoUrl,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        dob: dob ?? this.dob,
        maskedAadhaar: maskedAadhaar ?? this.maskedAadhaar,
        verified: verified ?? this.verified,
      );
}

/// Decodes a JWT's payload claims ({sub, userName, role, …}), or null if it
/// can't be parsed.
Map<String, dynamic>? _jwtClaims(String? token) {
  if (token == null || token.isEmpty) return null;
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    return jsonDecode(payload) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

/// Holds the current session, persisted to SharedPreferences under `vv_user`
/// (same key the web app uses in localStorage).
class AuthService extends ChangeNotifier {
  AuthService({Repository? repo}) : _repo = repo ?? Repository.instance;
  final Repository _repo;

  static const _prefsKey = 'vv_user';
  static const _tokenKey = 'vv_token';

  AppUser? _user;
  String? _token;
  bool _loaded = false;

  AppUser? get user => _user;
  String? get token => _token;
  // A session is only usable with a bearer token: every protected endpoint
  // (stories, posts, likes) 401s without one. Requiring the token here means a
  // profile persisted without a token (e.g. from before tokens were issued)
  // routes to login to get one, rather than looking signed in but failing every
  // protected call.
  bool get isLoggedIn => _user != null && (_token?.isNotEmpty ?? false);
  bool get loaded => _loaded;

  Future<void> load() async {
    // Clear the session on any 401 so an expired/missing token routes to login.
    ApiAuth.onUnauthorized = _clearSession;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        _user = AppUser.fromMap(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _user = null;
      }
    }
    // Restore the bearer token so protected calls work after a restart.
    _token = prefs.getString(_tokenKey);
    ApiAuth.token = _token;
    // Repair sessions persisted before AppUser carried id/userName: the JWT
    // payload has both (sub + userName), so backfill from it. Without this,
    // "is this me?" checks (chat bubble side, hiding my own directory card)
    // compare against empty strings and silently fail.
    final claims = _jwtClaims(_token);
    if (claims != null && _user != null) {
      final sub = (claims['sub'] ?? '').toString();
      final uName = (claims['userName'] ?? '').toString();
      if ((_user!.id.isEmpty && sub.isNotEmpty) ||
          (_user!.userName.isEmpty && uName.isNotEmpty)) {
        _user = _user!.copyWith(
          id: _user!.id.isEmpty ? sub : null,
          userName: _user!.userName.isEmpty ? uName : null,
        );
      }
    }
    _loaded = true;
    notifyListeners();

    // Best-effort refresh from the backend so a restored session picks up fields
    // added since it was cached (e.g. samajId, an updated photo). Fire-and-forget:
    // the UI already rendered from the cached user; this just tops it up.
    if (isLoggedIn) unawaited(refreshFromServer());
  }

  /// Pulls the latest self-profile from `/api/user/me` and merges it over the
  /// cached session, preserving local-only fields (avatar, local photo path,
  /// onboarding flag) the backend doesn't store. Best-effort — never throws.
  Future<void> refreshFromServer() async {
    if (_user == null || !(_token?.isNotEmpty ?? false)) return;
    try {
      final data = await _repo.me();
      final merged = <String, dynamic>{..._user!.toMap(), ...data};
      // The backend returns the photo as `profileUrl`; prefer it only when set so
      // a server photo wins but a blank one never wipes the local photo.
      final serverPhoto = (data['profileUrl'] ?? '').toString();
      if (serverPhoto.isNotEmpty) merged['photoUrl'] = serverPhoto;
      await _persist(AppUser.fromMap(merged));
    } catch (_) {/* offline / endpoint unavailable — keep the cached user */}
  }

  /// Logs in via the API. Captures the JWT token for subsequent protected
  /// requests. Throws [ApiException] with a human message on failure.
  Future<AppUser> login(String phone, String otp) async {
    final res = await _repo.login(phone, otp);
    final user = AppUser.fromMap(res['user'] as Map<String, dynamic>);
    final token = (res['token'] ?? '') as String;
    await _persist(user, token: token.isEmpty ? null : token);
    return user;
  }

  /// Logs in directly with a known profile (e.g. right after registration),
  /// optionally storing the JWT so protected calls work without a re-login.
  Future<void> loginWithUser(AppUser user, {String? token}) =>
      _persist(user, token: token);

  /// Persists an updated profile (after edits in onboarding / verify).
  Future<void> updateUser(AppUser user) => _persist(user);

  Future<void> _persist(AppUser user, {String? token}) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(user.toMap()));
    if (token != null) {
      _token = token;
      ApiAuth.token = token;
      await prefs.setString(_tokenKey, token);
    }
    notifyListeners();
  }

  /// Clears the in-memory + stored session and notifies listeners so the router
  /// redirects to login. Synchronous for the memory clear (safe to call from the
  /// ApiClient 401 handler); the prefs wipe is fire-and-forget.
  void _clearSession() {
    if (_user == null && _token == null) return;
    _user = null;
    _token = null;
    ApiAuth.token = null;
    ChatService.instance.disconnect();
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_prefsKey);
      prefs.remove(_tokenKey);
    });
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    ApiAuth.token = null;
    ChatService.instance.disconnect();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {/* ignore if Firebase isn't signed in */}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await prefs.remove(_tokenKey);
    notifyListeners();
  }
}
