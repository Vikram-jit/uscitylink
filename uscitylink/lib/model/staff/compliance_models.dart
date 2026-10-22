import 'dart:convert';

// Models for the staff Compliance (scale checks, routes, equipment, weight rules) and System
// Messages screens. JSON columns can arrive as strings from MariaDB, so everything is parsed
// defensively.

dynamic _json(dynamic v) {
  if (v is String && v.isNotEmpty && (v.startsWith('{') || v.startsWith('['))) {
    try {
      return jsonDecode(v);
    } catch (_) {}
  }
  return v;
}

Map<String, dynamic> _map(dynamic v) {
  final j = _json(v);
  return j is Map ? Map<String, dynamic>.from(j) : <String, dynamic>{};
}

List<dynamic> _list(dynamic v) {
  final j = _json(v);
  return j is List ? j : const [];
}

num? _num(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}

String? _str(dynamic v) => v?.toString();

const scaleGroups = ['steer', 'drive', 'trailer', 'gross'];
const scaleGroupLabels = {'steer': 'Steer', 'drive': 'Drive', 'trailer': 'Trailer', 'gross': 'Gross'};

const scaleStatusLabels = {
  'PASS_PRELIMINARY': 'Preliminary pass',
  'ROUTE_REVIEW_REQUIRED': 'Route review',
  'BRIDGE_REVIEW': 'Axle spacing review',
  'ADJUST_AND_REWEIGH': 'Adjust & reweigh',
  'OVER_GROSS': 'Over gross',
  'OCR_UNCERTAIN': 'Needs review',
};

/// Statuses dispatch may release (the review ones need a note).
const releasableStatuses = ['PASS_PRELIMINARY', 'ROUTE_REVIEW_REQUIRED', 'BRIDGE_REVIEW'];

const adjustmentLabels = {
  'tandems_forward': 'Tandems forward (drives → trailer)',
  'tandems_backward': 'Tandems backward (trailer → drives)',
  'fifth_wheel_forward': 'Fifth wheel forward (drives → steer)',
  'fifth_wheel_back': 'Fifth wheel back (steer → drives)',
  'rework_cargo': 'No slide fix — rework the load',
};

class ScaleAdjustment {
  final String action;
  final num? holes;
  final num? kpraAfterFt;
  final String? reason;

  ScaleAdjustment(this.action, this.holes, this.kpraAfterFt, this.reason);

  factory ScaleAdjustment.fromJson(Map<String, dynamic> j) =>
      ScaleAdjustment(_str(j['action']) ?? '', _num(j['holes']), _num(j['kpra_after_ft']), _str(j['reason']));

  String get label {
    if (reason == 'kpra') {
      return 'Tandems forward to meet the KPRA limit${holes != null ? ' (~$holes hole${holes == 1 ? '' : 's'})' : ''}';
    }
    final base = adjustmentLabels[action] ?? action;
    final h = holes != null ? ' · ~$holes hole${holes == 1 ? '' : 's'}' : '';
    final k = kpraAfterFt != null ? ' · KPRA after $kpraAfterFt ft' : '';
    return '$base$h$k';
  }
}

class ScaleCheck {
  final String id;
  final String messageId;
  final String? driverId;
  final String? driverName;
  final String? truck;
  final String? ticketNumber;
  final Map<String, num?> weights;
  final Map<String, num> overages;
  final Map<String, num> headroom;
  final String status;
  final List<String> flags;
  final List<ScaleAdjustment> adjustments;
  final List<String> assumptions;
  final String? driverMessage;
  final String? previousCheckId;
  final String approvalStatus;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? approvalNote;
  final String? ruleSetVersion;
  final String? tractorUnit;
  final String? trailerUnit;
  final Map<String, dynamic> rules;
  final List<Map<String, dynamic>> bridge;
  final Map<String, dynamic> kpra;
  final Map<String, dynamic> adjustmentMade;
  final Map<String, dynamic> prediction;
  final DateTime? createdAt;

