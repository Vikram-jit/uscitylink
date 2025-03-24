import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';
import 'package:uscitylink/utils/device/device_utility.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;

  const AudioPlayerWidget({Key? key, required this.audioUrl}) : super(key: key);

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  late Stream<Duration?> _durationStream;
  late Stream<Duration> _positionStream;
  late Stream<PlayerState> _playerStateStream;

  // Local variable to hold slider value during dragging.
  double? _dragValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _durationStream = _audioPlayer.durationStream;
    _positionStream = _audioPlayer.positionStream;
    _playerStateStream = _audioPlayer.playerStateStream;
    _audioPlayer.setUrl(widget.audioUrl);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "--:--";
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: _playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing ?? false;

        Widget controlButton;

        // If playback is complete, show a restart button.
        if (processingState == ProcessingState.completed) {
          controlButton = IconButton(
            icon: const Icon(Icons.replay),
            iconSize: 24.0,
            color: Colors.blueAccent,
            onPressed: () async {
              await _audioPlayer.seek(Duration.zero);
              await _audioPlayer.play();
            },
          );
        } else if (playing) {
          controlButton = IconButton(
            icon: const Icon(Icons.pause),
            iconSize: 24.0,
            onPressed: _audioPlayer.pause,
          );
        } else {
          controlButton = IconButton(
            padding: const EdgeInsets.all(0),
            icon: const Icon(Icons.play_arrow),
            iconSize: 24.0,
            onPressed: _audioPlayer.play,
          );
        }

        return Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(5)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              controlButton,
              Expanded(
                child: StreamBuilder<Duration?>(
                  stream: _durationStream,
                  builder: (context, snapshot) {
                    final duration = snapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration>(
                      stream: _positionStream,
                      builder: (context, snapshot) {
                        var position = snapshot.data ?? Duration.zero;
                        if (position > duration) {
                          position = duration;
                        }
                        // Use local _dragValue if user is dragging.
                        final sliderValue = _isDragging
                            ? _dragValue ?? position.inMilliseconds.toDouble()
                            : position.inMilliseconds.toDouble();
                        return Row(
                          children: [
                            SizedBox(
                              width:
                                  TDeviceUtils.getScreenWidth(context) * 0.30,
                              child: Slider(
                                min: 0.0,
                                max: duration.inMilliseconds.toDouble(),
                                value: sliderValue.clamp(
                                    0.0, duration.inMilliseconds.toDouble()),
                                activeColor: Colors.blueAccent,
                                inactiveColor: Colors.grey[300],
                                onChangeStart: (value) {
                                  setState(() {
                                    _isDragging = true;
                                    _dragValue = value;
                                  });
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _dragValue = value;
                                  });
                                },
                                onChangeEnd: (value) {
                                  _audioPlayer.seek(
                                      Duration(milliseconds: value.round()));
                                  setState(() {
                                    _isDragging = false;
                                    _dragValue = null;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width:
                                  TDeviceUtils.getScreenWidth(context) * 0.11,
                              child: Text(
                                _formatDuration(Duration(
                                    milliseconds: _isDragging
                                        ? _dragValue?.round() ??
                                            position.inMilliseconds
                                        : position.inMilliseconds)),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
