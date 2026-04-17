import 'package:chat_app/core/controller/global_search_controller.dart';
import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/core/widgets/reload_button.dart';
import 'package:chat_app/modules/broadcast_messages/widgets/broadcast_form.dart';
import 'package:chat_app/modules/broadcast_messages/widgets/broadcast_list.dart';

import 'package:chat_app/modules/home/desktop/widgets/left_sidebar.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class DesktopView extends StatelessWidget {
  DesktopView({super.key});

  final searchCtrl = Get.find<GlobalSearchController>();
  final searchKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => searchCtrl.hideOverlay(),
        child: Column(
          children: [
            SizedBox(height: 10),
            Container(
              height: 40,
              color: AppColors.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Spacer(),
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
                            ), // text black
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withValues(
                                alpha: 0.30,
                              ), // white box
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.white,
                                size: 18,
                              ),
                              hintText: "Search...",
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white,
                              ), // grey hint
                              contentPadding: EdgeInsets.symmetric(
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
                  Spacer(),

                  ReloadButton(),
                  Spacer(),
                  SizedBox(
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
                padding: EdgeInsets.only(bottom: 4.0, right: 4.0),
                child: Row(
                  children: [
                    LeftSidebar(),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: BroadcastForm(),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: BroadcastList(),
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
