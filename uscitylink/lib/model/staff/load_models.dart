// Loads for staff (dispatch): the same data the web Loads screen uses — server/src/services/trips.
// A load is tracked by its Load # (invoice #) and moved by one or more legs; each leg is one driver
// on one truck with its own stops, times and miles.

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse('$v');
int? _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');
double? _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
String? _str(dynamic v) => (v == null || '$v'.isEmpty) ? null : '$v';
bool _bool(dynamic v) => v == true || v == 1 || v == '1';
List<Map<String, dynamic>> _maps(dynamic v) => (v as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

class LoadStop {
  LoadStop({
    required this.id,
    required this.seq,
    required this.type,
    this.name,
    this.street,
    this.city,
    this.state,
    this.zip,
    this.appointmentLocal,
    this.arrivedAt,
    this.departedAt,
    this.timezone,
  });

  final int id;
  final int seq;

  /// pickup | drop | switch (meet point) | yard (our yard)
  final String type;
  final String? name;
  final String? street;
  final String? city;
  final String? state;
  final String? zip;

  /// The stop's own local time, "2026-11-12T08:00"
  final String? appointmentLocal;
  final DateTime? arrivedAt;
  final DateTime? departedAt;
  final String? timezone;

  factory LoadStop.fromJson(Map<String, dynamic> j) => LoadStop(
        id: _int(j['id']) ?? 0,
        seq: _int(j['seq']) ?? 0,
        type: '${j['type'] ?? 'drop'}',
        name: _str(j['name']),
        street: _str(j['street']),
        city: _str(j['city']),
        state: _str(j['state']),
        zip: _str(j['zip']),
        appointmentLocal: _str(j['appointment_local']),
        arrivedAt: _date(j['arrived_at']),
        departedAt: _date(j['departed_at']),
        timezone: _str(j['timezone']),
      );

  String get typeLabel => const {'pickup': 'Pickup', 'drop': 'Delivery', 'switch': 'Meet point', 'yard': 'Our yard'}[type] ?? 'Stop';
  String get place => [city, state].where((x) => x != null && x.isNotEmpty).join(', ');
  String get title => name ?? (place.isEmpty ? typeLabel : place);
  String get address => [street, [city, state, zip].where((x) => x != null && x.isNotEmpty).join(' ')].where((x) => x != null && x.isNotEmpty).join(', ');
}

class LoadLeg {
  LoadLeg({
    required this.id,
    this.loadId,
    required this.legNo,
    this.tripNo,
    required this.status,
    this.driverProfileId,
    this.driverId2,
    this.truck,
    this.trailers,
    this.temperature,
    this.notes,
    this.loadedTrailer = false,
    this.queuePos,
    this.endsAtYard = false,
    this.handoverReason,
    this.sentAt,
    this.startedAt,
    this.endedAt,
    this.plannedEtaAt,
    this.totalMileage,
    this.milesSource,
    this.milesNote,
    this.needsReview = false,
    this.reviewNotes,
    this.invoiceNo,
    this.stops = const [],
  });

  final int id;
  final int? loadId;
  final int legNo;
  final String? tripNo;

  /// scheduled | offered | planned | accepted | started | rolling | ended | paperwork | completed | routed | on_hold | cancelled
  final String status;
  final String? driverProfileId;
  final int? driverId2;
  final String? truck;
  final String? trailers;
  final String? temperature;
  final String? notes;
  final bool loadedTrailer;
  final int? queuePos;
  final bool endsAtYard;
  final String? handoverReason;
  final DateTime? sentAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? plannedEtaAt;
  final double? totalMileage;
  final String? milesSource;
  final String? milesNote;
  final bool needsReview;
  final String? reviewNotes;
  final String? invoiceNo;
  final List<LoadStop> stops;

  factory LoadLeg.fromJson(Map<String, dynamic> j) {
    final stops = _maps(j['stops']).map(LoadStop.fromJson).toList()..sort((a, b) => a.seq.compareTo(b.seq));
    return LoadLeg(
      id: _int(j['id']) ?? 0,
      loadId: _int(j['load_id']),
      legNo: _int(j['leg_no']) ?? 1,
      tripNo: _str(j['trip_no']),
      status: '${j['status']}',
      driverProfileId: _str(j['driver_profile_id']),
      driverId2: _int(j['driver_id_2']),
      truck: _str(j['truck_number']),
      trailers: _str(j['trailer_numbers']),
      temperature: _str(j['temperature']),
      notes: _str(j['notes']),
      loadedTrailer: _bool(j['loaded_trailer']),
      queuePos: _int(j['queue_pos']),
      endsAtYard: _bool(j['ends_at_yard']),
      handoverReason: _str(j['handover_reason']),
      sentAt: _date(j['sent_at']),
      startedAt: _date(j['started_at']),
      endedAt: _date(j['ended_at']),
      plannedEtaAt: _date(j['planned_eta_at']),
      totalMileage: _num(j['total_mileage']),
      milesSource: _str(j['miles_source']),
      milesNote: _str(j['miles_note']),
      needsReview: _bool(j['needs_review']),
      reviewNotes: _str(j['review_notes']),
      invoiceNo: _str(j['invoice_no']),
      stops: stops,
    );
  }

  LoadStop? get first => stops.isEmpty ? null : stops.first;
  LoadStop? get last => stops.isEmpty ? null : stops.last;
  bool get isTeam => driverId2 != null;

  /// Where the miles came from, in plain words
  String get milesSourceLabel => milesSource == 'manual' ? 'typed' : milesSource == 'gps' ? 'Samsara · times from GPS' : 'Samsara';

  /// On the driver's phone: sent, not delivered
  bool get onDriver => const ['planned', 'accepted', 'started', 'rolling', 'on_hold'].contains(status);
  bool get isDelivered => const ['ended', 'paperwork'].contains(status);
  bool get isDone => const ['completed', 'routed'].contains(status);
  bool get notSent => status == 'scheduled' || status == 'offered';

  String get statusLabel => const {
        'scheduled': 'Scheduled',
        'offered': 'Driver waiting',
        'planned': 'Sent',
        'accepted': 'Accepted',
        'started': 'Started',
        'rolling': 'Rolling',
        'ended': 'Delivered',
        'paperwork': 'Paperwork',
        'completed': 'Completed',
        'routed': 'Priced',
        'on_hold': 'On hold',
        'cancelled': 'Cancelled',
      }[status] ??
      status;

  /// Past its appointment without arriving
  bool get isLate =>
      const ['planned', 'accepted', 'started', 'rolling'].contains(status) &&
      stops.any((s) => s.arrivedAt == null && s.appointmentLocal != null && (DateTime.tryParse(s.appointmentLocal!)?.isBefore(DateTime.now()) ?? false));
}

class StaffLoad {
  StaffLoad({
    required this.id,
    this.loadNo,
    this.invoiceNo,
    this.trackToken,
    this.trackCode,
    required this.type,
    required this.status,
    this.createdAt,
    this.createdByName,
    this.legs = const [],
  });

  final int id;
  final String? loadNo;
  final String? invoiceNo;
  final String? trackToken;
  final String? trackCode;

  /// direct | via_yard | relay (shown as Transfer) | trailer_move
  final String type;

  /// scheduled | waiting | active | transfer | delivered | completed | cancelled
  final String status;
  final DateTime? createdAt;
  final String? createdByName;
  final List<LoadLeg> legs;

  factory StaffLoad.fromJson(Map<String, dynamic> j) => StaffLoad(
        id: _int(j['id']) ?? 0,
        loadNo: _str(j['load_no']),
        invoiceNo: _str(j['invoice_no']),
        trackToken: _str(j['track_token']),
        trackCode: _str(j['track_code']),
        type: '${j['type'] ?? 'direct'}',
        status: '${j['status'] ?? 'scheduled'}',
        createdAt: _date(j['created_at']),
        createdByName: _str(j['created_by_name']),
        legs: _maps(j['legs']).map(LoadLeg.fromJson).toList()..sort((a, b) => a.legNo.compareTo(b.legNo)),
      );

  /// The number staff typed (Load # / invoice #), exactly as saved
  String get number => invoiceNo ?? loadNo ?? '';
  String get typeLabel => const {'direct': 'Direct', 'via_yard': 'Via yard', 'relay': 'Transfer', 'trailer_move': 'Trailer move'}[type] ?? type;
  String get statusLabel =>
      const {
        'scheduled': 'Scheduled',
        'waiting': 'Driver waiting',
        'active': 'On the road',
        'transfer': 'Ready to transfer',
        'delivered': 'Delivered',
        'completed': 'Completed',
        'cancelled': 'Cancelled',
      }[status] ??
      status;
  List<LoadLeg> get activeLegs => legs.where((l) => l.status != 'cancelled').toList();
  bool get isClosed => status == 'completed' || status == 'cancelled';
}

class LoadSegment {
  LoadSegment({required this.legNo, this.tripNo, required this.status, this.drivers = const [], this.truck, this.trailers, this.from = '', this.to = '', this.startedAt, this.endedAt, this.minutes, this.miles, this.milesSource, this.handoverReason});

  final int legNo;
  final String? tripNo;
  final String status;
  final List<String> drivers;
  final String? truck;
  final String? trailers;
  final String from;
  final String to;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? minutes;
  final double? miles;
  final String? milesSource;
  final String? handoverReason;

  factory LoadSegment.fromJson(Map<String, dynamic> j) => LoadSegment(
        legNo: _int(j['legNo']) ?? 1,
        tripNo: _str(j['tripNo']),
        status: '${j['status']}',
        drivers: (j['drivers'] as List? ?? []).map((e) => '$e').toList(),
        truck: _str(j['truck']),
        trailers: _str(j['trailers']),
        from: '${j['from'] ?? ''}',
        to: '${j['to'] ?? ''}',
        startedAt: _date(j['startedAt']),
        endedAt: _date(j['endedAt']),
        minutes: _int(j['minutes']),
        miles: _num(j['miles']),
        milesSource: _str(j['milesSource']),
        handoverReason: _str(j['handoverReason']),
      );
}

class HistoryEntry {
  HistoryEntry({required this.at, required this.legNo, required this.type, this.from, this.to, this.note, required this.actor, this.data});

  final DateTime? at;
  final int legNo;
  final String type;
  final String? from;
  final String? to;
  final String? note;
  final String actor;
  final Map<String, dynamic>? data;

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        at: _date(j['at']),
        legNo: _int(j['legNo']) ?? 1,
        type: '${j['type']}',
        from: _str(j['from']),
        to: _str(j['to']),
        note: _str(j['note']),
        actor: '${j['actor'] ?? ''}',
        data: j['data'] is Map ? Map<String, dynamic>.from(j['data']) : null,
      );
}

