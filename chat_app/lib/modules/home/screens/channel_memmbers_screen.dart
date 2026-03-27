import 'package:chat_app/modules/home/controllers/channel_controller.dart';
import 'package:chat_app/modules/home/models/channel_memmber_model.dart';
import 'package:chat_app/modules/home/widgets/add_channel_member_dialog.dart';
import 'package:chat_app/widgets/container_header.dart';
import 'package:chat_app/widgets/data_table.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ChannelMemmbersScreen extends StatelessWidget {
  ChannelMemmbersScreen({super.key});

  final ChannelController _controller = Get.find<ChannelController>();

  @override
  Widget build(BuildContext context) {
    // ✅ FIRST LOAD CALL (SAFE)
    if (_controller.channelMembers.isEmpty &&
        !_controller.isLoadingFirst.value) {
      _controller.getChannelMembers(page: 1, search: "");
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ================= HEADER =================
            ContainerHeader(
              searchHint: "Search members...",
              title: "Channel Members",
              subtitle: "Manage and monitor all channel members",
              showActionButton: true,
              actionButtonText: "New Member",
              actionButtonIcon: Icons.add,
              onActionPressed: () {
                Get.dialog(AddChannelMemberDialog(), barrierDismissible: true);
              },
              showSearch: true,
              onSearchChanged: (value) {
                _controller.onSearch(value);
              },
            ),

            const SizedBox(height: 24),

            /// ================= TABLE =================
            Expanded(
              child: Obx(() {
                /// 🔄 FIRST LOADER
                if (_controller.isLoadingFirst.value &&
                    _controller.channelMembers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = _controller.channelMembers;

                /// ❌ EMPTY STATE
                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      "No members found",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Stack(
                  children: [
                    /// 📊 TABLE
                    TableContainer<UserChannels>(
                      data: users,
                      config: DataTableConfig<UserChannels>(
                        isScrollable: true,
                        title: "Drivers",

                        /// 🔹 HEADERS
                        columns: [
                          DataColumn(label: _headerText("NAME")),
                          DataColumn(label: _headerText("DRIVER NUMBER")),
                          DataColumn(label: _headerText("EMAIL")),
                          DataColumn(label: _headerText("PHONE")),
                          DataColumn(label: _headerText("STATUS")),
                          DataColumn(label: _headerText("ONLINE")),
                          DataColumn(label: _headerText("ACTION")),
                        ],

                        /// 🔹 ROWS
                        buildRows: (data) => data.asMap().entries.map((entry) {
                          final index = entry.key;
                          final driver = entry.value;
                          final isAlt = index % 2 == 1;

                          return DataRow(
                            color: MaterialStateProperty.resolveWith<Color?>(
                              (states) => isAlt ? Colors.grey.shade50 : null,
                            ),
                            cells: [
                              DataCell(_cellText(driver.userProfile?.username)),
                              DataCell(
                                _cellText(
                                  driver.userProfile?.user?.driverNumber,
                                ),
                              ),
                              DataCell(
                                _cellText(driver.userProfile?.user?.email),
                              ),
                              DataCell(
                                _cellText(
                                  driver.userProfile?.user?.phoneNumber,
                                ),
                              ),
                              DataCell(_cellText(driver.status)),

                              /// 🟢 ONLINE DOT
                              DataCell(
                                Center(
                                  child: CircleAvatar(
                                    radius: 5,
                                    backgroundColor:
                                        driver.userProfile?.isOnline == true
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),

                              /// ⚙️ ACTION
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () {},
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 18),
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),

                        /// 🔹 PAGINATION
                        totalItems: _controller.totalItems,
                        currentPage: _controller.currentPage.value,
                        itemsPerPage: _controller.itemsPerPage,

                        onPageChanged: (page) {
                          _controller.getChannelMembers(page: page);
                        },

                        showHeader: false,
                        showPagination: true,
                        showActions: true,
                        primaryColor: const Color(0xFF4A154B),
                      ),
                    ),

                    /// 🔄 PAGINATION LOADER
                    if (_controller.isLoadingMore.value)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= HELPERS =================

  Widget _headerText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _cellText(String? text) {
    return Text(
      text ?? "-",
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade800,
      ),
    );
  }
}
