import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// A member as one pin on the invitation route planner — what `GET
/// /api/user/map` returns.
///
/// Every member here has coordinates: the server geocodes a member's current
/// address when they save it (OpenStreetMap), and leaves anyone it could not
/// place out of this list entirely. So [point] is always safe to plot.
class InvitationMember {
  const InvitationMember({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.samajId = '',
    this.gotra = '',
    this.native = '',
    this.profileUrl = '',
    this.phone = '',
    this.addressLine = '',
    this.area = '',
    this.city = '',
  });

  final String id;
  final String samajId;
  final String name;
  final String gotra;
  final String native;
  final String profileUrl;

  /// Empty unless the member chose to show their number to other members.
  final String phone;

  /// The whole address on one line, street first — what to read out at the door.
  final String addressLine;
  final String area;
  final String city;
  final double latitude;
  final double longitude;

  LatLng get point => LatLng(latitude, longitude);

  /// The line under the name on a card: gotra, falling back to native place.
  String get subtitle {
    if (gotra.isNotEmpty) return '$gotra Gotra';
    return native;
  }

  /// Area, or the city when the member gave no area.
  String get locality => area.isNotEmpty ? area : city;

  static InvitationMember? fromMap(dynamic raw) {
    if (raw is! Map) return null;

    final m = Map<String, dynamic>.from(raw);

    // API structure:
    // currentAddress -> location -> latitude / longitude
    //
    // The directory does not answer with that shape for every row: some carry
    // `address`, some only the permanent one, and some put the fields flat on
    // the user. Take the first block that has anything in it, so a member with
    // coordinates but an unexpected key still shows their address instead of
    // just "N km away".
    Map<String, dynamic> asMap(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

    var address = <String, dynamic>{};
    for (final key in const [
      'currentAddress',
      'address',
      'presentAddress',
      'permanentAddress',
    ]) {
      final candidate = asMap(m[key]);
      if (candidate.isNotEmpty) {
        address = candidate;
        break;
      }
    }
    if (address.isEmpty) address = m; // flat fields on the user itself

    var location = asMap(address['location']);
    if (location.isEmpty) location = asMap(m['location']);
    if (location.isEmpty) location = address; // lat/lng beside the address text

    double? coord(dynamic value) {
      if (value is num) return value.toDouble();

      return double.tryParse((value ?? '').toString());
    }

    final lat = coord(location['latitude']);
    final lng = coord(location['longitude']);

    debugPrint(
      'InvitationMember: ${m['name']} | '
      'lat=$lat | lng=$lng | addressKeys=${address.keys.toList()}',
    );

    // No valid coordinates -> don't put this user on the map. 0/0 counts as
    // none: it is Null Island, and a member who was never geocoded would
    // otherwise show up ~8,600 km from anyone in India.
    if (lat == null || lng == null || (lat == 0 && lng == 0)) {
      debugPrint('❌ No coordinates for ${m['name']}');
      return null;
    }

    String s(String key) => (m[key] ?? '').toString();

    /// The first of [keys] that has a value, looked for in the address block and
    /// then on the user — so a flat `city` still lands when the block has none.
    String pick(List<String> keys) {
      for (final key in keys) {
        final v = (address[key] ?? m[key] ?? '').toString().trim();
        if (v.isNotEmpty && v.toLowerCase() != 'null') return v;
      }
      return '';
    }

    return InvitationMember(
      id: s('id'),
      samajId: s('samajId'),
      name: s('name'),
      gotra: s('gotra'),
      native: s('native'),
      profileUrl: s('profileUrl'),
      phone: s('phone'),

      // The address text sits next to the coordinates, under whichever names
      // this row happens to use.
      // /api/user/map already joins the parts into one line; the directory and
      // profile shapes leave them separate, so build it when it is missing.
      addressLine: pick(const ['addressLine']).isNotEmpty
          ? pick(const ['addressLine'])
          : [
              pick(const ['houseNo', 'houseNumber', 'flatNo', 'building']),
              pick(const [
                'street',
                'streetAddress',
                'addressLine1',
                'line1',
                'road',
              ]),
              pick(const ['landmark', 'addressLine2', 'line2']),
              pick(const ['pincode', 'pinCode', 'postalCode', 'zip']),
            ].where((v) => v.isNotEmpty).join(', '),

      area: pick(const ['area', 'locality', 'taluk', 'village']),
      city: pick(const ['city', 'town', 'district', 'state']),

      latitude: lat,
      longitude: lng,
    );
  }
}

/// One page of the planner's data: the members who can be visited, nearest
/// first from the position the request was made with.
///
/// There is no `me` here — the route starts from the device position the client
/// sent to get this page, not from a saved address.
class InvitationMap {
  const InvitationMap({
    this.members = const [],
    this.count = 0,
    this.page = 1,
    this.totalPages = 1,
  });

