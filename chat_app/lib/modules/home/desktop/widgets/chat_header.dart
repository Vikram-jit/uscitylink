import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';

class ChatHeader extends StatefulWidget {
  final String userName;
  final String avatarUrl;
  final String status;
  final bool isOnline;

  const ChatHeader({
    super.key,
    this.userName = "Vikramjit Singh",
    this.avatarUrl = "https://i.pravatar.cc/150?img=3",
    this.status = "Active",
    this.isOnline = true,
  });

  @override
  State<ChatHeader> createState() => _ChatHeaderState();
}

class _ChatHeaderState extends State<ChatHeader>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final messageController = Get.find<MessageController>();

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
        // 🎯 TOP BAR - Enhanced professional design
        Container(
          height: 64, // Slightly taller for better proportions
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(6.0),

              // bottomLeft and bottomRight remain square by default
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
              // 🔹 Avatar with Status Indicator
              Stack(
                children: [
                  Container(
                    height: 40, // Slightly larger
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.avatarGreen,
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // Smoother radius
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "A",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  if (widget.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.avatarGreen,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: Space.md),

              // 🔹 User Info with Improved Typography
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.bg,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
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
