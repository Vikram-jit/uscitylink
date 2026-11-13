import 'package:uscitylink/model/staff/load_models.dart';
import 'package:uscitylink/services/staff/staff_api_client.dart';

Map<String, dynamic> _data(Map<String, dynamic> res) => res['data'] is Map ? Map<String, dynamic>.from(res['data']) : <String, dynamic>{};

/// Loads for dispatch — the same endpoints the web Loads screen uses (/loads, /trips).
class LoadsService {
  LoadsService([StaffApiClient? api]) : _api = api ?? StaffApiClient();
  final StaffApiClient _api;

  Future<({List<StaffLoad> loads, int total, Map<String, int> counts, Map<String, String> driverNames})> list({String status = '', String q = '', int page = 1, int limit = 30}) async {
    final d = _data(await _api.get('loads', {'status': status, 'q': q, 'page': page, 'limit': limit}));
    final counts = <String, int>{};
    (d['counts'] as Map? ?? {}).forEach((k, v) => counts['$k'] = (v as num).toInt());
    final names = <String, String>{};
    (d['driverNames'] as Map? ?? {}).forEach((k, v) => names['$k'] = '$v');
    return (
      loads: (d['loads'] as List? ?? []).whereType<Map>().map((e) => StaffLoad.fromJson(Map<String, dynamic>.from(e))).toList(),
      total: (d['total'] as num?)?.toInt() ?? 0,
      counts: counts,
      driverNames: names,
    );
  }

  Future<LoadDetail> detail(int id) async => LoadDetail.fromJson(_data(await _api.get('loads/$id')));

  /// What this Load # is: new, or leg N after …; and whether the chosen driver is busy.
  Future<LoadLookup> lookup(String no, {String? driver}) async => LoadLookup.fromJson(_data(await _api.get('loads/lookup', {'no': no, 'driver': driver})));

  /// Save or send a load. Throws [NeedsAnswer] when dispatch must answer first (409).
  Future<String> addLoad(NewLoadInput input, {bool send = false, bool endPrevious = false, bool endDriverCurrent = false, bool lineUp = false, bool replace = false}) async {
    try {
      final res = await _api.post('loads', {...input.toJson(), 'send': send, 'endPrevious': endPrevious, 'endDriverCurrent': endDriverCurrent, 'lineUp': lineUp, 'replace': replace});
      return '${res['message'] ?? 'Load saved'}';
    } on StaffApiError catch (e) {
      if (e.statusCode == 409 && e.body['needs'] != null) throw asNeedsAnswer(e);
      rethrow;
    }
  }

  static NeedsAnswer asNeedsAnswer(StaffApiError e) {
    final info = e.body['info'] is Map ? Map<String, dynamic>.from(e.body['info']) : <String, dynamic>{};
    LegBrief? leg(dynamic v) => v is Map ? LegBrief.fromJson(Map<String, dynamic>.from(v)) : null;
    return NeedsAnswer('${e.body['needs']}', e.message, prev: leg(info['prev']), current: leg(info['current']), linedUp: leg(info['linedUp']));
  }

  /// A load pasted in a driver's chat box: sent as a load (never as a chat message). Throws
  /// [NeedsAnswer] when dispatch must answer first.
  Future<String> sendLoadText(String text, String driverProfileId, {bool endPrevious = false, bool endDriverCurrent = false, bool lineUp = false, bool replace = false}) async {
    try {
      final res = await _api.post('loads/from-text', {'text': text, 'driverProfileId': driverProfileId, 'endPrevious': endPrevious, 'endDriverCurrent': endDriverCurrent, 'lineUp': lineUp, 'replace': replace});
      return '${res['message'] ?? 'Load sent'}';
    } on StaffApiError catch (e) {
      if (e.statusCode == 409 && e.body['needs'] != null) throw asNeedsAnswer(e);
      rethrow;
    }
  }

