import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'demo_data.dart';
import 'invitation_member.dart';
import 'models/compatibility_astrology_modules.dart';
import 'models/compatibility_models.dart';
import 'models/compatibility_prerequisites.dart';
import 'models/compatibility_summary.dart';
import 'models/kundli_chart.dart';
import 'models/parampara.dart';
import 'models/south_indian_jataka.dart';

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

  /// Mutable (not `final`) so tests can swap in a `Repository(api:
  /// FakeApiClient())` for a screen under test, then restore the real one —
  /// the app itself only ever assigns this once, at startup.
  static Repository instance = Repository();

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

 
  /// GET /api/user/invitation-map — members with mapped coordinates, nearest
  /// first from [origin].
  ///
  /// [origin] is the device's position and the server requires it: it is what
  /// the `$near` sort measures from, and it is the route's starting point too,
  /// since this endpoint returns no saved-address `me`.
  ///
  /// `search` matches Samaj ID, username or phone — not name or area, so the
  /// list is filtered on the client for anything else.
  Future<InvitationMap> invitationMap(
    LatLng origin, {
    String q = '',
    int page = 1,
    int limit = 100,
  }) async {
    final query = <String>[
      'latitude=${origin.latitude}',
      'longitude=${origin.longitude}',
      'page=$page',
      'limit=$limit',
    ];
    if (q.isNotEmpty) query.add('search=${Uri.encodeQueryComponent(q)}');

    final data =
        await _api.getJson('/api/user/invitation-map?${query.join('&')}');
    if (data is! Map) return const InvitationMap();

    final members = <InvitationMember>[];
    for (final raw in (data['members'] as List? ?? const [])) {
      final m = InvitationMember.fromMap(raw);
      if (m != null) members.add(m);
    }
    return InvitationMap(
      members: members,
      count: (data['count'] as num?)?.toInt() ?? members.length,
      page: (data['page'] as num?)?.toInt() ?? page,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
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
        // GeoPointDto on the server: a GeoJSON point, longitude first.
        'origin': {
          'type': 'Point',
          'coordinates': [origin.longitude, origin.latitude],
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
  Future<List<Map<String, dynamic>>> purohitDirectory({
  int limit = 30,
  int page = 1,
}) async {
  final data = await _api.getJson(
    '/api/user/purohits?limit=$limit&page=$page',
  );

  if (data is Map && data['users'] is List) {
    return (data['users'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
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

  /// GET /api/family/search — member records whose name contains [q] (powers
  /// "Tag Family Members" and "Link to Tree Node"):
  /// `[{ _id, name, gender, status, profileUrl, isPlaceholder, linkedUserId }]`.
  /// Omitting [q] returns the first [limit] members. Requires the bearer token
  /// like every other family route. [limit] is clamped to 1–50 server-side.
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

  /// PATCH /api/posts/:postId — author-only caption edit. Caption is the
  /// only editable field (media/type/author are immutable after posting).
  Future<void> editPostCaption(String postId, String caption) async {
    await _api.patchJson('/api/posts/$postId', {'caption': caption});
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

  // ── Parampara (Gotra/Pravara/Kuladevata/Kuladevi declarations) ─────────────
  // A separate backend resource from the basic profile above — see
  // ParamparaProfile's own doc comment on why the two coexist.

  /// GET /api/parampara/me — the caller's own declared Kuladevata (this app
  /// only reads that one field today). Never 404s for a member who hasn't
  /// filled this in yet.
  Future<ParamparaProfile> myParampara() async {
    final data = await _api.getJson('/api/parampara/me');
    if (data is Map) {
      return ParamparaProfile.fromJson(Map<String, dynamic>.from(data));
    }
    throw ApiException('Could not load your Parampara profile');
  }

  /// PUT /api/parampara/me — saves only the Kuladevata declaration.
  /// Save-as-you-go: every field on this resource is independently settable,
  /// so sending just `kuladevata` leaves Gotra/Pravara/Kuladevi (if any)
  /// untouched server-side. [value] null/blank clears it back to
  /// NOT_PROVIDED. Always sent as USER_DECLARED free text — the backend's
  /// Kuladevata master list is deliberately empty (see kKuladevatas' own
  /// doc comment), so MASTER_DATA/masterId is never a valid source here.
  Future<void> saveKuladevata(String? value) async {
    final trimmed = value?.trim() ?? '';
    await _api.putJson('/api/parampara/me', {
      'kuladevata': trimmed.isEmpty
          ? {'status': 'NOT_PROVIDED'}
          : {'status': 'PROVIDED', 'source': 'USER_DECLARED', 'customValue': trimmed},
    });
  }

  /// PUT /api/parampara/me — saves the Gotra declaration used by the
  /// Daivagna Parampara compatibility comparison. Deliberately separate from
  /// the basic profile's own `User.gotra` field (sagotra matrimonial
  /// matching, saved via [saveProfile]) — see ParamparaProfile's doc comment
  /// on why the two coexist. Same independently-settable-fields behavior as
  /// [saveKuladevata]: this never touches Kuladevata/Pravara/Kuladevi.
  Future<void> saveParamparaGotra(String? value) async {
    final trimmed = value?.trim() ?? '';
    await _api.putJson('/api/parampara/me', {
      'gotra': trimmed.isEmpty
          ? {'status': 'NOT_PROVIDED'}
          : {'status': 'PROVIDED', 'source': 'USER_DECLARED', 'customValue': trimmed},
    });
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

  // ── Family (/api/family/*) ──────────────────────────────────────────────────
  //
  // A Person + Relationship graph with an approval / invitation /
  // placeholder-merge workflow. Only seven relations are ever stored — father,
  // mother, brother, sister, spouse, son, daughter — and everything else
  // (grandfather, uncle, sister-in-law…) is *derived at read time* by walking
  // those edges out from whoever is looking. Labels are therefore
  // viewer-relative: never cache a `relation` globally, only per `rootId`, and
  // localise off the stable `relationCode`.
  //
  // Every route needs the bearer token, `/search` included. There is no "create
  // my profile" call — `GET /tree`, `POST /members` and `GET /requests` each
  // lazily create the caller's own member node on first touch.

  /// GET /api/family/tree — the tree as seen from [rootMemberId] (me by default).
  /// Returns `{rootId, nodes, edges, truncated}`. Nodes come sorted by
  /// `generation` (`0` = root, negative = ancestors) and carry the derived
  /// `relation` / `relationCode`, `side`, `lineage`, `inLaw`, `bloodRelation`,
  /// `distance`, `isDirectRelation`, `path`, plus `profileUrl`, `deceased`,
  /// `isPlaceholder`, `linkedUserId` and `isSelf`. Each edge is
  /// `{relationshipId, from, to, relation, status}`. Pending edges are invisible
  /// unless [includePending] is set; `truncated` is true when [maxNodes] cut the
  /// walk short (the server caps it at 800).
  Future<Map<String, dynamic>> familyTree({
    String? rootMemberId,
    bool includePending = false,
    int maxNodes = 800,
  }) async {
    final q = <String>['maxNodes=$maxNodes'];
    if (rootMemberId != null && rootMemberId.isNotEmpty) {
      q.add('rootMemberId=${Uri.encodeQueryComponent(rootMemberId)}');
    }
    if (includePending) q.add('includePending=true');
    final data = await _api.getJson('/api/family/tree?${q.join('&')}');
    if (data is Map) return Map<String, dynamic>.from(data);
    return {
      'rootId': '',
      'nodes': const [],
      'edges': const [],
      'truncated': false,
    };
  }

  /// GET /api/family/relatives — the same nodes as [familyTree], flattened and
  /// grouped by relation for a list screen: `{rootId, total, groups: [{relation,
  /// count, members}]}`. The root itself is excluded.
  Future<Map<String, dynamic>> familyRelatives({String? rootMemberId}) async {
    final q = (rootMemberId != null && rootMemberId.isNotEmpty)
        ? '?rootMemberId=${Uri.encodeQueryComponent(rootMemberId)}'
        : '';
    final data = await _api.getJson('/api/family/relatives$q');
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'rootId': '', 'total': 0, 'groups': const []};
  }

  /// GET /api/family/relations/:memberId — "who is this person to me?". Returns
  /// `{memberId, related, relation, relationCode, inLaw, bloodRelation, distance,
  /// lineage, side, generation, path}`. An unconnected member is a **200** with
  /// `related: false` and a `message`, not a 404 — only an unknown member id 404s.
  Future<Map<String, dynamic>> familyRelation(String memberId) async {
    final data = await _api.getJson('/api/family/relations/$memberId');
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'memberId': memberId, 'related': false, 'relation': null};
  }

  /// GET /api/family/users/search — find the **account** to connect to; the `_id`
  /// it returns is what [addFamilyMember] takes as `targetUserId`. Criteria are
  /// ANDed and at least one is required (an empty query is a 400, so the endpoint
  /// can never dump the directory). My own account is always excluded. Returns
  /// `[{_id, userName, name, profileUrl, samajId, gotra, native, gender, phone}]`.
  Future<List<Map<String, dynamic>>> familyUserSearch({
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
    final data = await _api.getJson('/api/family/users/search?${q.join('&')}');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// POST /api/family/members — add one of my seven immediate relations. One
  /// endpoint, three modes picked from the fields sent:
  ///
  /// * **request** — [targetUserId] set: the person already has an account, so
  ///   the edge stays `pending` (and out of the tree) until they accept.
  /// * **invitation** — [name] + [gender] + [dob] for a living person with no
  ///   account: creates a placeholder and returns `inviteLink` + `whatsappUrl`.
  ///   [phone] is the merge key — without it the placeholder can never be
  ///   auto-claimed when that person registers.
  /// * **deceased** — `status: 'deceased'`: recorded immediately, edge already
  ///   `accepted`, no approval and no invite.
  ///
  /// Returns `{mode, relationship, member, inviteLink?, whatsappUrl?}`. Adding a
  /// relation that already exists (in either direction) is idempotent — the
  /// existing edge comes back unchanged, so a 200 is not proof a *new* request
  /// was sent.
Future<Map<String, dynamic>> addFamilyMember({
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
  String? profileUrl,
}) async {
  final body = <String, dynamic>{
    'relation': relation,
  };

  if (targetUserId != null && targetUserId.isNotEmpty) {
    body['targetUserId'] = targetUserId;
  } else {
    body['name'] = name;

    if (gender != null && gender.isNotEmpty) {
      body['gender'] = gender;
    }

    body['status'] = status;

    if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone;
    }

    if (dob != null && dob.isNotEmpty) {
      body['dob'] = dob;
    }

    if (dod != null && dod.isNotEmpty) {
      body['dod'] = dod;
    }

    if (placeOfDeath != null && placeOfDeath.isNotEmpty) {
      body['placeOfDeath'] = placeOfDeath;
    }

    if (biography != null && biography.isNotEmpty) {
      body['biography'] = biography;
    }

    if (profileUrl != null && profileUrl.isNotEmpty) {
      body['profileUrl'] = profileUrl;
    }
  }

  debugPrint('========== ADD FAMILY MEMBER ==========');
  debugPrint('Relation: $relation');
  debugPrint('Target User ID: $targetUserId');
  debugPrint('Request Body: $body');

  try {
    debugPrint('Calling: POST /api/family/members');

    final data = await _api.postJson(
      '/api/family/members',
      body,
    );

    debugPrint('API RESPONSE: $data');

    if (data is Map) {
      debugPrint('Family member added successfully');
      return Map<String, dynamic>.from(data);
    }

    debugPrint('Unexpected response type: ${data.runtimeType}');
    throw ApiException('Could not add member');
  } catch (e, stackTrace) {
    debugPrint('========== ADD FAMILY MEMBER ERROR ==========');
    debugPrint('Error: $e');
    debugPrint('Error type: ${e.runtimeType}');
    debugPrint('Stack trace: $stackTrace');
    debugPrint('=============================================');

    rethrow;
  }
}
  /// GET /api/family/requests — requests awaiting **my** approval, each with the
  /// `requester` preview and a ready-made `message`.
  Future<List<Map<String, dynamic>>> familyRequests() async {
    final data = await _api.getJson('/api/family/requests');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// GET /api/family/requests/sent — requests **I** sent that are still pending.
  /// Same shape as [familyRequests] but with `relative` instead of `requester`,
  /// plus an `inviteLink` (non-null only for placeholder invitations). Use this
  /// to show people who won't be in the tree yet.
  Future<List<Map<String, dynamic>>> familySentRequests() async {
    final data = await _api.getJson('/api/family/requests/sent');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// POST /api/family/requests/accept — accept a request by id, with an optional
  /// [note] (max 280 chars) appended to the requester's notification. The id is
  /// the `relationshipId` carried by the notification, so a notification tap can
  /// be answered without rebuilding a URL. **Refetch the tree afterwards** — one
  /// new edge can relabel dozens of nodes.
  Future<void> acceptFamilyRequest(String id, {String? note}) async {
    await _api.postJson('/api/family/requests/accept', {
      'relationshipId': id,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  /// POST /api/family/requests/decline — decline a request by id.
  Future<void> declineFamilyRequest(String id, {String? note}) async {
    await _api.postJson('/api/family/requests/decline', {
      'relationshipId': id,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  /// POST /api/family/requests/:id/cancel — withdraw a request I sent. Only the
  /// requester may call it; an already-answered request comes back unchanged.
  Future<void> cancelFamilyRequest(String id) async {
    await _api.postJson('/api/family/requests/$id/cancel', const {});
  }

  /// GET /api/family/invites — placeholders carrying **my** phone number, i.e.
  /// people who added me while I hadn't registered. Call this right after
  /// login/registration: `[{relationshipId, placeholderId, relation, requester,
  /// message}]`.
  Future<List<Map<String, dynamic>>> familyInvites() async {
    final data = await _api.getJson('/api/family/invites');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// POST /api/family/invites/accept — accept **all** matching invitations at
  /// once, merging every placeholder that stood in for me onto my account (three
  /// siblings who each created a father placeholder collapse onto one person with
  /// no relationship lost). Returns `{merged, tree}` — the freshly built tree is
  /// included so no second round-trip is needed.
  Future<Map<String, dynamic>> acceptFamilyInvites() async {
    final data = await _api.postJson('/api/family/invites/accept', const {});
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'merged': 0};
  }

  /// POST /api/family/invites/decline — decline all of them: the pending edges
  /// are marked declined, the placeholder records left as unclaimed profiles.
  Future<void> declineFamilyInvites() async {
    await _api.postJson('/api/family/invites/decline', const {});
  }

  /// GET /api/family/notifications — my family inbox, newest first, capped at
  /// 100. Types: `relationship_request`, `relationship_accepted`,
  /// `relationship_declined`, `member_joined`, `placeholder_converted`. The
  /// `relationshipId` is exactly what [acceptFamilyRequest] wants. You are never
  /// notified about your own action.
  Future<List<Map<String, dynamic>>> familyNotifications() async {
    final data = await _api.getJson('/api/family/notifications');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// GET /api/family/notifications/unread-count — the badge count.
  Future<int> familyUnreadCount() async {
    final data = await _api.getJson('/api/family/notifications/unread-count');
    if (data is Map && data['unread'] is num) {
      return (data['unread'] as num).toInt();
    }
    return 0;
  }

  /// POST /api/family/notifications/:id/read — mark one read (403 if not mine).
  Future<void> markFamilyNotificationRead(String id) async {
    await _api.postJson('/api/family/notifications/$id/read', const {});
  }

  /// POST /api/family/notifications/read-all — mark every one read.
  Future<void> markAllFamilyNotificationsRead() async {
    await _api.postJson('/api/family/notifications/read-all', const {});
  }

  /// GET /api/family/:id — one member record: `name gender status phone dob dod
  /// placeOfDeath biography profileUrl isPlaceholder linkedUserId createdBy`.
  /// 404 when missing, 400 when [id] isn't a valid ObjectId.
  Future<Map<String, dynamic>> familyMemberById(String id) async {
    final data = await _api.getJson('/api/family/$id');
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Member not found');
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

  /// GET /api/matrimonial/discover — Discover Matches: the same eligible
  /// candidate pool as [matrimonialProfiles], sorted server-side by
  /// `matchPercentage` DESC and shaped into discovery-safe preview cards
  /// (`{profileId, name, age, location, profileImage, occupation,
  /// matchPercentage, matchLevel, sharedInterests, coverage}`). The
  /// percentage/level are computed entirely server-side — nothing here
  /// recomputes or re-sorts them.
  ///
  /// [minAge]/[maxAge]/[location]/[minMatchPercentage]/[marriageIntention]/
  /// [foodPreference]/[interests] are the Discover-session filters added in
  /// Step 23A (backend) / 23B (this screen) — temporary query filters, not a
  /// rewrite of the member's saved matrimonial preferences. [sort] (Step 23D)
  /// is one of `BEST_MATCH`/`NEWEST`/`AGE_LOW_TO_HIGH`/`AGE_HIGH_TO_LOW`; the
  /// backend still owns the actual ordering — this only names the choice.
  Future<Map<String, dynamic>> discoverMatches({
    String? gender,
    String? gotra,
    String? location,
    int? minAge,
    int? maxAge,
    int? minMatchPercentage,
    String? marriageIntention,
    String? foodPreference,
    Set<String>? interests,
    String? sort,
    int limit = 20,
    int skip = 0,
  }) async {
    final q = <String>['limit=$limit', 'skip=$skip'];
    if (gender != null && gender != 'All') q.add('gender=$gender');
    if (gotra != null && gotra != 'All') {
      q.add('gotra=${Uri.encodeQueryComponent(gotra)}');
    }
    if (location != null && location.isNotEmpty) {
      q.add('location=${Uri.encodeQueryComponent(location)}');
    }
    if (minAge != null) q.add('minAge=$minAge');
    if (maxAge != null) q.add('maxAge=$maxAge');
    if (minMatchPercentage != null) {
      q.add('minMatchPercentage=$minMatchPercentage');
    }
    if (marriageIntention != null && marriageIntention.isNotEmpty) {
      q.add('marriageIntention=${Uri.encodeQueryComponent(marriageIntention)}');
    }
    if (foodPreference != null && foodPreference.isNotEmpty) {
      q.add('foodPreference=${Uri.encodeQueryComponent(foodPreference)}');
    }
    if (interests != null && interests.isNotEmpty) {
      q.add('interests=${Uri.encodeQueryComponent(interests.join(','))}');
    }
    if (sort != null && sort.isNotEmpty) q.add('sort=$sort');

    final data = await _api.getJson('/api/matrimonial/discover?${q.join('&')}');
    if (data is Map && data['matches'] is List) {
      return {
        'count': data['count'] ?? (data['matches'] as List).length,
        'matches': (data['matches'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      };
    }
    return const {'count': 0, 'matches': <Map<String, dynamic>>[]};
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
  /// `include` is accepted but produces nothing. No matching/astrology logic
  /// runs here or anywhere in the app — this only submits the two profile
  /// ids + roles and parses the concise `{reportId, ...moduleStatuses}` the
  /// server hands back. This is deliberately NOT [CompatibilityReport] — the
  /// full per-module detail lives at `GET /reports/:reportId` instead; a
  /// caller that needs it must fetch it separately using the `reportId`
  /// returned here (see [compatibilityReport]/[southIndianJataka]).
  Future<CalculateCompatibilityResponse> calculateCompatibility({
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
      return CalculateCompatibilityResponse.fromJson(Map<String, dynamic>.from(data));
    }
    throw ApiException('Could not calculate compatibility');
  }

  /// GET /api/v1/compatibility/reports/:reportId — re-reads a saved report
  /// in full. Used by CompatibilityReportScreen (STEP 25D) once a calculate
  /// call hands back a `reportId` to navigate to; nothing here recomputes
  /// anything. Guards against ever calling `GET /reports/` with a missing id
  /// (a blank [reportId] fails fast, client-side, with no network request).
  Future<CompatibilityReport> compatibilityReport(String reportId) async {
    if (reportId.trim().isEmpty) {
      throw ApiException('Missing compatibility report id');
    }
    final data = await _api.getJson('/api/v1/compatibility/reports/$reportId');
    if (data is Map) {
      return CompatibilityReport.fromJson(Map<String, dynamic>.from(data));
    }
    throw ApiException('Could not load the compatibility report');
  }

  // ── STEP 72 — dedicated single-module report endpoints. Each is a pure
  // reshaping of the same already-calculated/saved report [compatibilityReport]
  // returns in full (never a second calculation) — useful for a future screen
  // that only needs one module's detail without the full report payload.
  // Reuses the exact same module models the full report uses (the dedicated
  // response is that module's own fields plus a top-level `reportId`, which
  // each model's `fromJson` simply ignores).

  /// GET /reports/:reportId/advanced-jataka
  Future<AdvancedJataka> advancedJataka(String reportId) async {
    final data = await _dedicatedModuleJson(reportId, 'advanced-jataka');
    return AdvancedJataka.fromJson(data);
  }

  /// GET /reports/:reportId/kuja-dosha
  Future<KujaDosha> kujaDosha(String reportId) async {
    final data = await _dedicatedModuleJson(reportId, 'kuja-dosha');
    return KujaDosha.fromJson(data);
  }

  /// GET /reports/:reportId/dasha-compatibility
  Future<DashaCompatibility> dashaCompatibility(String reportId) async {
    final data = await _dedicatedModuleJson(reportId, 'dasha-compatibility');
    return DashaCompatibility.fromJson(data);
  }

  /// GET /reports/:reportId/daivagna-parampara
  Future<DaivagnaParampara> daivagnaParampara(String reportId) async {
    final data = await _dedicatedModuleJson(reportId, 'daivagna-parampara');
    return DaivagnaParampara.fromJson(data);
  }

  /// GET /reports/:reportId/vivaha-kala-bala
  Future<VivahaKalaBala> vivahaKalaBala(String reportId) async {
    final data = await _dedicatedModuleJson(reportId, 'vivaha-kala-bala');
    return VivahaKalaBala.fromJson(data);
  }

  /// GET /reports/:reportId/kundli-chart — STEP 80: the Kundli / Janma
  /// Kundali D1+D9 chart snapshot for both partners. Pure reshaping of an
  /// already-calculated/saved report, same as every other dedicated module
  /// endpoint above — no chart math happens client-side.
  Future<KundliChart> kundliChart(String reportId) async {
    final data = await _dedicatedModuleJson(reportId, 'kundli-chart');
    return KundliChart.fromJson(data);
  }

  /// GET /reports/:reportId/profile-compatibility
  Future<ProfileCompatibility> profileCompatibilityReport(String reportId) async {
    final data = await _dedicatedModuleJson(reportId, 'profile-compatibility');
    return ProfileCompatibility.fromJson(data);
  }

  /// Shared fetch for every `/reports/:reportId/<module>` endpoint above —
  /// same empty-id guard as [compatibilityReport]/[southIndianJataka], so a
  /// missing report id never reaches the network.
  Future<Map<String, dynamic>> _dedicatedModuleJson(String reportId, String module) async {
    if (reportId.trim().isEmpty) {
      throw ApiException('Missing compatibility report id');
    }
    final data = await _api.getJson('/api/v1/compatibility/reports/$reportId/$module');
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Could not load the $module result');
  }

  /// GET /api/v1/compatibility/prerequisites/:candidateProfileId — STEP 25A.
  /// Read-only readiness check for the Check Compatibility preparation
  /// screen: what's ready/missing per module (Jataka, Profile/Family/
  /// Personality Compatibility, Family Relationship, Verification), never a
  /// score. [candidateProfileId] is a User id (same identifier every other
  /// compatibility endpoint keys on), not a MatrimonialProfile document id.
  Future<CompatibilityPrerequisites> compatibilityPrerequisites(
      String candidateProfileId) async {
    final data = await _api
        .getJson('/api/v1/compatibility/prerequisites/$candidateProfileId');
    if (data is Map) {
      return CompatibilityPrerequisites.fromJson(
          Map<String, dynamic>.from(data));
    }
    throw ApiException('Could not check compatibility readiness');
  }

  /// GET /api/v1/compatibility/reports/:reportId/south-indian-jataka — STEP
  /// 49/F1: the Check Compatibility screen's South Indian Jataka card.
  /// Karnataka 10-Porutham (reshaped, never recomputed) and Ashtakoota
  /// 36-Guna, kept explicitly separate; `overallAstrologyScore` is always
  /// null (no approved formula combines the two systems). Pure read of an
  /// already-calculated report — nothing here runs any astrology math.
  /// Guards against ever calling `GET /reports//south-indian-jataka` with a
  /// missing id (a blank [reportId] fails fast, client-side, with no network
  /// request) — this is the one endpoint STEP F1 actually consumes.
  Future<SouthIndianJatakaResult> southIndianJataka(String reportId) async {
    if (reportId.trim().isEmpty) {
      throw ApiException('Missing compatibility report id');
    }
    final data =
        await _api.getJson('/api/v1/compatibility/reports/$reportId/south-indian-jataka');
    if (data is Map) {
      return SouthIndianJatakaResult.fromJson(Map<String, dynamic>.from(data));
    }
    throw ApiException('Could not load the South Indian Jataka result');
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