  ScaleCheck({
    required this.id,
    required this.messageId,
    this.driverId,
    this.driverName,
    this.truck,
    this.ticketNumber,
    required this.weights,
    required this.overages,
    required this.headroom,
    required this.status,
    required this.flags,
    required this.adjustments,
    required this.assumptions,
    this.driverMessage,
    this.previousCheckId,
    required this.approvalStatus,
    this.approvedByName,
    this.approvedAt,
    this.approvalNote,
    this.ruleSetVersion,
    this.tractorUnit,
    this.trailerUnit,
    required this.rules,
    required this.bridge,
    required this.kpra,
    required this.adjustmentMade,
    required this.prediction,
    this.createdAt,
  });

  factory ScaleCheck.fromJson(Map<String, dynamic> j) {
    Map<String, num> nums(dynamic v) {
      final m = _map(v);
      final out = <String, num>{};
      m.forEach((k, val) {
        final n = _num(val);
        if (n != null) out[k] = n;
      });
      return out;
    }

    final w = _map(j['measured_weights']);
    return ScaleCheck(
      id: _str(j['id']) ?? '',
      messageId: _str(j['message_id']) ?? '',
      driverId: _str(j['driver_id']),
      driverName: _str(j['driver_name']),
      truck: _str(j['truck']),
      ticketNumber: _str(j['ticket_number']),
      weights: {for (final g in scaleGroups) g: _num(w[g])},
      overages: nums(j['group_overages_lb']),
      headroom: nums(j['headroom_lb']),
      status: _str(j['status']) ?? '',
      flags: _list(j['flags']).map((e) => e.toString()).toList(),
      adjustments: _list(j['feasible_adjustments'])
          .whereType<Map>()
          .map((e) => ScaleAdjustment.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      assumptions: _list(j['assumptions']).map((e) => e.toString()).toList(),
      driverMessage: _str(j['driver_message']),
      previousCheckId: _str(j['previous_check_id']),
      approvalStatus: _str(j['approval_status']) ?? 'not_required',
      approvedByName: _str(j['approved_by_name']),
      approvedAt: DateTime.tryParse(_str(j['approved_at']) ?? '')?.toLocal(),
      approvalNote: _str(j['approval_note']),
      ruleSetVersion: _str(j['rule_set_version']),
      tractorUnit: _str(j['tractor_unit']),
      trailerUnit: _str(j['trailer_unit']),
      rules: _map(j['controlling_rules']),
      bridge: _list(j['bridge_results']).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      kpra: _map(j['kpra']),
      adjustmentMade: _map(j['adjustment_made']),
      prediction: _map(j['prediction']),
      createdAt: DateTime.tryParse(_str(j['createdAt']) ?? '')?.toLocal(),
    );
  }

  String get statusLabel => scaleStatusLabels[status] ?? status;
  bool get isPending => approvalStatus == 'pending';
  bool get releaseNeedsNote => status != 'PASS_PRELIMINARY';
  bool get routeKnown => rules['route_known'] == true;
  List<Map<String, dynamic>> get segments =>
      _list(rules['segments']).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  List<String> get missingRules => _list(rules['missing']).map((e) => e.toString()).toList();
  List<String> get unverifiedRules => _list(rules['unverified']).map((e) => e.toString()).toList();
  List<String> get equipmentMissing => _list(rules['equipment_missing']).map((e) => e.toString()).toList();
  List<Map<String, dynamic>> get bridgeOver => bridge.where((g) => (_num(g['over_lb']) ?? 0) > 0).toList();
}

class WeightRuleSet {
  final String id;
  final String jurisdiction;
  final String roadClass;
  final int version;
  final String name;
  final num singleAxle;
  final num tandem;
  final num gross;
  final num? steerTarget;
  final num? kpraMax;
  final bool bridgeFormula;
  final bool active;
  final bool verified;
  final String? reviewedByName;
  final DateTime? reviewDue;
  final String? citation;
  final String? sourceUrl;
  final String? notes;

  WeightRuleSet({
    required this.id,
    required this.jurisdiction,
    required this.roadClass,
    required this.version,
    required this.name,
    required this.singleAxle,
    required this.tandem,
    required this.gross,
    this.steerTarget,
    this.kpraMax,
    required this.bridgeFormula,
    required this.active,
    required this.verified,
    this.reviewedByName,
    this.reviewDue,
    this.citation,
    this.sourceUrl,
    this.notes,
  });