class YardVisit {
  YardVisit({this.trailer, this.inAt, this.outAt, this.minutes = 0, this.loaded, this.source = 'gate'});
  final String? trailer;
  final DateTime? inAt;
  final DateTime? outAt;
  final int minutes;
  final String? loaded;
  final String source;
  factory YardVisit.fromJson(Map<String, dynamic> j) => YardVisit(
        trailer: _str(j['trailer']),
        inAt: _date(j['inAt']),
        outAt: _date(j['outAt']),
        minutes: _int(j['minutes']) ?? 0,
        loaded: _str(j['loaded']),
        source: '${j['source'] ?? 'gate'}',
      );
}

class DeliveryTiming {
  DeliveryTiming({this.deliveredAt, this.etaAt, this.lateMinutes, this.etaOffMinutes, this.etaVsAppointmentMinutes});
  final DateTime? deliveredAt;
  final DateTime? etaAt;
  final int? lateMinutes;
  final int? etaOffMinutes;
  final int? etaVsAppointmentMinutes;
  factory DeliveryTiming.fromJson(Map<String, dynamic> j) => DeliveryTiming(
        deliveredAt: _date(j['deliveredAt']),
        etaAt: _date(j['etaAt']),
        lateMinutes: _int(j['lateMinutes']),
        etaOffMinutes: _int(j['etaOffMinutes']),
        etaVsAppointmentMinutes: _int(j['etaVsAppointmentMinutes']),
      );
}

