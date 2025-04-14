// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/controller/truck_controller.dart';
import 'package:uscitylink/services/network_service.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';

import 'package:uscitylink/views/driver/drawer/driver_custom_drawer.dart';
import 'package:uscitylink/views/driver/views/chat_view.dart';
import 'package:uscitylink/views/driver/views/document_view.dart';
import 'package:uscitylink/views/driver/views/driver_pay_view.dart';
import 'package:uscitylink/views/driver/views/driver_profile_view.dart';
import 'package:uscitylink/views/driver/views/training_view.dart';
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
  ChannelController channelController = Get.find<ChannelController>();
  TruckController truckController = Get.put(TruckController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  NetworkService _networkService = Get.find<NetworkService>();
  @override
  void initState() {
    ever(_networkService.connected, (_) {
      print("Network changed: ${_networkService.connected.value}");
      if (_networkService.connected.value) {
        socketService.sendQueueMessage();
      }
    });
    WidgetsBinding.instance.addObserver(this);
    _dashboardController.getDashboard();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (background/foreground)
    if (state == AppLifecycleState.paused) {
      if (socketService.isConnected.value) {
        socketService.socket.disconnect();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!socketService.isConnected.value) {
        socketService.connectSocket();
        Timer(Duration(seconds: 2), () {
          socketService.checkVersion();
          socketService.sendQueueMessage();
        });
      }
      _dashboardController.getDashboard();
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
      key: _scaffoldKey,
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
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              backgroundColor: TColors.primary,
              title: Obx(() {
                if (_networkService.connected.value == false) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        child: Container(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            )),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        "waiting for network",
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.white),
                      )
                    ],
                  );
                }
                return Text(
                  "${"Dashboard"}",
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: Colors.white),
                );
              }),
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
            Container(
              height: 1.0,
              color: Colors.grey.shade300,
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
                    child: Row(
                      children: [
                        StatCard(
                          title: "U S CITYLINK INC",
                          value: 0,
                          icon: Icons.wifi_channel,
                          gradientColors: const [
                            Color(0xFFe5e5e5),
                            Color(0xFFe5e5e5),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: TDeviceUtils.getAppBarHeight() * 0.3,
                  ),
                  SizedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                          onTap: () {
                            Get.to(() => ChatView());
                          },
                          child: StatCard(
                            title: "UNREAD MESSAGE",
                            icon: Icons.message,
                            value: _dashboardController
                                    .dashboard.value.messageCount ??
                                0,
                            gradientColors: [
                              Color(0xFFe5e5e5),
                              Color(0xFFe5e5e5),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Get.to(() => DriverProfileView());
                          },
                          child: StatCard(
                            isDocumentExpired: _dashboardController
                                    .dashboard.value.isDocumentExpired ??
                                false,
                            icon: Icons.person,
                            title: "MY INFORMATION",
                            value: 0,
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
                    height: TDeviceUtils.getAppBarHeight() * 0.3,
                  ),
                  SizedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                          onTap: () {
                            truckController.changeTab(0);
                            Get.to(() => DocumentView(
                                  tabIndexDefault: 0,
                                ));
                            // channelController.setTabIndex(2);
                          },
                          child: StatCard(
                            icon: Icons.fire_truck,
                            title: "TRUCKS",
                            value:
                                _dashboardController.dashboard.value.trucks ??
                                    0,
                            gradientColors: [
                              Color(0xFFe5e5e5),
                              Color(0xFFe5e5e5),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            truckController.changeTab(1);
                            Get.to(() => DocumentView(
                                  tabIndexDefault: 1,
                                ));
                            // channelController.setTabIndex(2);
                          },
                          child: StatCard(
                            title: "TRAILERS",
                            value: 0,
                            icon: Icons.car_crash,
                            gradientColors: [
                              Color(0xFFe5e5e5),
                              Color(0xFFe5e5e5),
                            ], // Gradient colors
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: TDeviceUtils.getAppBarHeight() * 0.3,
                  ),
                  SizedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                          onTap: () {
                            Get.to(
                              () => DriverPayView(),
                            );
                          },
                          child: StatCard(
                            title: "PAY SUMMARY",
                            value:
                                "\$${_dashboardController.dashboard.value.totalAmount}" ??
                                    "\$0",
                            icon: Icons.money,
                            gradientColors: [
                              Color(0xFFe5e5e5),
                              Color(0xFFe5e5e5),
                            ], // Gradient colors
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Get.to(() => TrainingView());
                          },
                          child: StatCard(
                            title: "TRAINING SECTION",
                            value: 0,
                            icon: Icons.class_,
                            gradientColors: [
                              Color(0xFFe5e5e5),
                              Color(0xFFe5e5e5),
                            ], // Gradient colors
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            })),
      ),
      drawer: DriverCustomDrawer(globalKey: _scaffoldKey),
    );
  }
}
