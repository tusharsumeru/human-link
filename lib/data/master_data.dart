/// Admin-managed pick lists, fetched from the server's master-data endpoints.
///
/// The admin panel's Dropdown Options screen edits these at
/// `/api/master/<route>`; the four routes in [MasterLists] are the ones it
/// marks "Live". Everything else on that screen is still a fixed list built
/// into the app or a server enum, and is shown there for reference only.
///
/// The contract the panel states to the admin is "edits reach the app on its
/// next load", so this caches per route for the lifetime of the process: a
/// screen opened twice does not fetch twice, and a restart picks up changes.
library;

import 'repository.dart';

/// One entry of a pick list, as `/api/master/<route>` returns it
/// (`MasterItemView` on the server).
class MasterItem {
  const MasterItem({
    required this.id,
    required this.name,
    required this.value,
    this.image = '',
    this.order = 0,
  });

  /// What the member sees.
  final String name;

  /// What gets stored on their record. Equal to [name] for the plain text
  /// lists these four are — kept separate because the endpoint models
  /// enum-backed lists with the same shape.
  final String value;

  final String id;

  /// Absolute URL of the entry's picture, or empty. Only Kuladevata uses it.
  final String image;

  final int order;

  factory MasterItem.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? '').toString();
    return MasterItem(
      id: (json['id'] ?? '').toString(),
      name: name,
      // An entry saved without an explicit value stores its label, which is
      // what the text lists do anyway.
      value: (json['value'] ?? '').toString().isEmpty
          ? name
          : json['value'].toString(),
      image: (json['image'] ?? '').toString(),
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  /// A bundled constant dressed as a server entry, so a caller that falls back
  /// handles one type rather than two.
  factory MasterItem.local(String value) =>
      MasterItem(id: 'local:$value', name: value, value: value);
}

/// The route segments of the four lists the admin panel edits live.
class MasterLists {
  MasterLists._();

  static const String kuladevatas = 'kuladevatas';
  static const String bloodGroups = 'blood-groups';
  static const String occupations = 'occupations';
  static const String annualIncomes = 'annual-incomes';
}

/// Reads the pick lists, falling back to the list bundled in the app.
///
/// The fallback is not a nicety: `/api/master/*` is not registered on every
/// deployment yet, and a profile form whose Blood group dropdown is empty is
/// worse than one showing the eight groups it always showed. A failed fetch is
/// cached like a successful one so a dead endpoint costs one request per run
/// rather than one per screen.
class MasterData {
  MasterData._();

  static final MasterData instance = MasterData._();

  final Map<String, Future<List<MasterItem>>> _cache = {};

  /// The entries for [route], or [fallback] if the server has none to give.
  Future<List<MasterItem>> list(
    String route, {
    required List<String> fallback,
  }) {
    return _cache.putIfAbsent(route, () async {
      try {
        final items = await Repository.instance.masterList(route);
        // An endpoint that exists but is empty still means "no options", and
        // an empty dropdown is a dead end — keep the bundled list.
        if (items.isNotEmpty) return items;
      } catch (_) {
        // Offline, or the route isn't registered on this backend.
      }
      return fallback.map(MasterItem.local).toList();
    });
  }

  /// Drops the cache so the next read refetches. For a pull-to-refresh or a
  /// sign-in that changes who the lists are being read as.
  void invalidate() => _cache.clear();
}

/// The display names of [items], with [current] guaranteed present.
///
/// `DropdownButtonFormField` asserts that its value matches exactly one item,
/// so a saved value the admin has since renamed or deactivated would throw.
/// Keeping it at the head of the list means an old record stays editable and
/// the member is never silently switched to something they did not choose.
List<String> namesWith(List<MasterItem> items, String? current) {
  final names = [for (final i in items) i.name];
  final value = (current ?? '').trim();
  if (value.isEmpty || names.contains(value)) return names;
  return [value, ...names];
}
