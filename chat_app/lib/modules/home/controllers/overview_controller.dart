import 'dart:convert';

import 'package:chat_app/core/services/socket_service.dart';
import 'package:chat_app/modules/home/models/overview_model.dart';
import 'package:chat_app/modules/home/services/overview_service.dart';
import 'package:get/get.dart';

class OverviewController extends GetxController {
  final SocketService _socketService = SocketService();
  final RxMap<String, bool> typingUsers = <String, bool>{}.obs;

  var currentTab = 0.obs; // 0 = Messages, 1 = Files, 2 = Pins
  var isLoading = false.obs;
  var errorText = "".obs;
  var overview = OverViewModel().obs;
  @override
  void onInit() {
    super.onInit();
    getOverview();
    _listenDriverOnlineStatus();
  }

  void _listenDriverOnlineStatus() {
    final socket = _socketService.socket;
    if (socket == null) return;

    socket.off('user_online_driver_web');
    socket.off('typingUser');

    socket.on('user_online_driver_web', (data) {
      _handleDriverOnlineEvent(data);
    });

    socket.on("typingUserWeb", (data) {
      final String userId = data['userId'];
      final bool isTyping = data['isTyping'] ?? false;
      setTyping(userId, isTyping);
    });
  }

  @override
  void onClose() {
    _socketService.socket.off('user_online_driver_web');
    _socketService.socket.off('typingUserWeb');
    super.onClose();
  }

  void setTyping(String userId, bool isTyping) {
    if (isTyping) {
      typingUsers[userId] = true;
    } else {
      typingUsers.remove(userId);
    }
  }

  bool isUserTyping(String userId) {
    return typingUsers[userId] ?? false;
  }

  Future<void> getOverview() async {
    try {
      isLoading.value = true;

      final res = await OverviewService().overview();

      if (res.status) {
        overview.value = res.data!;
      } else {
        errorText.value = res.message;
      }
    } catch (e) {
      errorText.value = "Error: $e";
    } finally {
      isLoading.value = false;
    }
  }

  void _handleDriverOnlineEvent(dynamic data) {
    final bool isOnline = data['isOnline'] ?? false;
    final Map<String, dynamic> driverJson = data['driver'];

    final driver = LastFiveDriver.fromJson(driverJson);

    final currentOverview = overview.value;

    final List<LastFiveDriver> drivers = List.from(
      currentOverview.onlineDrivers ?? [],
    );

    final int existingIndex = drivers.indexWhere((d) => d.id == driver.id);

    if (existingIndex != -1) {
      // 🔄 Update driver data
      drivers[existingIndex] = driver;

      // Remove from current position
      final updatedDriver = drivers.removeAt(existingIndex);

      if (isOnline) {
        // 🟢 ONLINE → move to first
        drivers.insert(0, updatedDriver);
      } else {
        // ⚫ OFFLINE → move to last
        drivers.add(updatedDriver);
      }
    } else {
      // ➕ New driver
      if (isOnline) {
        drivers.insert(0, driver);
      } else {
        drivers.add(driver);
      }
    }

    overview.value = currentOverview.copyWith(onlineDrivers: drivers);
  }
}
