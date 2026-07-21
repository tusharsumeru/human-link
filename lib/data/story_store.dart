import 'package:flutter/foundation.dart';

import 'repository.dart';

/// The author of a story tray (`{_id, userName}` from the API).
class StoryAuthor {
  const StoryAuthor(this.id, this.userName);
  final String id;
  final String userName;

  factory StoryAuthor.from(dynamic u) {
    if (u is Map) {
      return StoryAuthor(
          (u['_id'] ?? '').toString(), (u['userName'] ?? '').toString());
    }
    return StoryAuthor(u?.toString() ?? '', '');
  }
}

/// A single active story (image/video on Cloudinary), expiring after 24h.
class Story {
  Story({
    required this.id,
    required this.author,
    required this.mediaUrl,
    required this.isVideo,
    required this.caption,
    required this.createdAt,
    required this.expiresAt,
    required this.viewCount,
  });

  final String id;
  final StoryAuthor author;
  final String mediaUrl;
  final bool isVideo;
  final String caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int viewCount;

  factory Story.fromMap(Map<String, dynamic> m, {StoryAuthor? author}) {
    return Story(
      id: (m['_id'] ?? '').toString(),
      author: author ?? StoryAuthor.from(m['userId']),
      mediaUrl: (m['mediaUrl'] ?? '').toString(),
      isVideo: (m['storyType'] ?? '').toString() == 'video',
      caption: (m['caption'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((m['createdAt'] ?? '').toString()) ?? DateTime.now(),
      expiresAt:
          DateTime.tryParse((m['expiresAt'] ?? '').toString()) ?? DateTime.now(),
      viewCount: (m['viewCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One author's stack of active stories.
class StoryTray {
  StoryTray({required this.author, required this.latestAt, required this.stories});
  final StoryAuthor author;
  final DateTime latestAt;
  final List<Story> stories;

  factory StoryTray.fromMap(Map<String, dynamic> m) {
    final author = StoryAuthor.from(m['author']);
    final stories = ((m['stories'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Story.fromMap(Map<String, dynamic>.from(e), author: author))
        .toList();
    return StoryTray(
      author: author,
      latestAt:
          DateTime.tryParse((m['latestAt'] ?? '').toString()) ?? DateTime.now(),
      stories: stories,
    );
  }
}

/// App-wide store backed by the `/api/stories` endpoints.
///
/// Stories are uploaded to the backend (Cloudinary), expire server-side after
/// 24h, and views are recorded per user. "Seen" ring state is tracked locally
/// for the session (the feed doesn't report per-viewer state).
class StoryStore extends ChangeNotifier {
  StoryStore._();
  static final StoryStore instance = StoryStore._();
  final Repository _repo = Repository.instance;

  List<StoryTray> _trays = const [];
  List<Story> _mine = const [];
  final Set<String> _viewed = <String>{}; // story ids opened this session
  bool _loading = false;

  bool get loading => _loading;
  List<Story> get mine => List.unmodifiable(_mine);
  bool get hasActiveStory => _mine.isNotEmpty;

  String? get _myUserName =>
      _mine.isNotEmpty ? _mine.first.author.userName : null;

  /// Everyone else's trays (the feed includes my own tray, so drop it here).
  List<StoryTray> get otherTrays {
    final me = _myUserName;
    if (me == null || me.isEmpty) return List.unmodifiable(_trays);
    return _trays.where((t) => t.author.userName != me).toList(growable: false);
  }

  bool isViewed(String storyId) => _viewed.contains(storyId);

  /// A tray reads as "seen" once every story in it was opened this session.
  bool trayViewed(StoryTray t) =>
      t.stories.isNotEmpty && t.stories.every((s) => _viewed.contains(s.id));

  /// Loads the feed and my own stories from the backend.
  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final feed = await _repo.storiesFeed(limit: 30);
      _trays = ((feed['trays'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => StoryTray.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      final me = await _repo.myStories();
      _mine = me.map(Story.fromMap).toList();
    } catch (_) {
      // Keep whatever we had; the rail just won't update this cycle.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Uploads a new story (with optional tags / tree link / location), then
  /// refreshes so it appears in the rail.
  Future<void> addStory(
    String filePath, {
    String caption = '',
    String visibility = 'community',
    List<String> taggedMembers = const [],
    String? treeNodeId,
    String? locationName,
    String? locationKind,
  }) async {
    await _repo.createStory(
      filePath: filePath,
      caption: caption,
      visibility: visibility,
      taggedMembers: taggedMembers,
      treeNodeId: treeNodeId,
      locationName: locationName,
      locationKind: locationKind,
    );
    await refresh();
  }

  /// Records a view (locally for the ring, and on the backend for "seen by").
  Future<void> markViewed(String storyId) async {
    if (_viewed.add(storyId)) notifyListeners();
    try {
      await _repo.markStoryViewed(storyId);
    } catch (_) {/* view is best-effort */}
  }

  Future<List<Map<String, dynamic>>> viewers(String storyId) =>
      _repo.storyViewers(storyId);

  /// One story with counts + the caller's liked flag.
  Future<Map<String, dynamic>> detail(String storyId) => _repo.story(storyId);

  /// Toggle a like; returns `{liked, likeCount}`.
  Future<Map<String, dynamic>> toggleLike(String storyId) =>
      _repo.toggleStoryLike(storyId);

  Future<void> addComment(String storyId, String content) =>
      _repo.addStoryComment(storyId, content);

  Future<List<Map<String, dynamic>>> comments(String storyId) =>
      _repo.storyComments(storyId);

  Future<void> deleteStory(String storyId) async {
    await _repo.deleteStory(storyId);
    await refresh();
  }
}
