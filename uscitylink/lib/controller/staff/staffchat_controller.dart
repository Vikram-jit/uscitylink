import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/model/staff/user_message_model.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/services/staff_services/chat_service.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:path_provider/path_provider.dart';

class StaffchatController extends GetxController {
  SocketService _socketService = Get.find<SocketService>();
  var message = UserMessageModel().obs;
  TextEditingController messageController = TextEditingController();
  var templateUrl = "".obs;
  final __channelService = ChatService();
  var typing = false.obs;
  var typingMessage = "".obs;
  var loading = false.obs;
  var userId = "".obs;
  var channelId = "".obs;
  var userName = "".obs;
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var truckNumbers = "".obs;
  Timer? typingTimer;
  late DateTime typingStartTime;
  var selectedRplyMessage = MessageModel().obs;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final _apiService = NetworkApiService();
  RxBool isRecording = false.obs;
  RxBool isPaused = false.obs;
  RxString recordingPath = "".obs;
  RxBool isPlaying = false.obs;
  RxInt recordingDuration = 0.obs;
  RxBool showPlayer = false.obs;
  RxInt currentPosition = 0.obs;
  RxInt totalDuration = 1.obs; // Avoid division by zero

  Timer? _timer; // Timer to track duration

  @override
  void onInit() async {
    super.onInit();
    // await initializeRecorder();
    // await _initPlayer();
  }

  Future<void> initializeRecorder() async {
    // Request microphone permission
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      print(status);
    }