/// A photo / PDF the driver sent in the chat, put on the load by the server (BOL, POD, lumper …).
class LoadDocument {
  LoadDocument({required this.messageId, this.at, this.legNo = 1, required this.url, this.thumbnail, this.uploadType, this.caption, this.docType});
  final String messageId;
  final DateTime? at;
  final int legNo;
  final String url;
  final String? thumbnail;
  final String? uploadType;
  final String? caption;
  final String? docType;

  factory LoadDocument.fromJson(Map<String, dynamic> j) => LoadDocument(
        messageId: '${j['messageId']}',
        at: _date(j['at']),
        legNo: _int(j['legNo']) ?? 1,
        url: '${j['url'] ?? ''}',
        thumbnail: _str(j['thumbnail']),
        uploadType: _str(j['uploadType']),
        caption: _str(j['caption']),
        docType: _str(j['docType']),
      );

  bool get isPdf => url.toLowerCase().endsWith('.pdf');

  String get name {
    const names = {'bol': 'BOL', 'pod': 'POD', 'scale_ticket': 'Scale ticket', 'lumper': 'Lumper receipt', 'lumper_receipt': 'Lumper receipt'};
    if (docType != null) return names[docType] ?? docType!.replaceAll('_', ' ');
    return isPdf ? 'PDF' : 'Photo';
  }
}

class LoadDetail {
  LoadDetail({
    required this.load,
    required this.legs,
    this.segments = const [],
    this.history = const [],
    this.documents = const [],
    this.yardVisits = const [],
    this.yardMinutes = 0,
    this.timing,
    this.driverNames = const {},
    this.milesTotal = 0,
    this.milesMissing = 0,
  });

  final StaffLoad load;
  final List<LoadLeg> legs;
  final List<LoadSegment> segments;
  final List<HistoryEntry> history;
  final List<LoadDocument> documents;
  final List<YardVisit> yardVisits;
  final int yardMinutes;
  final DeliveryTiming? timing;
  final Map<String, String> driverNames;
  final double milesTotal;
  final int milesMissing;

