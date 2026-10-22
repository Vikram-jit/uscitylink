import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/views/update_view.dart';

enum UpdateStatus { upToDate, updateAvailable, forceUpdate }

/// The server's answer to "is this build still OK?" (Admin → App versions on the web).
class AppUpdateInfoResult {
  final UpdateStatus status;
  final String installed; // e.g. 1.3.22 (1)
  final String? latestVersion;
  final int? latestBuild;
  final String? releaseNotes;

  const AppUpdateInfoResult({
    required this.status,
    required this.installed,
    this.latestVersion,
    this.latestBuild,
    this.releaseNotes,
  });

  String? get latestLabel => latestVersion == null ? null : '$latestVersion ($latestBuild)';

  factory AppUpdateInfoResult.fromJson(Map<String, dynamic> data, String installed) {
    final latest = data['latest'] is Map ? Map<String, dynamic>.from(data['latest']) : null;
    return AppUpdateInfoResult(
      status: switch (data['status']) {
        'ForceUpdate' => UpdateStatus.forceUpdate,
        'UpdateAvailable' => UpdateStatus.updateAvailable,
        _ => UpdateStatus.upToDate,
      },
      installed: installed,
      latestVersion: latest?['version']?.toString(),
      latestBuild: (latest?['buildNumber'] as num?)?.toInt(),
      releaseNotes: (latest?['releaseNotes'] as String?)?.trim().isEmpty == true ? null : latest?['releaseNotes'] as String?,
    );
  }
}

/// Checks the installed build against the server at start-up and whenever the app comes back to
/// the foreground, and shows the forced update screen or the optional "update available" prompt.
/// Quiet on purpose: no loader, and any failure just lets the user carry on.
class AppUpdateService extends GetxService with WidgetsBindingObserver {
  static AppUpdateService get to => Get.isRegistered<AppUpdateService>() ? Get.find() : Get.put(AppUpdateService(), permanent: true);

  static const _recheckAfter = Duration(minutes: 10);
  DateTime? _lastCheck;
  String? _promptedFor; // the optional prompt is shown once per new build per app session
  bool _showingForce = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final last = _lastCheck;
    // On the force screen, check straight away: they may have just come back from the store
    if (_showingForce || last == null || DateTime.now().difference(last) > _recheckAfter) {
      checkAndPrompt();
    }
  }

  /// Asks the server; null when it can't be reached or the user isn't signed in.
  Future<AppUpdateInfoResult?> check() async {
    try {
      final token = await UserPreferenceController().getToken();
      if (token == null || token.toString().isEmpty) return null;
      final info = await PackageInfo.fromPlatform();
      final res = await http
          .put(
            Uri.parse('${Constant.url}/auth/updateAppVersion'),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
            body: jsonEncode({'version': info.version, 'buildNumber': info.buildNumber, 'platform': Platform.operatingSystem}),
          )
          .timeout(const Duration(seconds: 10));
      _lastCheck = DateTime.now();
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final body = jsonDecode(res.body);
      if (body is! Map || body['data'] is! Map) return null;
      return AppUpdateInfoResult.fromJson(Map<String, dynamic>.from(body['data']), '${info.version} (${info.buildNumber})');
    } catch (e) {
      debugPrint('App update check failed: $e');
      return null;
    }
  }

  /// Shows what the answer calls for. Returns true when the forced update screen took over.
  Future<bool> apply(AppUpdateInfoResult? result) async {
    if (result == null) return false;
    switch (result.status) {
      case UpdateStatus.forceUpdate:
        if (!_showingForce) {
          _showingForce = true;
          Get.offAll(() => UpdateView(info: result));
        }
        return true;
      case UpdateStatus.updateAvailable:
        _leaveForceScreen();
        final key = result.latestLabel;
        if (key != null && key != _promptedFor && !(Get.isDialogOpen ?? false)) {
          _promptedFor = key;
          await Get.dialog(OptionalUpdateDialog(info: result), barrierDismissible: true);
        }
        return false;
      case UpdateStatus.upToDate:
        _leaveForceScreen();
        return false;
    }
  }

  Future<bool> checkAndPrompt() async => apply(await check());

  // An admin lifted the force (or they updated): restart from the splash screen
  void _leaveForceScreen() {
    if (!_showingForce) return;
    _showingForce = false;
    Get.offAllNamed(AppRoutes.splashView);
  }
}
