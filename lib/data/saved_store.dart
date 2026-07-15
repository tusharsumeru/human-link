import 'package:flutter/material.dart';

/// A post or reel the user bookmarked. Carries just enough to render a saved
/// thumbnail (and re-open a reel) without reaching back into the feed.
class SavedItem {
  const SavedItem({
    required this.id,
    required this.author,
    required this.caption,
    this.mediaPath,
    this.mediaUrl,
    this.isReel = false,
    this.emoji = '🎬',
    this.gradient = const [Color(0xFF1B4332), Color(0xFF2D6A4F)],
  });

  final String id; // matches the feed post id, so a save can be toggled off
  final String author;
  final String caption;
  final String? mediaPath; // local file (video when isReel, else an image)
  final String? mediaUrl; // remote (Cloudinary) media from the backend feed
  final bool isReel;
  final String emoji; // placeholder glyph when there's no mediaPath
  final List<Color> gradient;
}

/// Global, app-wide store of bookmarked posts/reels. The feed's bookmark button
/// and the full-screen reel both write here; the profile's "Saved" shelf reads
/// it. In-memory only — saves live until the app is restarted.
class SavedStore extends ChangeNotifier {
  SavedStore._();
  static final SavedStore instance = SavedStore._();

  final List<SavedItem> _items = <SavedItem>[];
  List<SavedItem> get items => List.unmodifiable(_items);

  int get count => _items.length;

  bool isSaved(String id) => _items.any((e) => e.id == id);

  /// Adds the item if it isn't saved, removes it otherwise. Returns the new
  /// saved-state (true → now saved) so callers can show the right feedback.
  bool toggle(SavedItem item) {
    final i = _items.indexWhere((e) => e.id == item.id);
    if (i >= 0) {
      _items.removeAt(i);
      notifyListeners();
      return false;
    }
    _items.insert(0, item); // newest first
    notifyListeners();
    return true;
  }

  void remove(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
