import 'dart:convert';

import 'package:chat_app/modules/auth/auth_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static String? _token;

  /// Call this ONCE at app start
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("token");
  }

  /// SYNC access for middleware
  static String? syncGetToken() {
    return _token;
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
    _token = token;
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    _token = null;
  }

  static Future<void> saveUserData(AuthModel data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user", jsonEncode(data));
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<AuthModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    final userString = prefs.getString("user");
    if (userString == null || userString.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> json = jsonDecode(userString);
      return AuthModel.fromJson(json);
    } catch (e) {
      print("Failed to parse user: $e");
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }
}