  factory WeightRuleSet.fromJson(Map<String, dynamic> j) => WeightRuleSet(
        id: _str(j['id']) ?? '',
        jurisdiction: _str(j['jurisdiction']) ?? '',
        roadClass: _str(j['road_class']) ?? '',
        version: _num(j['version'])?.toInt() ?? 1,
        name: _str(j['name']) ?? '',
        singleAxle: _num(j['single_axle_lb']) ?? 0,
        tandem: _num(j['tandem_lb']) ?? 0,
        gross: _num(j['gross_lb']) ?? 0,
        steerTarget: _num(j['steer_target_lb']),
        kpraMax: _num(j['kpra_max_ft']),
        bridgeFormula: j['bridge_formula'] == true || j['bridge_formula'] == 1,
        active: j['active'] == true || j['active'] == 1,
        verified: j['verified'] == true,
        reviewedByName: _str(j['reviewed_by_name']),
        reviewDue: DateTime.tryParse(_str(j['review_due']) ?? '')?.toLocal(),
        citation: _str(j['citation']),
        sourceUrl: _str(j['source_url']),
        notes: _str(j['notes']),
      );
}

/// Equipment profile fields, in form order: (key, label, help, integer?)
class EquipmentField {
  final String key;
  final String label;
  final String? help;
  final bool integer;
  const EquipmentField(this.key, this.label, {this.help, this.integer = false});
}

const tractorFields = [
  EquipmentField('steer_to_drive_center_ft', 'Steer axle → drive center (ft)'),
  EquipmentField('drive_spread_ft', 'Drive axle spread (ft)'),
  EquipmentField('kingpin_to_drive_center_ft', 'Fifth wheel ahead of drive center (ft)', help: '0 = over the drive center'),
  EquipmentField('fifth_wheel_range_in', 'Fifth wheel slide range (in)'),
  EquipmentField('steer_rating_lb', 'Steer axle rating (lb)', help: 'Lowest of axle, tire and wheel', integer: true),
  EquipmentField('drive_rating_lb', 'Drive tandem rating (lb)', integer: true),
  EquipmentField('gvwr_lb', 'GVWR (lb)', integer: true),
];

const trailerFields = [
  EquipmentField('axle_count', 'Rear axles', integer: true),
  EquipmentField('length_ft', 'Trailer length (ft)'),
  EquipmentField('kpra_ft', 'Kingpin → rearmost axle center (ft)', help: 'At the current tandem position'),
  EquipmentField('trailer_spread_ft', 'Trailer axle spread (ft)'),
  EquipmentField('hole_spacing_in', 'Hole spacing (in)'),
  EquipmentField('holes_forward_available', 'Holes available forward', integer: true),
  EquipmentField('holes_back_available', 'Holes available back', integer: true),
  EquipmentField('lb_per_hole', 'Measured lb per hole', help: 'Learned from reweighs'),
  EquipmentField('trailer_rating_lb', 'Trailer tandem rating (lb)', integer: true),
];

class EquipmentProfile {
  final String? id;
  final String kind;
  final String unitNumber;
  final Map<String, num?> values;
  final int samples;
  final String? notes;

  EquipmentProfile({this.id, required this.kind, required this.unitNumber, required this.values, this.samples = 0, this.notes});

