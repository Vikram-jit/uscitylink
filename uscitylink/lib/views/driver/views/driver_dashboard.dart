// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/controller/hive_controller.dart';
import 'package:uscitylink/controller/truck_controller.dart';
import 'package:uscitylink/services/network_service.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';

import 'package:uscitylink/views/driver/views/chat_view.dart';
import 'package:uscitylink/views/driver/views/daily_inspection/add_inspection_screen.dart';
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
  HiveController _hiveController = Get.find<HiveController>();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _dashboardController.getDashboard();
    if (socketService.isConnected.value) {
      if (_hiveController.isProcessing.value == false) {
        // socketService.socket.disconnect();
      }
    }
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (background/foreground)
    if (state == AppLifecycleState.paused) {
      if (socketService.isConnected.value) {
        // if (_hiveController.isProcessing.value == false) {
        socketService.socket.disconnect();
        //}
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!socketService.isConnected.value) {
        socketService.connectSocket();
        Timer(Duration(seconds: 2), () {
          socketService.checkVersion();
          //socketService.sendQueueMessage();
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
      backgroundColor: Colors.grey[50],
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Column(
          children: [
            AppBar(
              elevation: 0,
              centerTitle: true,
              backgroundColor: TColors.white,
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
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                    letterSpacing: -0.3,
                  ),
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
            // Container(
            //   height: 1.0,
            //   color: Colors.grey.shade300,
            // ),
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
                            Color(0xFFffffff),
                            Color(0xFFffffff),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: TDeviceUtils.getScreenHeight() * 0.01,
                  ),
                  if (_dashboardController.dashboard.value.isInspectionDone ??
                      false)
                    SizedBox(
                      height: TDeviceUtils.getScreenHeight() *
                          0.05, // Explicit height
                      child: InkWell(
                        onTap: () {
                          Get.to(() => AddInspectionScreen());
                          // Your tap logic here
                        },
                        borderRadius:
                            BorderRadius.circular(8), // Ripple effect boundary
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red, // Background color
                            borderRadius: BorderRadius.circular(
                                8), // Matching border radius
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16), // Add horizontal padding
                          alignment: Alignment.center, // Center the content
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8), // Space between icon and text
                              Text(
                                "Daily Inspection",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    height: TDeviceUtils.getScreenHeight() * 0.2,
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
                              Color(0xFFffffff),
                              Color(0xFFffffff),
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
                              Color(0xFFffffff),
                              Color(0xFFffffff),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                              Color(0xFFffffff),
                              Color(0xFFffffff),
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
                              Color(0xFFffffff),
                              Color(0xFFffffff),
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
                              Color(0xFFffffff),
                              Color(0xFFffffff),
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
                              Color(0xFFffffff),
                              Color(0xFFffffff),
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
    );
  }
}
