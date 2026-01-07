import 'package:chat_app/modules/home/desktop/components/driver_table.dart';
import 'package:chat_app/modules/home/desktop/widgets/info_card.dart';
import 'package:chat_app/modules/home/desktop/widgets/stat_chip.dart';
import 'package:chat_app/modules/home/models/overview_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OverviewScreen extends StatelessWidget {
  final int totalMessages;
  final int unreadMessages;
  final int channels;
  final int trucksGroups;
  final int driverCount;

  final List<LastFiveDriver> drivers;

  OverviewScreen({
    super.key,

    this.totalMessages = 0,
    this.unreadMessages = 0,
    this.channels = 0,
    this.trucksGroups = 0,
    this.driverCount = 0,
    required this.drivers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(6.0),
          bottomRight: Radius.circular(6.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              "Overview",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // HORIZONTAL CHIPS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  StatChip(
                    label: "All Messages",
                    count: totalMessages,
                    icon: Icons.mail_outline,
                  ),
                  StatChip(
                    label: "Unread",
                    count: unreadMessages,
                    icon: Icons.mark_email_unread,
                  ),
                  StatChip(label: "Channels", count: channels, icon: Icons.tag),

                  StatChip(
                    label: "Trucks",
                    count: trucksGroups,
                    icon: Icons.local_shipping,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // INFO GRID CARDS
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoCard(
                      totalMessages: totalMessages,
                      unreadMessages: unreadMessages,
                      trucksGroups: trucksGroups,
                      driverCount: driverCount,
                    ),
                    const SizedBox(height: 30),

                    DriverTable(drivers: drivers),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
