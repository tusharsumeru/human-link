import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Thin HTTP wrapper around the Next.js API routes. Throws [ApiException] on any
/// non-2xx response so callers can fall back to embedded demo data.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<dynamic> getJson(String path) async {
    final res = await _client
        .get(_uri(path), headers: {'Accept': 'application/json'})
        .timeout(ApiConfig.timeout);
    return _decode(res);
  }

  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    final res = await _client
        .post(
          _uri(path),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.timeout);
    return _decode(res);
  }

  Future<dynamic> patchJson(String path, Map<String, dynamic> body) async {
    final res = await _client
        .patch(
          _uri(path),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.timeout);
    return _decode(res);
  }

  Future<dynamic> putJson(String path, Map<String, dynamic> body) async {
    final res = await _client
        .put(
          _uri(path),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.timeout);
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
    final msg = (data is Map && data['error'] is String)
        ? data['error'] as String
        : 'Request failed';
    throw ApiException(msg, statusCode: res.statusCode);
  }
}
