import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/drawer_controller.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/constant/image_strings.dart';

class CustomDrawer extends StatefulWidget {
  CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer>
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
                color: TColors.primaryStaff, // Background color
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
            _buildDrawerItem(context, Icons.card_membership, 'Channel Members',
                () => _navigateToHome(context, customDrawerController)),

            _buildDrawerItem(context, Icons.contacts, 'Drivers',
                () => _navigateToDrivers(context)),
            _buildDrawerItem(context, Icons.camera_roll, 'Templates',
                () => _navigateToTemplates(context)),
            _buildDrawerItem(context, Icons.settings, 'Settings', () => {}),

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
      BuildContext context, CustomDrawerController customDrawerController) {
    customDrawerController.closeDrawer();
    Get.toNamed(AppRoutes.staff_channel_member);
    // Add navigation to Home screen
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.pop(context);
    // Add navigation to Profile screen
  }

  void _navigateToDrivers(BuildContext context) {
    customDrawerController.closeDrawer();
    Get.toNamed(AppRoutes.staff_drivers);
    // Add navigation to Settings screen
  }

  void _navigateToTemplates(BuildContext context) {
    customDrawerController.closeDrawer();
    Get.toNamed(AppRoutes.staff_templates);
    // Add navigation to Settings screen
  }

  void _navigateToHelp(BuildContext context) {
    Navigator.pop(context);
    // Add navigation to Help screen
  }

  void _logout(BuildContext context) {
    loginController.logOut();
    // Handle logout logic
  }
}