  factory LoadDetail.fromJson(Map<String, dynamic> j) {
    final legs = _maps(j['legs']).map(LoadLeg.fromJson).toList()..sort((a, b) => a.legNo.compareTo(b.legNo));
    final load = StaffLoad.fromJson(Map<String, dynamic>.from(j['load'] as Map));
    final totals = j['milesTotals'] is Map ? Map<String, dynamic>.from(j['milesTotals']) : <String, dynamic>{};
    return LoadDetail(
      load: StaffLoad(
        id: load.id,
        loadNo: load.loadNo,
        invoiceNo: load.invoiceNo,
        trackToken: load.trackToken,
        trackCode: load.trackCode,
        type: load.type,
        status: load.status,
        createdAt: load.createdAt,
        createdByName: load.createdByName,
        legs: legs,
      ),
      legs: legs,
      segments: _maps(j['segments']).map(LoadSegment.fromJson).toList(),
      history: _maps(j['history']).map(HistoryEntry.fromJson).toList(),
      documents: _maps(j['documents']).map(LoadDocument.fromJson).where((d) => d.url.isNotEmpty).toList(),
      yardVisits: _maps(j['yardVisits']).map(YardVisit.fromJson).toList(),
      yardMinutes: _int(j['yardMinutes']) ?? 0,
      timing: j['timing'] is Map ? DeliveryTiming.fromJson(Map<String, dynamic>.from(j['timing'])) : null,
      driverNames: j['driverNames'] is Map ? Map<String, String>.from((j['driverNames'] as Map).map((k, v) => MapEntry('$k', '$v'))) : {},
      milesTotal: _num(totals['miles']) ?? 0,
      milesMissing: _int(totals['missing']) ?? 0,
    );
  }

  List<LoadLeg> get activeLegs => legs.where((l) => l.status != 'cancelled').toList();
  String driverName(LoadLeg l) => l.driverProfileId == null ? 'No driver yet' : (driverNames[l.driverProfileId] ?? 'Driver');
}

/// A leg in short: the Load # lookup and the questions before something is ended.
class LegBrief {
  LegBrief({required this.tripId, required this.legNo, this.tripNo, required this.status, required this.open, this.driverName, this.truck, this.from = '', this.to = ''});
  final int tripId;
  final int legNo;
  final String? tripNo;
  final String status;
  final bool open;
  final String? driverName;
  final String? truck;
  final String from;
  final String to;
  factory LegBrief.fromJson(Map<String, dynamic> j) => LegBrief(
        tripId: _int(j['tripId']) ?? 0,
        legNo: _int(j['legNo']) ?? 1,
        tripNo: _str(j['tripNo']),
        status: '${j['status']}',
        open: _bool(j['open']),
        driverName: _str(j['driverName']),
        truck: _str(j['truck']),
        from: '${j['from'] ?? ''}',
        to: '${j['to'] ?? ''}',
      );
  String get statusLabel => LoadLeg(id: 0, legNo: 1, status: status).statusLabel;
}

class LoadLookup {
  LoadLookup({this.loadNo, this.exists = false, this.nextLegNo = 1, this.prev, this.linedUp, this.driverBusy});
  final String? loadNo;
  final bool exists;
  final int nextLegNo;
  final LegBrief? prev;

  /// The same Load # already lined up (saved, not sent): saving / sending again replaces it
  final LegBrief? linedUp;
  final LegBrief? driverBusy;
  factory LoadLookup.fromJson(Map<String, dynamic> j) => LoadLookup(
        loadNo: _str(j['loadNo']),
        exists: j['load'] != null,
        nextLegNo: _int(j['nextLegNo']) ?? 1,
        prev: j['prev'] is Map ? LegBrief.fromJson(Map<String, dynamic>.from(j['prev'])) : null,
        linedUp: j['linedUp'] is Map ? LegBrief.fromJson(Map<String, dynamic>.from(j['linedUp'])) : null,
        driverBusy: j['driverBusy'] is Map ? LegBrief.fromJson(Map<String, dynamic>.from(j['driverBusy'])) : null,
      );
}

/// The server wants an answer before going on (end the previous leg / the driver's current load).
class NeedsAnswer implements Exception {
  NeedsAnswer(this.needs, this.message, {this.prev, this.current, this.linedUp});
  final String needs; // endPrevious | driverBusy | replaceLinedUp
  final LegBrief? linedUp;
  final String message;
  final LegBrief? prev;
  final LegBrief? current;
}

