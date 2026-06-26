import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repository.dart';

/// Authenticated user — mirrors the web app's VVUser shape.
class AppUser {
  final String name;
  final String phone;
  final String role; // "member" | "elder"
  final String gotra;
  final String native;
  final String avatar;

  const AppUser({
    required this.name,
    required this.phone,
    required this.role,
    required this.gotra,
    required this.native,
    required this.avatar,
  });

  bool get isElder => role == 'elder';

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        name: (m['name'] ?? '') as String,
        phone: (m['phone'] ?? '') as String,
        role: (m['role'] ?? 'member') as String,
        gotra: (m['gotra'] ?? '') as String,
        native: (m['native'] ?? '') as String,
        avatar: (m['avatar'] ?? '6') as String,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'role': role,
        'gotra': gotra,
        'native': native,
        'avatar': avatar,
      };
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

  /// Logs in directly with a known demo profile (the "Demo Profiles" tab).
  Future<void> loginWithUser(AppUser user) => _persist(user);

  Future<void> _persist(AppUser user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(user.toMap()));
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    notifyListeners();
  }
}
