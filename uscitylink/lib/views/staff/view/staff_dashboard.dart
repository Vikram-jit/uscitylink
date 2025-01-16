import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/drawer_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/staff/drawer/custom_drawer.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final CustomDrawerController _customDrawerController =
      Get.put(CustomDrawerController());

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
        body: CustomScrollView(),
        drawer: CustomDrawer());
  }
}
