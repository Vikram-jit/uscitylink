import 'package:chat_app/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoCard extends StatelessWidget {
  final int totalMessages;
  final int unreadMessages;
  final int driverCount;
  final int trucksGroups;
  const InfoCard({
    super.key,
    this.totalMessages = 0,
    this.unreadMessages = 0,
    this.driverCount = 0,
    this.trucksGroups = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        // Adding the top and bottom borders as seen in the screenshot
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 1. Finished Item
          Expanded(
            child: _buildStatItem(
              icon: Icons.message,
              label: "Total Messages",
              value: totalMessages.toString(),
            ),
          ),

          _buildDivider(),

          Expanded(
            child: _buildStatItem(
              icon: Icons.unarchive,
              label: "Unread Messages",
              value: unreadMessages.toString(),
            ),
          ),

          _buildDivider(),

          Expanded(
            child: _buildStatItem(
              icon: Icons.fire_truck,
              label: "Truck Groups",
              value: trucksGroups.toString(),
            ),
          ),
          _buildDivider(),

          Expanded(
            child: _buildStatItem(
              icon: Icons.drive_eta,
              label: "Drivers",
              value: driverCount.toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
        const SizedBox(width: 12),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // --- Helper Widget for the vertical line ---
  Widget _buildDivider() {
    return Container(
      height: 40, // Height of the divider
      width: 1,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
