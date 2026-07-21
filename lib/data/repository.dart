import 'dart:convert';

import 'api_client.dart';
import 'api_config.dart';
import 'demo_data.dart';

/// Single data source for the app.
///
/// Mirrors how the web app sources data: auth + headline stats come from the
/// Next.js API (`/api/user/login`, `/api/stats`); the rich content (family,
/// matrimonial, welfare, directory, verifications, conflicts, invitations) is
/// the same embedded demo dataset the React pages render from `lib/data.ts`.
/// Every network call degrades gracefully to embedded data so the app always
/// runs, even with the backend offline.
class Repository {
  Repository({ApiClient? api}) : _api = api ?? ApiClient();
  final ApiClient _api;

  static final Repository instance = Repository();

  /// POST /api/user/login — returns `{user, token}`: the authenticated user map
  /// from MongoDB plus the JWT bearer token for subsequent protected requests.
  /// Throws [ApiException] with the server's message ("Phone number not
  /// registered", "Invalid OTP") — the backend validates the OTP.
  Future<Map<String, dynamic>> login(String phone, String otp) async {
    final data = await _api.postJson('/api/user/login', {
      'phone': phone,
      'otp': otp,
    });
    if (data is Map && data['user'] is Map) {
      return {
        'user': Map<String, dynamic>.from(data['user'] as Map),
        'token': (data['token'] ?? '').toString(),
      };
    }
    throw ApiException('Login failed');
  }

