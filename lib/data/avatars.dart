/// Portrait photos are no longer stock/dummy images. We return an empty URL so
/// [PexelsImage]/[AvatarImage] fall back to clean name initials over a forest
/// gradient. Real photos come from user uploads, not Pexels.
String px(int id) => '';

/// Maps an avatar key to a portrait URL. Returns empty so the initials
/// fallback is shown instead of a dummy stock photo.
String avatarUrl(String? key) => '';

/// Returns initials for a name, used as an avatar fallback.
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}