    // Open the audio session
    await _recorder.openRecorder();
  }

  Future<void> _initPlayer() async {
    try {
      await _player.openPlayer();
      await _player.setSubscriptionDuration(const Duration(milliseconds: 500));
    } catch (e) {
      // Handle the exception, possibly logging it or showing a user-friendly message
      print('Error opening player: $e');
    }
  }

  Future<void> startRecording() async {
    if (recordingPath.value.isNotEmpty) {
      showPlayer.value = false;
      currentPosition.value = 0;
      totalDuration.value = 1;
      final previousFile = File(recordingPath.value);
      if (await previousFile.exists()) {
        await previousFile.delete();
      }
    }

    if (!_recorder.isRecording) {
      await initializeRecorder();
    }
    Directory tempDir = await getTemporaryDirectory();
    String path = "${tempDir.path}/recording.aac";

    await _recorder.startRecorder(toFile: path);
    recordingPath.value = path;
    isRecording.value = true;
    isPaused.value = false;
    recordingDuration.value = 0;

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel(); // Ensure no existing timer is running
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      recordingDuration.value++;
    });
  }

  Future<void> pauseRecording() async {
    if (!isRecording.value || isPaused.value) return;
    await _recorder.pauseRecorder();
    showPlayer.value = true;
    // isPaused.value = true;
    // isPlaying.value = true;
    _timer?.cancel();
    await playRecording();
  }

  Future<void> resumeRecording() async {
    if (!isRecording.value || !isPaused.value) return;
    if (_player.isPlaying) {
      await _player.pausePlayer();
    }
    showPlayer.value = false;
    currentPosition.value = 0;
    totalDuration.value = 1;
    await _recorder.resumeRecorder();
    isPaused.value = false;
    _startTimer();
  }

  Future<void> stopRecording() async {
    if (!isRecording.value) return;

    await _recorder.stopRecorder();
    isRecording.value = false;
    isPaused.value = false;
    showPlayer.value = true;
    currentPosition.value = 0;
    totalDuration.value = 1;
    _timer?.cancel();
  }

  Future<void> deleteRecoding() async {
    if (isPlaying.value) {
      await _player.stopPlayer();
    }
    isRecording.value = false;
    isPaused.value = false;
    showPlayer.value = false;
    currentPosition.value = 0;
    totalDuration.value = 1;
    _timer?.cancel();
  }

  Future<void> playRecording() async {
    if (recordingPath.value.isEmpty) return;

    final file = File(recordingPath.value);
    if (!await file.exists()) {
      print('Audio file does not exist at path: ${recordingPath.value}');
      return;
    }

    if (!_player.isOpen()) {
      await _initPlayer();
    }
    try {
      await _player.startPlayer(
        fromURI: recordingPath.value,
        whenFinished: () {
          isPaused.value = true;
          isPlaying.value = false;
          currentPosition.value = 0;
        },
      );

      _player.onProgress?.listen((event) {
        if (event != null) {
          currentPosition.value = event.position.inMilliseconds;
          totalDuration.value = event.duration.inMilliseconds;
        }
      });

      isPlaying.value = true;
    } catch (e) {
      print('Error starting player: $e');
    }
  }

  void seekTo(int milliseconds) {
    _player.seekToPlayer(Duration(milliseconds: milliseconds));
    currentPosition.value = milliseconds;
  }

  Future<void> stopPlaying() async {
    await _player.stopPlayer();
    isPlaying.value = false;
  }

  Future<void> pausePlayback() async {
    if (_player.isPlaying) {
      await _player.pausePlayer();
      isPaused.value = true;
    } else {
      print('Player is not playing. Cannot pause.');
    }
  }

  Future<void> resumePlaying() async {
    await _player.resumePlayer();
    isPaused.value = false;
  }

  String formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  @override
  void onClose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    _timer?.cancel();
    super.onClose();
  }

  Future<void> getChannelMembers(String id, int page, String channelId,
      [String? pinMessage]) async {
    if (loading.value) return; // Prevent multiple simultaneous requests

    loading.value = true;

    try {
      // Fetch messages from the server with pagination.
      var response = await __channelService.getMesssageByUserId(
          page: page,
          id: id,
          pageSize: 10,
          channelId: channelId,
          pinMessage: pinMessage ?? "0");

      // Check if the response is valid
      if (response.data != null) {
        truckNumbers.value = response.data.truckNumbers ?? "";
        // Append new messages if it's not the first page
        if (page > 1) {
          message.value.messages?.addAll(response.data.messages ?? []);
        } else {
          // Reset the message list if it's the first page
          message.value = response.data;
        }

        // Update pagination info
        currentPage.value = response.data.pagination!.currentPage!;
        totalPages.value = response.data.pagination!.totalPages!;
      } else {
        Utils.snackBar('No data', 'No messages found.');
      }
    } catch (error) {
      // Handle error by showing a snack bar
      Utils.snackBar('Error', error.toString());
    } finally {
      // Ensure loading state is reset
      loading.value = false;
    }
  }

  void updateChannelMessagesByNotification(
      String newChannelId, String channelName, String id) {
    _socketService.updateStaffActiveUserChat("");
    channelId.value = newChannelId;
    userName.value = channelName;
    userId.value = id;
    currentPage.value = 1;
    totalPages.value = 1;
    if (_socketService.isConnected.value) {
      _socketService.updateStaffActiveUserChat(id);
    }
    getChannelMembers(id, 1, newChannelId);
  }

  Future<void> deleteMember(String id) async {
    if (loading.value) return;

    loading.value = true;

    try {
      // Fetch messages from the server with pagination.
      var response = await __channelService.deletedById(id);

      // Check if the response is valid
      if (response.status) {
        Utils.toastMessage(response.message);
      }
    } catch (error) {
      // Handle error by showing a snack bar
      Utils.snackBar('Error', error.toString());
    } finally {
      // Ensure loading state is reset
      loading.value = false;
    }
  }

  void updateTypingStatus(dynamic data) {
    print(data);
    typing.value = data['isTyping'];
    typingMessage.value = data['message'];
  }

  void startTyping(String userId) {
    if (typingTimer != null && typingTimer!.isActive) {
      typingTimer!.cancel();
    }

    _socketService.staffTyping(userId, true);

    typingStartTime = DateTime.now();

    typingTimer = Timer(const Duration(seconds: 1), () {
      if (DateTime.now().difference(typingStartTime).inSeconds >= 1) {
        stopTyping(userId);
      }
    });
  }

  // Stop typing event
  void stopTyping(String userId) {
    _socketService.staffTyping(userId, false);
  }

  void onNewMessage(dynamic data) {
    MessageModel newMessage = MessageModel.fromJson(data);

    if (userId.value == newMessage.userProfileId) {
      message.value.messages?.insert(0, newMessage);
      message?.refresh();
    }
  }

  void pinMessage(dynamic data) {
    final messageId = data[0];
    message.value.messages!
        .where((message) => message.id == messageId)
        .forEach((message) => message.staffPin = data[1]);
    Utils.toastMessage(
        "${data[1] == "1" ? "pin" : "un-pin"} message successfully");
    message.refresh();
  }

  void deleteMessage(dynamic data) {
    final messageId = data;

    message.value.messages!.removeWhere((message) => message.id == messageId);

    Utils.toastMessage("Deleted message successfully.");
    message.refresh();
  }

  void sendAudio(String channelId, String type, String location,
      String? groupId, String? source, String? userId) async {
    try {
      if (recordingPath.value.isEmpty) {
        Utils.snackBar("Error", "Please record audio before send.");
        return;
      }
      Utils.showLoader();
      final file = File(recordingPath.value);
      var res = await _apiService.fileUpload(
          file,
          "${Constant.url}/message/fileUpload?groupId=$groupId&userId=$userId&source=$location",
          channelId,
          type,
          false);

      if (res.status) {
        if (source == "staff") {
          if (location == "group") {
            _socketService.sendGroupMessage(
                groupId!, channelId, "", res.data.key!);
          } else if (location == "truck") {
            _socketService.sendMessageToTruck(
                "", groupId!, "audio", res.data.key!);
          } else {
            _socketService.sendMessageToUser(userId!, "", res.data.key!);
          }
        } else {
          if (location == "group") {
            _socketService.sendGroupMessage(
                groupId!, channelId, "", res.data.key!);
          } else {
            _socketService.sendMessage("", res.data.key!, channelId);
          }
        }
        deleteRecoding();

        Utils.hideLoader();
      }
    } catch (e) {
      Utils.hideLoader();
      Utils.snackBar("File Upload Error", e.toString());
    }
  }
}