/// Add-load form body (one leg; the Load # decides new load or next leg).
class NewLoadInput {
  NewLoadInput({
    required this.loadNo,
    this.driverProfileId,
    this.teamDriverProfileId,
    this.truckNumber,
    this.trailerNumbers = const [],
    this.temperature,
    this.notes,
    this.loadedTrailer = false,
    this.stops = const [],
    this.teamNames = const [],
  });

  String loadNo;
  String? driverProfileId;
  String? teamDriverProfileId;
  String? truckNumber;
  List<String> trailerNumbers;
  String? temperature;
  String? notes;
  bool loadedTrailer;
  List<NewStop> stops;

  /// Team names found in a pasted text ("TEAM # ABBY + AMIT") — only used to pick the drivers, not sent.
  List<String> teamNames;

  Map<String, dynamic> toJson() => {
        'loadNo': loadNo.trim(),
        'driverProfileId': driverProfileId,
        'teamDriverProfileId': teamDriverProfileId,
        'truckNumber': (truckNumber ?? '').trim().isEmpty ? null : truckNumber!.trim(),
        'trailerNumbers': trailerNumbers.where((t) => t.trim().isNotEmpty).map((t) => t.trim()).toList(),
        'temperature': (temperature ?? '').trim().isEmpty ? null : temperature!.trim(),
        'notes': (notes ?? '').trim().isEmpty ? null : notes!.trim(),
        'loadedTrailer': loadedTrailer,
        'stops': stops.map((s) => s.toJson()).toList(),
      };
}

class NewStop {
  NewStop({this.type = 'drop', this.name = '', this.street = '', this.city = '', this.state = '', this.zip = '', this.appointment});
  String type;
  String name;
  String street;
  String city;
  String state;
  String zip;

  /// "2026-11-12T08:00" in the stop's own local time
  String? appointment;

  bool get filled => city.trim().isNotEmpty && state.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'street': street,
        'city': city,
        'state': state.toUpperCase(),
        'zip': zip,
        'appointment': appointment,
      };
}

// ---------- the fleet: trucks, trailers, drivers ----------

class LegRef {
  LegRef({this.loadId, required this.tripId, this.tripNo, this.invoiceNo, required this.status, this.legNo = 1});
  final int? loadId;
  final int tripId;
  final String? tripNo;
  final String? invoiceNo;
  final String status;
  final int legNo;
  factory LegRef.fromJson(Map<String, dynamic> j) => LegRef(
        loadId: _int(j['loadId']),
        tripId: _int(j['tripId']) ?? 0,
        tripNo: _str(j['tripNo']),
        invoiceNo: _str(j['invoiceNo']),
        status: '${j['status']}',
        legNo: _int(j['legNo']) ?? 1,
      );
  String get label => invoiceNo ?? tripNo ?? 'trip $tripId';
}

class FleetTruck {
  FleetTruck({required this.id, required this.number, required this.state, this.leg, this.drivers = const []});
  final int id;
  final String number;

  /// on_load | lined_up | free
  final String state;
  final LegRef? leg;
  final List<String> drivers;
  factory FleetTruck.fromJson(Map<String, dynamic> j) => FleetTruck(
        id: _int(j['id']) ?? 0,
        number: '${j['number']}',
        state: '${j['state']}',
        leg: j['leg'] is Map ? LegRef.fromJson(Map<String, dynamic>.from(j['leg'])) : null,
        drivers: _maps(j['drivers']).map((d) => '${d['name']}').toList(),
      );
}

class FleetTrailer {
  FleetTrailer({required this.id, required this.number, this.type, this.readiness, required this.state, this.leg, this.gateStatus, this.gateLoaded, this.gateAt});
  final int id;
  final String number;
  final String? type;
  final String? readiness;

  /// on_load | waiting_transfer | in_yard | out | unknown
  final String state;
  final LegRef? leg;
  final String? gateStatus;
  final String? gateLoaded;
  final DateTime? gateAt;
  factory FleetTrailer.fromJson(Map<String, dynamic> j) {
    final gate = j['gate'] is Map ? Map<String, dynamic>.from(j['gate']) : null;
    return FleetTrailer(
      id: _int(j['id']) ?? 0,
      number: '${j['number']}',
      type: _str(j['type']),
      readiness: _str(j['readiness']),
      state: '${j['state']}',
      leg: j['leg'] is Map ? LegRef.fromJson(Map<String, dynamic>.from(j['leg'])) : null,
      gateStatus: gate == null ? null : _str(gate['status']),
      gateLoaded: gate == null ? null : _str(gate['loaded']),
      gateAt: gate == null ? null : _date(gate['at']),
    );
  }
}

class FleetDriver {
  FleetDriver({required this.yardId, required this.name, this.profileId, this.truck, required this.state, this.leg, this.lineup = 0});
  final int yardId;
  final String name;
  final String? profileId;
  final String? truck;

