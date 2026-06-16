import 'dart:async';

import 'package:chat_app/core/controller/global_search_controller.dart';
import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/core/widgets/reload_button.dart';
import 'package:chat_app/modules/home/desktop/widgets/left_sidebar.dart';
import 'package:chat_app/modules/system_messages/system_message_controller.dart';
import 'package:chat_app/modules/system_messages/widgets/system_message_filters.dart';
import 'package:chat_app/modules/system_messages/widgets/system_message_list.dart';
import 'package:chat_app/modules/system_messages/widgets/unread_messages_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SystemMessagesDesktopView extends StatefulWidget {
  const SystemMessagesDesktopView({super.key});

  @override
  State<SystemMessagesDesktopView> createState() =>
      _SystemMessagesDesktopViewState();
}

class _SystemMessagesDesktopViewState extends State<SystemMessagesDesktopView> {
  final searchCtrl = Get.find<GlobalSearchController>();
  final searchKey = GlobalKey();
  Timer? _dialogTimer;

  @override
  void initState() {
    super.initState();
    _scheduleDialog();
  }

  void _scheduleDialog() {
    _dialogTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final c = Get.find<SystemMessageController>();
      if (c.unreadMessages.isNotEmpty && Get.isDialogOpen != true) {
        Get.dialog(const UnreadMessagesDialog(), barrierDismissible: false);
      }
    });
  }

  @override
  void dispose() {
    _dialogTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => searchCtrl.hideOverlay(),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              height: 40,
              color: AppColors.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width * 0.1,
                        ),
                        child: SizedBox(
                          height: 30,
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: TextField(
                            controller: searchCtrl.searchController,
                            key: searchKey,
                            onChanged: (value) => searchCtrl.onSearchChanged(
                              value,
                              context,
                              searchKey,
                            ),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.30),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.white,
                                size: 18,
                              ),
                              hintText: 'Search...',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const ReloadButton(),
                  const Spacer(),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: Icon(
                      Icons.help_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4.0, right: 4.0),
                child: Row(
                  children: [
                    LeftSidebar(),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: SingleChildScrollView(
                          child: SystemMessageFilters(),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SystemMessageList(),
                      ),
                    ),
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