  factory EquipmentProfile.fromJson(Map<String, dynamic> j) {
    final kind = _str(j['kind']) ?? 'trailer';
    final fields = kind == 'tractor' ? tractorFields : trailerFields;
    return EquipmentProfile(
      id: _str(j['id']),
      kind: kind,
      unitNumber: _str(j['unit_number']) ?? '',
      values: {for (final f in fields) f.key: _num(j[f.key])},
      samples: _num(j['lb_per_hole_samples'])?.toInt() ?? 0,
      notes: _str(j['notes']),
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'unit_number': unitNumber,
        'notes': notes,
        ...values.map((k, v) => MapEntry(k, v)),
      };
}

const roadClassLabels = {'interstate': 'Interstate', 'state_highway': 'State highway', 'local': 'Local road'};

const usStates = [
  'AL', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 'MA',
  'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
  'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY', 'DC',
];

class TripSegment {
  String state;
  String roadClass;
  String note;
  TripSegment({this.state = '', this.roadClass = 'interstate', this.note = ''});
  factory TripSegment.fromJson(Map<String, dynamic> j) =>
      TripSegment(state: _str(j['state']) ?? '', roadClass: _str(j['road_class']) ?? 'interstate', note: _str(j['note']) ?? '');
  Map<String, dynamic> toJson() => {'state': state, 'road_class': roadClass, if (note.isNotEmpty) 'note': note};
}

class TripPermit {
  String state;
  String number;
  String expiresAt; // YYYY-MM-DD
  num? grossLb;
  num? tandemLb;
  num? singleAxleLb;
  TripPermit({this.state = '', this.number = '', this.expiresAt = '', this.grossLb, this.tandemLb, this.singleAxleLb});
  factory TripPermit.fromJson(Map<String, dynamic> j) => TripPermit(
        state: _str(j['state']) ?? '',
        number: _str(j['number']) ?? '',
        expiresAt: _str(j['expires_at']) ?? '',
        grossLb: _num(j['gross_lb']),
        tandemLb: _num(j['tandem_lb']),
        singleAxleLb: _num(j['single_axle_lb']),
      );
  Map<String, dynamic> toJson() => {
        'state': state,
        'number': number,
        'expires_at': expiresAt,
        'gross_lb': grossLb,
        'tandem_lb': tandemLb,
        'single_axle_lb': singleAxleLb,
      };
}

class DriverTrip {
  String truck;
  String trailer;
  String origin;
  String destination;
  String cargo;
  List<TripSegment> segments;
  List<TripPermit> permits;
  final bool exists;

  DriverTrip({
    this.truck = '',
    this.trailer = '',
    this.origin = '',
    this.destination = '',
    this.cargo = '',
    List<TripSegment>? segments,
    List<TripPermit>? permits,
    this.exists = false,
  })  : segments = segments ?? [TripSegment()],
        permits = permits ?? [];

  factory DriverTrip.fromJson(Map<String, dynamic> j) {
    final segs = _list(j['segments']).whereType<Map>().map((e) => TripSegment.fromJson(Map<String, dynamic>.from(e))).toList();
    return DriverTrip(
      truck: _str(j['truck']) ?? '',
      trailer: _str(j['trailer']) ?? '',
      origin: _str(j['origin']) ?? '',
      destination: _str(j['destination']) ?? '',
      cargo: _str(j['cargo']) ?? '',
      segments: segs.isEmpty ? [TripSegment()] : segs,
      permits: _list(j['permits']).whereType<Map>().map((e) => TripPermit.fromJson(Map<String, dynamic>.from(e))).toList(),
      exists: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'truck': truck,
        'trailer': trailer,
        'origin': origin,
        'destination': destination,
        'cargo': cargo,
        'segments': segments.map((s) => s.toJson()).toList(),
        'permits': permits.map((p) => p.toJson()).toList(),
      };
}

class SystemMessage {
  final String id;
  final String body;
  final String? url;
  final DateTime? timestamp;
  final bool isCompleted;
  final String? completedByName;
  final String? note;

  SystemMessage({
    required this.id,
    required this.body,
    this.url,
    this.timestamp,
    required this.isCompleted,
    this.completedByName,
    this.note,
  });

  factory SystemMessage.fromJson(Map<String, dynamic> j) => SystemMessage(
        id: _str(j['id']) ?? '',
        body: _str(j['body']) ?? '',
        url: (_str(j['url']) ?? '').isEmpty ? null : _str(j['url']),
        timestamp: DateTime.tryParse(_str(j['messageTimestampUtc']) ?? '')?.toLocal(),
        isCompleted: j['isCompleted'] == true || j['isCompleted'] == 1,
        completedByName: j['completedByUser'] is Map ? _str(j['completedByUser']['username']) : null,
        note: (_str(j['note']) ?? '').isEmpty ? null : _str(j['note']),
      );

  bool get isImage => url != null && RegExp(r'\.(jpe?g|png|gif|webp|heic)$', caseSensitive: false).hasMatch(url!);
}

class StaffUser {
  final String id;
  final String name;
  StaffUser(this.id, this.name);
}
