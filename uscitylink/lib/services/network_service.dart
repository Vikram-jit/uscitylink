import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

enum UConnectivityResult { none, wifi, mobile }

class NetworkService extends GetxController {
  final _connectionType = UConnectivityResult.none.obs;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription _streamSubscription;

  UConnectivityResult get connectionType => _connectionType.value;

  bool get isConnected => _connectionType.value != UConnectivityResult.none;
  RxBool connected = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _streamSubscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateState(
          results.isNotEmpty ? results.first : ConnectivityResult.none);
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
