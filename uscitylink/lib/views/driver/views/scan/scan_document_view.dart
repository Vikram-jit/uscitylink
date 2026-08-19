import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/image_picker_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/driver/views/chat_view.dart';
import 'package:uscitylink/views/widgets/photo_preview_multiple.dart';

class ScanDocumentView extends StatefulWidget {
  // When opened from inside an existing chat/group, the destination is
  // already known, so the recipient-picker step is skipped entirely.
  final String? presetChannelId;
  final String? presetGroupId;

  const ScanDocumentView({
    super.key,
    this.presetChannelId,
    this.presetGroupId,
  });

  @override
  State<ScanDocumentView> createState() => _ScanDocumentViewState();
}

class _ScanDocumentViewState extends State<ScanDocumentView> {
  final ImagePickerController controller = Get.find();
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    // selectedImages/selectedXImages are shared with the camera/gallery
    // send flow — start every scan session on a clean slate so leftovers
    // from an earlier, unfinished send don't leak into the scanned set.
    controller.clearSelectedImage();
  }

  Future<void> _scanPage() async {
    setState(() => _scanning = true);
    await controller.scanDocumentPage();
    if (mounted) setState(() => _scanning = false);
  }

  void _leave() {
    controller.clearSelectedImage();
    Get.back();
  }

  void _sendTo(String channelId, String? groupId) {
    Get.off(() => PhotoPreviewMultiple(
          channelId: channelId,
          type: "media",
          location: groupId != null ? "group" : "chat",
          groupId: groupId,
          source: "driver_chat",
          userId: "",
          uploadBy: "driver",
        ));
  }

  void _chooseRecipient() {
    if (widget.presetChannelId != null) {
      _sendTo(widget.presetChannelId!, widget.presetGroupId);
      return;
    }
    Get.to(() => ChatView(
          selectionMode: true,
          onTargetSelected: (channelId, groupId, name) =>
              _sendTo(channelId, groupId),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: TColors.navyHeader,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Scan Document',
          style: TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: _leave,
        ),
        actions: [
          Obx(() {
            if (controller.selectedImages.value.isEmpty) {
              return const SizedBox();
            }
            return TextButton(
              onPressed: controller.clearSelectedImage,
              child: const Text(
                'Reset',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        final pages = controller.selectedImages.value;
        if (pages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 96,
                  width: 96,
                  decoration: BoxDecoration(
                    color: TColors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.document_scanner_rounded,
                      size: 44, color: TColors.teal),
                ),
                const SizedBox(height: 20),
                Text(
                  'Scan a document to get started',
                  style: TextStyle(
                      fontSize: 15,
                      color: TColors.textMuted,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _scanning ? null : _scanPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.navyHeader,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _scanning
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.camera_alt_rounded),
                  label: const Text('Scan Document'),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: pages.length + 1,
                itemBuilder: (context, index) {
                  if (index == pages.length) {
                    return GestureDetector(
                      onTap: _scanning ? null : _scanPage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: TColors.hairline, width: 1.5),
                        ),
                        child: Center(
                          child: _scanning
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.add_rounded,
                                  color: TColors.textMuted, size: 32),
                        ),
                      ),
                    );
                  }
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: TColors.hairline),
                            image: DecorationImage(
                              image: FileImage(pages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () {
                            pages.removeAt(index);
                            if (index < controller.selectedXImages.value.length) {
                              controller.selectedXImages.value.removeAt(index);
                            }
                            controller.selectedImages.refresh();
                            controller.selectedXImages.refresh();
                          },
                          child: Container(
                            height: 22,
                            width: 22,
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _chooseRecipient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.navyHeader,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                      '${widget.presetChannelId != null ? 'Continue' : 'Next'} · ${pages.length} page${pages.length == 1 ? '' : 's'}'),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
