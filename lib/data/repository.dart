import 'dart:convert';

import 'api_client.dart';
import 'api_config.dart';
import 'demo_data.dart';

/// Single data source for the app.
///
/// Mirrors how the web app sources data: auth + headline stats come from the
/// Next.js API (`/api/auth/login`, `/api/stats`); the rich content (family,
/// matrimonial, welfare, directory, verifications, conflicts, invitations) is
/// the same embedded demo dataset the React pages render from `lib/data.ts`.
/// Every network call degrades gracefully to embedded data so the app always
/// runs, even with the backend offline.
class Repository {
  Repository({ApiClient? api}) : _api = api ?? ApiClient();
  final ApiClient _api;

  static final Repository instance = Repository();

  /// POST /api/auth/login — returns the authenticated user map, or throws
  /// [ApiException] with a human message ("Phone number not registered",
  /// "Invalid OTP"). Falls back to the embedded demo users on network failure.
  Future<Map<String, dynamic>> login(String phone, String otp) async {
    if (otp != '121212') {
      throw ApiException('Invalid OTP. Use 121212 for this demo.',
          statusCode: 401);
    }
    try {
      final data = await _api.postJson('/api/auth/login', {
        'phone': phone,
        'otp': otp,
      });
      if (data is Map && data['user'] is Map) {
        return Map<String, dynamic>.from(data['user'] as Map);
      }
      throw ApiException('Login failed');
    } on ApiException catch (e) {
      // 404 = genuinely not registered; surface that. Other statuses too.
      if (e.statusCode != null) rethrow;
      return _demoLogin(phone);
    } catch (_) {
      return _demoLogin(phone);
    }
  }

  /// Resolves the member profile for a phone number, after the OTP has already
  /// been verified externally (e.g. Firebase phone auth). Fetches the real
  /// profile from MongoDB via the login API; falls back to embedded demo data
  /// if the backend is unreachable or the number isn't registered.
  Future<Map<String, dynamic>> profileForPhone(String phone) async {
    try {
      // The backend login still uses the fixed demo OTP; Firebase has already
      // done the real verification, so we use it purely to fetch the profile.
      final data = await _api.postJson('/api/auth/login', {
        'phone': phone,
        'otp': '121212',
      });
      if (data is Map && data['user'] is Map) {
        return Map<String, dynamic>.from(data['user'] as Map);
      }
    } catch (_) {/* 404 / offline → fall back below */}
    return _demoLogin(phone);
  }

  Map<String, dynamic> _demoLogin(String phone) {
    final user = kTestUsers.cast<Map<String, dynamic>?>().firstWhere(
          (u) => u!['phone'] == phone,
          orElse: () => null,
        );
    if (user == null) {
      // Mirror lib/auth.ts: unknown number + correct OTP → default member.
      return {
        'name': 'Samaj Member',
        'phone': phone,
        'role': 'member',
        'gotra': 'Kashyap',
        'native': 'Karnataka',
        'avatar': '6',
      };
    }
    return Map<String, dynamic>.from(user)..remove('otp');
  }

