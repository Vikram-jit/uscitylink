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

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(5)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (processingState == ProcessingState.loading ||
                  processingState == ProcessingState.buffering)
                Container(
                  margin: EdgeInsets.all(8.0),
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(),
                )
              else if (playing)
                Container(
                  width: 30,
                  height: 30,
                  child: IconButton(
                    icon: Icon(Icons.pause),
                    iconSize: 24.0,
                    onPressed: _audioPlayer.pause,
                  ),
                )
              else
                Container(
                  width: 30,
                  height: 30,
                  child: IconButton(
                    padding: EdgeInsets.all(0),
                    icon: Icon(Icons.play_arrow),
                    iconSize: 24.0,
                    onPressed: _audioPlayer.play,
                  ),
                ),
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
                        return Row(
                          children: [
                            SizedBox(
                              width:
                                  TDeviceUtils.getScreenWidth(context) * 0.32,
                              child: Slider(
                                activeColor: Colors.blue,
                                min: 0.0,
                                max: duration.inMilliseconds.toDouble(),
                                value: position.inMilliseconds.toDouble().clamp(
                                    0.0, duration.inMilliseconds.toDouble()),
                                onChanged: (value) {
                                  _audioPlayer.seek(
                                      Duration(milliseconds: value.round()));
                                },
                              ),
                            ),

                            SizedBox(
                              width:
                                  TDeviceUtils.getScreenWidth(context) * 0.11,
                              child: Text(_formatDuration(position)),
                            ),
                            // Text(_formatDuration(duration)),
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
