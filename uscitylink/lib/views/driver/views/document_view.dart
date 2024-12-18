import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/truck_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/utils/constant/colors.dart';

class DocumentView extends StatefulWidget {
  DocumentView({super.key});

  @override
  State<DocumentView> createState() => _DocumentViewState();
}

class _DocumentViewState extends State<DocumentView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final TruckController _controller = Get.put(TruckController());

  late Timer _debounce;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _debounce = Timer(Duration(seconds: 0), () {});
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    // Listen for tab changes to refetch channels when the Channels tab is selected
    _tabController.addListener(() {
      if (_tabController.index == 0 && !_tabController.indexIsChanging) {
        _controller.currentPage.value = 1;
        _controller.totalPages.value = 1;
        _controller.trucks.value = [];
        _controller.fetchTrucks(page: 1, type: "trucks");
      }
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        _controller.currentPage.value = 1;
        _controller.totalPages.value = 1;
        _controller.trucks.value = [];
        _controller.fetchTrucks(page: 1, type: "trailers");
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This will run after the widget tree is built, avoiding the error
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce.isActive) {
      _debounce.cancel(); // Cancel previous debounce timer
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _controller.trucks.value = [];
      // Call API with the new search query
      _controller.fetchTrucks(
          page: 1,
          type: _tabController.index == 0 ? "trucks" : "trailers",
          search: query);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce.cancel(); // Cancel debounce timer when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(
            180), // Increased height for AppBar and search
        child: Column(
          children: [
            AppBar(
              backgroundColor: TColors.primary,
              title: Text(
                "Vehicles",
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    // Logic for triggering the search field can go here
                    print("Search button pressed");
                  },
                ),
              ],
            ),
            Container(
              height: 50.0, // Height for the search bar
              color: TColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Container(
                    height: 40,
                    child: TextField(
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: "Search vehicles...",
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.all(0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                  color: Color(0xFFf0f0f2),
                  borderRadius: BorderRadius.circular(10)),
              margin: EdgeInsets.all(10),
              height: 50,
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: TColors.white,
                unselectedLabelColor: Colors.grey,
                indicator: BoxDecoration(
                    color: TColors.primary,
                    borderRadius: BorderRadius.circular(10)),
                indicatorWeight: 4.0,
                controller: _tabController,
                tabs: const [
                  Tab(text: "Trucks"),
                  Tab(text: "Trailers"),
                ],
              ),
            )
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          VehicleList(controller: _controller, type: "truck"),
          VehicleList(
            controller: _controller,
            type: "trailer",
          ),
        ],
      ),
    );
  }
}

class VehicleList extends StatelessWidget {
  final TruckController _controller;
  final String type; // New parameter to control the type

  const VehicleList({
    super.key,
    required TruckController controller,
    required this.type, // Initialize the type here
  }) : _controller = controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Show loading indicator if data is being fetched and trucks list is empty
      if (_controller.isLoading.value && _controller.trucks.isEmpty) {
        return Center(child: CircularProgressIndicator());
      }

      return ListView.builder(
        controller: ScrollController()
          ..addListener(() {
            // Don't load more if data is already loading
            if (_controller.isLoading.value) return;

            // Check if there are more pages and trigger data fetch if necessary
            if (_controller.currentPage.value < _controller.totalPages.value) {
              if (_controller.trucks.isNotEmpty &&
                  _controller.trucks.last ==
                      _controller.trucks[_controller.trucks.length - 1]) {
                _controller.fetchTrucks(
                    page: _controller.currentPage.value + 1);
              }
            }
          }),
        itemCount:
            _controller.trucks.length + 1, // +1 for the loading indicator
        itemBuilder: (context, index) {
          // If the index is the last item, show the loading indicator (pagination)
          if (index == _controller.trucks.length) {
            if (_controller.currentPage.value < _controller.totalPages.value) {
              return Center(child: CircularProgressIndicator());
            } else {
              return SizedBox(); // No more data to load
            }
          }

          final truck = _controller.trucks[index];
          return InkWell(
            onTap: () {
              Get.toNamed(
                AppRoutes.vehicleDetails,
                arguments: {'id': truck.id, 'type': type},
              );
            },
            child: Card(
              color: Colors.white,
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              margin: EdgeInsets.symmetric(vertical: 5.0),
              child: ListTile(
                leading: Icon(
                    type == "truck" ? Icons.local_shipping : Icons.rv_hookup),
                title: Text('${truck.number}'),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                trailing: Icon(Icons.arrow_right),
              ),
            ),
          );
        },
      );
    });
  }
}
