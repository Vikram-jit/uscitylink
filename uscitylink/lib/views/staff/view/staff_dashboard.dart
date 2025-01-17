import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/controller/drawer_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/views/driver/widegts/stat_card.dart';
import 'package:uscitylink/views/staff/drawer/custom_drawer.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard>
    with WidgetsBindingObserver {
  final CustomDrawerController _customDrawerController =
      Get.put(CustomDrawerController());
  DashboardController _dashboardController = Get.find<DashboardController>();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _dashboardController.getStaffDashboard();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(state);
    // Handle app lifecycle changes (background/foreground)
    if (state == AppLifecycleState.paused) {
      // App is in the background

      print("App is in the background");
      // socketService.disconnect(); // Disconnect the socket when the app goes to background
    } else if (state == AppLifecycleState.resumed) {
      // App is in the foreground

      print("App is in the foreground");
      // socketService
      //     .connectSocket(); // Reconnect the socket when the app comes back to foreground
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _customDrawerController.scaffoldKey,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              AppBar(
                leading: IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    // Open the drawer using the scaffold key
                    _customDrawerController.openDrawer();
                  },
                ),

                backgroundColor: TColors
                    .primaryStaff, // Uncomment to use your custom primary color
                title: Text(
                  "Dashboard",
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: Colors.white),
                ),
                actions: const [
                  Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.end, // Align icons to the right
                      children: [
                        // Center(
                        //   child: Icon(
                        //     Icons.notification_add,
                        //     color: Colors.white,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
              // Add a bottom line under the AppBar using a Container
              Container(
                height: 1.0, // Thickness of the line
                color: Colors.grey.shade300, // Color of the line (light grey)
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Obx(() {
                if (_dashboardController.loading.value) {
                  return Center(child: CircularProgressIndicator());
                }
                return Column(
                  children: [
                    SizedBox(
                      height: TDeviceUtils.getAppBarHeight() * 0.3,
                    ),
                    SizedBox(
                      height: TDeviceUtils.getAppBarHeight() * 1.2,
                      child: Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: "TOTAL CHANNEL",
                              value: _dashboardController
                                      .dashboardStaff.value.channelCount ??
                                  0,
                              icon: Icons.wifi_channel,
                              gradientColors: const [
                                Color(
                                    0xFFe5e5e5), // Hex color for a shade of green (Active User)
                                Color(0xFFe5e5e5),
                              ], // Gradient colors
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: "TOTAL MESSAGE",
                              icon: Icons.message,
                              value: _dashboardController
                                      .dashboardStaff.value.messageCount ??
                                  0,
                              gradientColors: [
                                Color(
                                    0xFFe5e5e5), // Hex color for a shade of green (Active User)
                                Color(0xFFe5e5e5),
                              ], // Gradient colors
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: TDeviceUtils.getAppBarHeight() * 0.1,
                    ),
                    SizedBox(
                      height: TDeviceUtils.getAppBarHeight() * 1.2,
                      child: Row(
                        children: [
                          StatCard(
                            icon: Icons.message,
                            title: "UNREAD MESSAGES",
                            value: _dashboardController
                                    .dashboardStaff.value.userUnMessage ??
                                0,
                            gradientColors: [
                              Color(
                                  0xFFe5e5e5), // Hex color for a shade of green (Active User)
                              Color(0xFFe5e5e5),
                            ], // Gradient colors
                          ),
                          Expanded(
                            flex: 1,
                            child: StatCard(
                              icon: Icons.group,
                              title: "GROUPS",
                              value: _dashboardController
                                      .dashboardStaff.value.groupCount ??
                                  0,
                              gradientColors: [
                                Color(0xFFe5e5e5),
                                Color(0xFFe5e5e5),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: TDeviceUtils.getAppBarHeight() * 0.1,
                    ),
                    SizedBox(
                      height: TDeviceUtils.getAppBarHeight() * 0.30,
                    ),
                  ],
                );
              })),
        ),
        drawer: CustomDrawer());
  }
}
