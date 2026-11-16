import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every permission the driver app uses, in one place, so the dashboard can ask for them all at once
/// ("Allow what the app needs", views/driver/widegts/permissions_sheet.dart) instead of one surprise
/// prompt at a time in the middle of a call or a chat. Calls need: microphone, notifications, and on
/// Android the lock-screen call alert and nearby devices (headsets); video also needs the camera.

enum AppPermStatus {
  /// Allowed
  granted,

  /// Never asked: the OS prompt will show
  notAsked,

  /// Asked and refused, but it can be asked again (Android)
  denied,

  /// Refused for good (or restricted): only the phone's Settings can change it
  blocked,
}

class AppPermissionItem {
  AppPermissionItem({required this.key, required this.title, required this.reason, required this.icon, this.forCalls = false, this.status = AppPermStatus.notAsked});
  final String key;
  final String title;
  final String reason;
  final IconData icon;

  /// Needed for calling dispatch / answering calls
  final bool forCalls;
  AppPermStatus status;

  bool get granted => status == AppPermStatus.granted;
  bool get blocked => status == AppPermStatus.blocked;
}

/// The phone side of the permissions (so tests can fake it).
abstract class PermissionBackend {
  bool get isAndroid;
  Future<AppPermStatus> status(String key);

  /// Shows the OS prompt (or the system settings page for the lock-screen call alert); returns the result.
  Future<AppPermStatus> request(String key);
  Future<void> openSettings();
}

class PhonePermissionBackend implements PermissionBackend {
  @override
  bool get isAndroid => Platform.isAndroid;

  Permission? _perm(String key) => switch (key) {
        'microphone' => Permission.microphone,
        'camera' => Permission.camera,
        'notifications' => Permission.notification,
        'location' => Permission.locationWhenInUse,
        'photos' => Permission.photos,
        'nearby' => Permission.bluetoothConnect,
        _ => null,
      };

  AppPermStatus _map(PermissionStatus s) => switch (s) {
        PermissionStatus.granted || PermissionStatus.limited || PermissionStatus.provisional => AppPermStatus.granted,
        PermissionStatus.permanentlyDenied || PermissionStatus.restricted => AppPermStatus.blocked,
        PermissionStatus.denied => AppPermStatus.denied,
      };

  Future<bool> _asked(String key) async => (await SharedPreferences.getInstance()).getBool('perm_asked_$key') == true;
  Future<void> _markAsked(String key) async => (await SharedPreferences.getInstance()).setBool('perm_asked_$key', true);

  @override
  Future<AppPermStatus> status(String key) async {
    try {
      if (key == 'fullscreen') {
        if (await FlutterCallkitIncoming.canUseFullScreenIntent()) return AppPermStatus.granted;
        return await _asked(key) ? AppPermStatus.denied : AppPermStatus.notAsked;
      }
      final p = _perm(key);
      if (p == null) return AppPermStatus.granted;
      final s = _map(await p.status);
      // The OS says "denied" both before the first question and after a refusal: our own note tells which
      if (s == AppPermStatus.denied && !await _asked(key)) return AppPermStatus.notAsked;
      return s;
    } catch (_) {
      return AppPermStatus.granted; // not available on this phone: nothing to ask
    }
  }

  @override
  Future<AppPermStatus> request(String key) async {
    try {
      await _markAsked(key);
      if (key == 'fullscreen') {
        await FlutterCallkitIncoming.requestFullIntentPermission();
        return await status(key);
      }
      final p = _perm(key);
      if (p == null) return AppPermStatus.granted;
      return _map(await p.request());
    } catch (_) {
      return await status(key);
    }
  }

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }
}

class AppPermissions {
  AppPermissions({PermissionBackend? backend}) : backend = backend ?? PhonePermissionBackend() {
    items = [
      AppPermissionItem(key: 'microphone', title: 'Microphone', reason: 'Talk to dispatch on calls and send voice messages', icon: Icons.mic_rounded, forCalls: true),
      AppPermissionItem(key: 'notifications', title: 'Notifications', reason: 'Ring when dispatch calls and show new messages', icon: Icons.notifications_active_rounded, forCalls: true),
      if (this.backend.isAndroid) AppPermissionItem(key: 'fullscreen', title: 'Calls on the lock screen', reason: 'Show an incoming call over the lock screen', icon: Icons.phone_android_rounded, forCalls: true),
      if (this.backend.isAndroid) AppPermissionItem(key: 'nearby', title: 'Nearby devices', reason: 'Use a Bluetooth headset or car audio on calls', icon: Icons.bluetooth_audio_rounded, forCalls: true),
      AppPermissionItem(key: 'camera', title: 'Camera', reason: 'Video calls, and photos of your documents and loads', icon: Icons.photo_camera_rounded, forCalls: true),
      AppPermissionItem(key: 'location', title: 'Location', reason: 'Show your position and record where you start, arrive and deliver', icon: Icons.location_on_rounded),
      AppPermissionItem(key: 'photos', title: 'Photos', reason: 'Pick pictures and files to send in chat', icon: Icons.photo_library_rounded),
    ];
  }

  final PermissionBackend backend;
  late final List<AppPermissionItem> items;

  /// Already shown during this app launch: it is offered once, not again on every return to the dashboard.
  static bool offeredThisLaunch = false;

  /// Reads the phone's answer for each permission.
  Future<void> refresh() async {
    for (final i in items) {
      i.status = await backend.status(i.key);
    }
  }

  /// Something has never been asked, so the sheet has something to offer.
  bool get hasUnasked => items.any((i) => i.status == AppPermStatus.notAsked);
  bool get allGranted => items.every((i) => i.granted);
  List<AppPermissionItem> get missing => items.where((i) => !i.granted).toList();

  Future<void> requestOne(AppPermissionItem item) async {
    item.status = await backend.request(item.key);
  }

  /// One OS prompt after another (never two at once). Blocked ones can't be asked: they are skipped.
  /// [onStep] is told after each one so the screen can show progress.
  Future<void> requestAll({void Function(AppPermissionItem item)? onStep}) async {
    for (final i in items) {
      if (i.granted || i.blocked) continue;
      await requestOne(i);
      onStep?.call(i);
    }
  }
}
