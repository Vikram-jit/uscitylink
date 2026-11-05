import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uscitylink/services/call/call_models.dart';
import 'package:uscitylink/services/staff/call_log_service.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';
import 'package:video_player/video_player.dart';

/// Staff → Call log → details: the call's recording, as on the web dashboard (CallDetailDrawer.tsx):
/// "Saving…" / failed states, play the audio, play the video grid (video calls with "Record video"),
/// the file fingerprint (sha256), and download links. Links are fetched on demand (they expire).
class CallRecordingSection extends StatefulWidget {
  const CallRecordingSection(
      {super.key,
      required this.recording,
      required this.answered,
      required this.loadLink});

  final CallRecordingInfo? recording;

  /// The call was answered (only answered calls can have a recording).
  final bool answered;
  final Future<CallRecordingLink> Function() loadLink;

  @override
  State<CallRecordingSection> createState() => _CallRecordingSectionState();
}

class _CallRecordingSectionState extends State<CallRecordingSection> {
  CallRecordingLink? _link;
  bool _loading = false;
  String _error = '';

  Future<void> _open() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final link = await widget.loadLink();
      if (mounted) setState(() => _link = link);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  Widget _note(IconData icon, String text, Color color) => Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: Text(text, style: AppText.bodySm.copyWith(color: color))),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final r = widget.recording;
    final Widget body;
    if (r == null) {
      body = _note(
          Icons.mic_off_rounded,
          widget.answered
              ? 'This call was not recorded'
              : 'Only answered calls are recorded',
          StaffColors.textMuted);
    } else if (r.status == 'recording' || r.status == 'processing') {
      body = Row(
        children: [
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: StaffColors.primary)),
          const SizedBox(width: AppSpacing.sm),
          Text(r.status == 'recording' ? 'Recording…' : 'Saving the recording…',
              style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
        ],
      );
    } else if (r.status == 'failed') {
      body = _note(
          Icons.error_outline_rounded,
          'The recording failed${r.error.isEmpty ? '' : ': ${r.error}'}',
          StaffColors.danger);
    } else {
      final link = _link;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (r.error.isNotEmpty) ...[
            _note(
                Icons.warning_amber_rounded,
                '${r.error} — only the other voice is in the recording.',
                StaffColors.warning),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (link == null)
            FilledButton.icon(
              key: const Key('playRecording'),
              onPressed: _loading ? null : _open,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(
                      r.hasVideo
                          ? Icons.smart_display_rounded
                          : Icons.play_arrow_rounded,
                      size: 20),
              label:
                  Text(r.hasVideo ? 'Play video recording' : 'Play recording'),
              style:
                  FilledButton.styleFrom(backgroundColor: StaffColors.primary),
            )
          else if (link.videoUrl.isNotEmpty)
            _VideoRecording(url: link.videoUrl)
          else
            _AudioRecording(url: link.url, knownSeconds: r.durationSec),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _note(Icons.error_outline_rounded, _error, StaffColors.danger),
          ],
          if (r.sha256.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: r.sha256));
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    const SnackBar(content: Text('Fingerprint copied')));
              },
              child: Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Fingerprint (SHA-256): '),
                  TextSpan(
                      text:
                          '${r.sha256.substring(0, r.sha256.length < 16 ? r.sha256.length : 16)}…',
                      style: const TextStyle(fontFamily: 'monospace')),
                ]),
                style: AppText.labelMd.copyWith(color: StaffColors.textMuted),
              ),
            ),
            Text(
                'If anything in the recording changed, this would change. Long-press to copy.',
                style: AppText.labelMd.copyWith(
                    color: StaffColors.textMuted.withValues(alpha: 0.8))),
          ],
          if (link != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                TextButton.icon(
                  key: const Key('downloadAudio'),
                  onPressed: () => _download(link.url),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download audio'),
                ),
                if (link.videoUrl.isNotEmpty)
                  TextButton.icon(
                    key: const Key('downloadVideo'),
                    onPressed: () => _download(link.videoUrl),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download video'),
                  ),
              ],
            ),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.fiber_manual_record,
                size: 12, color: StaffColors.danger),
            const SizedBox(width: 6),
            Text('Recording',
                style: AppText.titleMd.copyWith(color: StaffColors.textStrong)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        body,
      ],
    );
  }
}

