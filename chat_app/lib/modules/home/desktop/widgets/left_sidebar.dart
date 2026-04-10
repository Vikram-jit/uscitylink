import 'package:chat_app/core/controller/global_socket_controller.dart';
import 'package:chat_app/core/storage/storage_service.dart';
import 'package:chat_app/modules/home/controllers/sidebar_controller.dart';
import 'package:chat_app/modules/home/desktop/components/sidebar_icon.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import 'package:web/web.dart' as web; // Modern 2026 standard for Web/Wasm

class LeftSidebar extends StatelessWidget {
  LeftSidebar({super.key});
  final sidebarController = Get.put(SidebarController());

  bool isRouteActive(String route) => Get.currentRoute == route;

  void _goHome() {
    Get.find<HomeController>().closeDirectMessage(userId: '', userName: '');
    Get.toNamed(AppRoutes.home);
  }

  void _goDriverChat() {
    Get.find<HomeController>().closeDirectMessage(userId: '', userName: '');
    Get.toNamed(AppRoutes.driverChat);
  }

  void _goTruckChat() {
    Get.find<HomeController>().closeDirectMessage(userId: '', userName: '');
    Get.toNamed(AppRoutes.truckChat);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.06,
      color: AppColors.primary,
      // ✅ Use a Column with a fixed top section, scrollable middle, and fixed bottom
      child: Column(
        children: [
          // ── Logo / Avatar ──
          const SizedBox(height: Space.md),
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              'U',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: AppColors.bg,
              ),
            ),
          ),
          const SizedBox(height: Space.lg),

          // ✅ Nav icons — scrollable so they never overflow
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SidebarIcon(
                    Icons.home_filled,
                    tooltip: 'Home',
                    onTap: _goHome,
                    active: isRouteActive(AppRoutes.home),
                  ),
                  SidebarIcon(
                    Icons.message,
                    tooltip: 'Messages',
                    onTap: _goDriverChat,
                    active: isRouteActive(AppRoutes.driverChat),
                  ),
                  SidebarIcon(
                    Icons.fire_truck,
                    tooltip: 'Truck Groups',
                    onTap: _goTruckChat,
                    active: isRouteActive(AppRoutes.truckChat),
                  ),
                  SidebarIcon(
                    Icons.broadcast_on_home,
                    tooltip: 'Broadcast Messages',
                    onTap: () => Get.toNamed(AppRoutes.broadcastMessages),
                    active: isRouteActive(AppRoutes.broadcastMessages),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom: profile ──
          SidebarIcon(
            Icons.person,
            tooltip: 'Profile',
            menuItems: [
              PopupMenuItem(
                enabled: false,
                child: SizedBox(
                  width: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Username',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Online',
                        style: TextStyle(color: Colors.green, fontSize: 13),
                      ),
                      const Divider(),
                    ],
                  ),
                ),
              ),
              const PopupMenuItem(child: Text('My Profile')),
              const PopupMenuItem(child: Text('Account Settings')),
              const PopupMenuDivider(),
              PopupMenuItem(
                onTap: () async {
                  if (Get.isRegistered<GlobalSocketController>()) {
                    Get.find<GlobalSocketController>().onClose();
                  }

                  // 2. Clear persisted storage
                  await StorageService.clear();

                  // 3. Delete ALL GetX controllers + bindings
                  //    force:true skips the permanent flag
                  Get.deleteAll(force: true);

                  // 4. Navigate — all previous routes are cleared
                  Get.offAllNamed(AppRoutes.login);
                  web.window.location.reload(); // 👈 reload page
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
        ],
      ),
    );
  }
}
