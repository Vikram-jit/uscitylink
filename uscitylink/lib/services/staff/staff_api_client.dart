import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';

/// Error from the API, keeping the response body (e.g. `requiresNote` on system messages).
/// `toString()` matches the rest of the app's errors ("Exception: " followed by the message).
class StaffApiError implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic> body;

  StaffApiError(this.message, this.statusCode, [this.body = const {}]);

  @override
  String toString() => 'Exception: $message';
}

/// Small HTTP client for the staff Compliance and System Messages screens.
///
/// The shared NetworkApiService logs the user out on any 403 and drops the body of a 400. Those
/// screens need both: a 403 here means "not allowed", not "session expired", and a 400 can carry
/// extra fields. Only an actual expired session (401, or a 403 without a token) logs out.
class StaffApiClient {
  final _prefs = UserPreferenceController();
  static const _timeout = Duration(seconds: 20);

  /// Tests point this at a local server; the app always uses Constant.url.
  static String? baseUrlOverride;

  Future<Map<String, String>> _headers() async {
    final headers = {'Content-Type': 'application/json'};
    final token = await _prefs.getToken();
    if (token != null && token.toString().isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('${baseUrlOverride ?? Constant.url}/$path');
    if (query == null) return uri;
    final q = <String, String>{};
    query.forEach((k, v) {
      if (v != null && v.toString().isNotEmpty) q[k] = v.toString();
    });
    return uri.replace(queryParameters: {...uri.queryParameters, ...q});
  }

  Future<Map<String, dynamic>> get(String path, [Map<String, dynamic>? query]) =>
      _send(() async => http.get(_uri(path, query), headers: await _headers()));

  Future<Map<String, dynamic>> post(String path, [Object? body]) =>
      _send(() async => http.post(_uri(path), headers: await _headers(), body: jsonEncode(body ?? {})));

  Future<Map<String, dynamic>> put(String path, [Object? body]) =>
      _send(() async => http.put(_uri(path), headers: await _headers(), body: jsonEncode(body ?? {})));

  Future<Map<String, dynamic>> delete(String path) =>
      _send(() async => http.delete(_uri(path), headers: await _headers()));

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request().timeout(_timeout);
    } on SocketException {
      throw StaffApiError('No Internet Connection', 0);
    } on TimeoutException {
      throw StaffApiError('The server took too long to answer. Try again.', 0);
    }

    Map<String, dynamic> body = {};
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    final message = (body['message'] ?? 'Request failed (${res.statusCode})').toString();
    final sessionExpired =
        res.statusCode == 401 || (res.statusCode == 403 && message.toLowerCase().contains('no token'));
    if (sessionExpired && Get.isRegistered<LoginController>()) {
      await Get.find<LoginController>().logOut();
    }
    throw StaffApiError(message, res.statusCode, body);
  }
}