  /// POST /api/auth/register — creates the member in MongoDB and returns the
  /// user map. Throws [ApiException] on failure: status 409 means the phone is
  /// already registered; other codes / network errors propagate to the caller.
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String gotra,
    required String native,
    String role = 'member',
    String avatar = '6',
  }) async {
    final data = await _api.postJson('/api/auth/register', {
      'name': name,
      'phone': phone,
      'gotra': gotra,
      'native': native,
      'role': role,
      'avatar': avatar,
    });
    if (data is Map && data['user'] is Map) {
      return Map<String, dynamic>.from(data['user'] as Map);
    }
    throw ApiException('Registration failed');
  }

  /// POST /api/auth/upload — uploads an image (base64) to MongoDB, keyed by
  /// phone + type ("selfie" | "id" | "familyDoc"). Returns the absolute URL to
  /// load it back, or null if the backend is unreachable.
  Future<String?> uploadImage({
    required String phone,
    required String type,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final res = await _api.postJson('/api/auth/upload', {
        'phone': phone,
        'type': type,
        'data': base64Encode(bytes),
        'contentType': contentType,
      });
      if (res is Map && res['url'] is String) {
        return '${ApiConfig.baseUrl}${res['url']}';
      }
    } catch (_) {/* offline / endpoint not deployed yet */}
    return null;
  }

  /// PATCH /api/auth/profile — saves editable profile fields. Best-effort:
  /// returns true on success, false if the backend is unreachable.
  Future<bool> updateProfile({
    required String phone,
    String? gotra,
    String? native,
    String? bio,
    bool? matrimonialOptIn,
    String? dob,
    String? gender,
    String? address,
    String? maskedAadhaar,
    bool? verified,
  }) async {
    try {
      await _api.patchJson('/api/auth/profile', {
        'phone': phone,
        'gotra': ?gotra,
        'native': ?native,
        'bio': ?bio,
        'matrimonialOptIn': ?matrimonialOptIn,
        'dob': ?dob,
        'gender': ?gender,
        'address': ?address,
        'masked_aadhaar': ?maskedAadhaar,
        'verified': ?verified,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// DigiLocker (Surepass) — start a session. Returns a map with `client_id`,
  /// the hosted `url` to open in a WebView, and `redirect_url` to watch for.
  Future<Map<String, dynamic>> digilockerInitialize() async {
    final res = await _api.postJson('/api/digilocker/initialize', {});
    if (res is Map) {
      final data = res['data'];
      if (data is Map) {
        return {
          'client_id': data['client_id'],
          // Via Link returns a URL to open; field name may vary by product.
          'url': data['url'] ?? data['link'] ?? data['digilocker_url'],
          'token': data['token'],
          'redirect_url': res['redirect_url'],
        };
      }
    }
    throw ApiException('Could not start DigiLocker');
  }

  /// DigiLocker (Surepass) — fetch the verified Aadhaar data after the user
  /// finishes the DigiLocker flow. Returns the KYC map (full_name, dob, …).
  Future<Map<String, dynamic>> digilockerAadhaar(String clientId) async {
    final res = await _api.getJson('/api/digilocker/aadhaar?client_id=$clientId');
    if (res is Map && res['data'] is Map) {
      final data = Map<String, dynamic>.from(res['data'] as Map);
      // Flatten the useful KYC block if present.
      if (data['aadhaar_xml_data'] is Map) {
        return Map<String, dynamic>.from(data['aadhaar_xml_data'] as Map);
      }
      return data;
    }
    throw ApiException('Could not fetch Aadhaar data');
  }

  /// Aadhaar (Surepass) — step 1: send OTP to the Aadhaar-linked mobile.
  /// Returns the `client_id` needed to submit the OTP. Throws [ApiException]
  /// with the server message on failure (invalid Aadhaar, not configured, …).
  Future<String> aadhaarGenerateOtp(String idNumber) async {
    final data = await _api.postJson('/api/aadhaar/generate-otp', {
      'id_number': idNumber,
    });
    if (data is Map && data['data'] is Map) {
      final clientId = (data['data'] as Map)['client_id'];
      if (clientId is String && clientId.isNotEmpty) return clientId;
    }
    throw ApiException('Could not start Aadhaar verification');
  }

  /// Aadhaar (Surepass) — step 2: submit the OTP. Returns the verified KYC
  /// data map (full_name, dob, gender, address, …). Throws on invalid OTP.
  Future<Map<String, dynamic>> aadhaarSubmitOtp(
      String clientId, String otp) async {
    final data = await _api.postJson('/api/aadhaar/submit-otp', {
      'client_id': clientId,
      'otp': otp,
    });
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw ApiException('Aadhaar verification failed');
  }

  /// GET /api/stats — headline counts. Falls back to demo-derived totals.
  Future<Map<String, dynamic>> stats() async {
    try {
      final data = await _api.getJson('/api/stats');
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (_) {/* fall through */}
    return _demoStats();
  }

  Map<String, dynamic> _demoStats() {
    final donations = kWelfareCampaigns.fold<int>(
        0, (sum, c) => sum + (c['raised'] as int));
    return {
      'totalMembers': 1428,
      'pendingVerifications': kVerificationRequests.length,
      'familyMembers': kFamilyMembers.length,
      'matrimonialProfiles': kMatrimonialCandidates.length,
      'totalDonations': kWelfareCampaigns.length,
      'totalDonationAmount': donations,
      'activeTrees': 86,
    };
  }

  // ── Embedded content (same dataset the web pages use) ───────────────────────
  List<Map<String, dynamic>> familyMembers() => kFamilyMembers;
  List<Map<String, dynamic>> matrimonial() => kMatrimonialCandidates;
  List<Map<String, dynamic>> welfare() => kWelfareCampaigns;
  List<Map<String, dynamic>> communityMembers() => kCommunityMembers;
  List<Map<String, dynamic>> verifications() => kVerificationRequests;
  List<Map<String, dynamic>> conflicts() => kConflictCases;
  List<Map<String, dynamic>> invitations() => kInvitationFamilies;
  List<Map<String, dynamic>> activity() => kDashboardActivity;
  List<Map<String, dynamic>> elderQueue() => kElderQueue;

  Map<String, dynamic>? matrimonialById(String id) =>
      _byId(kMatrimonialCandidates, id);
  Map<String, dynamic>? welfareById(String id) => _byId(kWelfareCampaigns, id);
  Map<String, dynamic>? verificationById(String id) =>
      _byId(kVerificationRequests, id);
  Map<String, dynamic>? conflictById(String id) => _byId(kConflictCases, id);
  Map<String, dynamic>? communityMemberById(String id) =>
      _byId(kCommunityMembers, id);

  Map<String, dynamic>? _byId(List<Map<String, dynamic>> list, String id) {
    for (final m in list) {
      if (m['id'] == id) return m;
    }
    return null;
  }
}
