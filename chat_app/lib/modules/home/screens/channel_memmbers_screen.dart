import 'package:chat_app/modules/home/controllers/channel_controller.dart';
import 'package:chat_app/modules/home/models/channel_memmber_model.dart';

import 'package:chat_app/widgets/container_header.dart';
import 'package:chat_app/widgets/data_table.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ChannelMemmbersScreen extends StatelessWidget {
  ChannelMemmbersScreen({super.key});
  final ChannelController _driverController = Get.find<ChannelController>();

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
              title: "Channel Memmbers",
              subtitle: "Manage and monitor all channel memmbers",

              showActionButton: true,
              actionButtonText: "New Memmber",
              actionButtonIcon: Icons.add,
              onActionPressed: () {},
            ),

            const SizedBox(height: 24),

            // Table Container
            Expanded(
              child: FutureBuilder(
                future: _driverController.getChannelMembers(page: 1),
                builder: (context, snapshot) {
                  if (!snapshot.hasData && _driverController.isLoading.isTrue) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  return Obx(() {
                    final usres = _driverController.channelMembers.value;

                    return TableContainer<UserChannels>(
                      data: usres,

                      config: DataTableConfig<UserChannels>(
                        isScrollable: true,
                        title: "Drivers",
                        columns: [
                          DataColumn(
                            label: Text(
                              "NAME",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "DRIVER NUMBER",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),

                          DataColumn(
                            label: Text(
                              "EMAIL",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "PHONE NUMBER",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "STATUS",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "IS ONLINE",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "ACTION",
                              style: GoogleFonts.poppins(
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
                          final driver = entry.value;
                          final isAlternate = index % 2 == 1;

                          return DataRow(
                            color: MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) =>
                                  isAlternate ? Colors.grey.shade50 : null,
                            ),
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    driver.userProfile?.username ?? "-",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    driver.userProfile?.user?.driverNumber ??
                                        "-",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ),

                              DataCell(
                                Text(
                                  driver.userProfile?.user?.email ?? "-",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  driver.userProfile?.user?.phoneNumber ?? "-",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  driver?.status ?? "-",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 10,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    child: CircleAvatar(
                                      backgroundColor:
                                          driver?.userProfile?.isOnline ?? false
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                              ),

                              DataCell(
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Tooltip(
                                      message: "DEACTIVATE",
                                      textStyle: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                      child: IconButton(
                                        onPressed: () {},
                                        icon: Icon(Icons.edit),
                                      ),
                                    ),
                                    Tooltip(
                                      message: "REMOVE",
                                      textStyle: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                      child: IconButton(
                                        onPressed: () {},
                                        icon: Icon(Icons.delete),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        totalItems: _driverController
                            .totalItems, // Total items in database
                        currentPage: _driverController.currentPage.value,
                        itemsPerPage: _driverController.itemsPerPage,
                        onPageChanged: (page) {
                          _driverController.currentPage.value = page;
                          _driverController.getChannelMembers(page: page);
                        },

                        showHeader: false,
                        showPagination: true,
                        showActions: true,
                        primaryColor: const Color(0xFF4A154B),
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
