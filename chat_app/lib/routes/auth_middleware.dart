import 'package:chat_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  Future<RouteSettings?> redirectFuture(String? route) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    // 🔐 Already logged in → block /login
    if (token != null && token.isNotEmpty && route == AppRoutes.login) {
      return const RouteSettings(name: AppRoutes.home);
    }

    // 🚫 Not logged in → block everything except /login
    if ((token == null || token.isEmpty) && route != AppRoutes.login) {
      return const RouteSettings(name: AppRoutes.login);
    }

    return null;
  }
}