  /// GET /api/user/username/check — Instagram-style availability. Returns
  /// `{ available: bool, suggestions: [..] }`.
  Future<Map<String, dynamic>> checkUsername(String userName) async {
    final data = await _api.getJson(
        '/api/user/username/check?userName=${Uri.encodeQueryComponent(userName)}');
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'available': false};
  }

  /// POST /api/user/register — creates the member in MongoDB and returns the
  /// user map. The backend requires a unique `userName`; when the caller doesn't
  /// supply one we derive it from the name + phone. Throws [ApiException] on
  /// failure (409 → phone/username already registered).
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    String userName = '',
    String gotra = '',
    String native = '',
    String role = 'member',
    String avatar = '6',
    String gender = '',
  }) async {
    final data = await _api.postJson('/api/user/register', {
      'userName': userName.isNotEmpty ? userName : _deriveUserName(name, phone),
      'name': name,
      'phone': phone,
      if (gotra.isNotEmpty) 'gotra': gotra,
      if (native.isNotEmpty) 'native': native,
      'role': role,
      if (gender.isNotEmpty) 'gender': gender,
    });
    if (data is Map && data['user'] is Map) {
      return {
        'user': Map<String, dynamic>.from(data['user'] as Map),
        'token': (data['token'] ?? '').toString(),
      };
    }
    throw ApiException('Registration failed');
  }

  /// A backend-legal username (3–30 chars, lowercase letters/digits/._) derived
  /// from the name, disambiguated with the last 4 phone digits.
  String _deriveUserName(String name, String phone) {
    final base = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9._]'), '');
    final suffix = phone.length >= 4 ? phone.substring(phone.length - 4) : phone;
    final raw = '${base.isEmpty ? 'member' : base}_$suffix';
    return raw.length > 30 ? raw.substring(0, 30) : raw;
  }

  // ── Feed & posts ────────────────────────────────────────────────────────────

  /// GET /feed — cursor-based feed. Pass [before] (a lastVisiblePostId) to load
  /// older posts, or [after] (a firstVisiblePostId) to load newer ones. Returns
  /// the raw envelope: `{count, posts, firstVisiblePostId, lastVisiblePostId}`.
  Future<Map<String, dynamic>> feed({
    int limit = 20,
    String? before,
    String? after,
  }) async {
    final q = <String>['limit=$limit'];
    if (before != null && before.isNotEmpty) q.add('before=$before');
    if (after != null && after.isNotEmpty) q.add('after=$after');
    final data = await _api.getJson('/feed?${q.join('&')}');
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'posts': const []};
  }

  /// GET /feed/new-count — exact number of posts newer than [afterPostId], for
  /// the "N new posts" banner.
  Future<int> feedNewCount(String afterPostId) async {
    try {
      final data = await _api.getJson('/feed/new-count?after=$afterPostId');
      if (data is Map && data['count'] is num) {
        return (data['count'] as num).toInt();
      }
    } catch (_) {/* best-effort */}
    return 0;
  }

  /// POST /api/posts — multipart upload of an image/video (≤2 MB) to Cloudinary,
  /// then stores the post. Requires a logged-in session (bearer token). Returns
  /// the created post map.
  Future<Map<String, dynamic>> createPost({
    required String filePath,
    String caption = '',
    List<String> hashtags = const [],
    List<String> taggedUsers = const [],
    String visibility = 'public',
  }) async {
    final data = await _api.postMultipart(
      '/api/posts',
      fileField: 'media',
      filePath: filePath,
      fields: {
        'caption': caption,
        'visibility': visibility,
        if (hashtags.isNotEmpty) 'hashtags': jsonEncode(hashtags),
        if (taggedUsers.isNotEmpty) 'taggedUsers': jsonEncode(taggedUsers),
      },
    );
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not create post');
  }

  /// POST /api/posts/:postId/likes — like a post. Requires a bearer token.
  Future<void> likePost(String postId) async {
    await _api.postJson('/api/posts/$postId/likes', const {});
  }

  /// POST /api/posts/comments — add a comment. Requires a bearer token.
  Future<void> addComment({required String postId, required String text}) async {
    await _api.postJson('/api/posts/comments', {
      'postId': postId,
      'text': text,
    });
  }

  // ── Stories (24h) ───────────────────────────────────────────────────────────

  /// GET /api/stories — active stories grouped per author ("trays"). Returns the
  /// raw envelope: `{count, trays:[{author, latestAt, stories:[...]}], nextCursor}`.
  Future<Map<String, dynamic>> storiesFeed({int limit = 30, String? cursor}) async {
    final q = <String>['limit=$limit'];
    if (cursor != null && cursor.isNotEmpty) q.add('cursor=$cursor');
    final data = await _api.getJson('/api/stories?${q.join('&')}');
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'trays': const []};
  }

  /// GET /api/stories/me — the caller's own active stories (array).
  Future<List<Map<String, dynamic>>> myStories() async {
    final data = await _api.getJson('/api/stories/me');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// POST /api/stories — multipart upload of an image/video (≤100 MB) as a story
  /// that expires in 24h. Optionally tags family members, links to an ancestor
  /// tree node, and attaches a location. Requires a bearer token.
  Future<Map<String, dynamic>> createStory({
    required String filePath,
    String caption = '',
    String visibility = 'community',
    List<String> taggedMembers = const [],
    String? treeNodeId,
    String? locationName,
    String? locationKind,
  }) async {
    final data = await _api.postMultipart(
      '/api/stories',
      fileField: 'media',
      filePath: filePath,
      fields: {
        'caption': caption,
        'visibility': visibility,
        // taggedMembers is sent as a JSON-array string (per the API contract).
        if (taggedMembers.isNotEmpty) 'taggedMembers': jsonEncode(taggedMembers),
        if (treeNodeId != null && treeNodeId.isNotEmpty) 'treeNodeId': treeNodeId,
        if (locationName != null && locationName.isNotEmpty)
          'locationName': locationName,
        if (locationKind != null && locationKind.isNotEmpty)
          'locationKind': locationKind,
      },
    );
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not create story');
  }

  /// GET /api/stories/:id — one story with counts and the caller's liked flag.
  Future<Map<String, dynamic>> story(String storyId) async {
    final data = await _api.getJson('/api/stories/$storyId');
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Story not found');
  }

  /// POST /api/stories/:id/likes — toggle a like. Returns `{liked, likeCount}`.
  Future<Map<String, dynamic>> toggleStoryLike(String storyId) async {
    final data = await _api.postJson('/api/stories/$storyId/likes', const {});
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'liked': false, 'likeCount': 0};
  }

  /// POST /api/stories/:id/comments — reply to a story.
  Future<void> addStoryComment(String storyId, String content) async {
    await _api.postJson('/api/stories/$storyId/comments', {'content': content});
  }

  /// GET /api/stories/:id/comments — the replies:
  /// `[{ _id, userId:{_id,userName}, content, createdAt }]`.
  Future<List<Map<String, dynamic>>> storyComments(String storyId) async {
    final data = await _api.getJson('/api/stories/$storyId/comments');
    if (data is Map && data['comments'] is List) {
      return (data['comments'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// GET /api/family/search — members matching [q] (for tagging / tree link):
  /// `[{ _id, name, gotra, native, photoUrl, generation, branch }]`.
  Future<List<Map<String, dynamic>>> familySearch(String q,
      {int limit = 20}) async {
    final data = await _api.getJson(
        '/api/family/search?q=${Uri.encodeQueryComponent(q)}&limit=$limit');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// POST /api/stories/:id/views — mark a story viewed. Returns the new count.
  Future<int> markStoryViewed(String storyId) async {
    final data = await _api.postJson('/api/stories/$storyId/views', const {});
    if (data is Map && data['viewCount'] is num) {
      return (data['viewCount'] as num).toInt();
    }
    return 0;
  }

  /// GET /api/stories/:id/views — the viewers list:
  /// `[{ user:{_id,userName}, viewedAt }]`.
  Future<List<Map<String, dynamic>>> storyViewers(String storyId) async {
    final data = await _api.getJson('/api/stories/$storyId/views');
    if (data is Map && data['viewers'] is List) {
      return (data['viewers'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// DELETE /api/stories/:id — remove one of the caller's stories.
  Future<void> deleteStory(String storyId) async {
    await _api.deleteJson('/api/stories/$storyId');
  }

  // ── Aadhaar / DigiLocker (backend `/api/adhar/*`) ───────────────────────────

  /// POST /api/adhar/initialize — start a DigiLocker consent session. Returns
  /// `{ client_id, url }`: the id to keep and the URL the user opens to consent.
  Future<Map<String, dynamic>> adharInitialize({required String redirectUrl}) async {
    final data = await _api.postJson('/api/adhar/initialize', {
      'redirectUrl': redirectUrl,
    });
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not start DigiLocker');
  }

  /// POST /api/adhar/download — fetch the verified Aadhaar for a consented
  /// session identified by [clientId].
  Future<Map<String, dynamic>> adharDownload(String clientId) async {
    final data = await _api.postJson('/api/adhar/download', {
      'clientId': clientId,
    });
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not download Aadhaar');
  }

  /// POST /api/user/upload — uploads an image (base64) to MongoDB, keyed by
  /// phone + type ("selfie" | "id" | "familyDoc"). Returns the absolute URL to
  /// load it back, or null if the backend is unreachable.
  Future<String?> uploadImage({
    required String phone,
    required String type,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final res = await _api.postJson('/api/user/upload', {
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

  /// PATCH /api/user/profile — saves editable profile fields. Best-effort:
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
      await _api.patchJson('/api/user/profile', {
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

  /// GET /api/family — the real family-tree members from MongoDB (same source
  /// the web family-tree/profile pages render). Each map follows the DB shape:
  /// `_id`, `name`, `gender`, `dob`, `dod`, `gotra`, `native`, `occupation`,
  /// `photoUrl`, `generation`, `branch`, `notes`, `parentId`. Throws
  /// [ApiException] on a non-2xx response; returns [] when the collection is
  /// empty.
  Future<List<Map<String, dynamic>>> familyTree() async {
    final data = await _api.getJson('/api/family');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// POST /api/family — create a family-tree node (a "person", not an account).
  /// Placement is derived from the relationship by the caller (parentId /
  /// spouseId / generation). Returns the new `id` and `matchedExistingUser`
  /// (true when the phone already belongs to a registered account, in which
  /// case a pending link request was auto-created server-side).
  Future<Map<String, dynamic>> addFamilyMember(Map<String, dynamic> body) async {
    final data = await _api.postJson('/api/family', body);
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not add member');
  }

  /// PUT /api/family/:id — patch a node. Used to re-link an anchor to a newly
  /// added ancestor (set the anchor's parentId) or spouse.
  Future<void> updateFamilyMember(String id, Map<String, dynamic> patch) async {
    await _api.putJson('/api/family/$id', patch);
  }

  /// POST /api/family/connect — request to link the current account to an
  /// existing (accountless) node. Sits pending until an elder approves it.
  Future<void> requestConnect({
    required String memberId,
    required String requesterPhone,
    required String requesterName,
    String relation = 'self',
    String note = '',
  }) async {
    await _api.postJson('/api/family/connect', {
      'memberId': memberId,
      'requesterPhone': requesterPhone,
      'requesterName': requesterName,
      'relation': relation,
      'note': note,
    });
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
