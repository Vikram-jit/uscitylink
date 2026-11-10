/// A trip (load) the driver is on — server/src/services/trips. GET trips/current.
class TripStop {
  TripStop({
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
  });

  final int id;
  final int seq;

  /// pickup | drop | switch
  final String type;
  final String? name;
  final String? street;
  final String? city;
  final String? state;
  final String? zip;

  /// The stop's own local time, "2026-11-06T03:15"
  final String? appointmentLocal;
  final DateTime? arrivedAt;
  final DateTime? departedAt;

  String get typeLabel => type == 'pickup' ? 'Pickup' : type == 'switch' ? 'Switch' : 'Drop';
  String get place => [city, state].where((s) => s != null && s.isNotEmpty).join(', ');

  /// "11/06 03:15 AM"
  String? get appointment {
    final v = appointmentLocal;
    if (v == null || !v.contains('T')) return null;
    final parts = v.split('T');
    final d = parts[0].split('-');
    final t = parts[1].split(':').map(int.parse).toList();
    final h = t[0] % 12 == 0 ? 12 : t[0] % 12;
    return '${d[1]}/${d[2]} ${h.toString().padLeft(2, '0')}:${t[1].toString().padLeft(2, '0')} ${t[0] >= 12 ? 'PM' : 'AM'}';
  }

  static DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();

  factory TripStop.fromJson(Map<String, dynamic> j) => TripStop(
        id: (j['id'] as num).toInt(),
        seq: (j['seq'] as num?)?.toInt() ?? 0,
        type: '${j['type'] ?? 'drop'}',
        name: j['name'] as String?,
        street: j['street'] as String?,
        city: j['city'] as String?,
        state: j['state'] as String?,
        zip: j['zip'] as String?,
        appointmentLocal: j['appointment_local'] as String?,
        arrivedAt: _date(j['arrived_at']),
        departedAt: _date(j['departed_at']),
      );
}

/// The one big button: what the server says the driver's next step is.
class TripStep {
  TripStep({required this.action, required this.label, this.stopId});
  final String action;
  final String label;
  final int? stopId;

  factory TripStep.fromJson(Map<String, dynamic> j) =>
      TripStep(action: '${j['action']}', label: '${j['label']}', stopId: (j['stopId'] as num?)?.toInt());
}

class CurrentTrip {
  CurrentTrip({
    required this.id,
    required this.tripNo,
    required this.status,
    required this.stops,
    this.truck,
    this.trailers,
    this.temperature,
    this.notes,
    this.loadedTrailer = false,
    this.openProblems = 0,
    this.next,
    this.sentAt,
    this.startedAt,
    this.endedAt,
    this.completedAt,
  });

  final int id;
  final String tripNo;

  /// planned | accepted | started | rolling | ended | paperwork | on_hold
  final String status;
  final List<TripStop> stops;
  final String? truck;
  final String? trailers;
  final String? temperature;
  final String? notes;
  final bool loadedTrailer;
  final int openProblems;
  final TripStep? next;
  final DateTime? sentAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? completedAt;

  TripStop? get firstStop => stops.isEmpty ? null : stops.first;
  TripStop? get lastStop => stops.isEmpty ? null : stops.last;

  String get statusLabel => const {
        'planned': 'New load',
        'accepted': 'Accepted',
        'started': 'Started',
        'rolling': 'Rolling',
        'ended': 'Delivered',
        'paperwork': 'Paperwork check',
        'on_hold': 'On hold',
        'completed': 'Completed',
        'routed': 'Completed',
        'cancelled': 'Cancelled',
      }[status] ??
      status;

  /// GET trips/current: { trip, next }
  static CurrentTrip? fromResponse(dynamic data) {
    if (data is! Map || data['trip'] is! Map) return null;
    return fromTrip(Map<String, dynamic>.from(data['trip']),
        next: data['next'] is Map ? TripStep.fromJson(Map<String, dynamic>.from(data['next'])) : null);
  }

  /// One trip as the server sends it (GET trips/mine lists these)
  static CurrentTrip fromTrip(Map<String, dynamic> t, {TripStep? next}) {
    final stops = (t['stops'] as List? ?? []).map((s) => TripStop.fromJson(Map<String, dynamic>.from(s))).toList()
      ..sort((a, b) => a.seq.compareTo(b.seq));
    final problems = (t['problems'] as List? ?? []).where((p) => p is Map && p['resolved_at'] == null).length;
    return CurrentTrip(
      id: (t['id'] as num).toInt(),
      tripNo: '${t['trip_no'] ?? t['id']}',
      status: '${t['status']}',
      stops: stops,
      truck: t['truck_number'] as String?,
      trailers: t['trailer_numbers'] as String?,
      temperature: t['temperature'] as String?,
      notes: t['notes'] as String?,
      loadedTrailer: t['loaded_trailer'] == true || t['loaded_trailer'] == 1,
      openProblems: problems,
      next: next,
      sentAt: TripStop._date(t['sent_at']),
      startedAt: TripStop._date(t['started_at']),
      endedAt: TripStop._date(t['ended_at']),
      completedAt: TripStop._date(t['completed_at']),
    );
  }
}

/// The assistant read the driver's message and offers the matching button ("Mark Rolling?").
class TripSuggestion {
  TripSuggestion({required this.tripId, required this.action, required this.label, this.stopId});
  final int tripId;
  final String action;
  final String label;
  final int? stopId;
}
