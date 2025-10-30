import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quickride/config.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _http;
  String? _token;

  ApiClient({http.Client? httpClient, this.baseUrl = Config.baseUrl})
    : _http = httpClient ?? http.Client();

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300)
      return data as Map<String, dynamic>;
    throw Exception(data['error'] ?? 'Request failed');
  }

  Future<List<dynamic>> getList(String path) async {
    final res = await _http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    final data = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300)
      return data as List<dynamic>;
    throw Exception(
      (data is Map) ? data['error'] ?? 'Request failed' : 'Request failed',
    );
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final res = await _http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    final data = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300)
      return data as Map<String, dynamic>;
    throw Exception(data['error'] ?? 'Request failed');
  }

  Future<Map<String, dynamic>> postMultipart(
    String path,
    Map<String, String> fields, {
    String? fileField,
    String? filePath,
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
    fields.forEach((k, v) => req.fields[k] = v);
    if (fileField != null && filePath != null) {
      req.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    }
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final data = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300)
      return data as Map<String, dynamic>;
    throw Exception(data['error'] ?? 'Upload failed');
  }
}
