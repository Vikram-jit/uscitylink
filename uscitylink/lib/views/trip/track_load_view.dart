import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/utils/constant/colors.dart';

/// "Track a load" (login screen, no account needed): the customer types their load number
/// (e.g. 56033) and sees what the public tracking link shows — status, ETA,
/// where the truck is (or why it's stopped), breaks on the way, stops and activity. It stops
/// working once the load is completed. Server: GET public/track-code/:code.
class TrackLoadView extends StatefulWidget {
  const TrackLoadView({super.key, this.initialCode, this.fetcher});

  final String? initialCode;

  /// For tests: returns the server's JSON body for a code.
  final Future<Map<String, dynamic>> Function(String code)? fetcher;

  @override
  State<TrackLoadView> createState() => _TrackLoadViewState();
}

class _TrackLoadViewState extends State<TrackLoadView> {
  final _code = TextEditingController();
  Map<String, dynamic>? _view;
  String? _error;
  bool _loading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) {
      _code.text = widget.initialCode!;
      // After the first frame: _track uses the screen's focus
      WidgetsBinding.instance.addPostFrameCallback((_) => _track());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _get(String code) async {
    if (widget.fetcher != null) return widget.fetcher!(code);
    final res = await http.get(Uri.parse('${Constant.url}/public/track-code/${Uri.encodeComponent(code)}')).timeout(const Duration(seconds: 20));
    final body = jsonDecode(res.body);
    return body is Map<String, dynamic> ? body : {'status': false};
  }

  Future<void> _track({bool quiet = false}) async {
    final code = _code.text.trim().toUpperCase();
    if (code.length < 3) {
      setState(() => _error = 'Please type your load number first (like 56033)');
      return;
    }
    FocusScope.of(context).unfocus();
    if (!quiet) setState(() => _loading = true);
    try {
      final body = await _get(code);
      if (body['status'] == true && body['data'] is Map) {
        setState(() {
          _view = Map<String, dynamic>.from(body['data']);
          _error = null;
        });
        _timer?.cancel();
        if (_view?['expired'] != true) _timer = Timer.periodic(const Duration(minutes: 1), (_) => _track(quiet: true));
      } else {
        setState(() {
          _view = null;
          _error = body['message']?.toString() ?? 'No load found with that tracking code';
        });
      }
    } catch (_) {
      if (!quiet) setState(() => _error = 'Could not reach tracking — check your connection and try again');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = _view;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          surfaceTintColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          shape: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          title: const Text('Track a load', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        ),
        body: RefreshIndicator(
          onRefresh: () => _track(quiet: true),
          child: ListView(
            key: const Key('trackList'),
            padding: const EdgeInsets.all(16),
            children: [
              if (view == null)
                _Welcome(controller: _code, loading: _loading, error: _error, onTrack: () => _track())
              else
                _CodeBar(
                  code: _code.text.trim().toUpperCase(),
                  onChange: () {
                    _timer?.cancel();
                    setState(() {
                      _view = null;
                      _error = null;
                    });
                  },
                ),
              if (_error != null && view != null) ...[
                const SizedBox(height: 12),
                _Note(key: const Key('trackError'), icon: Icons.error_outline, color: Colors.red.shade700, text: _error!),
              ],
              if (view != null) ...[
                const SizedBox(height: 16),
                if (view['expired'] == true) _Expired(view: view) else _Tracking(view: view),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- pieces ----------

/// Before a load is shown: what this is, the code entry, and where the code comes from.
class _Welcome extends StatelessWidget {
  const _Welcome({required this.controller, required this.loading, required this.onTrack, this.error});
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [TColors.navyHeader, TColors.navyHeaderDeep]),
          ),
          child: Column(children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 14),
            const Text('Track your shipment', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Enter your load number to see where your load is, live.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), height: 1.35)),
          ]),
        ),
        const SizedBox(height: 16),
        _Card(children: [
          const Text('Load number', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          TextField(
            key: const Key('trackCodeInput'),
            controller: controller,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            maxLength: 20,
            autocorrect: false,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9-]')),
              TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase())),
            ],
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 4),
            decoration: InputDecoration(
              hintText: '56033',
              hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 4),
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF4F6FA),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: TColors.navyHeaderDeep, width: 2)),
            ),
            onSubmitted: (_) => onTrack(),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            _Note(key: const Key('trackError'), icon: Icons.error_outline, color: Colors.red.shade700, text: error!),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              key: const Key('trackButton'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.navyHeaderDeep,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: loading ? null : onTrack,
              icon: loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search_rounded),
              label: const Text('Track shipment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _Card(children: const [
          Text("What you'll see", style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 10),
          _Line(Icons.my_location_rounded, 'Where the truck is right now, on a map'),
          _Line(Icons.schedule_rounded, 'When it arrives — on time or running late'),
          _Line(Icons.alt_route_rounded, 'Every stop, breaks on the way, and what happened so far'),
        ]),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            "It's the load number on your order from US City Link. It works until the load is delivered and completed.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5, height: 1.4),
          ),
        ),
      ]);
}