  /// Answer the question about a load typed in chat.
  Future<Map<String, dynamic>> answerTyped(String pendingId, {bool endPrevious = false, bool endDriverCurrent = false, bool lineUp = false, bool replace = false}) async =>
      _data(await _api.post('loads/typed/$pendingId/answer', {'endPrevious': endPrevious, 'endDriverCurrent': endDriverCurrent, 'lineUp': lineUp, 'replace': replace}));

  Future<String> endLeg(int loadId, int legId, {DateTime? at}) async => '${(await _api.post('loads/$loadId/legs/$legId/end', {'at': at?.toUtc().toIso8601String()}))['message'] ?? 'Load ended'}';

  Future<String> releaseLeg(int loadId, int legId, {DateTime? at}) async => '${(await _api.post('loads/$loadId/legs/$legId/release', {'at': at?.toUtc().toIso8601String()}))['message'] ?? 'Handed over'}';

  /// Send a lined-up / scheduled leg to its driver.
  Future<String> sendLeg(int tripId) async => '${(await _api.post('trips/$tripId/send'))['message'] ?? 'Sent'}';

  /// Mark a delivered leg completed (needs the invoice # on older loads).
  Future<String> completeLeg(int tripId, {String? invoiceNo}) async {
    final res = await _api.post('trips/$tripId/action', {'action': 'complete', if (invoiceNo != null && invoiceNo.isNotEmpty) 'invoiceNo': invoiceNo});
    return '${res['message'] ?? 'Marked completed'}';
  }

  Future<String> assignLeg(int loadId, int legId, {String? driverProfileId, String? teamDriverProfileId, String? truckNumber, bool send = false}) async {
    final res = await _api.post('loads/$loadId/legs/$legId/assign', {'driverProfileId': driverProfileId, 'teamDriverProfileId': teamDriverProfileId, 'truckNumber': truckNumber, 'send': send});
    return '${res['message'] ?? 'Assigned'}';
  }

  Future<String> correctTimes(int loadId, int legId, Map<String, dynamic> body) async => '${(await _api.patch('loads/$loadId/legs/$legId/times', body))['message'] ?? 'Times corrected'}';

  /// Read the leg's times / miles from the truck's GPS again.
  Future<String> matchGps(int loadId, int legId) async => '${(await _api.post('loads/$loadId/legs/$legId/match-gps'))['message'] ?? 'Miles re-checked'}';

  Future<String> setMiles(int loadId, int legId, {double? miles, String? note}) async => '${(await _api.patch('loads/$loadId/legs/$legId/miles', {'miles': miles, 'note': note}))['message'] ?? 'Miles saved'}';

  // ---- live tracking, edit, hold / cancel, problems ----
  Future<LiveTrip> live(int tripId) async => LiveTrip.fromJson(_data(await _api.get('trips/$tripId/live')));

  /// hold | resume | cancel (note = why)
  Future<String> tripAction(int tripId, String action, {String? note}) async {
    await _api.post('trips/$tripId/action', {'action': action, if (note != null && note.isNotEmpty) 'note': note});
    return const {'hold': 'Put on hold', 'resume': 'Resumed', 'cancel': 'Trip cancelled'}[action] ?? 'Done';
  }

  Future<String> addProblem(int tripId, {required String kind, String? note, double? amount}) async {
    await _api.post('trips/$tripId/problems', {'kind': kind, 'note': note, 'amount': amount});
    return 'Problem added';
  }

  /// Edit one leg (the same fields as Add load; the stops are replaced by the list given).
  Future<String> editLeg(int tripId, NewLoadInput i) async {
    final b = i.toJson()..remove('loadNo');
    await _api.patch('trips/$tripId', {...b, 'needsReview': false});
    return 'Load updated';
  }

  // ---- fleet ----
  Future<List<FleetTruck>> trucks() async => _list(await _api.get('loads/equipment/trucks')).map(FleetTruck.fromJson).toList();
  Future<List<FleetTrailer>> trailers() async => _list(await _api.get('loads/equipment/trailers')).map(FleetTrailer.fromJson).toList();
  Future<List<FleetDriver>> drivers() async => _list(await _api.get('loads/equipment/drivers')).map(FleetDriver.fromJson).toList();

