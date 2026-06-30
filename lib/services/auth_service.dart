import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repository.dart';

/// Authenticated user — mirrors the web app's VVUser shape, plus a few
/// mobile-only fields (gender/bio/address/photo) the backend doesn't store.
class AppUser {
  final String name;
  final String phone;
  final String role; // "member" | "elder"
  final String gotra;
  final String native;
  final String avatar;
  // Extras — backend supports `bio`/`matrimonialOptIn`; the rest are local-only.
  final String gender;
  final String bio;
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
    required this.phone,
    required this.role,
    required this.gotra,
    required this.native,
    required this.avatar,
    this.gender = '',
    this.bio = '',
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
        phone: (m['phone'] ?? '') as String,
        role: (m['role'] ?? 'member') as String,
        gotra: (m['gotra'] ?? '') as String,
        native: (m['native'] ?? '') as String,
        avatar: (m['avatar'] ?? '6') as String,
        gender: (m['gender'] ?? '') as String,
        bio: (m['bio'] ?? '') as String,
        address: (m['address'] ?? '') as String,
        matrimonialOptIn: (m['matrimonialOptIn'] ?? false) as bool,
        photoPath: (m['photoPath'] ?? '') as String,
        photoUrl: (m['photoUrl'] ?? '') as String,
        onboardingComplete: (m['onboardingComplete'] ?? true) as bool,
        dob: (m['dob'] ?? '') as String,
        maskedAadhaar: (m['masked_aadhaar'] ?? m['maskedAadhaar'] ?? '') as String,
        verified: (m['verified'] ?? false) as bool,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'role': role,
        'gotra': gotra,
        'native': native,
        'avatar': avatar,
        'gender': gender,
        'bio': bio,
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
    String? phone,
    String? role,
    String? gotra,
    String? native,
    String? avatar,
    String? gender,
    String? bio,
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
        phone: phone ?? this.phone,
        role: role ?? this.role,
        gotra: gotra ?? this.gotra,
        native: native ?? this.native,
        avatar: avatar ?? this.avatar,
        gender: gender ?? this.gender,
        bio: bio ?? this.bio,
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

  AppUser? _user;
  bool _loaded = false;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        _user = AppUser.fromMap(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _user = null;
      }
    }
    _loaded = true;
    notifyListeners();
  }

  /// Logs in via the API (with demo fallback). Throws with a human message.
  Future<AppUser> login(String phone, String otp) async {
    final map = await _repo.login(phone, otp);
    final user = AppUser.fromMap(map);
    await _persist(user);
    return user;
  }

  /// Logs in directly with a known profile.
  Future<void> loginWithUser(AppUser user) => _persist(user);

  /// Persists an updated profile (after edits in onboarding / verify).
  Future<void> updateUser(AppUser user) => _persist(user);

  Future<void> _persist(AppUser user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(user.toMap()));
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {/* ignore if Firebase isn't signed in */}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    notifyListeners();
  }
}