  /// on_load | lined_up | free
  final String state;
  final LegRef? leg;
  final int lineup;
  factory FleetDriver.fromJson(Map<String, dynamic> j) => FleetDriver(
        yardId: _int(j['yardId']) ?? 0,
        name: '${j['name']}',
        profileId: _str(j['profileId']),
        truck: _str(j['truck']),
        state: '${j['state']}',
        leg: j['leg'] is Map ? LegRef.fromJson(Map<String, dynamic>.from(j['leg'])) : null,
        lineup: _int(j['lineup']) ?? 0,
      );
}

// ---------- lineup and miles ----------

class LineupItem {
  LineupItem({required this.tripId, this.loadId, this.tripNo, this.invoiceNo, this.legNo = 1, this.legCount = 1, required this.status, this.position = 0, this.waits, this.fit, this.from = '', this.to = '', this.pickupLocal, this.deliveryLocal, this.truck, this.createdAt});
  final int tripId;
  final int? loadId;
  final String? tripNo;
  final String? invoiceNo;
  final int legNo;
  final int legCount;
  final String status;
  final int position;
  final String? waits;
  final String? fit;
  final String from;
  final String to;
  final String? pickupLocal;
  final String? deliveryLocal;
  final String? truck;
  final DateTime? createdAt;

  factory LineupItem.fromJson(Map<String, dynamic> j) {
    String place(dynamic s) => s is Map ? [s['city'], s['state']].where((x) => x != null && '$x'.isNotEmpty).join(', ') : '—';
    final blocked = j['blockedBy'] is Map ? Map<String, dynamic>.from(j['blockedBy']) : null;
    return LineupItem(
      tripId: _int(j['tripId']) ?? 0,
      loadId: _int(j['loadId']),
      tripNo: _str(j['tripNo']),
      invoiceNo: _str(j['invoiceNo']),
      legNo: _int(j['legNo']) ?? 1,
      legCount: _int(j['legCount']) ?? 1,
      status: '${j['status']}',
      position: _int(j['position']) ?? 0,
      waits: blocked == null ? null : 'Leg ${blocked['legNo']} (${blocked['tripNo']}) must be delivered first',
      fit: _str(j['fit']),
      from: place(j['first']),
      to: place(j['last']),
      pickupLocal: j['first'] is Map ? _str((j['first'] as Map)['appointmentLocal']) : null,
      deliveryLocal: j['last'] is Map ? _str((j['last'] as Map)['appointmentLocal']) : null,
      truck: _str(j['truck']),
      createdAt: _date(j['createdAt']),
    );
  }
  String get number => invoiceNo ?? tripNo ?? '';
}

class DriverLineup {
  DriverLineup({this.name, this.truck, this.now, this.next = const []});
  final String? name;
  final String? truck;
  final LineupItem? now;
  final List<LineupItem> next;
  factory DriverLineup.fromJson(Map<String, dynamic> j) {
    final d = j['driver'] is Map ? Map<String, dynamic>.from(j['driver']) : <String, dynamic>{};
    return DriverLineup(
      name: _str(d['name']),
      truck: _str(d['truck']),
      now: j['now'] is Map ? LineupItem.fromJson(Map<String, dynamic>.from(j['now'])) : null,
      next: _maps(j['next']).map(LineupItem.fromJson).toList(),
    );
  }
}

class MilesItem {
  MilesItem({this.loadId, this.tripNo, this.invoiceNo, this.truck, this.drivers = const [], this.from = '', this.to = '', this.startedAt, this.endedAt, this.hours, this.miles, this.milesSource});
  final int? loadId;
  final String? tripNo;
  final String? invoiceNo;
  final String? truck;
  final List<String> drivers;
  final String from;
  final String to;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final double? hours;
  final double? miles;
  final String? milesSource;
  factory MilesItem.fromJson(Map<String, dynamic> j) => MilesItem(
        loadId: _int(j['loadId']),
        tripNo: _str(j['tripNo']),
        invoiceNo: _str(j['invoiceNo']),
        truck: _str(j['truck']),
        drivers: (j['drivers'] as List? ?? []).map((e) => '$e').toList(),
        from: '${j['from'] ?? ''}',
        to: '${j['to'] ?? ''}',
        startedAt: _date(j['startedAt']),
        endedAt: _date(j['endedAt']),
        hours: _num(j['hours']),
        miles: _num(j['miles']),
        milesSource: _str(j['milesSource']),
      );
}

