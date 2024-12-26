import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/staff/drawer/custom_drawer.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
