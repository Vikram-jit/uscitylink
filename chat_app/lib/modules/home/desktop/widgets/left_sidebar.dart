import 'package:chat_app/core/storage/storage_service.dart';
import 'package:chat_app/modules/home/controllers/sidebar_controller.dart';
import 'package:chat_app/modules/home/desktop/components/sidebar_icon.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';

class LeftSidebar extends StatelessWidget {
  LeftSidebar({super.key});
  final sidebarController = Get.put(SidebarController());

  @override
  Widget build(BuildContext context) {
    String currentPath = Get.currentRoute;

    return Container(
      width: 80,
      color: AppColors.primary,
      child: Column(
        children: [
          Container(
            height: 50, // Slightly larger
            width: 50,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(10), // Smoother radius
            ),
            alignment: Alignment.center,
            child: Text(
              "U",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: AppColors.bg,
              ),
            ),
          ),

          const SizedBox(height: Space.xl),
          SidebarIcon(Icons.home_filled, tooltip: "Home", active: true),
          SidebarIcon(Icons.message, tooltip: "Messages"),
          SidebarIcon(Icons.fire_truck, tooltip: "Truck Groups"),
          SidebarIcon(Icons.groups, tooltip: "Groups"),

          const Spacer(),
          SidebarIcon(
            Icons.person,
            tooltip: "Profile",
            menuItems: [
              PopupMenuItem(
                enabled: false, // prevent click
                child: SizedBox(
                  width: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "username",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Online",
                        style: TextStyle(color: Colors.green, fontSize: 13),
                      ),
                      Divider(),
                    ],
                  ),
                ),
              ),
              PopupMenuItem(child: Text("My Profile")),
              PopupMenuItem(child: Text("Account Settings")),
              PopupMenuDivider(),
              PopupMenuItem(
                child: Text("Logout", style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await StorageService.clear();
                  Get.offAndToNamed(AppRoutes.login);
                },
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
        ],
      ),
    );
  }
}
