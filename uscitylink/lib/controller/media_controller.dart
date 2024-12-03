import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:uscitylink/model/media_model.dart';
import 'package:uscitylink/services/message_service.dart';

class MediaController extends GetxController {
  var selectedSegment = 0.obs;
  var mediaList = <Media>[].obs;
  var isLoading = false.obs;
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var channel = Channel().obs;
  // Method to update the selected segment
  void selectSegment(int index) {
    mediaList.clear();
    selectedSegment.value = index;
    if (index == 0) {
      fetchMediaData(channelId, "media", source);
    } else {
      fetchMediaData(channelId, "doc", source);
    }
  }

  ScrollController scrollController = ScrollController();

  final String channelId;
  final String source;
  MediaController({required this.channelId, required this.source});
  @override
  void onInit() {
    super.onInit();
    fetchMediaData(channelId, "media", source);
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  final __messageService = MessageService();
  Future<void> fetchMediaData(
      String channelId, String type, String source) async {
    if (isLoading.value) return;

    isLoading.value = true;

    try {
      final response = await __messageService.getMedia(channelId, type, source);

      if (response.status) {
        mediaList.clear();
        channel.value = response.data.channel!;
        mediaList.addAll(response.data.media ?? []);

        currentPage.value++;
        totalPages.value = response.data.totalPages!;
      } else {
        throw Exception('Failed to load media');
      }
    } catch (e) {
      isLoading.value = false;
      print('Error fetching media: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
