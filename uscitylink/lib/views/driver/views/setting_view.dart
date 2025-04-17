import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/hive_controller.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/views/driver/drawer/driver_custom_drawer.dart';
import 'package:uscitylink/views/widgets/custom_button.dart';

class SettingView extends StatefulWidget {
  const SettingView({super.key});

  @override
  _SettingViewState createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> with WidgetsBindingObserver {
  final loginController = Get.put(LoginController());
  SocketService socketService = Get.find<SocketService>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  HiveController _hiveController = Get.find<HiveController>();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    // TODO: implement initState
    super.initState();
    loginController.getProfile();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (background/foreground)
    if (state == AppLifecycleState.paused) {
      if (socketService.isConnected.value) {
        //if (_hiveController.isProcessing.value == false) {
        socketService.socket.disconnect();
//}
      }
      print("App is in the background");
    } else if (state == AppLifecycleState.resumed) {
      if (!socketService.isConnected.value) {
        socketService.connectSocket();
        Timer(Duration(seconds: 2), () {
          socketService.checkVersion();
        });
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
      key: _scaffoldKey,
      backgroundColor: TColors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Column(
          children: [
            AppBar(
              // leading: IconButton(
              //   icon: Icon(
              //     Icons.menu,
              //     color: Colors.white,
              //   ),
              //   onPressed: () {
              //     // Open the drawer using the scaffold key
              //     _scaffoldKey.currentState?.openDrawer();
              //   },
              // ),
              backgroundColor: TColors.primary,
              title: Text(
                "Settings",
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
            ),
            Container(
              height: 1.0,
              color: Colors.grey.shade300,
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        children: [
          // Profile Section
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  backgroundColor: TColors.grey,
                  radius: 60,
                  child: Text("A"), // Placeholder for profile image
                ),
                SizedBox(height: TDeviceUtils.getScreenHeight() * 0.01),
                Obx(() {
                  return Text(
                      "${loginController.userProfile.value != null ? loginController.userProfile.value.username : ""}",
                      style: Theme.of(context).textTheme.headlineLarge);
                }),
              ],
            ),
          ),
          SizedBox(height: TDeviceUtils.getScreenHeight() * 0.03),

          // Account and Settings Options List
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            elevation: 0, // Adding some elevation for a card-like effect
            child: Column(
              children: [
                // First ListTile for Account
                ListTile(
                  minTileHeight: 20,
                  leading: const Icon(Icons.account_circle, size: 18),
                  title: Text('Account',
                      style: Theme.of(context).textTheme.labelLarge),
                  onTap: () {
                    Get.toNamed(AppRoutes.driverAccount);
                  },
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                ),
                Divider(thickness: 1, color: Colors.grey.shade300),

                // Second ListTile for Change Password
                ListTile(
                  minTileHeight: 20,
                  leading: const Icon(Icons.password, size: 18),
                  title: Text('Change Password',
                      style: Theme.of(context).textTheme.labelLarge),
                  onTap: () {
                    Get.toNamed(AppRoutes.driverChangePassword);
                  },
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                ),
                Divider(thickness: 1, color: Colors.grey.shade300),

                // Third ListTile for Pin Messages
                ListTile(
                  minTileHeight: 20,
                  leading: const Icon(Icons.message, size: 18),
                  title: Text('Pin Messages',
                      style: Theme.of(context).textTheme.labelLarge),
                  onTap: () {
                    print("Pin Messages tapped");
                  },
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                ),
                Divider(thickness: 1, color: Colors.grey.shade300),
              ],
            ),
          ),
          SizedBox(height: TDeviceUtils.getScreenHeight() * 0.20),

          // Log out Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CustomButton(
                label: "Log out",
                onPressed: () {
                  loginController.logOut();
                }),
          ),
        ],
      ),
      //drawer: DriverCustomDrawer(globalKey: _scaffoldKey),
    );
  }
}
