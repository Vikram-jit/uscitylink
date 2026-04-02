import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:chat_app/widgets/file_viewer_gallery.dart';
import 'package:chat_app/widgets/media_component.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class MediaGallery extends StatefulWidget {
  const MediaGallery({super.key});

  @override
  State<MediaGallery> createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<MediaGallery> {
  late final MessageController _controller;
  late final HomeController _homeController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<MessageController>();
    _homeController = Get.find<HomeController>();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_controller.isLoading.value &&
        _controller.hasMoreMedia.value) {
      _controller.loadMoreMedia(_homeController.driverId.value);
    }
  }

  Future<void> _onRefresh() async {
    _controller.media.clear();
    _controller.currentMediaPage = 1;
    _controller.hasMoreMedia.value = true;
    await _controller.fetchMedia(_homeController.driverId.value, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // ── Initial full-screen loader (first load only) ──
      if (_controller.isLoading.value && _controller.media.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }

      // ── Empty state ──
      if (_controller.media.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 56,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 12),
              Text(
                'No media yet',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
      }

      // ── Grid ──
      return RefreshIndicator(
        color: Colors.white,
        backgroundColor: Colors.grey.shade900,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Media grid ──
            SliverPadding(
              padding: const EdgeInsets.all(2),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _controller.media[index];
                    return MediaComponent(
                      key: ValueKey(item.id),
                      initialIndex: index,
                      type: GallertType.Media,
                      messageId: item.id!,
                      url: item.key!,
                      fileName: item.fileName ?? '',
                      uploadType: item.uploadType ?? 'server',
                      messageDirection:
                          item.userProfileId == _homeController.driverId.value
                          ? 'R'
                          : 'S',
                      thumbnail: item.thumbnail,
                    );
                  },
                  childCount: _controller.media.length,
                  // ── Key prevents tiles from rebuilding on append ──
                  findChildIndexCallback: (key) {
                    final id = (key as ValueKey).value;
                    final idx = _controller.media.indexWhere((m) => m.id == id);
                    return idx == -1 ? null : idx;
                  },
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
              ),
            ),

            // ── Load-more footer (no blink — separate sliver) ──
            SliverToBoxAdapter(
              child: Obx(
                () => _controller.isLoading.value
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white54,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Loading more…',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _controller.hasMoreMedia.value
                    ? const SizedBox(height: 16)
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'All media loaded',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
