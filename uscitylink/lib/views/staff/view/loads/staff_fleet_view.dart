import 'package:flutter/material.dart';
import 'package:uscitylink/model/staff/load_models.dart';
import 'package:uscitylink/services/staff/loads_service.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/view/loads/loads_common.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';

/// Equipment board (trucks, trailers, drivers: free / on a load / in the yard), lineups and miles.
class StaffFleetView extends StatefulWidget {
  const StaffFleetView({super.key, this.service});
  final LoadsService? service;

  @override
  State<StaffFleetView> createState() => _StaffFleetViewState();
}

class _StaffFleetViewState extends State<StaffFleetView> with SingleTickerProviderStateMixin {
  late final LoadsService _svc = widget.service ?? LoadsService();
  late final TabController _tabs = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StaffColors.canvas,
      body: Column(children: [
        StaffHeader(
          title: 'Equipment & miles',
          subtitle: 'Who and what is free',
          leadingIcon: Icons.arrow_back_rounded,
          onLeading: () => Navigator.pop(context),
          bottom: StaffSegmentedTabs(controller: _tabs, labels: const ['Trucks', 'Trailers', 'Drivers', 'Miles']),
        ),
        Expanded(
          child: TabBarView(controller: _tabs, children: [
            _FleetList<FleetTruck>(load: _svc.trucks, row: (t) => _row(t.number, stateLabel(t.state), stateColor(t.state), [if (t.drivers.isNotEmpty) t.drivers.join(' + '), if (t.leg != null) 'Load ${t.leg!.label}'].join(' · '))),
            _FleetList<FleetTrailer>(
              load: _svc.trailers,
              row: (t) => _row(t.number, trailerLabel(t.state), trailerColor(t.state), [if (t.type != null) t.type!, if (t.leg != null) 'Load ${t.leg!.label}', if (t.gateAt != null) 'Gate ${t.gateStatus ?? ''} ${fmtDateTime(t.gateAt)}'].join(' · ')),
            ),
            _FleetList<FleetDriver>(
              load: _svc.drivers,
              row: (d) => _row(d.name, stateLabel(d.state), stateColor(d.state), [if (d.truck != null) 'Truck ${d.truck}', if (d.leg != null) 'Load ${d.leg!.label}', if (d.lineup > 0) '${d.lineup} lined up'].join(' · '), onTap: d.profileId == null ? null : () => _lineup(d)),
            ),
            _MilesTab(service: _svc),
          ]),
        ),
      ]),
    );
  }

  Future<void> _lineup(FleetDriver d) => Navigator.push(context, MaterialPageRoute(builder: (_) => StaffLineupView(profileId: d.profileId!, service: _svc)));
}

String stateLabel(String s) => const {'on_load': 'On a load', 'lined_up': 'Lined up', 'free': 'Free'}[s] ?? s;
Color stateColor(String s) => s == 'free' ? StaffColors.success : s == 'lined_up' ? StaffColors.warning : StaffColors.sky;
String trailerLabel(String s) => const {'on_load': 'On a load', 'waiting_transfer': 'Waiting transfer', 'in_yard': 'In yard', 'out': 'Out', 'unknown': 'Unknown'}[s] ?? s;
Color trailerColor(String s) => s == 'in_yard' ? StaffColors.success : s == 'waiting_transfer' ? StaffColors.orange : s == 'on_load' ? StaffColors.sky : StaffColors.textMuted;

Widget _row(String title, String pill, Color color, String sub, {VoidCallback? onTap}) => Material(
      color: StaffColors.card,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: AppText.titleMd),
        subtitle: sub.isEmpty ? null : Text(sub),
        trailing: StaffPill(label: pill, color: color),
      ),
    );

class _FleetList<T> extends StatefulWidget {
  const _FleetList({required this.load, required this.row});
  final Future<List<T>> Function() load;
  final Widget Function(T) row;

  @override
  State<_FleetList<T>> createState() => _FleetListState<T>();
}

class _FleetListState<T> extends State<_FleetList<T>> with AutomaticKeepAliveClientMixin {
  List<T>? _items;
  String? _error;
  String _q = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final r = await widget.load();
      if (mounted) setState(() => (_items = r, _error = null));
    } catch (e) {
      if (mounted) setState(() => _error = errText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_error != null) return Center(child: Text(_error!));
    final items = _items;
    if (items == null) return const Center(child: CircularProgressIndicator());
    final shown = _q.isEmpty ? items : items.where((x) => (x as dynamic).toString().isNotEmpty && _text(x).toLowerCase().contains(_q)).toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: TextField(onChanged: (v) => setState(() => _q = v.trim().toLowerCase()), decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search', isDense: true, filled: true, fillColor: Colors.white)),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _fetch,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: shown.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => widget.row(shown[i]),
          ),
        ),
      ),
    ]);
  }

  String _text(T x) {
    if (x is FleetTruck) return '${x.number} ${x.drivers.join(' ')}';
    if (x is FleetTrailer) return x.number;
    if (x is FleetDriver) return '${x.name} ${x.truck ?? ''}';
    return '';
  }
}

class _MilesTab extends StatefulWidget {
  const _MilesTab({required this.service});
  final LoadsService service;

  @override
  State<_MilesTab> createState() => _MilesTabState();
}

