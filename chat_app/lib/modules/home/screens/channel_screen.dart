import 'package:chat_app/core/extension/date_extension.dart';
import 'package:chat_app/modules/home/controllers/channel_controller.dart';
import 'package:chat_app/modules/home/models/channel_model.dart';
import 'package:chat_app/widgets/container_header.dart';
import 'package:chat_app/widgets/data_table.dart';
import 'package:chat_app/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ChannelScreen extends StatelessWidget {
  ChannelScreen({super.key});
  final ChannelController _channelController = Get.put(ChannelController());

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(6.0),
          bottomRight: Radius.circular(6.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            ContainerHeader(
              title: "Channels",
              subtitle: "Manage and monitor all communication channels",

              showActionButton: true,
              actionButtonText: "New Channel",
              actionButtonIcon: Icons.add,
              onActionPressed: () {},
            ),

            const SizedBox(height: 24),

            // Table Container
            Expanded(
              child: Obx(() {
                final channels = _channelController.channels.value;

                return TableContainer<ChannelModel>(
                  data: channels,
                  config: DataTableConfig<ChannelModel>(
                    title: "All Channels",
                    columns: [
                      DataColumn(
                        label: Text(
                          "CHANNEL",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "CHANNEL ID",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),

                      DataColumn(
                        label: Text(
                          "CREATED",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                    buildRows: (data) => data.asMap().entries.map((entry) {
                      final index = entry.key;
                      final channel = entry.value;
                      final isAlternate = index % 2 == 1;

                      return DataRow(
                        color: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) =>
                              isAlternate ? Colors.grey.shade50 : null,
                        ),
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.public,
                                    size: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      channel.name ?? "-",
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              channel.id ?? "-",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),

                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  channel.createdAt.formatDate(),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    totalItems: channels.length, // Total items in database
                    currentPage: 1,
                    itemsPerPage: 10,
                    onPageChanged: (page) {
                      // Fetch data for this page
                      print("Page changed to: $page");
                    },
                    onExport: () {
                      print("Export data");
                    },
                    onFilter: () {
                      print("Open filter");
                    },
                    onRefresh: () {
                      print("Refresh data");
                    },
                    showHeader: false,
                    showPagination: false,
                    showActions: false,
                    primaryColor: const Color(0xFF4A154B),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
