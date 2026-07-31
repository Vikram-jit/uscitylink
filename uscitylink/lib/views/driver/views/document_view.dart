import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/controller/truck_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/driver/drawer/driver_custom_drawer.dart';

// This card is taller than the single-row search cards on other screens
// (it stacks a search field AND a tab bar), so it needs its own fixed
// height and a bigger overflow value — otherwise it rides up far enough
// to cover the header's back button and title.
const double _kSearchCardHeight = 132;
const double _kSearchCardOverlap = 24;
const double _kSearchCardOverflow = _kSearchCardHeight - _kSearchCardOverlap;

class DocumentView extends StatefulWidget {
  int tabIndexDefault;
  DocumentView({super.key, this.tabIndexDefault = 0});

  @override
  State<DocumentView> createState() => _DocumentViewState();
}

class _DocumentViewState extends State<DocumentView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TruckController _controller = Get.put(TruckController());
  DashboardController _dashboardController = Get.find<DashboardController>();
  late Timer _debounce;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _debounce = Timer(Duration(seconds: 0), () {});
    super.initState();

    _controller.tabController.addListener(() {
      if (_controller.tabController.index == 0 &&
          !_controller.tabController.indexIsChanging) {
        _controller.currentPage.value = 1;
        _controller.totalPages.value = 1;
        _controller.trucks.value = [];
        _controller.fetchTrucks(page: 1, type: "trucks");
        _controller.initialIndex.value = 0;
      }
      if (_controller.tabController.index == 1 &&
          !_controller.tabController.indexIsChanging) {
        _controller.currentPage.value = 1;
        _controller.totalPages.value = 1;
        _controller.trucks.value = [];
        _controller.fetchTrucks(page: 1, type: "trailers");
        _controller.initialIndex.value = 1;
      }
    });

    // Don't rely on the caller having already primed the tab/fetch before
    // navigating here — make sure this screen always loads its own data
    // for the tab it was opened on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.changeTab(widget.tabIndexDefault);
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce.isActive) {
      _debounce.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _controller.trucks.value = [];
      _controller.fetchTrucks(
          page: 1,
          type: _controller.tabController.index == 0 ? "trucks" : "trailers",
          search: query);
    });
  }

  @override
  void dispose() {
    _debounce.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F6FA),
        body: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    _Header(
                      onBack: () {
                        _dashboardController.getDashboard();
                        Get.back();
                      },
                    ),
                    const SizedBox(height: _kSearchCardOverflow),
                  ],
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 0,
                  child: SizedBox(
                    height: _kSearchCardHeight,
                    child: _SearchTabsCard(
                      controller: _controller,
                      onSearchChanged: _onSearchChanged,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: _kSearchCardOverflow - 60),
            Expanded(
              child: TabBarView(
                controller: _controller.tabController,
                children: [
                  VehicleList(controller: _controller, type: "truck"),
                  VehicleList(controller: _controller, type: "trailer"),
                ],
              ),
            ),
          ],
        ),
        drawer: DriverCustomDrawer(globalKey: _scaffoldKey),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(12, topInset + 12, 20, 46),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [TColors.navyHeader, TColors.navyHeaderDeep],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(top: -50, right: -30, child: _orb(140, 0.06)),
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: Colors.white),
                ),
                const Expanded(
                  child: Text(
                    'Vehicles',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SearchTabsCard extends StatelessWidget {
  final TruckController controller;
  final ValueChanged<String> onSearchChanged;

  const _SearchTabsCard(
      {required this.controller, required this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Obx(() => TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText:
                      "Search ${controller.initialIndex.value == 0 ? "trucks" : "trailers"}...",
                  hintStyle:
                      TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: Colors.grey.shade500, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              )),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(12),
            ),
            height: 44,
            child: TabBar(
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              indicator: BoxDecoration(
                color: TColors.navyHeader,
                borderRadius: BorderRadius.circular(12),
              ),
              controller: controller.tabController,
              tabs: const [
                Tab(text: "Trucks"),
                Tab(text: "Trailers"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VehicleList extends StatelessWidget {
  final TruckController _controller;
  final String type;

  const VehicleList({
    super.key,
    required TruckController controller,
    required this.type,
  }) : _controller = controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_controller.isLoading.value && _controller.trucks.isEmpty) {
        return const Center(
            child: CircularProgressIndicator(color: TColors.navyHeader));
      }
      if (_controller.trucks.isEmpty) {
        return _EmptyState(
          message: type == "truck" ? "No trucks found." : "No trailers found.",
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        controller: ScrollController()
          ..addListener(() {
            if (_controller.isLoading.value) return;
          }),
        itemCount: _controller.trucks.length + 1,
        itemBuilder: (context, index) {
          if (index == _controller.trucks.length) {
            if (_controller.currentPage.value < _controller.totalPages.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                    child:
                        CircularProgressIndicator(color: TColors.navyHeader)),
              );
            }
            return const SizedBox();
          }

          final truck = _controller.trucks[index];
          final color = type == "truck"
              ? const Color(0xFF2E5BFF)
              : const Color(0xFF0D9488);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Get.toNamed(
                  AppRoutes.vehicleDetails,
                  arguments: {'id': truck.id, 'type': type},
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        type == "truck"
                            ? Icons.local_shipping_rounded
                            : Icons.rv_hookup_rounded,
                        color: color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${truck.number}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to view details',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.grey.shade400, size: 20),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 44, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
