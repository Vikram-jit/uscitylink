import 'package:chat_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/services/socket_service.dart';
import '../core/storage/storage_service.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final token = StorageService.syncGetToken();
    print(token);
    // ❌ NOT logged in → block protected routes
    if (token == null || token.isEmpty) {
      if (route != AppRoutes.login) {
        return const RouteSettings(name: AppRoutes.login);
      }
      return null; // allow login
    }

    // ✅ Logged in → prevent access to login page
    if (route == AppRoutes.login) {
      return const RouteSettings(name: AppRoutes.home);
    }

    // ✅ Logged in → connect socket once
    SocketService().connect(token);

    return null; // allow route
  }
}
