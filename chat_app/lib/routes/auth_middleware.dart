import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  Future<RouteSettings?> redirectFuture(String? route) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    // If token exists, user is already logged in → block login page
    if (token != null && token.isNotEmpty && route == AppRoutes.login) {
      return const RouteSettings(name: AppRoutes.home);
    }

    // If NO token and user tries to open home → redirect to login
    if ((token == null || token.isEmpty) && route == AppRoutes.home) {
      return const RouteSettings(name: AppRoutes.login);
    }

    return null; // allow normal navigation
  }
}
