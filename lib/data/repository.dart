import 'api_client.dart';
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
