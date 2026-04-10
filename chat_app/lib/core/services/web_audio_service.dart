import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────
// Web Audio Service
// Uses the browser's native Audio API via dart:js_interop.
// Works on Flutter Web + Wasm — no audioplayers plugin needed.
// ─────────────────────────────────────────────────────────────

class WebAudioService {
  WebAudioService._();

  static web.HTMLAudioElement? _audio;
  static int _playCount = 0;
  static int _maxPlays = 2;

  /// Call once in onInit to pre-load the audio asset.
  static void init({String src = 'assets/images/notification.wav'}) {
    if (!kIsWeb) return;
    _audio = web.HTMLAudioElement();
    _audio!.src = src;
    _audio!.preload = 'auto';
    _audio!.volume = 1.0;

    // Re-play up to [_maxPlays] times
    _audio!.addEventListener(
      'ended',
      (web.Event _) {
        _playCount++;
        if (_playCount < _maxPlays) {
          _audio!.currentTime = 0;
          _audio!.play();
        } else {
          _playCount = 0;
        }
      }.toJS,
    );
  }

  /// Play the notification sound.
  /// [maxPlays] — how many times to repeat (default 2).
  static void play({int maxPlays = 2}) {
    if (!kIsWeb || _audio == null) return;
    _maxPlays = maxPlays;
    _playCount = 0;
    _audio!.currentTime = 0;
    _audio!.play();
  }

  static void stop() {
    if (!kIsWeb || _audio == null) return;
    _audio!.pause();
    _audio!.currentTime = 0;
    _playCount = 0;
  }

  static void dispose() {
    stop();
    _audio = null;
  }
}
