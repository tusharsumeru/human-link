import 'dart:convert';

import 'package:latlong2/latlong.dart';

import 'api_client.dart';
import 'api_config.dart';
import 'demo_data.dart';
import 'invitation_member.dart';
import 'models/compatibility_models.dart';

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
    Map<String, dynamic>? currentAddress,
    bool isPurohit = false,
  }) async {
    final data = await _api.postJson('/api/user/register', {
      'userName': userName.isNotEmpty ? userName : _deriveUserName(name, phone),
      'name': name,
      'phone': phone,
      if (gotra.isNotEmpty) 'gotra': gotra,
      if (native.isNotEmpty) 'native': native,
      'role': role,
      if (gender.isNotEmpty) 'gender': gender,
      // Send it as `CurrentAddress.toRequest()` builds it — parts only, no
      // empty strings. The server geocodes it and stores the coordinates.
      'currentAddress': ?currentAddress,
      'isPurohit': isPurohit,
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
    String location = '',
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
        // Instagram-style place the author attached; the server stores it on the
        // post and returns it in the feed.
        if (location.isNotEmpty) 'location': location,
        if (hashtags.isNotEmpty) 'hashtags': jsonEncode(hashtags),
        if (taggedUsers.isNotEmpty) 'taggedUsers': jsonEncode(taggedUsers),
      },
    );
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not create post');
  }

  /// POST /api/posts/:postId/likes — toggles the caller's like on a post and
  /// returns the fresh `{liked, likeCount}`. Requires a bearer token.
  Future<Map<String, dynamic>> likePost(String postId) async {
    final data = await _api.postJson('/api/posts/$postId/likes', const {});
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'liked': true, 'likeCount': 0};
  }

  /// POST /api/posts/comments — add a comment. The server DTO field is
  /// `content` (not `text`); a mismatch is stripped by the global
  /// ValidationPipe and rejected as "content should not be empty".
  /// Returns the created comment with its author populated.
  Future<Map<String, dynamic>> addComment({
    required String postId,
    required String text,
  }) async {
    final data = await _api.postJson('/api/posts/comments', {
      'postId': postId,
      'content': text,
    });
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not post comment');
  }

  /// POST /api/posts/comments/:commentId/likes — toggles the caller's like on
  /// a comment. Returns `{liked, likeCount}`.
  Future<Map<String, dynamic>> likeComment(String commentId) async {
    final data =
        await _api.postJson('/api/posts/comments/$commentId/likes', const {});
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'liked': true, 'likeCount': 0};
  }

  /// GET /api/posts/:postId/comments — newest first:
  /// `{count, comments:[{_id, userId:{userName, profileUrl}, content,
  /// createdAt, likeCount, likedByMe}]}`.
  Future<List<Map<String, dynamic>>> postComments(String postId) async {
    final data = await _api.getJson('/api/posts/$postId/comments');
    if (data is Map && data['comments'] is List) {
      return (data['comments'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
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

  /// GET /api/user/directory — registered members (the `users` collection),
  /// searchable + paginated. PII-safe shape: `{id, userName, name, gotra,
  /// native, gender, profileUrl, occupation, bio, verified, role}`.
  Future<List<Map<String, dynamic>>> usersDirectory({
    String q = '',
    int limit = 50,
    int page = 1,
  }) async {
    final query = <String>['limit=$limit', 'page=$page'];
    if (q.isNotEmpty) query.add('q=${Uri.encodeQueryComponent(q)}');
    final data = await _api.getJson('/api/user/directory?${query.join('&')}');
    if (data is Map && data['users'] is List) {
      return (data['users'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// GET /api/user/map — members to plot on the invitation route planner:
  /// everyone whose current address has been geocoded, nearest to you first,
  /// plus your own pin as the route's starting point.
  ///
  /// Unlike the directory this carries the full address and coordinates — it is
  /// the view the address parts were collected for, since delivering an
  /// invitation by hand means finding the door.
  Future<InvitationMap> invitationMap({String q = '', int limit = 100}) async {
    final query = <String>['limit=$limit'];
    if (q.isNotEmpty) query.add('q=${Uri.encodeQueryComponent(q)}');
    final data = await _api.getJson('/api/user/map?${query.join('&')}');
    if (data is! Map) return const InvitationMap();

    final members = <InvitationMember>[];
    for (final raw in (data['members'] as List? ?? const [])) {
      final m = InvitationMember.fromMap(raw);
      if (m != null) members.add(m);
    }
    return InvitationMap(
      me: InvitationMember.fromMap(data['me']),
      members: members,
      unmapped: (data['unmapped'] as num?)?.toInt() ?? 0,
    );
  }

  /// POST /api/user/route — the optimised order to visit the selected members
  /// in, starting from [origin] (your saved address when it is omitted) and
  /// ending at the last family rather than back home.
  ///
  /// The ids go up in whatever order they were picked: working out the order is
  /// the server's job. It always answers with a usable route — see
  /// [RoutePlan.isEstimate] for whether the distances are real road distances.
  Future<RoutePlan> planRoute(
    List<String> memberIds, {
    LatLng? origin,
  }) async {
    final data = await _api.postJson('/api/user/route', {
      'memberIds': memberIds,
      if (origin != null)
        'origin': {
          'latitude': origin.latitude,
          'longitude': origin.longitude,
        },
    });
    final plan = RoutePlan.fromMap(data);
    if (plan == null) throw ApiException('Could not plan the route');
    return plan;
  }

  /// GET /api/user/directory?isPurohit=true — members who answered "Yes" to
  /// "Are you a purohit?" at registration. Also filters client-side on the
  /// same field, in case the backend returns it without honoring the query
  /// filter — so this never shows a non-purohit member.
  Future<List<Map<String, dynamic>>> purohitDirectory({int limit = 100}) async {
    final data =
        await _api.getJson('/api/user/directory?limit=$limit&isPurohit=true');
    if (data is Map && data['users'] is List) {
      return (data['users'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((m) => m['isPurohit'] == true)
          .toList();
    }
    return const [];
  }

  /// GET /api/user/me — the authenticated member's own full profile (same shape
  /// as login/register, including `samajId`). Used to refresh a restored session
  /// so fields added after the session was cached (e.g. samajId) populate without
  /// requiring a re-login.
  Future<Map<String, dynamic>> me() async {
    final data = await _api.getJson('/api/user/me');
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not load your profile');
  }

  /// GET /api/user/:id — one registered member's public (PII-safe) profile.
  Future<Map<String, dynamic>> userById(String id) async {
    final data = await _api.getJson('/api/user/$id');
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Member not found');
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

  // ── Messaging & connections ───────────────────────────────────────────────

  /// GET /api/conversations — my inbox: `[{ key, otherUser, lastText, lastAt,
  /// lastSenderId, unread }]`, newest activity first.
  Future<List<Map<String, dynamic>>> conversations() async {
    final data = await _api.getJson('/api/conversations');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// GET /api/conversations/:userId/messages — history, oldest→newest.
  Future<List<Map<String, dynamic>>> messageHistory(String userId,
      {int limit = 40, String? before}) async {
    final q = <String>['limit=$limit'];
    if (before != null && before.isNotEmpty) q.add('before=$before');
    final data = await _api
        .getJson('/api/conversations/$userId/messages?${q.join('&')}');
    if (data is Map && data['messages'] is List) {
      return (data['messages'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// POST /api/messages — send over REST (fallback when the socket is down).
  Future<Map<String, dynamic>> sendMessage(String toUserId, String text) async {
    final data = await _api
        .postJson('/api/messages', {'toUserId': toUserId, 'text': text});
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not send message');
  }

  /// POST /api/conversations/:userId/read — mark that thread's messages read.
  Future<void> markConversationRead(String userId) async {
    await _api.postJson('/api/conversations/$userId/read', const {});
  }

  /// POST /api/connections — send a connection request (directory "Connect").
  Future<Map<String, dynamic>> connect(String toUserId) async {
    final data = await _api.postJson('/api/connections', {'toUserId': toUserId});
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not send connection request');
  }

  /// GET /api/connections — my connections (incoming + outgoing) with status.
  Future<List<Map<String, dynamic>>> connections() async {
    final data = await _api.getJson('/api/connections');
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

  /// DELETE /api/posts/:postId — remove one of the caller's posts.
  Future<void> deletePost(String postId) async {
    await _api.deleteJson('/api/posts/$postId');
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

  /// PATCH /api/user/profile — saves editable profile fields and returns the
  /// updated user map. Throws [ApiException] carrying the server's validation
  /// message ("Name must be at least 2 characters"), which is what an edit form
  /// needs to show; [updateProfile] is the best-effort wrapper for the
  /// background call sites that would rather ignore a failure.
  ///
  /// The user is identified by the bearer token, so `phone` is not sent — the
  /// server strips it anyway, and sending it implied an identity the request
  /// does not actually carry.
  Future<Map<String, dynamic>> saveProfile({
    String? name,
    String? gotra,
    String? native,
    String? bio,
    String? occupation,
    bool? matrimonialOptIn,
    bool? showPhoneToMembers,
    String? dob,
    String? gender,
    String? address,
    Map<String, dynamic>? currentAddress,
    String? profileUrl,
    String? maskedAadhaar,
    bool? verified,
  }) async {
    final data = await _api.patchJson('/api/user/profile', {
      'name': ?name,
      'gotra': ?gotra,
      'native': ?native,
      'bio': ?bio,
      'occupation': ?occupation,
      'matrimonialOptIn': ?matrimonialOptIn,
      'showPhoneToMembers': ?showPhoneToMembers,
      'dob': ?dob,
      'gender': ?gender,
      'address': ?address,
      // Replaces the stored address wholesale, so it carries every part the
      // member still wants kept — see [CurrentAddress.toRequest].
      'currentAddress': ?currentAddress,
      'profileUrl': ?profileUrl,
      'masked_aadhaar': ?maskedAadhaar,
      'verified': ?verified,
    });
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not save your profile');
  }

  /// Best-effort [saveProfile]: true on success, false if the backend rejected
  /// the change or is unreachable. Used by the onboarding/registration flows,
  /// which must not stall on a profile write.
  Future<bool> updateProfile({
    String? phone,
    String? name,
    String? gotra,
    String? native,
    String? bio,
    String? occupation,
    bool? matrimonialOptIn,
    bool? showPhoneToMembers,
    String? dob,
    String? gender,
    String? address,
    Map<String, dynamic>? currentAddress,
    String? profileUrl,
    String? maskedAadhaar,
    bool? verified,
  }) async {
    try {
      await saveProfile(
        name: name,
        gotra: gotra,
        native: native,
        bio: bio,
        occupation: occupation,
        matrimonialOptIn: matrimonialOptIn,
        showPhoneToMembers: showPhoneToMembers,
        dob: dob,
        gender: gender,
        address: address,
        currentAddress: currentAddress,
        profileUrl: profileUrl,
        maskedAadhaar: maskedAadhaar,
        verified: verified,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// POST /api/user/profile/photo — multipart upload of the profile picture
  /// (image only). Returns the updated user map, including the new
  /// `profileUrl`. A photo is required to enter the matrimonial hub.
  Future<Map<String, dynamic>> uploadProfilePhoto(String filePath) async {
    final data = await _api.postMultipart(
      '/api/user/profile/photo',
      fileField: 'media',
      filePath: filePath,
    );
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not upload your photo');
  }

  // ── Aadhaar KYC via DigiLocker (backend `/api/adhar/*`, Surepass behind it) ─
  //
  // The NestJS server mounts these under `/api/adhar`, *not* `/api/digilocker`
  // (that path only exists on the Next.js web app). Calling the wrong one made
  // Nest answer its 404 body — "Cannot POST /api/digilocker/initialize" — which
  // the verification screens then showed as the error message.

  /// POST /api/adhar/initialize — start a DigiLocker consent session. Returns
  /// `client_id` (needed to download the Aadhaar afterwards), the hosted `url`
  /// to open in a WebView, and the `redirect_url` that signals completion.
  /// Leave [redirectUrl] empty to use the server's configured callback.
  Future<Map<String, dynamic>> digilockerInitialize({
    String redirectUrl = '',
  }) async {
    final res = await _api.postJson('/api/adhar/initialize', {
      if (redirectUrl.isNotEmpty) 'redirectUrl': redirectUrl,
    });
    final data = _unwrapSurepass(res);
    final clientId = (data['client_id'] ?? '').toString();
    // Via Link returns a URL to open; the field name varies by product.
    final url =
        (data['url'] ?? data['link'] ?? data['digilocker_url'] ?? '').toString();
    if (clientId.isEmpty || url.isEmpty) {
      throw ApiException('Could not start DigiLocker');
    }
    // Only the web route echoes a redirect_url back; otherwise the WebView
    // falls back to matching the `digilocker-callback` marker in the URL.
    final echoed = (res is Map ? res['redirect_url'] ?? '' : '').toString();
    return {
      'client_id': clientId,
      'url': url,
      'token': (data['token'] ?? '').toString(),
      'redirect_url': echoed.isNotEmpty ? echoed : redirectUrl,
    };
  }

  /// POST /api/adhar/download — the verified Aadhaar for a consented session.
  /// Normalises Surepass's payload to just what the profile stores:
  /// `full_name`, `dob`, `gender`, `masked_aadhaar`, `full_address`.
  Future<Map<String, dynamic>> digilockerAadhaar(String clientId) async {
    final res = await _api.postJson('/api/adhar/download', {
      'clientId': clientId,
    });
    var data = _unwrapSurepass(res);
    // Some Surepass products nest the KYC block one level deeper.
    for (final key in const ['aadhaar_xml_data', 'aadhaar_data']) {
      if (data[key] is Map) data = Map<String, dynamic>.from(data[key] as Map);
    }
    if (data.isEmpty) throw ApiException('Could not fetch Aadhaar data');
    return {
      'full_name': (data['full_name'] ?? data['name'] ?? '').toString(),
      'dob': (data['dob'] ?? data['date_of_birth'] ?? '').toString(),
      'gender': _normalizeGender(data['gender']),
      'masked_aadhaar': (data['masked_aadhaar'] ??
              data['aadhaar_id'] ??
              data['aadhaar_number'] ??
              '')
          .toString(),
      'full_address': _fullAddress(data),
    };
  }

  /// The NestJS server returns Surepass's `data` block already unwrapped; the
  /// Next.js web route returns the whole `{data: …}` envelope. Accept either.
  Map<String, dynamic> _unwrapSurepass(dynamic res) {
    if (res is Map && res['data'] is Map) {
      return Map<String, dynamic>.from(res['data'] as Map);
    }
    if (res is Map) return Map<String, dynamic>.from(res);
    return const {};
  }

  /// Aadhaar gender arrives as `M`/`F` or `MALE`/`FEMALE`; the profile DTO only
  /// accepts the single letter.
  String _normalizeGender(dynamic raw) {
    final g = (raw ?? '').toString().toUpperCase();
    if (g.startsWith('M')) return 'M';
    if (g.startsWith('F')) return 'F';
    return '';
  }

  /// Surepass returns either a ready `full_address` string or a structured
  /// `address` object; both collapse to the one line the profile shows.
  String _fullAddress(Map<String, dynamic> data) {
    final full = (data['full_address'] ?? '').toString();
    if (full.isNotEmpty) return full;
    final address = data['address'];
    if (address is String) return address;
    if (address is Map) {
      const order = [
        'house', 'street', 'landmark', 'loc', 'vtc', 'po',
        'subdist', 'dist', 'state', 'country',
      ];
      final line = [
        for (final key in order) (address[key] ?? '').toString().trim(),
      ].where((part) => part.isNotEmpty).join(', ');
      final zip = (data['zip'] ?? address['zip'] ?? '').toString().trim();
      return [line, zip].where((part) => part.isNotEmpty).join(' - ');
    }
    return '';
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

  // ── Family Tree (new normalized backend, /api/family-tree/*) ────────────────
  //
  // The redesigned family tree: a Person + Relationship graph with an approval /
  // invitation / placeholder-merge workflow. Distinct from the legacy `/api/family`
  // methods above (which are a flat read/write view over `family_members`).

  /// GET /api/family-tree — my tree, built by traversing accepted relationships.
  /// Returns the envelope `{rootId, nodes, edges, truncated}`, where each node is
  /// `{id, name, gender, status, photoUrl, isPlaceholder, deceased, linkedUserId,
  /// generation, relationToRoot, isSelf}` and each edge is `{from, to, relation}`.
  Future<Map<String, dynamic>> familyTreeGraph() async {
    final data = await _api.getJson('/api/family-tree');
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'rootId': '', 'nodes': const [], 'edges': const []};
  }

  /// GET /api/family-tree/search — find an existing account to connect to. Any
  /// combination of criteria narrows the match (all ANDed server-side). Returns
  /// account previews `[{_id, userName, name, profileUrl, samajId, gotra, native,
  /// gender, phone}]`.
  Future<List<Map<String, dynamic>>> familyTreeSearch({
    String? samajId,
    String? phone,
    String? name,
    String? village,
    String? dob,
    int limit = 20,
  }) async {
    final q = <String>['limit=$limit'];
    if (samajId != null && samajId.isNotEmpty) {
      q.add('samajId=${Uri.encodeQueryComponent(samajId)}');
    }
    if (phone != null && phone.isNotEmpty) {
      q.add('phone=${Uri.encodeQueryComponent(phone)}');
    }
    if (name != null && name.isNotEmpty) {
      q.add('name=${Uri.encodeQueryComponent(name)}');
    }
    if (village != null && village.isNotEmpty) {
      q.add('village=${Uri.encodeQueryComponent(village)}');
    }
    if (dob != null && dob.isNotEmpty) {
      q.add('dob=${Uri.encodeQueryComponent(dob)}');
    }
    final data = await _api.getJson('/api/family-tree/search?${q.join('&')}');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// POST /api/family-tree/members — add a family member. Set [relation] plus
  /// either [targetUserId] (send a request to an existing account) or the
  /// placeholder fields (name/gender/status/...). Deceased members are added
  /// immediately; alive placeholders return an `inviteLink` + `whatsappUrl`.
  /// Returns `{mode: 'request'|'invitation'|'deceased', relationship, person, ...}`.
  Future<Map<String, dynamic>> addFamilyTreeMember({
    required String relation,
    String? targetUserId,
    String? name,
    String? gender,
    String status = 'alive',
    String? phone,
    String? dob,
    String? dod,
    String? placeOfDeath,
    String? biography,
    String? photoUrl,
  }) async {
    final body = <String, dynamic>{'relation': relation};
    if (targetUserId != null && targetUserId.isNotEmpty) {
      body['targetUserId'] = targetUserId;
    } else {
      body['name'] = name;
      if (gender != null && gender.isNotEmpty) body['gender'] = gender;
      body['status'] = status;
      if (phone != null && phone.isNotEmpty) body['phone'] = phone;
      if (dob != null && dob.isNotEmpty) body['dob'] = dob;
      if (dod != null && dod.isNotEmpty) body['dod'] = dod;
      if (placeOfDeath != null && placeOfDeath.isNotEmpty) {
        body['placeOfDeath'] = placeOfDeath;
      }
      if (biography != null && biography.isNotEmpty) body['biography'] = biography;
      if (photoUrl != null && photoUrl.isNotEmpty) body['photoUrl'] = photoUrl;
    }
    final data = await _api.postJson('/api/family-tree/members', body);
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not add member');
  }

  /// GET /api/family-tree/requests — pending relationship requests addressed to
  /// me, each with the requester's details.
  Future<List<Map<String, dynamic>>> familyTreeRequests() async {
    final data = await _api.getJson('/api/family-tree/requests');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// POST /api/family-tree/requests/:id/accept — accept an incoming request.
  Future<void> acceptFamilyTreeRequest(String id) async {
    await _api.postJson('/api/family-tree/requests/$id/accept', const {});
  }

  /// POST /api/family-tree/requests/:id/decline — decline an incoming request.
  Future<void> declineFamilyTreeRequest(String id) async {
    await _api.postJson('/api/family-tree/requests/$id/decline', const {});
  }

  /// POST /api/family-tree/requests/:id/cancel — withdraw a request I sent.
  Future<void> cancelFamilyTreeRequest(String id) async {
    await _api.postJson('/api/family-tree/requests/$id/cancel', const {});
  }

  /// GET /api/family-tree/invites — invitations matching my phone (placeholders
  /// others created for me). Call after registering / verifying my number.
  Future<List<Map<String, dynamic>>> familyTreeInvites() async {
    final data = await _api.getJson('/api/family-tree/invites');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// POST /api/family-tree/invites/accept — merge matching placeholders into my
  /// account and connect the trees. Returns `{merged, tree}`.
  Future<Map<String, dynamic>> acceptFamilyTreeInvites() async {
    final data = await _api.postJson('/api/family-tree/invites/accept', const {});
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'merged': 0};
  }

  /// POST /api/family-tree/invites/decline — decline invitations matching my phone.
  Future<void> declineFamilyTreeInvites() async {
    await _api.postJson('/api/family-tree/invites/decline', const {});
  }

  /// GET /api/family-tree/notifications — my family-tree inbox (newest first).
  Future<List<Map<String, dynamic>>> familyTreeNotifications() async {
    final data = await _api.getJson('/api/family-tree/notifications');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// POST /api/family-tree/notifications/:id/read — mark a notification read.
  Future<void> markFamilyTreeNotificationRead(String id) async {
    await _api.postJson('/api/family-tree/notifications/$id/read', const {});
  }

  // ── Matrimonial ─────────────────────────────────────────────────────────────

  /// GET /api/matrimonial/eligibility — the gate. Returns
  /// `{eligible, age, ageEligible, ageRange:{min,max}, profileComplete,
  /// missing:[{key,label}], status, reviewNote, reasons:[..]}`.
  Future<Map<String, dynamic>> matrimonialEligibility() async {
    final data = await _api.getJson('/api/matrimonial/eligibility');
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not check matrimonial eligibility');
  }

  /// GET /api/matrimonial/me — `{profile, eligibility}`; profile is null until
  /// the member starts one.
  Future<Map<String, dynamic>> myMatrimonialProfile() async {
    final data = await _api.getJson('/api/matrimonial/me');
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not load your matrimonial profile');
  }

  /// PUT /api/matrimonial/me — save-as-you-go draft. Every field optional.
  Future<Map<String, dynamic>> saveMatrimonialProfile(
      Map<String, dynamic> fields) async {
    final data = await _api.putJson('/api/matrimonial/me', fields);
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not save your matrimonial profile');
  }

  /// POST /api/matrimonial/me/submit — publish the profile to the hub. Takes
  /// effect immediately; there is no review step. Throws with the server's
  /// message (and a `missing` list) when the profile is incomplete or the
  /// member is outside the permitted age range.
  Future<Map<String, dynamic>> publishMatrimonialProfile() async {
    final data = await _api.postJson('/api/matrimonial/me/submit', const {});
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not submit your matrimonial profile');
  }

  /// POST /api/matrimonial/me/withdraw — take the profile out of the hub.
  Future<void> withdrawMatrimonialProfile() async {
    await _api.postJson('/api/matrimonial/me/withdraw', const {});
  }

  /// GET /api/matrimonial — published profiles. 403 (ApiException) when the
  /// caller has not passed the gate.
  Future<List<Map<String, dynamic>>> matrimonialProfiles({
    String? gender,
    String? gotra,
    String? location,
    int? ageMin,
    int? ageMax,
    int limit = 50,
  }) async {
    final q = <String>['limit=$limit'];
    if (gender != null && gender != 'All') q.add('gender=$gender');
    if (gotra != null && gotra != 'All') {
      q.add('gotra=${Uri.encodeQueryComponent(gotra)}');
    }
    if (location != null && location != 'All') {
      q.add('location=${Uri.encodeQueryComponent(location)}');
    }
    if (ageMin != null) q.add('ageMin=$ageMin');
    if (ageMax != null) q.add('ageMax=$ageMax');

    final data = await _api.getJson('/api/matrimonial?${q.join('&')}');
    if (data is Map && data['profiles'] is List) {
      return (data['profiles'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// GET /api/matrimonial/:id — one published profile in full.
  Future<Map<String, dynamic>> matrimonialProfile(String id) async {
    final data = await _api.getJson('/api/matrimonial/$id');
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Profile not found');
  }

  // ── Marriage Compatibility ───────────────────────────────────────────────────

  /// GET /api/birth-profile/me — the caller's saved birth data for
  /// compatibility calculation (`birth_profiles` in the compatibility spec).
  /// Flat shape — `{dateOfBirth, timeOfBirth, city, state, country, latitude,
  /// longitude, timezone, birthTimeAccuracy, verificationStatus, ...}` — with
  /// dateOfBirth merged in live from the account. This never 404s: a member
  /// who hasn't filled it in yet gets the same shape back with blank/UNKNOWN
  /// defaults, not an error.
  Future<Map<String, dynamic>> myBirthProfile() async {
    final data = await _api.getJson('/api/birth-profile/me');
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not load your birth details');
  }

  /// PUT /api/birth-profile/me — save-as-you-go, like the matrimonial draft.
  /// Flat fields only — `timeOfBirth`, `city`, `state`, `country`,
  /// `latitude`, `longitude`, `timezone` (required), `birthTimeAccuracy` —
  /// matching `UpsertBirthProfileDto` exactly. `dateOfBirth` is never sent
  /// here: the server reads it live off the account (PATCH
  /// /api/user/profile) and rejects the request with DATE_OF_BIRTH_REQUIRED
  /// if that's still blank. No astrology calculation happens here or
  /// anywhere in the app; this only stores the raw inputs the server-side
  /// engine will read later.
  Future<Map<String, dynamic>> saveBirthProfile(
      Map<String, dynamic> fields) async {
    final data = await _api.putJson('/api/birth-profile/me', fields);
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not save your birth details');
  }

  /// POST /api/v1/compatibility/calculate — only the JATAKA module (South
  /// Indian 10 Porutham) is implemented server-side; everything else in
  /// `include` is accepted but produces nothing (see
  /// `CompatibilityReport.notImplementedInclude`). No matching/astrology
  /// logic runs here or anywhere in the app — this only submits the two
  /// profile ids + roles and parses whatever report the server computed.
  Future<CompatibilityReport> calculateCompatibility({
    required String profileAId,
    required String profileBId,
    required TraditionalRole roleA,
    required TraditionalRole roleB,
    String ruleVersion = 'KARNATAKA_SOUTH_INDIAN_V1',
    List<String> include = const ['JATAKA'],
  }) async {
    final data = await _api.postJson('/api/v1/compatibility/calculate', {
      'profileAId': profileAId,
      'profileBId': profileBId,
      'traditionalRoles': {
        'profileA': roleA.wireValue,
        'profileB': roleB.wireValue,
      },
      'ruleVersion': ruleVersion,
      'include': include,
    });
    if (data is Map) {
      return CompatibilityReport.fromJson(Map<String, dynamic>.from(data));
    }
    throw ApiException('Could not calculate compatibility');
  }

  /// GET /api/v1/compatibility/consent — the caller's own status for every
  /// compatibility consent purpose. Self-service only, matching
  /// ConsentController: there is no endpoint to read another profile's
  /// consent, by design.
  Future<List<ConsentStatus>> myCompatibilityConsent() async {
    final data = await _api.getJson('/api/v1/compatibility/consent');
    if (data is Map && data['consents'] is List) {
      return (data['consents'] as List)
          .whereType<Map>()
          .map((e) => ConsentStatus.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  /// POST /api/v1/compatibility/consent — grants one of the caller's own
  /// compatibility consent types. Self-service only: there is no way to
  /// grant consent on someone else's behalf, matching ConsentController.
  Future<void> grantCompatibilityConsent(String consentType) async {
    await _api.postJson('/api/v1/compatibility/consent', {
      'consentType': consentType,
    });
  }

  /// POST /api/v1/compatibility/consent/revoke — revokes one of the
  /// caller's own compatibility consent types. A no-op server-side if
  /// nothing was granted, matching ConsentService.revoke.
  Future<void> revokeCompatibilityConsent(String consentType) async {
    await _api.postJson('/api/v1/compatibility/consent/revoke', {
      'consentType': consentType,
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