  final List<InvitationMember> members;

  /// Mapped members in total, not just on this page.
  final int count;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

/// Straight-line kilometres between two points. Not road distance — the same
/// approximation the server sorts by.
double distanceKm(LatLng a, LatLng b) =>
    const Distance().as(LengthUnit.Kilometer, a, b);

/// A link that opens the planned round in the phone's maps app, and how many
/// stops had to be left off it.
class DirectionsLink {
  const DirectionsLink(this.url, this.dropped);

  final Uri url;

  /// Stops beyond what the maps link can carry. 0 for any ordinary round.
  final int dropped;
}

/// Builds the turn-by-turn link for a planned route.
///
/// Google's universal directions URL: the Google Maps app answers it on both
/// Android and iOS, and the browser handles it when the app isn't installed.
/// The stops stay in the order given — the URL has no "optimise" flag, which
/// suits us, because the server already worked out the best order.
///
/// The scheme carries at most nine intermediate waypoints plus a destination,
/// so a round longer than ten stops is truncated rather than rejected: better
/// to navigate the first ten and say so.
DirectionsLink directionsLink({LatLng? origin, required List<LatLng> stops}) {
  const maxStops = 10; // 9 waypoints + the destination

  final dropped = stops.length > maxStops ? stops.length - maxStops : 0;
  final used = dropped > 0 ? stops.sublist(0, maxStops) : stops;

  String fmt(LatLng p) =>
      '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}';

  final waypoints = used.sublist(0, used.length - 1);
  final url = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    if (origin != null) 'origin': fmt(origin),
    'destination': fmt(used.last),
    if (waypoints.isNotEmpty) 'waypoints': waypoints.map(fmt).join('|'),
    'travelmode': 'driving',
  });

  return DirectionsLink(url, dropped);
}

/// One member in a planned route: where they fall in the visiting order, and
/// how far it is from the stop before them.
class RouteStop {
  const RouteStop({
    required this.member,
    required this.order,
    required this.legKm,
  });

  final InvitationMember member;

  /// 1-based position in the route.
  final int order;

  /// Distance from the previous stop — from your starting point, for stop 1.
  final double legKm;

  static RouteStop? fromMap(dynamic raw) {
    final member = InvitationMember.fromMap(raw);
    if (member == null || raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    return RouteStop(
      member: member,
      order: (m['order'] as num?)?.toInt() ?? 0,
      legKm: (m['legKm'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// The optimised round: `POST /api/user/route` decides the order, not us.
///
/// [geometry] is the line to draw. When [isEstimate] is false it is the actual
/// roads OSRM routed along; when it is true OSRM could not be reached and the
/// line is straight hops between stops, with distances to match — worth saying
/// out loud rather than presenting as driving distance.
class RoutePlan {
  const RoutePlan({
    required this.origin,
    this.stops = const [],
    this.totalKm = 0,
    this.totalMinutes = 0,
    this.geometry = const [],
    this.isEstimate = false,
  });

  final LatLng origin;
  final List<RouteStop> stops;
  final double totalKm;
  final int totalMinutes;
  final List<LatLng> geometry;
  final bool isEstimate;

  static RoutePlan? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);

    LatLng? point(dynamic v) {
      if (v is! Map) return null;
      final lat = (v['latitude'] as num?)?.toDouble();
      final lng = (v['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return LatLng(lat, lng);
    }

    final origin = point(m['origin']);
    if (origin == null) return null;

    final stops = <RouteStop>[];
    for (final raw in (m['stops'] as List? ?? const [])) {
      final stop = RouteStop.fromMap(raw);
      if (stop != null) stops.add(stop);
    }
    stops.sort((a, b) => a.order.compareTo(b.order));

    final geometry = <LatLng>[];
    for (final raw in (m['geometry'] as List? ?? const [])) {
      final p = point(raw);
      if (p != null) geometry.add(p);
    }

    return RoutePlan(
      origin: origin,
      stops: stops,
      totalKm: (m['totalKm'] as num?)?.toDouble() ?? 0,
      totalMinutes: (m['totalMinutes'] as num?)?.toInt() ?? 0,
      geometry: geometry,
      isEstimate: (m['source'] ?? '').toString() == 'estimate',
    );
  }
}
