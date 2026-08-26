import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Client HTTP minimal vers le backend Node.js.
/// Change [baseUrl] selon ton environnement :
/// - Émulateur Android : http://10.0.2.2:4000
/// - iOS simulator / web : http://localhost:4000
/// - Appareil physique : http://<ip-locale-de-ton-pc>:4000
class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000/api',
  );

  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'iai_horizon_token';

  Future<String?> get token async => _storage.read(key: _tokenKey);
  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final t = await token;
      if (t != null) headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  Future<dynamic> get(String path, {bool auth = true}) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: await _headers(auth: auth));
    return _handle(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: await _headers(auth: auth));
    return _handle(res);
  }

  dynamic _handle(http.Response res) {
    final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded is Map ? decoded['data'] : decoded;
    }
    final message = decoded is Map ? (decoded['message'] ?? 'Erreur inconnue') : 'Erreur inconnue';
    throw ApiException(message.toString(), res.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}