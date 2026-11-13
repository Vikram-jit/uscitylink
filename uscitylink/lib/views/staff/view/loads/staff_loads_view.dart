import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uscitylink/model/staff/load_models.dart';
import 'package:uscitylink/services/staff/loads_service.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/view/loads/loads_common.dart';
import 'package:uscitylink/views/staff/view/loads/staff_add_load_view.dart';
import 'package:uscitylink/views/staff/view/loads/staff_fleet_view.dart';
import 'package:uscitylink/views/staff/view/loads/staff_load_detail_view.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';

/// Loads tab for dispatch: every load by its Load #, filtered by what needs doing.
class StaffLoadsView extends StatefulWidget {
  const StaffLoadsView({super.key, this.service});
  final LoadsService? service;

  @override
  State<StaffLoadsView> createState() => StaffLoadsViewState();
}

class StaffLoadsViewState extends State<StaffLoadsView> {
  late final LoadsService _svc = widget.service ?? LoadsService();
  static const _tabs = [
    ('', 'All'),
    ('transfer', 'Ready to transfer'),
    ('waiting', 'Driver waiting'),
    ('scheduled', 'Scheduled'),
    ('active', 'On the road'),
    ('delivered', 'Delivered'),
    ('completed', 'Completed'),
  ];
  String _status = '';
  String _q = '';
  Timer? _debounce;
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<StaffLoad> _loads = [];
  Map<String, int> _counts = {};
  Map<String, String> _names = {};

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Also called when a socket event says loads changed.
  Future<void> refresh() async {
    try {
      final r = await _svc.list(status: _status, q: _q);
      if (!mounted) return;
      setState(() {
        _loads = r.loads;
        _counts = r.counts;
        _names = r.driverNames;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = errText(e);
      });
    }
  }

  int _count(String s) => s.isEmpty ? _counts.values.fold(0, (a, b) => a + b) : (_counts[s] ?? 0);

  @override
  Widget build(BuildContext context) {
    final attention = (_counts['transfer'] ?? 0) + (_counts['waiting'] ?? 0);
    return Scaffold(
      backgroundColor: StaffColors.canvas,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addLoad'),
        backgroundColor: StaffColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => StaffAddLoadView(service: _svc)));
          if (saved == true) refresh();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add load'),
      ),
      body: Column(children: [
        StaffHeader(
          title: 'Loads',
          subtitle: attention > 0 ? '$attention need${attention == 1 ? 's' : ''} dispatch' : 'Every load by its Load #',
          leadingIcon: Icons.local_shipping_rounded,
          actions: [
            StaffGlassButton(icon: Icons.fire_truck_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StaffFleetView(service: _svc)))),
          ],
          bottom: StaffSearchField(
            controller: _search,
            hint: 'Search Load #, driver, truck, trailer',
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), () {
                _q = v.trim();
                refresh();
              });
            },
          ),
        ),
        SizedBox(
          height: 56,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 12, AppSpacing.md, 8),
            child: Row(children: [
              for (final t in _tabs)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterTab(
                    key: Key('tab_${t.$1.isEmpty ? 'all' : t.$1}'),
                    label: t.$2,
                    count: _count(t.$1),
                    selected: _status == t.$1,
                    alert: (t.$1 == 'transfer' || t.$1 == 'waiting') && _count(t.$1) > 0,
                    onTap: () {
                      setState(() {
                        _status = t.$1;
                        _loading = true;
                      });
                      refresh();
                    },
                  ),
                ),
            ]),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
                  : RefreshIndicator(
                      onRefresh: refresh,
                      child: _loads.isEmpty
                          ? ListView(children: [
                              const SizedBox(height: 80),
                              Center(child: Text('No loads here yet', style: AppText.bodyMd.copyWith(color: StaffColors.textMuted))),
                            ])
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 96),
                              itemCount: _loads.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) => LoadCard(
                                load: _loads[i],
                                names: _names,
                                onTap: () async {
                                  await Navigator.push(context, MaterialPageRoute(builder: (_) => StaffLoadDetailView(loadId: _loads[i].id, service: _svc)));
                                  refresh();
                                },
                              ),
                            ),
                    ),
        ),
      ]),
    );
  }
}

/// Filter pill: name + count bubble. Selected = filled navy with white text.
class _FilterTab extends StatelessWidget {
  const _FilterTab({super.key, required this.label, required this.count, required this.selected, required this.onTap, this.alert = false});
  final String label;
  final int count;
  final bool selected;
  final bool alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : StaffColors.textBody;
    return Material(
      color: selected ? StaffColors.primary : Colors.white,
      shape: StadiumBorder(side: BorderSide(color: selected ? StaffColors.primary : StaffColors.hairline)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 7, 8, 7),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: AppText.labelLg.copyWith(color: fg, fontWeight: selected ? FontWeight.w700 : FontWeight.w600)),
            const SizedBox(width: 6),
            Container(
              constraints: const BoxConstraints(minWidth: 22),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: 0.2) : alert ? StaffColors.danger : StaffColors.canvas,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text('$count', textAlign: TextAlign.center, style: AppText.labelMd.copyWith(color: selected || alert ? Colors.white : StaffColors.textMuted, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }
}