/// While a load is shown: the code, and a way to track another one.
class _CodeBar extends StatelessWidget {
  const _CodeBar({required this.code, required this.onChange});
  final String code;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Icon(Icons.qr_code_rounded, color: TColors.navyHeaderDeep),
          const SizedBox(width: 10),
          Text('Load', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(width: 8),
          Expanded(child: Text(code, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3, fontSize: 16))),
          TextButton(key: const Key('trackChange'), onPressed: onChange, child: const Text('Change')),
        ]),
      );
}

String _when(String? iso) {
  if (iso == null) return '—';
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '—';
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day} · $h:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
}

/// "2026-11-12T08:00" (the stop's own local time) → "Thu, Nov 12 · 8:00 AM"
String? _appt(String? local) {
  if (local == null || local.isEmpty) return null;
  final d = DateTime.tryParse(local);
  return d == null ? local : _whenLocal(d);
}

String _whenLocal(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day} · $h:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
}

String _span(num? minutes) {
  if (minutes == null) return '';
  final m = minutes.round();
  return m >= 60 ? '${m ~/ 60} h${m % 60 > 0 ? ' ${m % 60} min' : ''}' : '$m min';
}

class _Expired extends StatelessWidget {
  const _Expired({required this.view});
  final Map<String, dynamic> view;

