import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/services/trip/trip_models.dart';

/// The driver's current trip (load): what the dashboard card shows and the buttons it sends.
/// Every tap is recorded on the server with when and where (GPS); a tap made without signal is kept
/// on the phone and sent later with its real time. The server decides what is allowed
/// (server/src/services/trips/lifecycle.ts); this only shows its answer.
class TripService extends GetxService {
  static TripService get to => Get.isRegistered<TripService>() ? Get.find() : Get.put(TripService(), permanent: true);

  final current = Rxn<CurrentTrip>();

  /// Loads screen: every load sent to this driver, newest first (GET trips/mine)
  final history = <CurrentTrip>[].obs;
  final historyLoading = false.obs;
  int _historyPage = 0;
  int _historyTotal = 0;
  bool get hasMoreHistory => history.length < _historyTotal;
  /// Loads lined up for this driver, not sent yet — read-only "Up next" (GET trips/upcoming)
  final upcoming = <CurrentTrip>[].obs;
  final suggestion = Rxn<TripSuggestion>();
  final busy = false.obs;
  final pendingCount = 0.obs;

  /// Undo is offered for a few minutes after the driver's own tap
  final undoUntil = Rxn<DateTime>();

  static const _pendingKey = 'trip_pending_actions';
  static const _locationAskedKey = 'trip_location_asked';
  io.Socket? _bound;

  @override
  void onInit() {
    super.onInit();
    final socketService = Get.isRegistered<SocketService>() ? Get.find<SocketService>() : null;
    if (socketService != null) {
      ever<bool>(socketService.isConnected, (connected) {
        if (connected) _bind(socketService.socket);
      });
      if (socketService.isConnected.value) _bind(socketService.socket);
    }
    unawaited(_loadPendingCount());
    unawaited(refresh());
    unawaited(loadUpcoming());
  }

  void _bind(io.Socket socket) {
    if (identical(socket, _bound)) return;
    _bound = socket;
    socket.on('trip:updated', (_) {
      refresh();
      loadUpcoming();
      if (_historyPage > 0) loadHistory(reset: true);
    });
    socket.on('trip:suggest', (d) {
      if (d is! Map) return;
      final tripId = (d['tripId'] as num?)?.toInt();
      if (tripId == null || current.value?.id != tripId) return;
      suggestion.value = TripSuggestion(
        tripId: tripId,
        action: '${d['action']}',
        label: '${d['label']}',
        stopId: (d['stopId'] as num?)?.toInt(),
      );
    });
    // Back online: send what was tapped without signal, then catch up
    unawaited(_flush().then((_) => refresh()));
  }

  /// First page ([reset]) or the next one.
  Future<void> loadHistory({bool reset = false}) async {
    if (historyLoading.value || (!reset && _historyPage > 0 && !hasMoreHistory)) return;
    historyLoading.value = true;
    try {
      final page = reset ? 1 : _historyPage + 1;
      final res = await _rest('GET', 'trips/mine?page=$page');
      final data = res.body?['data'];
      if (!res.ok || data is! Map) return;
      final trips = (data['trips'] as List? ?? []).map((t) => CurrentTrip.fromTrip(Map<String, dynamic>.from(t))).toList();
      _historyTotal = (data['total'] as num?)?.toInt() ?? trips.length;
      _historyPage = page;
      if (reset) {
        history.assignAll(trips);
      } else {
        history.addAll(trips);
      }
    } finally {
      historyLoading.value = false;
    }
  }

  Future<void> loadUpcoming() async {
    final res = await _rest('GET', 'trips/upcoming');
    final data = res.body?['data'];
    if (!res.ok || data is! Map) return;
    upcoming.assignAll((data['trips'] as List? ?? []).map((t) => CurrentTrip.fromTrip(Map<String, dynamic>.from(t))));
  }

  Future<void> refresh() async {
    final res = await _rest('GET', 'trips/current');
    if (res.ok) current.value = CurrentTrip.fromResponse(res.body?['data']);
  }

  // ---------- actions ----------

