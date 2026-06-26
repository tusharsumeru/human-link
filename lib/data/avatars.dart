/// Real Indian portrait photos from Pexels — ported from lib/avatarSvgs.ts.
String px(int id) =>
    'https://images.pexels.com/photos/$id/pexels-photo-$id.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&fit=crop';

const Map<String, int> _avatarIds = {
  '1': 4053536,
  '2': 11138457,
  '3': 2601464,
  '4': 5746790,
  '5': 34515496,
  '6': 7485047,
  'elder': 17815020,
};

/// Maps an avatar key (e.g. "6", "elder") to a Pexels portrait URL.
String avatarUrl(String? key) {
  final id = _avatarIds[key ?? ''];
  if (id != null) return px(id);
  return px(7485047); // default portrait
}

/// Returns initials for a name, used as an avatar fallback.
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}