class _AudioRecording extends StatefulWidget {
  const _AudioRecording({required this.url, this.knownSeconds});
  final String url;
  final int? knownSeconds;

  @override
  State<_AudioRecording> createState() => _AudioRecordingState();
}

class _AudioRecordingState extends State<_AudioRecording> {
  final _player = AudioPlayer();
  String _error = '';

  @override
  void initState() {
    super.initState();
    _player
        .setUrl(widget.url)
        .then((_) => _player.play())
        .catchError((Object e) {
      if (mounted) setState(() => _error = 'Could not play the recording');
      return null;
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error.isNotEmpty) {
      return Text(_error,
          style: AppText.bodySm.copyWith(color: StaffColors.danger));
    }
    return Container(
      key: const Key('audioRecordingPlayer'),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
      decoration: BoxDecoration(
          color: StaffColors.canvas,
          borderRadius: BorderRadius.circular(AppRadii.md)),
      child: StreamBuilder<PlayerState>(
        stream: _player.playerStateStream,
        builder: (_, stateSnap) {
          final state = stateSnap.data;
          final playing = state?.playing == true &&
              state?.processingState != ProcessingState.completed;
          final buffering = state?.processingState == ProcessingState.loading ||
              state?.processingState == ProcessingState.buffering;
          return StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (_, posSnap) {
              final total = _player.duration ??
                  Duration(seconds: widget.knownSeconds ?? 0);
              final pos = posSnap.data ?? Duration.zero;
              final max = total.inMilliseconds <= 0
                  ? 1.0
                  : total.inMilliseconds.toDouble();
              return Row(
                children: [
                  IconButton(
                    key: const Key('audioPlayPause'),
                    onPressed: () async {
                      if (playing) {
                        await _player.pause();
                      } else {
                        if (state?.processingState == ProcessingState.completed) {
                          await _player.seek(Duration.zero);
                        }
                        await _player.play();
                      }
                    },
                    icon: buffering
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: StaffColors.primary))
                        : Icon(
                            playing
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            size: 36,
                            color: StaffColors.primary),
                  ),
                  Expanded(
                    child: Slider(
                      value:
                          pos.inMilliseconds.clamp(0, max.toInt()).toDouble(),
                      max: max,
                      activeColor: StaffColors.primary,
                      onChanged: (v) =>
                          _player.seek(Duration(milliseconds: v.toInt())),
                    ),
                  ),
                  Text(
                      '${formatCallDuration(pos.inSeconds)} / ${formatCallDuration(total.inSeconds)}',
                      style: AppText.labelMd
                          .copyWith(color: StaffColors.textMuted)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _VideoRecording extends StatefulWidget {
  const _VideoRecording({required this.url});
  final String url;

  @override
  State<_VideoRecording> createState() => _VideoRecordingState();
}

class _VideoRecordingState extends State<_VideoRecording> {
  late final VideoPlayerController _video =
      VideoPlayerController.networkUrl(Uri.parse(widget.url));
  ChewieController? _chewie;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _video.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _chewie = ChewieController(
          videoPlayerController: _video,
          autoPlay: true,
          allowFullScreen: true,
          showOptions: false,
          aspectRatio:
              _video.value.aspectRatio == 0 ? 16 / 9 : _video.value.aspectRatio,
        );
      });
    }).catchError((Object e) {
      if (mounted) setState(() => _error = 'Could not play the video');
    });
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chewie = _chewie;
    return ClipRRect(
      key: const Key('videoRecordingPlayer'),
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        color: const Color(0xFF0B1F3A),
        child: AspectRatio(
          aspectRatio: chewie?.aspectRatio ?? 16 / 9,
          child: _error.isNotEmpty
              ? Center(
                  child:
                      Text(_error, style: const TextStyle(color: Colors.white)))
              : chewie == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                  : Chewie(controller: chewie),
        ),
      ),
    );
  }
}
