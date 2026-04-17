import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic body;
  ApiException(this.statusCode, this.message, {this.body});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final TokenStorage _storage;
  final http.Client _http;

  ApiClient({TokenStorage? storage, http.Client? httpClient})
      : _storage = storage ?? TokenStorage(),
        _http = httpClient ?? http.Client();

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final t = await _storage.read();
      if (t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  Future<dynamic> get(String path,
      {bool auth = true, Duration? timeout}) async {
    final res = await _http
        .get(_uri(path), headers: await _headers(auth: auth))
        .timeout(timeout ?? ApiConfig.timeout);
    return _parse(res);
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true, Duration? timeout}) async {
    final res = await _http
        .post(_uri(path),
            headers: await _headers(auth: auth),
            body: body == null ? null : jsonEncode(body))
        .timeout(timeout ?? ApiConfig.timeout);
    return _parse(res);
  }

  Future<dynamic> put(String path, {Object? body, bool auth = true}) async {
    final res = await _http
        .put(_uri(path),
            headers: await _headers(auth: auth),
            body: body == null ? null : jsonEncode(body))
        .timeout(ApiConfig.timeout);
    return _parse(res);
  }

  Future<void> delete(String path, {bool auth = true}) async {
    final res = await _http
        .delete(_uri(path), headers: await _headers(auth: auth))
        .timeout(ApiConfig.timeout);
    _parse(res, expectBody: false);
  }

  dynamic _parse(http.Response res, {bool expectBody = true}) {
    final code = res.statusCode;
    final text = res.body;
    dynamic decoded;
    if (text.isNotEmpty) {
      try {
        decoded = jsonDecode(text);
      } catch (_) {
        decoded = text;
      }
    }
    if (code >= 200 && code < 300) {
      return decoded;
    }
    final msg = decoded is Map && decoded['error'] != null
        ? decoded['error'].toString()
        : 'HTTP $code';
    throw ApiException(code, msg, body: decoded);
  }
}