class _MilesTabState extends State<_MilesTab> with AutomaticKeepAliveClientMixin {
  String _by = 'driver';
  DateTimeRange _range = DateTimeRange(start: DateTime.now().subtract(const Duration(days: 7)), end: DateTime.now());
  List<MilesRow>? _rows;
  double _total = 0;
  int _missing = 0;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _rows = null);
    try {
      final r = await widget.service.miles(by: _by, from: _range.start, to: DateTime(_range.end.year, _range.end.month, _range.end.day, 23, 59, 59));
      if (mounted) setState(() => (_rows = r.rows, _total = r.miles, _missing = r.missing, _error = null));
    } catch (e) {
      if (mounted) setState(() => (_error = errText(e), _rows = []));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          SegmentedButton<String>(
            segments: const [ButtonSegment(value: 'driver', label: Text('By driver')), ButtonSegment(value: 'truck', label: Text('By truck'))],
            selected: {_by},
            onSelectionChanged: (v) {
              _by = v.first;
              _fetch();
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.date_range_rounded),
            onPressed: () async {
              final r = await showDateRangePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now().add(const Duration(days: 1)), initialDateRange: _range);
              if (r != null) {
                _range = r;
                _fetch();
              }
            },
          ),
        ]),
      ),
      Text('${fmtDay(_range.start)} – ${fmtDay(_range.end)} · ${fmtMiles(_total)}${_missing > 0 ? ' · $_missing leg(s) missing miles' : ''}', style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
      Expanded(
        child: _rows == null
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : ListView(padding: const EdgeInsets.all(12), children: [
                    for (final r in _rows!)
                      Card(
                        color: StaffColors.card,
                        elevation: 0,
                        child: ExpansionTile(
                          title: Text(r.name, style: AppText.titleMd),
                          subtitle: Text('${fmtMiles(r.miles)} · ${r.loads} load(s) · ${r.hours.toStringAsFixed(1)} h${r.missing > 0 ? ' · ${r.missing} missing' : ''}'),
                          children: [
                            for (final i in r.items)
                              ListTile(dense: true, title: Text('Load ${i.invoiceNo ?? i.tripNo ?? ''}  ${i.from} → ${i.to}'), subtitle: Text('${i.drivers.join(' + ')}${i.truck == null ? '' : ' · Truck ${i.truck}'}\n${fmtDateTime(i.startedAt)} – ${fmtDateTime(i.endedAt)}'), trailing: Text(fmtMiles(i.miles))),
                          ],
                        ),
                      ),
                    if (_rows!.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No miles in this range'))),
                  ]),
      ),
    ]);
  }
}

/// A driver's lineup: the load they're on and what's lined up next (remove, or reorder by dragging).
class StaffLineupView extends StatefulWidget {
  const StaffLineupView({super.key, required this.profileId, this.service});
  final String profileId;
  final LoadsService? service;

  @override
  State<StaffLineupView> createState() => _StaffLineupViewState();
}

class _StaffLineupViewState extends State<StaffLineupView> {
  late final LoadsService _svc = widget.service ?? LoadsService();
  DriverLineup? _l;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final l = await _svc.lineup(widget.profileId);
      if (mounted) setState(() => (_l = l, _error = null));
    } catch (e) {
      if (mounted) setState(() => _error = errText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = _l;
    return Scaffold(
      backgroundColor: StaffColors.canvas,
      body: Column(children: [
        StaffHeader(title: l?.name ?? 'Lineup', subtitle: l?.truck == null ? 'Loads in order' : 'Truck ${l!.truck}', leadingIcon: Icons.arrow_back_rounded, onLeading: () => Navigator.pop(context)),
        Expanded(
          child: l == null
              ? Center(child: _error != null ? Text(_error!) : const CircularProgressIndicator())
              : ListView(padding: const EdgeInsets.all(12), children: [
                  Text('On the road now', style: AppText.titleMd),
                  const SizedBox(height: 6),
                  l.now == null ? const Text('Nothing right now') : _item(l.now!, null),
                  const SizedBox(height: 16),
                  Text('Lined up next', style: AppText.titleMd),
                  const SizedBox(height: 6),
                  if (l.next.isEmpty) const Text('No loads lined up'),
                  if (l.next.isNotEmpty)
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: (a, b) async {
                        final list = [...l.next];
                        if (b > a) b -= 1;
                        list.insert(b, list.removeAt(a));
                        setState(() => _l = DriverLineup(name: l.name, truck: l.truck, now: l.now, next: list));
                        try {
                          await _svc.reorderLineup(widget.profileId, list.map((x) => x.tripId).toList());
                        } catch (e) {
                          if (mounted) snack(context, errText(e), error: true);
                          _fetch();
                        }
                      },
                      children: [for (final i in l.next) KeyedSubtree(key: ValueKey(i.tripId), child: Padding(padding: const EdgeInsets.only(bottom: 8), child: _item(i, () => _remove(i))))],
                    ),
                ]),
        ),
      ]),
    );
  }

  Future<void> _remove(LineupItem i) async {
    if (!await confirmDialog(context, title: 'Take off the lineup?', body: 'Load ${i.number} will wait for a driver.', yes: 'Take off')) return;
    try {
      await _svc.removeFromLineup(widget.profileId, i.tripId);
      _fetch();
    } catch (e) {
      if (mounted) snack(context, errText(e), error: true);
    }
  }

  Widget _item(LineupItem i, VoidCallback? remove) => Material(
        color: StaffColors.card,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: ListTile(
          title: Text('Load ${i.number}${i.legCount > 1 ? ' · leg ${i.legNo}/${i.legCount}' : ''}', style: AppText.titleMd),
          subtitle: Text('${i.from} → ${i.to}${i.pickupLocal == null ? '' : '\nPickup ${fmtLocal(i.pickupLocal)}'}${i.waits == null ? '' : '\n${i.waits}'}'),
          trailing: remove == null ? null : IconButton(icon: const Icon(Icons.remove_circle_outline_rounded), onPressed: remove),
        ),
      );
}
