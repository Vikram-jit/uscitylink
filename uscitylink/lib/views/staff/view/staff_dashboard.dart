import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/controller/drawer_controller.dart';
import 'package:uscitylink/controller/staff/staffview_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/views/driver/widegts/stat_card.dart';
import 'package:uscitylink/views/staff/drawer/custom_drawer.dart';
import 'package:uscitylink/views/staff/view/staff_channel_members_view.dart';
import 'package:uscitylink/views/staff/view/staff_templates_view.dart';
import 'package:uscitylink/views/staff/view/staff_trainings_view.dart';

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
  StaffviewController _staffviewController = Get.find<StaffviewController>();
  SocketService socketService = Get.find<SocketService>();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _dashboardController.getStaffDashboard();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (background/foreground)
    if (state == AppLifecycleState.paused) {
      // App is in the background

      print("App is in the background");
      // socketService.disconnect(); // Disconnect the socket when the app goes to background
    } else if (state == AppLifecycleState.resumed) {
      // App is in the foreground

      Timer(Duration(seconds: 2), () {
        socketService.checkVersion();
      });

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
                              title: "U S CITYLINK INC",
                              value: 0,
                              icon: Icons.wifi_channel,
                              gradientColors: const [
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
                      height: TDeviceUtils.getAppBarHeight() * 0.2,
                    ),
                    SizedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          InkWell(
                            onTap: () {
                              _staffviewController.currentIndex.value = 1;
                            },
                            child: StatCard(
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
                          ),
                          InkWell(
                            onTap: () {
                              Get.to(() => StaffChannelMembersView());
                            },
                            child: StatCard(
                              icon: Icons.group,
                              title: "TOTAL DRIVERS",
                              value: _dashboardController
                                      .dashboardStaff.value.driverCount ??
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
                      height: TDeviceUtils.getAppBarHeight() * 0.2,
                    ),
                    SizedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          InkWell(
                            onTap: () {
                              Get.to(() => StaffTemplatesView());
                            },
                            child: StatCard(
                              icon: Icons.message,
                              title: "TOTAL TEMPLATES",
                              value: _dashboardController
                                      .dashboardStaff.value.templateCount ??
                                  0,
                              gradientColors: [
                                Color(
                                    0xFFe5e5e5), // Hex color for a shade of green (Active User)
                                Color(0xFFe5e5e5),
                              ], // Gradient colors
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Get.to(() => StaffTrainingsView());
                            },
                            child: StatCard(
                              icon: Icons.group,
                              title: "TRAINING VIDEOS",
                              value: _dashboardController
                                      .dashboardStaff.value.trainingCount ??
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
                      height: TDeviceUtils.getAppBarHeight() * 0.2,
                    ),
                    SizedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          InkWell(
                            onTap: () {
                              _staffviewController.currentIndex.value = 2;
                            },
                            child: StatCard(
                              icon: Icons.message,
                              title: "TOTAL TRUCK GROUPS",
                              value: _dashboardController
                                      .dashboardStaff.value.truckGroupCount ??
                                  0,
                              gradientColors: [
                                Color(
                                    0xFFe5e5e5), // Hex color for a shade of green (Active User)
                                Color(0xFFe5e5e5),
                              ], // Gradient colors
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Get.toNamed(
                                AppRoutes.staffGroupMessage,
                                arguments: {
                                  'channelId':
                                      "1cb8a91e-921f-40fc-873f-af30d2ee3da0",
                                  'name': "Staff",
                                  'groupId':
                                      "1fe8cc7c-482f-4cdc-8d22-8ba0bb3b3578"
                                },
                              );
                            },
                            child: StatCard(
                              icon: Icons.message,
                              title: "STAFF GROUP",
                              value: _dashboardController
                                      .dashboardStaff.value.staffGroupCount ??
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
                      height: TDeviceUtils.getAppBarHeight() * 0.30,
                    ),
                  ],
                );
              })),
        ),
        drawer: CustomDrawer());
  }
}