class MilesRow {
  MilesRow({required this.key, required this.name, this.legs = 0, this.loads = 0, this.miles = 0, this.hours = 0, this.missing = 0, this.others = const [], this.items = const []});
  final String key;
  final String name;
  final int legs;
  final int loads;
  final double miles;
  final double hours;
  final int missing;
  final List<String> others;
  final List<MilesItem> items;
  factory MilesRow.fromJson(Map<String, dynamic> j) => MilesRow(
        key: '${j['key']}',
        name: '${j['name']}',
        legs: _int(j['legs']) ?? 0,
        loads: _int(j['loads']) ?? 0,
        miles: _num(j['miles']) ?? 0,
        hours: _num(j['hours']) ?? 0,
        missing: _int(j['missing']) ?? 0,
        others: (j['others'] as List? ?? []).map((e) => '$e').toList(),
        items: _maps(j['items']).map(MilesItem.fromJson).toList(),
      );
}

/// A place found with Google (address search).
class PlaceGuess {
  PlaceGuess({required this.placeId, required this.main, required this.secondary});
  final String placeId;
  final String main;
  final String secondary;
  factory PlaceGuess.fromJson(Map<String, dynamic> j) => PlaceGuess(placeId: '${j['placeId']}', main: '${j['main']}', secondary: '${j['secondary'] ?? ''}');
}

/// Someone to pick as a driver.
class DriverPick {
  DriverPick({required this.id, required this.name});
  final String id;
  final String name;
}

class TruckPick {
  TruckPick({required this.truck, this.drivers = const []});
  final String truck;
  final List<DriverPick> drivers;
}

// ---------- live tracking (Samsara truck + Google route + US hours-of-service plan) ----------

class TruckNow {
  TruckNow({this.speedMph, this.address, this.at, this.fuelPercent, this.engine, this.vehicleName, this.stoppedSince});
  final double? speedMph;
  final String? address;
  final DateTime? at;
  final double? fuelPercent;
  final String? engine;
  final String? vehicleName;
  final DateTime? stoppedSince;
  factory TruckNow.fromJson(Map<String, dynamic> j) => TruckNow(
        speedMph: _num(j['speedMph']),
        address: _str(j['address']),
        at: _date(j['at']),
        fuelPercent: _num(j['fuelPercent']),
        engine: _str(j['engine']),
        vehicleName: _str(j['vehicleName']),
        stoppedSince: _date(j['stoppedSince']),
      );
}

class StopEta {
  StopEta({required this.stopId, required this.type, this.name, this.place = '', this.miles = 0, this.driveMinutes = 0, this.eta, this.lateMinutes});
  final int stopId;
  final String type;
  final String? name;
  final String place;
  final double miles;
  final double driveMinutes;
  final DateTime? eta;
  final int? lateMinutes;
  factory StopEta.fromJson(Map<String, dynamic> j) => StopEta(
        stopId: _int(j['stopId']) ?? 0,
        type: '${j['type']}',
        name: _str(j['name']),
        place: '${j['place'] ?? ''}',
        miles: _num(j['miles']) ?? 0,
        driveMinutes: _num(j['driveMinutes']) ?? 0,
        eta: _date(j['eta']),
        lateMinutes: _int(j['lateMinutes']),
      );
}

class EtaPlan {
  EtaPlan({this.googleMinutes = 0, this.drivingMinutes = 0, this.breakMinutes = 0, this.restMinutes = 0, this.fuelMinutes = 0, this.totalMinutes = 0, this.breaks = 0, this.rests = 0, this.fuels = 0});
  final double googleMinutes, drivingMinutes, breakMinutes, restMinutes, fuelMinutes, totalMinutes;
  final int breaks, rests, fuels;
  factory EtaPlan.fromJson(Map<String, dynamic> j) {
    final stops = _maps(j['stops']);
    int count(String k) => stops.where((s) => s['kind'] == k).length;
    return EtaPlan(
      googleMinutes: _num(j['googleMinutes']) ?? 0,
      drivingMinutes: _num(j['drivingMinutes']) ?? 0,
      breakMinutes: _num(j['breakMinutes']) ?? 0,
      restMinutes: _num(j['restMinutes']) ?? 0,
      fuelMinutes: _num(j['fuelMinutes']) ?? 0,
      totalMinutes: _num(j['totalMinutes']) ?? 0,
      breaks: count('break'),
      rests: count('rest'),
      fuels: count('fuel'),
    );
  }
}

