import 'package:chat_app/modules/home/controllers/channel_controller.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppRouteObserver extends GetObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    _handleRouteChange(route.settings.name);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _handleRouteChange(previousRoute?.settings.name);
  }

  void _handleRouteChange(String? routeName) {
    if (routeName == AppRoutes.driverChat) {
      final controller = Get.find<ChannelController>();

      controller.resetPagination();
      controller.getChannelMembers(page: 1);
      controller.attachScroll();
    }
  }
}
