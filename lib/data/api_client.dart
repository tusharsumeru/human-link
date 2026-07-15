import 'dart:convert';
import 'package:http/http.dart' as http;
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
    req.files.add(await http.MultipartFile.fromPath(fileField, filePath));
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
    final msg = (data is Map && (data['message'] ?? data['error']) != null)
        ? (data['message'] ?? data['error']).toString()
        : 'Request failed';
    throw ApiException(msg, statusCode: res.statusCode);
  }
}
