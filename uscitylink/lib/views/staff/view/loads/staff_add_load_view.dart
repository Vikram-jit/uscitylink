import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uscitylink/model/staff/load_models.dart';
import 'package:uscitylink/services/staff/loads_service.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/view/loads/loads_common.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';

/// Add a load: Load # is required; the same Load # again is the next leg (the form says so).
class StaffAddLoadView extends StatefulWidget {
  const StaffAddLoadView(
      {super.key, this.service, this.edit, this.loadNumber, this.driverName});
  final LoadsService? service;

  /// Editing this leg (the Load # stays as it is)
  final LoadLeg? edit;
  final String? loadNumber;
  final String? driverName;

  @override
  State<StaffAddLoadView> createState() => _StaffAddLoadViewState();
}

class _StaffAddLoadViewState extends State<StaffAddLoadView> {
  late final LoadsService _svc = widget.service ?? LoadsService();
  final _loadNo = TextEditingController();
  final _trailer = TextEditingController();
  final _temp = TextEditingController();
  final _notes = TextEditingController();
  final _truck = TextEditingController();
  List<NewStop> _stops = [NewStop(type: 'pickup'), NewStop(type: 'drop')];
  List<DriverPick> _drivers = [];
  DriverPick? _driver;
  DriverPick? _team;
  bool _loaded = false;
  bool _busy = false;
  LoadLookup? _lookup;
  Timer? _debounce;
  final Map<NewStop, TextEditingController> _addr = {};

  bool get _editing => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final l = widget.edit;
    if (l == null) return;
    _loadNo.text = widget.loadNumber ?? '';
    _truck.text = l.truck ?? '';
    _trailer.text = l.trailers ?? '';
    _temp.text = l.temperature ?? '';
    _notes.text = l.notes ?? '';
    _loaded = l.loadedTrailer;
    _stops = [
      for (final x in l.stops)
        NewStop(
            type: x.type,
            name: x.name ?? '',
            street: x.street ?? '',
            city: x.city ?? '',
            state: x.state ?? '',
            zip: x.zip ?? '',
            appointment: x.appointmentLocal)
    ];
    if (l.driverProfileId != null)
      _driver = DriverPick(
          id: l.driverProfileId!, name: widget.driverName ?? 'Driver');
    _drivers = [if (_driver != null) _driver!];
    if (l.truck != null) {
      _svc.truckPicks(l.truck!).then((picks) {
        final t = picks.where((p) => p.truck == l.truck).firstOrNull;
        if (t == null || !mounted) return;
        setState(() {
          _drivers = t.drivers;
          _driver =
              t.drivers.where((d) => d.id == l.driverProfileId).firstOrNull ??
                  _driver;
          if (!_drivers.contains(_driver) && _driver != null)
            _drivers = [_driver!, ..._drivers];
        });
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_loadNo, _trailer, _temp, _notes, _truck]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onLoadNo(String v) {
    _debounce?.cancel();
    if (v.trim().isEmpty) return setState(() => _lookup = null);
    _debounce = Timer(const Duration(milliseconds: 400), _doLookup);
  }

  Future<void> _doLookup() async {
    try {
      final r = await _svc.lookup(_loadNo.text.trim(), driver: _driver?.id);
      if (mounted) setState(() => _lookup = r);
    } catch (_) {}
  }

  String? get _note {
    final l = _lookup;
    if (l == null) return null;
    if (!l.exists) return 'New load';
    final u = l.linedUp;
    if (u != null) {
      return 'Load ${l.loadNo} is already lined up for ${u.driverName ?? 'no driver'}${u.truck == null ? '' : ' / truck ${u.truck}'} (${u.from} → ${u.to}) — not sent yet. Saving or sending this one replaces that copy.';
    }
    final p = l.prev;
    final who = p == null
        ? ''
        : ' after ${p.driverName ?? 'the driver'}${p.truck == null ? '' : ' / truck ${p.truck}'} (${p.from} → ${p.to}, ${p.statusLabel.toLowerCase()})';
    return 'Load ${l.loadNo} exists — this is leg ${l.nextLegNo}$who'
        '${p != null && p.open ? '. ${p.driverName ?? 'The driver'} hasn\'t ended leg ${p.legNo} yet.' : ''}';
  }

  Future<void> _pickTruck() async {
    List<TruckPick> trucks;
    try {
      trucks = await _svc.truckPicks('');
    } catch (e) {
      return snack(context, errText(e), error: true);
    }
    if (!mounted) return;
    final t = await showModalBottomSheet<TruckPick>(
      context: context,
      isScrollControlled: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (c, sc) => ListView(controller: sc, children: [
          const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Pick a truck',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
          for (final t in trucks)
            ListTile(
                title: Text('Truck ${t.truck}'),
                subtitle: Text(t.drivers.isEmpty
                    ? 'No driver assigned'
                    : t.drivers.map((d) => d.name).join(' + ')),
                onTap: () => Navigator.pop(c, t)),
        ]),
      ),
    );
    if (t != null) _applyTruck(t);
  }

