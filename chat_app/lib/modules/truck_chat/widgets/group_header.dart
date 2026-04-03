import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/modules/truck_chat/controller/group_message_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/spacing.dart';

class GroupHeader extends StatefulWidget {
  final String userName;
  final String avatarUrl;
  final String status;

  const GroupHeader({
    super.key,
    this.userName = "",
    this.avatarUrl = "",
    this.status = "",
  });

  @override
  State<GroupHeader> createState() => _ChatHeaderState();
}

class _ChatHeaderState extends State<GroupHeader>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final messageController = Get.find<GroupMessageController>();
  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging == false) {
        messageController.switchTab(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    // Only dispose the controller if we created it

    super.dispose();
  }

  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(6.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => messageController.toggleDetails(),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Stack(
                      children: [
                        const SizedBox(height: Space.md),
                        Obx(() {
                          return Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              messageController.group.value.name?.characters
                                      .take(1)
                                      .toString()
                                      .toUpperCase() ??
                                  "",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                color: AppColors.white,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(width: Space.md),
                    SizedBox(
                      width: 420,
                      child: Obx(() {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${messageController.group.value.name ?? widget.userName} ",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.bg,
                                height: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Members Groups : ${messageController.memmbers.map((f) {
                                final username = f.userProfile?.username ?? "-";
                                final driverNo = f.userProfile?.user?.driverNumber ?? "-";
                                return "$username ($driverNo)";
                              }).join(", ")}",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.bg,
                                height: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),

        // 🎯 TAB BAR - Professional refinement
        Container(
          height: 30,
          decoration: BoxDecoration(color: Colors.white),
          child: TabBar(
            tabAlignment: TabAlignment.start,
            controller: _tabController,
            isScrollable: true,
            padding: EdgeInsets.zero,
            indicatorPadding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: 10),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textGrey,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.primary, width: 3),
              ),
            ),
            indicatorWeight: 3,
            labelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.15,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.15,
            ),

            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.message_outlined, size: 18),
                    SizedBox(width: 8),
                    Text("Messages"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_file_outlined, size: 18),
                    SizedBox(width: 8),
                    Text("Files"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.push_pin_outlined, size: 18),
                    SizedBox(width: 8),
                    Text("Pins"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
