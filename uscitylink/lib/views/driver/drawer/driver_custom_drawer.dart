import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/drawer_controller.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/constant/image_strings.dart';
import 'package:uscitylink/views/driver/views/driver_pay_view.dart';

class DriverCustomDrawer extends StatefulWidget {
  final GlobalKey<ScaffoldState> globalKey;

  DriverCustomDrawer({super.key, required this.globalKey});

  @override
  State<DriverCustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<DriverCustomDrawer>
    with WidgetsBindingObserver {
  final loginController = Get.put(LoginController());
  final customDrawerController = Get.find<CustomDrawerController>();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    // TODO: implement initState
    super.initState();
    loginController.getProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // Adding shape for border
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(0),
        ),
      ),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header section (Profile Information)
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: TColors.primary, // Background color
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                ),
              ),
              accountName: Obx(() {
                return Container(
                  margin: EdgeInsets.only(top: 8),
                  child: Text(
                    "${loginController.userProfile.value != null ? loginController.userProfile?.value?.username : ""}",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                );
              }),
              accountEmail: Obx(() {
                return Text(
                  "${loginController.userProfile.value != null ? loginController.userProfile?.value?.user?.email : ""}",
                  style: TextStyle(color: Colors.white),
                );
              }),
              currentAccountPicture: CircleAvatar(
                backgroundImage: AssetImage(TImages.logoWhite),
                radius: 40,
              ),
            ),

            // List of Drawer Items
            _buildDrawerItem(context, Icons.payment, 'Pays', () {
              _navigateToHome(context, widget.globalKey);
            }),

            Divider(color: Colors.grey),
            ListTile(
              leading: Icon(Icons.logout, color: TColors.primaryStaff),
              title: Text('Logout'),
              onTap: () {
                loginController.logOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Reusable method to build Drawer items
  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String title, Function() onTap) {
    return ListTile(
      leading: Icon(icon, color: TColors.primaryStaff),
      title: Text(title),
      onTap: onTap,
    );
  }

  // Navigation methods
  void _navigateToHome(
      BuildContext context, GlobalKey<ScaffoldState> globalKey) {
    globalKey.currentState?.closeDrawer();
    Get.to(() => DriverPayView());
    // Add navigation to Home screen
  }
}