  @override
  Widget build(BuildContext context) {
    final cancelled = view['status'] == 'cancelled';
    return _Card(key: const Key('trackExpired'), children: [
      Center(child: Icon(Icons.check_circle_rounded, size: 52, color: cancelled ? Colors.grey : Colors.green.shade600)),
      const SizedBox(height: 8),
      Center(
        child: Text('Load ${view['loadNo']} ${cancelled ? 'was cancelled' : 'is completed'}',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      const SizedBox(height: 6),
      Center(
        child: Text(
          cancelled ? 'This tracking is no longer active.' : 'Delivered ${_when(view['deliveredAt'] as String?)}. This tracking has expired.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ),
    ]);
  }
}

class _Tracking extends StatelessWidget {
  const _Tracking({required this.view});
  final Map<String, dynamic> view;

  @override
  Widget build(BuildContext context) {
    final stops = (view['stops'] as List? ?? []).cast<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    final live = view['live'] is Map ? Map<String, dynamic>.from(view['live']) : null;
    final truck = live?['truck'] is Map ? Map<String, dynamic>.from(live!['truck']) : null;
    final stopped = live?['stopped'] is Map ? Map<String, dynamic>.from(live!['stopped']) : null;
    final breaks = (live?['breaks'] as List? ?? []).cast<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    final activity = (view['activity'] as List? ?? []).cast<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    final phase = '${view['phase']}';
    final delivered = phase == 'delivered';
    final origin = stops.isNotEmpty ? stops.first : null;
    final dest = stops.lastWhere((s) => s['type'] == 'drop', orElse: () => stops.isNotEmpty ? stops.last : <String, dynamic>{});
    final late = (view['lateMinutes'] as num?)?.round();
    final equipment = view['equipment'] is Map ? Map<String, dynamic>.from(view['equipment']) : null;
    final headline = delivered
        ? 'Delivered'
        : view['eta'] != null
            ? 'Arriving ${_when(view['eta'] as String?)}'
            : phase == 'in_transit'
                ? 'In transit'
                : phase == 'dispatched'
                    ? 'Driver assigned — pickup coming up'
                    : 'Booked — waiting for dispatch';

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Card(key: const Key('trackHeader'), children: [
        Text('LOAD ${view['loadNo']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(headline, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.15)),
        const SizedBox(height: 6),
        Text('${origin?['place'] ?? '—'} → ${dest['place'] ?? '—'}', style: TextStyle(color: Colors.grey.shade700)),
        if (late != null && !delivered) ...[
          const SizedBox(height: 8),
          _Pill(
            key: const Key('trackLate'),
            text: late.abs() <= 15 ? 'On time' : (late > 0 ? 'Running ${_span(late)} late' : '${_span(-late)} early'),
            color: late > 15 ? Colors.orange.shade800 : Colors.green.shade700,
          ),
        ],
        if (_appt(dest['appointment'] as String?) != null) ...[
          const SizedBox(height: 6),
          Text('Delivery appointment ${_appt(dest['appointment'] as String?)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
        const SizedBox(height: 14),
        _Steps(phase: phase),
      ]),
      if (live != null && (truck != null || (live['path'] as List? ?? []).isNotEmpty)) ...[
        const SizedBox(height: 12),
        _TrackMap(live: live),
      ],
      const SizedBox(height: 12),
      _Card(children: [
        const Text('Shipment', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (equipment?['truck'] != null)
          _Line(Icons.local_shipping_rounded, 'Truck ${equipment!['truck']}${equipment['trailer'] != null ? ' · Trailer ${equipment['trailer']}' : ''}'),
        if (equipment?['temperature'] != null) _Line(Icons.thermostat_rounded, 'Temperature ${equipment!['temperature']}'),
        if (truck != null) _Line(Icons.place_rounded, '${truck['address'] ?? 'On the road'}'),
        if (truck != null)
          ((truck['speedMph'] as num?) ?? 0) > 3
              ? _Line(Icons.speed_rounded, 'Moving · ${((truck['speedMph'] as num?) ?? 0).round()} mph')
              : _Line(
                  Icons.pause_circle_rounded,
                  'Stopped${stopped?['minutes'] != null ? ' · ${_span(stopped!['minutes'] as num?)}' : ''}${stopped?['reason'] != null ? ' · ${stopped!['reason']}' : ''}',
                  key: const Key('trackStopped'),
                  color: Colors.orange.shade800,
                ),
        if (live?['miles'] != null && !delivered) _Line(Icons.timeline_rounded, '${live!['miles']} miles to go'),
        if (truck == null && !delivered) _Line(Icons.info_outline, 'The truck shows on the map once it is on its way.'),
      ]),
      if (breaks.isNotEmpty && !delivered) ...[
        const SizedBox(height: 12),
        _Card(key: const Key('trackBreaks'), children: [
          Row(children: [
            const Expanded(child: Text('Breaks on the way', style: TextStyle(fontWeight: FontWeight.w700))),
            Text('Included in the ETA', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          for (final b in breaks)
            _Line(
              b['kind'] == 'rest' ? Icons.bedtime_rounded : b['kind'] == 'fuel' ? Icons.local_gas_station_rounded : Icons.coffee_rounded,
              '${b['kind'] == 'rest' ? '10-hour rest' : b['kind'] == 'fuel' ? 'Fuel stop' : '30-min break'} · around ${_when(b['at'] as String?)} · mile ${b['atMile']}',
            ),
        ]),
      ],
      const SizedBox(height: 12),
      _Card(key: const Key('trackStops'), children: [
        const Text('Stops', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final s in stops) _StopRow(stop: s),
      ]),
      const SizedBox(height: 12),
      _Card(key: const Key('trackActivity'), children: [
        const Text('Activity', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final a in activity)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Icon(Icons.circle, size: 8, color: identical(a, activity.first) ? TColors.navyHeaderDeep : Colors.grey.shade400),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${a['text']}', style: TextStyle(fontWeight: identical(a, activity.first) ? FontWeight.w700 : FontWeight.w500)),
                  Text(_when(a['at'] as String?), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ]),
              ),
            ]),
          ),
      ]),
      const SizedBox(height: 10),
      Center(child: Text('Updates every minute · pull down to refresh', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
      const SizedBox(height: 24),
    ]);
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.phase});
  final String phase;

  @override
  Widget build(BuildContext context) {
    const steps = ['Booked', 'Dispatched', 'In transit', 'Delivered'];
    final at = {'booked': 0, 'dispatched': 1, 'picked_up': 2, 'in_transit': 2, 'delivered': 3}[phase] ?? 0;
    return Row(
      key: const Key('trackSteps'),
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Column(children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: i < at ? Colors.green.shade600 : (i == at ? TColors.navyHeaderDeep : Colors.grey.shade300),
              child: i < at ? const Icon(Icons.check, size: 15, color: Colors.white) : Text('${i + 1}', style: TextStyle(fontSize: 12, color: i == at ? Colors.white : Colors.grey.shade600)),
            ),
            const SizedBox(height: 4),
            Text(steps[i], style: TextStyle(fontSize: 11, fontWeight: i == at ? FontWeight.w700 : FontWeight.w500)),
          ]),
          if (i < steps.length - 1)
            Expanded(child: Container(height: 3, margin: const EdgeInsets.only(bottom: 16), color: i < at ? Colors.green.shade600 : Colors.grey.shade300)),
        ],
      ],
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({required this.stop});
  final Map<String, dynamic> stop;

  @override
  Widget build(BuildContext context) {
    final type = '${stop['type']}';
    final state = '${stop['state']}';
    final color = type == 'pickup' ? Colors.green.shade700 : type == 'drop' ? Colors.red.shade700 : Colors.orange.shade800;
    final label = type == 'pickup' ? 'PICKUP' : type == 'drop' ? 'DELIVERY' : 'TRANSFER POINT';
    final times = [
      if (_appt(stop['appointment'] as String?) != null) 'Appointment ${_appt(stop['appointment'] as String?)}',
      if (stop['arrivedAt'] != null) 'Arrived ${_when(stop['arrivedAt'] as String?)}',
      if (stop['departedAt'] != null) 'Left ${_when(stop['departedAt'] as String?)}',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(state == 'done' ? Icons.check_circle : Icons.radio_button_checked, size: 16, color: state == 'upcoming' ? Colors.grey.shade400 : color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$label${state == 'next' ? ' · NEXT' : ''}', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
            Text('${stop['name'] ?? stop['place']}', style: const TextStyle(fontWeight: FontWeight.w700)),
            if (stop['address'] != null) Text('${stop['address']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            if (times.isNotEmpty) Text(times.join(' · '), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}

class _TrackMap extends StatelessWidget {
  const _TrackMap({required this.live});
  final Map<String, dynamic> live;

  @override
  Widget build(BuildContext context) {
    final truck = live['truck'] is Map ? Map<String, dynamic>.from(live['truck']) : null;
    final path = (live['path'] as List? ?? [])
        .whereType<List>()
        .where((p) => p.length == 2)
        .map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList();
    final stops = (live['stops'] as List? ?? []).cast<Map>().where((s) => s['lat'] != null && s['lng'] != null).toList();
    final markers = <Marker>{
      if (truck != null)
        Marker(
          markerId: const MarkerId('truck'),
          position: LatLng((truck['lat'] as num).toDouble(), (truck['lng'] as num).toDouble()),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'Truck ${truck['vehicleName'] ?? ''}', snippet: '${truck['address'] ?? ''}'),
        ),
      for (final s in stops)
        Marker(
          markerId: MarkerId('stop_${s['stopId']}'),
          position: LatLng((s['lat'] as num).toDouble(), (s['lng'] as num).toDouble()),
          infoWindow: InfoWindow(title: '${s['name'] ?? s['place']}'),
        ),
    };
    final center = truck != null
        ? LatLng((truck['lat'] as num).toDouble(), (truck['lng'] as num).toDouble())
        : (path.isNotEmpty ? path.first : const LatLng(39.5, -98.35));
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 260,
        child: GoogleMap(
          key: const Key('trackMap'),
          initialCameraPosition: CameraPosition(target: center, zoom: 7),
          markers: markers,
          polylines: {
            if (path.length > 1) Polyline(polylineId: const PolylineId('route'), points: path, width: 5, color: const Color(0xFF2563EB)),
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

class _Line extends StatelessWidget {
  const _Line(this.icon, this.text, {super.key, this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: color ?? Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontWeight: color != null ? FontWeight.w700 : FontWeight.w500, color: color))),
        ]),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({super.key, required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(border: Border.all(color: color), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      );
}

class _Note extends StatelessWidget {
  const _Note({super.key, required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
        ]),
      );
}
