import 'dart:io';

import 'package:chat_app/core/services/socket_service.dart';
import 'package:chat_app/modules/broadcast_messages/Broadcast_controller.dart';
import 'package:chat_app/modules/home/controllers/channel_controller.dart';
import 'package:chat_app/modules/truck_chat/controller/group_controller.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppRouteObserver extends GetObserver {
  String? _lastRoute;

  @override
  void didPush(Route route, Route? previousRoute) {
    final routeName = route.settings.name;

    if (_isValidRoute(routeName)) {
      if (_lastRoute != routeName) {
        _lastRoute = routeName;
        _handleRouteChange(routeName!);
      }
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    // ❌ DO NOTHING HERE
    // dialog close triggers this → ignore
  }

  bool _isValidRoute(String? routeName) {
    return routeName != null && routeName.startsWith("/"); // only real routes
  }

  void _handleRouteChange(String routeName) {
    print("🔥 Route changed: $routeName");

    if (routeName == AppRoutes.driverChat) {
      final controller = Get.find<ChannelController>();

      controller.resetPagination();
      controller.getChannelMembers(page: 1);
    }

    if (routeName == AppRoutes.truckChat) {
      final controller = Get.find<GroupController>();
      SocketService().emit("staff_open_chat", "");
      controller.refreshData();
      //controller.attachScroll();
    }
    if (routeName == AppRoutes.broadcastMessages) {
      final controller = Get.find<BroadcastController>();

      if (!controller.isInitialized) {
        controller.init();
      }
    }
  }
}