class LiveTrip {
  LiveTrip({this.truck, this.truckProblem, this.routeProblem, this.stops = const [], this.miles, this.driveMinutes, this.restMinutes, this.plan, this.team = false, this.eta, this.fuelGallons});
  final TruckNow? truck;
  final String? truckProblem;
  final String? routeProblem;
  final List<StopEta> stops;
  final double? miles;
  final double? driveMinutes;
  final double? restMinutes;
  final EtaPlan? plan;
  final bool team;
  final DateTime? eta;
  final double? fuelGallons;
  factory LiveTrip.fromJson(Map<String, dynamic> j) => LiveTrip(
        truck: j['truck'] is Map ? TruckNow.fromJson(Map<String, dynamic>.from(j['truck'])) : null,
        truckProblem: _str(j['truckProblem']),
        routeProblem: _str(j['routeProblem']),
        stops: _maps(j['stops']).map(StopEta.fromJson).toList(),
        miles: _num(j['miles']),
        driveMinutes: _num(j['driveMinutes']),
        restMinutes: _num(j['restMinutes']),
        plan: j['plan'] is Map ? EtaPlan.fromJson(Map<String, dynamic>.from(j['plan'])) : null,
        team: _bool(j['team']),
        eta: _date(j['eta']),
        fuelGallons: _num(j['fuelGallons']),
      );
}

/// A load a chat message made — asked about before the message is deleted.
class MessageLoad {
  MessageLoad({required this.loadId, required this.legId, this.legNo = 1, this.tripNo, this.loadNo, this.status = '', this.driverName, this.onlyLeg = true, this.canDelete = true, this.why});
  final int loadId;
  final int legId;
  final int legNo;
  final String? tripNo;
  final String? loadNo;
  final String status;
  final String? driverName;
  final bool onlyLeg;
  final bool canDelete;
  final String? why;

  factory MessageLoad.fromJson(Map<String, dynamic> j) => MessageLoad(
        loadId: _int(j['loadId']) ?? 0,
        legId: _int(j['legId']) ?? 0,
        legNo: _int(j['legNo']) ?? 1,
        tripNo: _str(j['tripNo']),
        loadNo: _str(j['loadNo']),
        status: '${j['status'] ?? ''}',
        driverName: _str(j['driverName']),
        onlyLeg: j['onlyLeg'] != false,
        canDelete: j['canDelete'] == true,
        why: _str(j['why']),
      );

  String get title => 'Load ${loadNo ?? '#${tripNo ?? loadId}'}${onlyLeg ? '' : ' · leg $legNo'}';
}

/// Repair / Add to loads, step 1: what re-reading a chat message would change (nothing changes yet).
class RepairChange {
  RepairChange({required this.label, required this.before, required this.after});
  final String label;
  final String before;
  final String after;
  factory RepairChange.fromJson(Map<String, dynamic> j) => RepairChange(label: '${j['label']}', before: '${j['before']}', after: '${j['after']}');
}

class RepairPreview {
  RepairPreview({required this.messageId, this.text = '', this.mode = 'ok', this.loadNo, this.plan = false, this.load, this.changes = const [], this.messageBefore, this.messageAfter, this.canApply = false, this.why});
  final String messageId;
  final String text;

  /// add: no load yet · repair: something to fix · ok: the load already matches
  final String mode;
  final String? loadNo;
  final bool plan;
  final MessageLoad? load;
  final List<RepairChange> changes;

  /// The assistant's message that would be replaced in the chat (null: dispatch's own text stays)
  final String? messageBefore;
  final String? messageAfter;
  final bool canApply;
  final String? why;

  factory RepairPreview.fromJson(Map<String, dynamic> j) {
    final msg = j['message'] is Map ? Map<String, dynamic>.from(j['message']) : null;
    return RepairPreview(
      messageId: '${j['messageId']}',
      text: '${j['text'] ?? ''}',
      mode: '${j['mode'] ?? 'ok'}',
      loadNo: _str(j['loadNo']),
      plan: j['plan'] == true,
      load: j['load'] is Map ? MessageLoad.fromJson(Map<String, dynamic>.from(j['load'])) : null,
      changes: _maps(j['changes']).map(RepairChange.fromJson).toList(),
      messageBefore: msg == null ? null : '${msg['before']}',
      messageAfter: msg == null ? null : '${msg['after']}',
      canApply: j['canApply'] == true,
      why: _str(j['why']),
    );
  }
}

/// A recent chat message that looks like a load but isn't in Loads (missing) or made a wrong load (fixable).
class MissedLoad {
  MissedLoad({required this.kind, required this.messageId, this.at, this.driverName, this.loadNo, this.firstLine = '', this.changes = const []});
  final String kind;
  final String messageId;
  final DateTime? at;
  final String? driverName;
  final String? loadNo;
  final String firstLine;
  final List<String> changes;
  bool get missing => kind == 'missing';

  factory MissedLoad.fromJson(Map<String, dynamic> j) => MissedLoad(
        kind: '${j['kind']}',
        messageId: '${j['messageId']}',
        at: _date(j['at']),
        driverName: _str(j['driverName']),
        loadNo: _str(j['loadNo']),
        firstLine: '${j['firstLine'] ?? ''}',
        changes: (j['changes'] as List? ?? []).map((e) => '$e').toList(),
      );
}
