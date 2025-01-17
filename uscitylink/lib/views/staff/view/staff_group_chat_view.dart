import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/drawer_controller.dart';
import 'package:uscitylink/controller/staff/staffgroup_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/staff/drawer/custom_drawer.dart';
import 'package:uscitylink/views/staff/widgets/group_tab.dart';
import 'package:uscitylink/views/staff/widgets/truck_group_tab.dart';

class StaffGroupChatView extends StatefulWidget {
  const StaffGroupChatView({super.key});

  @override
  State<StaffGroupChatView> createState() => _StaffGroupChatViewState();
}

class _StaffGroupChatViewState extends State<StaffGroupChatView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  // Assuming you have a controller to manage unread counts (this will be used in Obx)
  final StaffgroupController _staffGroupController =
      Get.put(StaffgroupController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _staffGroupController.getTrucks();
    // Initializing the tab controller with 2 tabs (Channels & Groups)
    _tabController = TabController(length: 2, vsync: this);

    // Listen to tab changes if needed
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        _staffGroupController.type.value = "group";
        _staffGroupController.getGroups(_staffGroupController.currentPage.value,
            _staffGroupController.searchController.text);
        _staffGroupController.searchController.text = "";
      }
      if (_tabController.index == 0 && !_tabController.indexIsChanging) {
        _staffGroupController.type.value = "truck";
        _staffGroupController.getGroups(_staffGroupController.currentPage.value,
            _staffGroupController.searchController.text);
        _staffGroupController.searchController.text = "";
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (background/foreground)
    if (state == AppLifecycleState.paused) {
      // Add logic for when the app goes to the background
      print("App is in the background");
    } else if (state == AppLifecycleState.resumed) {
      // Add logic for when the app comes back to the foreground
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _staffGroupController.getTrucks();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "kjdld",
        backgroundColor: Colors.amber,
        onPressed: () {
          _showGroupNameDialog(_staffGroupController.type.value);
        },
        label: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
            Obx(() {
              return Text(
                  _staffGroupController.type.value == "group"
                      ? "Add Group"
                      : "ADD TRUCK GROUP",
                  style: TextStyle(color: Colors.white));
            })
          ],
        ),
      ),
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Colors.white,
          ),
          onPressed: () {
            // Open the drawer using the scaffold key
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        backgroundColor: TColors.primaryStaff,
        title: Text("Group Chats",
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Container(
                height: 50.0, // Height for the search bar
                color: TColors.primaryStaff,
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Container(
                      height: 40,
                      child: TextField(
                        controller: _staffGroupController.searchController,
                        onChanged: _staffGroupController.onSearchChanged,
                        decoration: InputDecoration(
                          hintText: "Search ...",
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
              TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade500,
                indicatorColor: Colors.white,
                controller: _tabController,
                tabs: [
                  Tab(
                    text: 'Truck Groups',
                  ),
                  Tab(text: 'Groups'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Channels tab content
          TruckGroupTab(),
          GroupTab(),
          // Groups tab content
        ],
      ),
      drawer: CustomDrawer(),
    );
  }

  // Function to show dialog
  void _showGroupNameDialog(String type) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: TColors.primaryStaff,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  // crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        type == "group" ? 'ADD GROUP' : 'ADD TRUCK GROUP',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () {
                          Get.back();
                        },
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // TextField for entering the group name
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  if (type == "group")
                    TextField(
                      controller: _staffGroupController.groupName,
                      decoration: InputDecoration(
                        hintText: 'Enter group name',
                        helperStyle: TextStyle(color: Colors.grey.shade500),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0)),
                      ),
                    ),
                  if (type == "truck")
                    Obx(
                      () => SizedBox(
                        width: double
                            .infinity, // Makes the DropdownButton take up all available width
                        child: DropdownButton<String>(
                            dropdownColor: Colors.white,
                            value: _staffGroupController
                                    .selectedTruck.value.isEmpty
                                ? null
                                : _staffGroupController.selectedTruck.value,
                            hint: Text('Select Truck Number '),
                            // value: _staffGroupController.selectedTruck.value, // Bind the selected value here
                            onChanged: (String? newValue) {
                              _staffGroupController.selectedTruck.value =
                                  newValue ?? ""; // Update selected truck
                            },
                            items: [
                              ..._staffGroupController.trucks
                                  .map<DropdownMenuItem<String>>((value) {
                                return DropdownMenuItem<String>(
                                  value: value.number,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 10),
                                        child: Text(
                                          "${value.number}",
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall,
                                        ),
                                      ),
                                      Divider()
                                    ],
                                  ),
                                );
                              }).toList(),
                            ]),
                      ),
                    )
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Submit button
                  InkWell(
                    onTap: () {
                      _staffGroupController.addGroup();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.0),
                      decoration: BoxDecoration(
                          color: TColors.primaryStaff,
                          borderRadius: BorderRadius.circular(6)),
                      height: 30,
                      child: Center(
                        child: Text(
                          "submit",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  )
                  // Close button
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
