import 'package:just_audio/just_audio.dart';

/// In-app call sounds (assets/sounds): the ringtone for an incoming call while the app is open, and
/// the ringback the caller hears while it rings. Stopped before the call audio starts.
class CallTones {
  static AudioPlayer? _player;
  static String? _playing;

  static Future<void> _loop(String asset) async {
    if (_playing == asset) return;
    await stop();
    try {
      final player = AudioPlayer();
      _player = player;
      _playing = asset;
      await player.setAsset(asset);
      await player.setLoopMode(LoopMode.one);
      await player.play();
    } catch (_) {
      // a missing sound must never break a call
    }
  }

  static Future<void> ringtone() => _loop('assets/sounds/call_ringtone.wav');

  /// Recorded call: two short beeps when it connects, so both people know it's recorded.
  static Future<void> recordingBeep() async {
    try {
      final player = AudioPlayer();
      await player.setAsset('assets/sounds/call_recording.wav');
      await player.play();
      await player.dispose();
    } catch (_) {
      // a missing sound must never break a call
    }
  }
  static Future<void> ringback() => _loop('assets/sounds/call_ringback.wav');

  static Future<void> stop() async {
    final player = _player;
    _player = null;
    _playing = null;
    try {
      await player?.stop();
      await player?.dispose();
    } catch (_) {}
  }
}
