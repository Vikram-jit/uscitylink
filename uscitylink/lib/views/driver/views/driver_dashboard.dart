// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/driver/widegts/stat_card.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard>
    with WidgetsBindingObserver {
  SocketService socketService = Get.find<SocketService>();
  DashboardController _dashboardController = Get.put(DashboardController());
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    // TODO: implement initState
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (background/foreground)
    if (state == AppLifecycleState.paused) {
      if (socketService.isConnected.value) {
        socketService.socket.disconnect();
      }
      print("App is in the background");
    } else if (state == AppLifecycleState.resumed) {
      if (!socketService.isConnected.value) {
        socketService.connectSocket();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Column(
          children: [
            AppBar(
              backgroundColor:
                  TColors.primary, // Uncomment to use your custom primary color
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
                                    .dashboard.value.channelCount ??
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
                                    .dashboard.value.messageCount ??
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
                        Expanded(
                          child: StatCard(
                            icon: Icons.fire_truck,
                            title: "TRUCKS",
                            value: _dashboardController
                                    .dashboard.value.truckCount ??
                                0,
                            gradientColors: [
                              Color(
                                  0xFFe5e5e5), // Hex color for a shade of green (Active User)
                              Color(0xFFe5e5e5),
                            ], // Gradient colors
                          ),
                        ),
                        Expanded(
                          child: StatCard(
                            title: "TRAILERS",
                            value: _dashboardController
                                    .dashboard.value.trailerCount ??
                                0,
                            icon: Icons.car_crash,
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
                        Expanded(
                          child: StatCard(
                            icon: Icons.group,
                            title: "GROUPS",
                            value: _dashboardController
                                    .dashboard.value.groupCount ??
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
                    height: TDeviceUtils.getAppBarHeight() * 0.30,
                  ),
                  // Display Latest Messages
                  if (_dashboardController
                          .dashboard.value.latestMessage!.length >
                      0)
                    Row(
                      children: [
                        Text(
                          "Channel Message",
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: TColors.darkGrey),
                        )
                      ],
                    ),

                  // List of Latest Messages
                  ListView.builder(
                    shrinkWrap:
                        true, // To make it scrollable inside the SingleChildScrollView
                    physics:
                        NeverScrollableScrollPhysics(), // Disable scrolling in the ListView itself
                    itemCount: _dashboardController
                        .dashboard.value.latestMessage?.length,
                    itemBuilder: (context, index) {
                      var message = _dashboardController
                          .dashboard.value.latestMessage?[index];
                      return InkWell(
                        onTap: () {
                          Get.toNamed(
                            AppRoutes.driverMessage,
                            arguments: {
                              'channelId': message?.channelId,
                              'name': message?.channel?.name,
                            },
                          );
                        },
                        child: Card(
                          color: Colors.white,
                          elevation: 2.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                  height: TDeviceUtils.getAppBarHeight() * 0.2),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '${message?.channel?.name ?? 'No Channel'}',
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                              ),
                              Divider(),
                              SizedBox(
                                  height: TDeviceUtils.getAppBarHeight() * 0.1),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 2.0),
                                child: Text(
                                  '${message?.body ?? 'No Message'}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              Divider(),
                              SizedBox(
                                  height: TDeviceUtils.getAppBarHeight() * 0.1),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 2.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'by:${message?.sender?.username ?? ""}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    Text(
                                      '${Utils.formatUtcDateTime(message?.messageTimestampUtc) ?? ""}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if ((_dashboardController
                              .dashboard.value.latestGroupMessage?.length ??
                          0) >
                      0)
                    SizedBox(height: TDeviceUtils.getAppBarHeight() * 0.2),
                  // Display Latest Group Messages
                  if ((_dashboardController
                              .dashboard.value.latestGroupMessage?.length ??
                          0) >
                      0)
                    Row(
                      children: [
                        Text(
                          "Group Message",
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: TColors.darkGrey),
                        ),
                      ],
                    ),
                  // List of Latest Group Messages

                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _dashboardController
                        .dashboard.value.latestGroupMessage?.length,
                    itemBuilder: (context, index) {
                      var groupMessage = _dashboardController
                          .dashboard.value.latestGroupMessage?[index];
                      return InkWell(
                        onTap: () {
                          Get.toNamed(
                            AppRoutes.driverGroupMessage,
                            arguments: {
                              'channelId': groupMessage?.channelId,
                              'name': groupMessage?.group?.name,
                              'groupId': groupMessage?.group?.id,
                            },
                          );
                        },
                        child: Card(
                          color: Colors.white,
                          elevation: 2.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                  height: TDeviceUtils.getAppBarHeight() * 0.2),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '${groupMessage?.group?.name ?? 'No Group'}',
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                              ),
                              Divider(),
                              SizedBox(
                                  height: TDeviceUtils.getAppBarHeight() * 0.1),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 3.0),
                                child: Text(
                                  '${groupMessage?.body ?? 'No Group Message'}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              Divider(),
                              SizedBox(
                                  height: TDeviceUtils.getAppBarHeight() * 0.1),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 2.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'by:${groupMessage?.sender?.username ?? ""}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    Text(
                                      '${Utils.formatUtcDateTime(groupMessage?.messageTimestampUtc) ?? ""}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            })),
      ),
    );
  }
}
