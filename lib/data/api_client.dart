import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:mime/mime.dart' show lookupMimeType;
import 'api_config.dart';

/// Thin HTTP wrapper around the backend API routes. Throws [ApiException] on any
/// non-2xx response so callers can fall back to embedded demo data.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Holds the current bearer token (JWT). [AuthService] sets it on login (from
/// the `/api/user/login` response) and clears it on logout; [ApiClient] attaches
/// it to every request so the protected endpoints (posts, likes, comments) work.
class ApiAuth {
  ApiAuth._();
  static String? token;

  /// Called when the backend rejects a request with 401 (missing/expired/invalid
  /// token). AuthService registers this to clear the session so the router sends
  /// the user back to login to obtain a fresh token, instead of the app looking
  /// "logged in" while every protected call silently fails.
  static void Function()? onUnauthorized;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> _headers({bool json = false}) {
    final h = <String, String>{
      'Accept': 'application/json',
      // ngrok's free tunnels otherwise serve an HTML interstitial to
      // non-browser clients; this header returns the real JSON response.
      'ngrok-skip-browser-warning': 'true',
    };
    if (json) h['Content-Type'] = 'application/json';
    final t = ApiAuth.token;
    if (t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    return h;
  }

  Future<dynamic> getJson(String path) async {
    final res = await _client
        .get(_uri(path), headers: _headers())
        .timeout(ApiConfig.timeout);
    return _decode(res);
  }

  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    final res = await _client
        .post(_uri(path), headers: _headers(json: true), body: jsonEncode(body))
        .timeout(ApiConfig.timeout);
    return _decode(res);
  }

  Future<dynamic> patchJson(String path, Map<String, dynamic> body) async {
    final res = await _client
        .patch(_uri(path), headers: _headers(json: true), body: jsonEncode(body))
        .timeout(ApiConfig.timeout);
    return _decode(res);
  }

  Future<dynamic> putJson(String path, Map<String, dynamic> body) async {
    final res = await _client
        .put(_uri(path), headers: _headers(json: true), body: jsonEncode(body))
        .timeout(ApiConfig.timeout);
    return _decode(res);
  }

  Future<dynamic> deleteJson(String path) async {
    final res = await _client
        .delete(_uri(path), headers: _headers())
        .timeout(ApiConfig.timeout);
    return _decode(res);
  }

  /// multipart/form-data upload (e.g. create post → uploads `media`). Extra
  /// [fields] are sent alongside the file. Uses a longer timeout than JSON
  /// calls since uploads take longer than the [ApiConfig.timeout] default.
  Future<dynamic> postMultipart(
    String path, {
    required String fileField,
    required String filePath,
    Map<String, String> fields = const {},
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final req = http.MultipartRequest('POST', _uri(path));
    req.headers.addAll(_headers()); // don't set Content-Type; multipart sets it
    req.fields.addAll(fields);
    // Tag the file part with its real MIME type. Without this the http package
    // sends `application/octet-stream`, which the backend rejects ("Only image
    // and video files are allowed"). Sniff the file header first (robust to a
    // missing/odd extension on picker temp files), then fall back to the path.
    final header = await File(filePath).openRead(0, 512).first;
    final mimeType = lookupMimeType(filePath, headerBytes: header) ??
        lookupMimeType(filePath) ??
        'application/octet-stream';
    req.files.add(await http.MultipartFile.fromPath(
      fileField,
      filePath,
      contentType: MediaType.parse(mimeType),
    ));
    final streamed = await _client.send(req).timeout(timeout);
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    dynamic data;
    try {
      data = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      data = null;
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    // A 401 means our token is missing, invalid, or expired. Drop it and let the
    // app clear the session so the user is routed to login — otherwise the same
    // request keeps failing forever while the UI still shows a signed-in state.
    if (res.statusCode == 401) {
      ApiAuth.token = null;
      ApiAuth.onUnauthorized?.call();
    }
    final msg = (data is Map && (data['message'] ?? data['error']) != null)
        ? (data['message'] ?? data['error']).toString()
        : 'Request failed';
    throw ApiException(msg, statusCode: res.statusCode);
  }
}
