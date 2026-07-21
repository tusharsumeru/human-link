import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/api_client.dart';
import '../data/repository.dart';

/// Authenticated user — mirrors the web app's VVUser shape, plus a few
/// mobile-only fields (gender/bio/address/photo) the backend doesn't store.
class AppUser {
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
  final String address;
  final bool matrimonialOptIn;
  final String photoPath; // local file path to the user's photo/selfie
  final String photoUrl; // remote (MongoDB-served) photo URL
  final bool onboardingComplete; // false only for a brand-new registration
  // Aadhaar (DigiLocker) verified KYC — never store the full Aadhaar number.
  final String dob;
  final String maskedAadhaar;
  final bool verified;

  const AppUser({
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
        'matrimonialOptIn': matrimonialOptIn,
        'photoPath': photoPath,
        'photoUrl': photoUrl,
        'onboardingComplete': onboardingComplete,
        'dob': dob,
        'masked_aadhaar': maskedAadhaar,
        'verified': verified,
      };

  AppUser copyWith({
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
    bool? matrimonialOptIn,
    String? photoPath,
    String? photoUrl,
    bool? onboardingComplete,
    String? dob,
    String? maskedAadhaar,
    bool? verified,
  }) =>
      AppUser(
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
        matrimonialOptIn: matrimonialOptIn ?? this.matrimonialOptIn,
        photoPath: photoPath ?? this.photoPath,
        photoUrl: photoUrl ?? this.photoUrl,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        dob: dob ?? this.dob,
        maskedAadhaar: maskedAadhaar ?? this.maskedAadhaar,
        verified: verified ?? this.verified,
      );
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
    _loaded = true;
    notifyListeners();
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
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {/* ignore if Firebase isn't signed in */}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await prefs.remove(_tokenKey);
    notifyListeners();
  }
}
