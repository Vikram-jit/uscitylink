import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/hive_controller.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/services/socket_service.dart';

enum UConnectivityResult { none, wifi, mobile }

class NetworkService extends GetxController {
  final _connectionType = UConnectivityResult.none.obs;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription _streamSubscription;

  UConnectivityResult get connectionType => _connectionType.value;
  UserPreferenceController userPreferenceController =
      Get.put(UserPreferenceController());

  bool get isConnected => _connectionType.value != UConnectivityResult.none;
  RxBool connected = true.obs;

  SocketService socketService = Get.find<SocketService>();
  HiveController hiveController = Get.put(HiveController());
  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _streamSubscription = _connectivity.onConnectivityChanged.listen((results) {
      print("Netwrok Value ${results.first}");
      _updateState(
          results.isNotEmpty ? results.first : ConnectivityResult.none);
    });
    ever(connected, (bool isConnected) {
      print("Network changed controller: $isConnected");
      if (isConnected) {
        userPreferenceController.getToken().then((value) {
          if (value != null) {
            if (socketService.socket.disconnected) {
              socketService.socket.connect();
              Timer(Duration(seconds: 2), () {
                socketService.sendQueueMessage();
                hiveController.uploadQueeueMedia();
              });
            }
          }
        });
        // Check if the socket is disconnected and reconnect if necessary
      } else {
        userPreferenceController.getToken().then((value) {
          if (value != null) {
            if (socketService.socket.connected) {
              socketService.socket.disconnect();
            }
          }
        });
      }
    });
  }

  Future<void> _initConnectivity() async {
    late List<ConnectivityResult> connectivityResults;
    try {
      connectivityResults = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      if (kDebugMode) print(e);
      return;
    }

    final result = connectivityResults.isNotEmpty
        ? connectivityResults.first
        : ConnectivityResult.none;

    _updateState(result);
  }

  void _updateState(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        _connectionType.value = UConnectivityResult.wifi;
        connected.value = true;
        //  Get.snackbar("Connection", "Connected to Wi-Fi");
        break;
      case ConnectivityResult.mobile:
        _connectionType.value = UConnectivityResult.mobile;
        connected.value = true;
        // Get.snackbar("Connection", "Using Mobile Data");
        break;
      case ConnectivityResult.none:
        _connectionType.value = UConnectivityResult.none;
        connected.value = false;
        // Get.snackbar("Connection", "No Internet Connection");
        break;
      default:
        _connectionType.value = UConnectivityResult.none;
        connected.value = false;
        // Get.snackbar("Connection", "Unknown Network");
        break;
    }
  }

  @override
  void onClose() {
    _streamSubscription.cancel();
    super.onClose();
  }
}
