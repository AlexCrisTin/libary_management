import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AppSession {
  AppSession._();

  static String? token;
  static Map<String, dynamic>? user;

  static bool get isLoggedIn => token != null;
  static bool get isReader => user?['role'] == 'reader';
  static String get displayName =>
      (user?['full_name'] ?? user?['username'] ?? '').toString();
  static String? get readerId => user?['reader_id']?.toString();

  static void setAuth(Map<String, dynamic> data) {
    token = data['token']?.toString();
    user = _map(data['user']);
  }

  static void clear() {
    token = null;
    user = null;
  }
}

class ApiClient {
  ApiClient._();

  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000/api'
        : 'http://127.0.0.1:3000/api';
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (AppSession.token != null) 'Authorization': 'Bearer ${AppSession.token}',
  };

  static Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final uri = _uri(path, query);
    return _decode(await http.get(uri, headers: _headers));
  }

  static Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    return _decode(
      await http.post(
        _uri(path),
        headers: _headers,
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
    );
  }

  static Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    return _decode(
      await http.put(
        _uri(path),
        headers: _headers,
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
    );
  }

  static Future<dynamic> delete(String path) async {
    return _decode(await http.delete(_uri(path), headers: _headers));
  }

  static Future<dynamic> uploadImage(
    String path, {
    required List<int> bytes,
    String filename = 'book-cover.jpg',
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers['Accept'] = 'application/json';
    if (AppSession.token != null) {
      request.headers['Authorization'] = 'Bearer ${AppSession.token}';
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ),
    );
    final streamed = await request.send();
    return _decode(await http.Response.fromStream(streamed));
  }

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final values = <String, String>{};
    query?.forEach((key, value) {
      final text = value?.toString() ?? '';
      if (text.isNotEmpty) values[key] = text;
    });
    return Uri.parse(
      '$baseUrl$normalized',
    ).replace(queryParameters: values.isEmpty ? null : values);
  }

  static dynamic _decode(http.Response response) {
    dynamic payload;
    try {
      payload = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw ApiException(
        'Máy chủ trả về dữ liệu không hợp lệ.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload is Map ? payload['message']?.toString() : null;
      final detail = payload is Map ? payload['error']?.toString() : null;
      throw ApiException(
        detail != null && detail.isNotEmpty && response.statusCode >= 500
            ? '${message ?? 'Lỗi máy chủ'} ($detail)'
            : message ?? 'Không thể kết nối máy chủ (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    if (payload is Map && payload['success'] == false) {
      throw ApiException(payload['message']?.toString() ?? 'Có lỗi xảy ra.');
    }
    return payload is Map ? payload['data'] : payload;
  }
}

String apiAssetUrl(String? value) {
  final path = value?.trim() ?? '';
  if (path.isEmpty || path.startsWith('data:')) return path;
  final uri = Uri.tryParse(path);
  if (uri != null && uri.hasScheme) return path;
  final normalized = path.startsWith('/') ? path : '/$path';
  return '${Uri.parse(ApiClient.baseUrl).origin}$normalized';
}

Map<String, dynamic> apiMap(dynamic value) => _map(value);

List<Map<String, dynamic>> apiList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map(_map).toList();
}

Map<String, dynamic> _map(dynamic value) {
  if (value is! Map) return <String, dynamic>{};
  return value.map((key, value) => MapEntry(key.toString(), value));
}

String apiText(dynamic value, {String fallback = '—'}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text == 'null' ? fallback : text;
}

String apiDate(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return '—';
  final date = DateTime.tryParse(text)?.toLocal();
  if (date == null) return text;
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