  // ---- lineup ----
  Future<DriverLineup> lineup(String profileId) async => DriverLineup.fromJson(_data(await _api.get('loads/lineup/$profileId')));
  Future<void> reorderLineup(String profileId, List<int> tripIds) async => _api.put('loads/lineup/$profileId', {'tripIds': tripIds});
  Future<void> removeFromLineup(String profileId, int tripId) async => _api.delete('loads/lineup/$profileId/$tripId');

  // ---- miles ----
  Future<({List<MilesRow> rows, double miles, int legs, int missing})> miles({required String by, required DateTime from, required DateTime to, String q = ''}) async {
    final d = _data(await _api.get('loads/miles', {'by': by, 'from': from.toUtc().toIso8601String(), 'to': to.toUtc().toIso8601String(), 'q': q}));
    final t = d['totals'] is Map ? Map<String, dynamic>.from(d['totals']) : <String, dynamic>{};
    return (
      rows: (d['rows'] as List? ?? []).whereType<Map>().map((e) => MilesRow.fromJson(Map<String, dynamic>.from(e))).toList(),
      miles: (t['miles'] as num?)?.toDouble() ?? 0,
      legs: (t['legs'] as num?)?.toInt() ?? 0,
      missing: (t['missing'] as num?)?.toInt() ?? 0,
    );
  }

  // ---- form helpers ----
  /// Read a typed / pasted load into form fields.
  Future<NewLoadInput> parseText(String text) async {
    final d = _data(await _api.post('trips/parse', {'text': text}));
    String? s(dynamic v) => (v == null || '$v'.isEmpty) ? null : '$v';
    return NewLoadInput(
      loadNo: s(d['loadNo']) ?? '',
      truckNumber: s(d['truck']),
      trailerNumbers: (d['trailers'] as List? ?? []).map((e) => '$e').toList(),
      temperature: s(d['temperature']),
      loadedTrailer: d['loadedTrailer'] == true,
      stops: (d['stops'] as List? ?? [])
          .whereType<Map>()
          .map((x) => NewStop(type: '${x['type']}', name: '${x['name'] ?? ''}', street: '${x['street'] ?? ''}', city: '${x['city'] ?? ''}', state: '${x['state'] ?? ''}', zip: '${x['zip'] ?? ''}', appointment: s(x['appointment'])))
          .toList(),
    );
  }

  Future<List<TruckPick>> truckPicks(String q) async {
    final res = await _api.get('trips/trucks', {'q': q});
    return _list(res)
        .map((t) => TruckPick(
              truck: '${t['truck']}',
              drivers: (t['drivers'] as List? ?? []).whereType<Map>().map((d) => DriverPick(id: '${d['id']}', name: '${d['name']}')).toList(),
            ))
        .toList();
  }

  Future<TruckPick?> truckOfDriver(String profileId) async {
    final d = _data(await _api.get('trips/drivers/$profileId/truck'));
    if (d.isEmpty) return null;
    return TruckPick(truck: '${d['truck']}', drivers: (d['drivers'] as List? ?? []).whereType<Map>().map((x) => DriverPick(id: '${x['id']}', name: '${x['name']}')).toList());
  }

  Future<List<PlaceGuess>> searchPlaces(String q, {String? session}) async =>
      _list(await _api.get('loads/places/search', {'q': q, 'session': session})).map(PlaceGuess.fromJson).toList();

  Future<NewStop?> placeStop(String placeId, {String? session}) async {
    final d = _data(await _api.get('loads/places/${Uri.encodeComponent(placeId)}', {'session': session}));
    if (d.isEmpty) return null;
    String s(dynamic v) => v == null ? '' : '$v';
    return NewStop(name: s(d['name']), street: s(d['street']), city: s(d['city']), state: s(d['state']), zip: s(d['zip']));
  }

  List<Map<String, dynamic>> _list(Map<String, dynamic> res) => (res['data'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}
