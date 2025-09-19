import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;

  const AudioPlayerWidget({Key? key, required this.audioUrl}) : super(key: key);

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isLocalFile = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Try multiple approaches to load the audio
      await _tryDirectUrl();
    } catch (e) {
      print('All audio loading approaches failed: $e');
      setState(() {
        _errorMessage = 'Cannot play audio. Format may not be supported.';
        _isLoading = false;
      });
    }
  }

  Future<void> _tryDirectUrl() async {
    try {
      // Approach 1: Try direct URL with setUrl
      await _audioPlayer.setUrl(widget.audioUrl);
      setState(() {
        _isLoading = false;
        _isLocalFile = false;
      });
    } catch (e) {
      print('Direct URL failed: $e');
      await _tryDownloadAndPlay();
    }
  }

  Future<void> _tryDownloadAndPlay() async {
    try {
      // Approach 2: Download the file first and play locally
      print('Downloading audio file...');

      final response = await http.get(Uri.parse(widget.audioUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download audio: ${response.statusCode}');
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/temp_audio.aac');
      await file.writeAsBytes(response.bodyBytes);

      // Try playing the local file
      await _audioPlayer.setFilePath(file.path);

      setState(() {
        _isLoading = false;
        _isLocalFile = true;
      });

      print('Audio loaded successfully from local file');
    } catch (e) {
      print('Download approach failed: $e');
      await _tryAudioSourceUri();
    }
  }

  Future<void> _tryAudioSourceUri() async {
    try {
      // Approach 3: Try with AudioSource.uri
      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(widget.audioUrl)),
      );
      setState(() {
        _isLoading = false;
        _isLocalFile = false;
      });
    } catch (e) {
      print('AudioSource.uri failed: $e');
      rethrow;
    }
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

  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage ?? 'Audio playback failed',
                style: const TextStyle(color: Colors.red, fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadAudio,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading audio...', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton() {
    return StreamBuilder<PlayerState>(
      stream: _audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final playerState =
            snapshot.data ?? PlayerState(false, ProcessingState.idle);
        final processingState = playerState.processingState;

        if (processingState == ProcessingState.loading) {
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        } else if (processingState == ProcessingState.completed) {
          return IconButton(
            icon: const Icon(Icons.replay),
            iconSize: 24.0,
            color: Colors.blue,
            onPressed: () => _audioPlayer
                .seek(Duration.zero)
                .then((_) => _audioPlayer.play()),
          );
        } else if (playerState.playing) {
          return IconButton(
            icon: const Icon(Icons.pause),
            iconSize: 24.0,
            color: Colors.blue,
            onPressed: _audioPlayer.pause,
          );
        } else {
          return IconButton(
            icon: const Icon(Icons.play_arrow),
            iconSize: 24.0,
            color: Colors.blue,
            onPressed: _audioPlayer.play,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _buildControlButton(),
          const SizedBox(width: 12),
          Expanded(
            child: StreamBuilder<Duration?>(
              stream: _audioPlayer.durationStream,
              builder: (context, durationSnapshot) {
                final duration = durationSnapshot.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: _audioPlayer.positionStream,
                  builder: (context, positionSnapshot) {
                    var position = positionSnapshot.data ?? Duration.zero;

                    return Row(
                      children: [
                        Expanded(
                          child: Slider(
                            min: 0.0,
                            max: duration.inMilliseconds > 0
                                ? duration.inMilliseconds.toDouble()
                                : 1.0,
                            value: position.inMilliseconds
                                .toDouble()
                                .clamp(0.0, duration.inMilliseconds.toDouble()),
                            onChanged: (value) {
                              _audioPlayer
                                  .seek(Duration(milliseconds: value.round()));
                            },
                            activeColor: Colors.blue,
                            inactiveColor: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(position),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
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
  }
}