  /// The big button, or a suggestion the driver confirmed.
  Future<void> act(String action, {int? stopId, String? note}) async {
    final trip = current.value;
    if (trip == null || busy.value) return;
    busy.value = true;
    suggestion.value = null;
    try {
      if (action == 'start') await _askLocationOnce();
      final where = await _position();
      final body = {
        'action': action,
        if (stopId != null) 'stopId': stopId,
        if (note != null) 'note': note,
        if (where != null) 'lat': where.latitude,
        if (where != null) 'lng': where.longitude,
        'at': DateTime.now().toUtc().toIso8601String(),
      };
      final res = await _rest('POST', 'trips/${trip.id}/action', body);
      if (res.ok) {
        undoUntil.value = DateTime.now().add(const Duration(minutes: 5));
        await refresh();
      } else if (res.offline) {
        await _queue(trip.id, body);
        _toast('No signal — saved, it will be sent when you are back online');
      } else {
        _toast('${res.body?['message'] ?? 'Could not update the trip'}');
        await refresh();
      }
    } finally {
      busy.value = false;
    }
  }

  Future<void> undo() async {
    final trip = current.value;
    if (trip == null) return;
    final res = await _rest('POST', 'trips/${trip.id}/undo');
    undoUntil.value = null;
    if (!res.ok) _toast('${res.body?['message'] ?? 'Could not undo'}');
    await refresh();
  }

  Future<bool> reportProblem(String kind, String note) async {
    final trip = current.value;
    if (trip == null) return false;
    final res = await _rest('POST', 'trips/${trip.id}/problems', {'kind': kind, 'note': note});
    if (!res.ok) _toast('${res.body?['message'] ?? 'Could not send — try again'}');
    await refresh();
    return res.ok;
  }

  // ---------- location ----------

  /// Asked once, on the first Start trip: where the driver starts, arrives and delivers.
  Future<void> _askLocationOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_locationAskedKey) == true) return;
      await prefs.setBool(_locationAskedKey, true);
      final p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) await Geolocator.requestPermission();
    } catch (_) {}
  }

  /// Best effort: a trip tap never waits long or fails for lack of a fix.
  Future<Position?> _position() async {
    try {
      final p = await Geolocator.checkPermission();
      if (p != LocationPermission.always && p != LocationPermission.whileInUse) return null;
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 6)),
        );
      } catch (_) {
        return await Geolocator.getLastKnownPosition();
      }
    } catch (_) {
      return null;
    }
  }

  // ---------- taps made without signal ----------

  Future<void> _queue(int tripId, Map<String, dynamic> body) async {
    final prefs = await SharedPreferences.getInstance();
    final list = List<String>.from(prefs.getStringList(_pendingKey) ?? []);
    list.add(jsonEncode({'tripId': tripId, 'body': body}));
    await prefs.setStringList(_pendingKey, list);
    pendingCount.value = list.length;
  }

  Future<void> _loadPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    pendingCount.value = (prefs.getStringList(_pendingKey) ?? []).length;
  }

  bool _flushing = false;

  /// In the order tapped; one the server refuses is dropped (the trip moved on), one that can't be
  /// sent yet stays for next time.
  Future<void> _flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = List<String>.from(prefs.getStringList(_pendingKey) ?? []);
      while (list.isNotEmpty) {
        final item = jsonDecode(list.first) as Map<String, dynamic>;
        final res = await _rest('POST', 'trips/${item['tripId']}/action', Map<String, dynamic>.from(item['body']));
        if (res.offline) break;
        list.removeAt(0);
        await prefs.setStringList(_pendingKey, list);
      }
      pendingCount.value = list.length;
    } catch (_) {
    } finally {
      _flushing = false;
    }
  }

  // ---------- helpers ----------

  Future<_Res> _rest(String method, String path, [Map<String, dynamic>? body]) async {
    try {
      final token = await UserPreferenceController().getToken();
      if (token == null || token.toString().isEmpty) return _Res(0, null);
      final uri = Uri.parse('${Constant.url}/$path');
      final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
      final request = method == 'POST'
          ? http.post(uri, headers: headers, body: jsonEncode(body ?? {}))
          : http.get(uri, headers: headers);
      final res = await request.timeout(const Duration(seconds: 12));
      final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : null;
      return _Res(res.statusCode, decoded is Map ? Map<String, dynamic>.from(decoded) : null);
    } catch (e) {
      debugPrint('[trip] $method $path failed: $e');
      return _Res(0, null);
    }
  }

  void _toast(String message) {
    if (Get.context == null) return;
    Get.snackbar('Trip', message, snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
  }
}

class _Res {
  _Res(this.status, this.body);
  final int status;
  final Map<String, dynamic>? body;
  bool get ok => status >= 200 && status < 300 && body?['status'] != false;

  /// No answer at all (no signal, server unreachable): worth trying again later
  bool get offline => status == 0 || status >= 500;
}