  void _applyTruck(TruckPick t) {
    setState(() {
      _truck.text = t.truck;
      _drivers = t.drivers;
      _driver = t.drivers.isEmpty ? null : t.drivers.first;
      _team = t.drivers.length > 1 ? t.drivers[1] : null;
    });
    _doLookup();
  }

  Future<void> _paste() async {
    final c = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Paste a typed load'),
        content: TextField(
            controller: c,
            maxLines: 10,
            decoration: const InputDecoration(
                hintText: 'LOAD # 1011\nPICKUP…\nDELIVERY…')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(d, c.text),
              child: const Text('Read it'))
        ],
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    try {
      final p = await _svc.parseText(text);
      setState(() {
        if (p.loadNo.isNotEmpty) _loadNo.text = p.loadNo;
        _trailer.text = p.trailerNumbers.join(', ');
        _temp.text = p.temperature ?? '';
        _loaded = p.loadedTrailer;
        if (p.stops.isNotEmpty) _stops = p.stops;
      });
      if (p.truckNumber != null) {
        final m = (await _svc.truckPicks(p.truckNumber!))
            .where((t) => t.truck == p.truckNumber)
            .firstOrNull;
        if (m != null) _applyTruck(m);
      }
      _doLookup();
      if (mounted && p.loadNo.isEmpty)
        snack(context, 'No Load # found in that text — type it above',
            error: true);
    } catch (e) {
      if (mounted) snack(context, errText(e), error: true);
    }
  }

  NewLoadInput _input() => NewLoadInput(
        loadNo: _loadNo.text,
        driverProfileId: _driver?.id,
        teamDriverProfileId: _team?.id,
        truckNumber: _truck.text,
        trailerNumbers: _trailer.text.split(RegExp(r'[,\s]+')),
        temperature: _temp.text,
        notes: _notes.text,
        loadedTrailer: _loaded,
        stops: _stops.where((s) => s.filled).toList(),
      );

  Future<void> _saveEdit() async {
    if (_stops.where((s) => s.filled).isEmpty)
      return snack(context, 'Add at least one stop (city and state)',
          error: true);
    setState(() => _busy = true);
    try {
      final msg = await _svc.editLeg(widget.edit!.id, _input());
      if (!mounted) return;
      snack(context, msg);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) snack(context, errText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit({required bool send}) async {
    if (_editing) return _saveEdit();
    if (_loadNo.text.trim().isEmpty)
      return snack(context, 'Type the Load # first', error: true);
    if (_stops.where((s) => s.filled).isEmpty)
      return snack(context, 'Add at least one stop (city and state)',
          error: true);
    if (send && _driver == null)
      return snack(context, 'Pick a truck / driver to send to', error: true);
    setState(() => _busy = true);
    var endPrevious = false, endCurrent = false, lineUp = false, replace = false;
    try {
      for (var i = 0; i < 4; i++) {
        try {
          final msg = await _svc.addLoad(_input(),
              send: send,
              endPrevious: endPrevious,
              endDriverCurrent: endCurrent,
              lineUp: lineUp,
              replace: replace);
          if (!mounted) return;
          snack(context, msg);
          Navigator.pop(context, true);
          return;
        } on NeedsAnswer catch (n) {
          if (!mounted) return;
          if (n.needs == 'replaceLinedUp' && n.linedUp != null) {
            final choice = await askReplaceLinedUp(context, loadNo: _loadNo.text.trim().toUpperCase(), linedUp: n.linedUp!, current: n.current, send: send);
            if (choice == null) return;
            replace = true;
            if (choice == 'line') lineUp = true;
            if (choice == 'end') endCurrent = true;
          } else if (n.needs == 'endPrevious') {
            final p = n.prev;
            final ok = await confirmDialog(context,
                title: 'Leg ${p?.legNo ?? ''} is still open',
                body:
                    '${p?.driverName ?? 'The driver'} hasn\'t ended leg ${p?.legNo ?? ''} (${p?.from ?? ''} → ${p?.to ?? ''}). End it now and send this leg?',
                yes: 'End & send');
            if (!ok) return;
            endPrevious = true;
          } else {
            final c = n.current;
            final choice = await showDialog<String>(
              context: context,
              builder: (d) => AlertDialog(
                title: const Text('Driver is on another load'),
                content: Text(
                    '${_driver?.name ?? 'The driver'} is on load ${c?.tripNo ?? ''} (${c?.statusLabel.toLowerCase() ?? ''}). End it now, or line this one up after it?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(d),
                      child: const Text('Cancel')),
                  OutlinedButton(
                      onPressed: () => Navigator.pop(d, 'line'),
                      child: const Text('Line up after')),
                  FilledButton(
                      onPressed: () => Navigator.pop(d, 'end'),
                      child: Text('End ${c?.tripNo ?? ''} & send')),
                ],
              ),
            );
            if (choice == null) return;
            if (choice == 'line') {
              lineUp = true;
            } else {
              endCurrent = true;
            }
          }
        }
      }
    } catch (e) {
      if (mounted) snack(context, errText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<DateTime?> _pickDate(String? cur) async {
    final base = DateTime.tryParse(cur ?? '') ?? DateTime.now();
    final d = await showDatePicker(
        context: context,
        initialDate: base,
        firstDate: DateTime(2024),
        lastDate: DateTime(2100));
    if (d == null || !mounted) return null;
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(base));
    return t == null
        ? null
        : DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _searchAddress(NewStop s) async {
    final q = TextEditingController();
    List<PlaceGuess> guesses = [];
    Timer? t;
    final pick = await showModalBottomSheet<PlaceGuess>(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(builder: (c, set) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
          child: SizedBox(
            height: 420,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: q,
                  autofocus: true,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Search an address or place'),
                  onChanged: (v) {
                    t?.cancel();
                    t = Timer(const Duration(milliseconds: 350), () async {
                      final r = await _svc
                          .searchPlaces(v)
                          .catchError((_) => <PlaceGuess>[]);
                      if (c.mounted) set(() => guesses = r);
                    });
                  },
                ),
              ),
              Expanded(
                  child: ListView(children: [
                for (final g in guesses)
                  ListTile(
                      title: Text(g.main),
                      subtitle: Text(g.secondary),
                      onTap: () => Navigator.pop(c, g))
              ])),
            ]),
          ),
        );
      }),
    );
    t?.cancel();
    if (pick == null) return;
    final p = await _svc.placeStop(pick.placeId).catchError((_) => null);
    if (p == null || !mounted) return;
    setState(() {
      s.name = p.name;
      s.street = p.street;
      s.city = p.city;
      s.state = p.state;
      s.zip = p.zip;
    });
  }

  @override
  Widget build(BuildContext context) {
    final note = _note;
    return Scaffold(
      backgroundColor: StaffColors.canvas,
      body: Column(children: [
        StaffHeader(
          title: _editing ? 'Edit load' : 'Add load',
          subtitle: _editing
              ? 'Leg ${widget.edit!.legNo} · #${widget.edit!.tripNo ?? ''}'
              : 'The Load # decides the legs',
          leadingIcon: Icons.arrow_back_rounded,
          onLeading: () => Navigator.pop(context),
          actions: [
            if (!_editing)
              StaffGlassButton(icon: Icons.content_paste_rounded, onTap: _paste)
          ],
        ),
        Expanded(
          child:
              ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
            TextField(
                key: const Key('loadNo'),
                controller: _loadNo,
                readOnly: _editing,
                onChanged: _onLoadNo,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                    labelText: 'Load # (required)',
                    filled: true,
                    fillColor: Colors.white)),
            if (note != null)
              Container(
                key: const Key('lookupNote'),
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: (_lookup!.exists
                            ? StaffColors.sky
                            : StaffColors.success)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadii.sm)),
                child: Text(note,
                    style:
                        AppText.bodySm.copyWith(color: StaffColors.textStrong)),
              ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickTruck,
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Truck',
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: Icon(Icons.arrow_drop_down)),
                child: Text(
                    _truck.text.isEmpty
                        ? 'Pick a truck'
                        : 'Truck ${_truck.text}',
                    key: const Key('truckField')),
              ),
            ),
            if (_drivers.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<DriverPick>(
                key: const Key('driverField'),
                initialValue: _driver,
                decoration: const InputDecoration(
                    labelText: 'Driver', filled: true, fillColor: Colors.white),
                items: [
                  for (final d in _drivers)
                    DropdownMenuItem(value: d, child: Text(d.name))
                ],
                onChanged: (v) {
                  setState(() => _driver = v);
                  _doLookup();
                },
              ),
              if (_drivers.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: DropdownButtonFormField<DriverPick?>(
                    initialValue: _team,
                    decoration: const InputDecoration(
                        labelText: 'Team driver',
                        filled: true,
                        fillColor: Colors.white),
                    items: [
                      const DropdownMenuItem<DriverPick?>(
                          value: null, child: Text('None')),
                      for (final d
                          in _drivers.where((x) => x.id != _driver?.id))
                        DropdownMenuItem(value: d, child: Text(d.name))
                    ],
                    onChanged: (v) => setState(() => _team = v),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            TextField(
                controller: _trailer,
                decoration: const InputDecoration(
                    labelText: 'Trailer(s)',
                    hintText: '10010',
                    filled: true,
                    fillColor: Colors.white)),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Trailer is already loaded'),
                value: _loaded,
                onChanged: (v) => setState(() => _loaded = v)),
            const SizedBox(height: 4),
            Text('Stops', style: AppText.titleMd),
            for (var i = 0; i < _stops.length; i++) _stopCard(i),
            TextButton.icon(
                onPressed: () =>
                    setState(() => _stops.add(NewStop(type: 'drop'))),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Add stop')),
            const SizedBox(height: 8),
            TextField(
                controller: _temp,
                decoration: const InputDecoration(
                    labelText: 'Temperature',
                    hintText: '34 CONT.',
                    filled: true,
                    fillColor: Colors.white)),
            const SizedBox(height: 12),
            TextField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Notes', filled: true, fillColor: Colors.white)),
            const SizedBox(height: 90),
          ]),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(AppSpacing.md, 8, AppSpacing.md, 8),
            child: _editing
                ? SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        key: const Key('saveEdit'),
                        onPressed: _busy ? null : _saveEdit,
                        child: const Text('Save changes')))
                : Row(children: [
                    Expanded(
                        child: OutlinedButton(
                            key: const Key('saveLater'),
                            onPressed:
                                _busy ? null : () => _submit(send: false),
                            child: const Text('Save for later'))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: FilledButton(
                            key: const Key('sendNow'),
                            onPressed: _busy ? null : () => _submit(send: true),
                            child: _busy
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Send now'))),
                  ]),
          ),
        ),
      ]),
    );
  }

  Widget _stopCard(int i) {
    final s = _stops[i];
    final c = _addr.putIfAbsent(s, () => TextEditingController());
    c.text = s.filled
        ? [s.name, s.street, '${s.city}, ${s.state} ${s.zip}']
            .where((x) => x.trim().isNotEmpty)
            .join(' · ')
        : '';
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.md)),
      child: Column(children: [
        Row(children: [
          DropdownButton<String>(
            value: s.type,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'pickup', child: Text('Pickup')),
              DropdownMenuItem(value: 'drop', child: Text('Delivery')),
              DropdownMenuItem(value: 'switch', child: Text('Meet point')),
              DropdownMenuItem(value: 'yard', child: Text('Our yard')),
            ],
            onChanged: (v) => setState(() => s.type = v ?? s.type),
          ),
          const Spacer(),
          if (_stops.length > 1)
            IconButton(
                onPressed: () => setState(() => _stops.removeAt(i)),
                icon: const Icon(Icons.close_rounded)),
        ]),
        TextField(
            controller: c,
            readOnly: true,
            onTap: () => _searchAddress(s),
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search address (Google)')),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
              child: TextFormField(
                  key: ValueKey('city${s.hashCode}${s.city}'),
                  initialValue: s.city,
                  onChanged: (v) => s.city = v,
                  decoration: const InputDecoration(labelText: 'City'))),
          const SizedBox(width: 8),
          SizedBox(
              width: 64,
              child: TextFormField(
                  key: ValueKey('st${s.hashCode}${s.state}'),
                  initialValue: s.state,
                  onChanged: (v) => s.state = v,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 2,
                  decoration:
                      const InputDecoration(labelText: 'ST', counterText: ''))),
        ]),
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(Icons.schedule_rounded),
          title: Text(s.appointment == null
              ? 'Appointment (stop\'s local time)'
              : fmtLocal(s.appointment)),
          onTap: () async {
            final d = await _pickDate(s.appointment);
            if (d != null) setState(() => s.appointment = _iso(d));
          },
        ),
      ]),
    );
  }
}
