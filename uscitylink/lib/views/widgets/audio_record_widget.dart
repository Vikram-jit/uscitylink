import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/audio_controller.dart';

class AudioRecordWidget extends StatelessWidget {
  AudioController audioController;
  AudioRecordWidget({super.key, required this.audioController});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(() {
        return Row(
          children: [
            if (audioController.isRecording.value)
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      audioController.showPlayer.value
                          ? audioController.isPlaying.value
                              ? audioController.isPaused.value
                                  ? audioController.resumePlaying()
                                  : audioController.pausePlayback()
                              : audioController.playRecording()
                          : null;
                    },
                    child: Icon(
                        audioController.showPlayer.value
                            ? (audioController.isPlaying.value &&
                                    !audioController.isPaused.value)
                                ? Icons.pause
                                : Icons.play_arrow
                            : Icons.mic,
                        color: audioController.showPlayer.value
                            ? Colors.blueAccent
                            : Colors.red,
                        size: 28),
                  ),
                  SizedBox(width: 8),
                  if (audioController.showPlayer.value)
                    Obx(() {
                      final remainingTime =
                          audioController.totalDuration.value -
                              audioController.currentPosition.value;
                      return Text(
                        audioController.formatDuration(remainingTime ~/ 1000),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      );
                    })
                  else
                    Text(
                      audioController.formatDuration(
                          audioController.recordingDuration.value),
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            SizedBox(
              width: 10,
            ),
            if (audioController.showPlayer.value)
              Expanded(
                flex: audioController.isPlaying.value ? 3 : 3,
                child: Obx(() => Slider(
                      value: audioController.currentPosition.value.toDouble(),
                      min: 0,
                      max: audioController.totalDuration.value.toDouble(),
                      activeColor: Colors.blueAccent,
                      inactiveColor: Colors.grey[300],
                      onChanged: (value) {
                        audioController.seekTo(value.toInt());
                      },
                    )),
              ),
            if (!audioController.showPlayer.value)
              Expanded(
                child: Text(
                  "recording...",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            if (!audioController.isRecording.value)
              Expanded(
                child: IconButton(
                  icon: Icon(Icons.mic, color: Colors.blue, size: 30),
                  onPressed: audioController.startRecording,
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() {
                    return IconButton(
                      icon: Icon(
                        audioController.isPaused.value
                            ? Icons.mic
                            : !audioController.showPlayer.value
                                ? Icons.stop
                                : null,
                        color: audioController.isPaused.value
                            ? Colors.orange
                            : Colors.red,
                        size: 30,
                      ),
                      onPressed: () {
                        audioController.isPaused.value
                            ? audioController.resumeRecording()
                            : audioController.pauseRecording();
                      },
                    );
                  }),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 30),
                    onPressed: audioController.deleteRecoding,
                  ),
                ],
              ),
          ],
        );
      }),
    );
  }
}
