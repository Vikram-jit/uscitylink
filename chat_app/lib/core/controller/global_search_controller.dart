import 'dart:async';
import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:chat_app/widgets/chat_conversation_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app/modules/home/services/driver_service.dart';
import 'package:google_fonts/google_fonts.dart';

class GlobalSearchController extends GetxController {
  RxList<dynamic> results = <dynamic>[].obs;
  RxBool isLoading = false.obs;

  Timer? _debounce;
  OverlayEntry? _overlayEntry;

  // ----------------------------
  // SEARCH HANDLER
  // ----------------------------
  void onSearchChanged(String value, BuildContext context, GlobalKey key) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (value.isNotEmpty) {
        fetchResults(value, context, key);
      } else {
        hideOverlay();
        results.clear();
      }
    });
  }

  // ----------------------------
  // API CALL
  // ----------------------------
  Future<void> fetchResults(
    String q,
    BuildContext context,
    GlobalKey key,
  ) async {
    try {
      isLoading.value = true;

      final res = await DriverService().getSearch(q);
      final data = res.data;

      results.value = [
        ...data["drivers"].map(
          (e) => {
            "id": e["id"],
            "label": e["username"],
            "type": "driver",
            "user": e["user"],
          },
        ),
        ...data["groups"].map(
          (e) => {"id": e["id"], "label": e["name"], "type": "group"},
        ),
        ...data["truckGroups"].map(
          (e) => {"id": e["id"], "label": e["name"], "type": "truck"},
        ),
      ];

      showOverlay(context, key);
    } catch (e) {
      results.clear();
      hideOverlay();
    } finally {
      isLoading.value = false;
    }
  }

  // ----------------------------
  // OVERLAY LOGIC
  // ----------------------------
  void showOverlay(BuildContext context, GlobalKey key) {
    hideOverlay();

    final box = key.currentContext!.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: position.dx,
        top: position.dy + box.size.height + 8,
        width: box.size.width,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 360),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(blurRadius: 24, color: Color(0x22000000)),
              ],
            ),
            child: Obx(() {
              if (isLoading.value) return _loadingState();
              if (results.isEmpty) return _emptyState();
              return _groupedResults();
            }),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _groupedResults() {
    final drivers = results.where((e) => e["type"] == "driver").toList();
    final groups = results.where((e) => e["type"] == "group").toList();
    final trucks = results.where((e) => e["type"] == "truck").toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (drivers.isNotEmpty) _section("Drivers", drivers),
        if (groups.isNotEmpty) _section("Groups", groups),
        if (trucks.isNotEmpty) _section("Trucks", trucks),
      ],
    );
  }

  Widget _section(String title, List items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: Colors.black45,
            ),
          ),
        ),
        ...items.map(_resultTile),
      ],
    );
  }

  void openChatInDialog() {
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: Get.width * 0.8,
          height: Get.height * 0.8,
          child: ChatConversationView(
            controller: Get.find<HomeController>(),
            msgController: Get.find<MessageController>(),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Widget _resultTile(dynamic item) {
    return InkWell(
      onTap: () {
        Get.find<HomeController>().openDirectMessageDialog(
          userId: item["id"] ?? "",
          userName: item["label"],
        );
        hideOverlay();
        openChatInDialog();
      },
      hoverColor: const Color(0xFFF4F6F8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item["type"] == "driver"
                    ? Icons.person_outline
                    : item["type"] == "group"
                    ? Icons.group_outlined
                    : Icons.local_shipping_outlined,
                size: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${item["label"]} ${item["type"] == "driver" ? "(${item["user"]["driver_number"]})" : ""}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item["type"],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.search, size: 28, color: Colors.black26),
          SizedBox(height: 12),
          Text(
            "No matches",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Try a different name or number",
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _loadingState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text(
            "Searching…",
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  void hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void onClose() {
    hideOverlay();
    super.onClose();
  }
}
