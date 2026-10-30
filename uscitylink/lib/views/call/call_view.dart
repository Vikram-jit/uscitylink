import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uscitylink/services/call/call_models.dart';
import 'package:uscitylink/services/call/call_service.dart';

/// Full-screen voice call (outgoing, connecting, on call, ended). Incoming ringing uses the phone's
/// native call screen (CallKit / Android full-screen), which opens this once answered.
class CallView extends StatefulWidget {
  const CallView({super.key, this.service});

  /// For tests; the app uses CallService.to.
  final CallService? service;

  @override
  State<CallView> createState() => _CallViewState();
}

class _CallViewState extends State<CallView> with SingleTickerProviderStateMixin {
  late final CallService call = widget.service ?? CallService.to;
  late final AnimationController _pulse;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Created here, not lazily: a call that opens straight into "on call" never touches it
    // before dispose()
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && call.phase.value == CallPhase.active) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
    final s = parts.map((p) => p[0].toUpperCase()).join();
    return s.isEmpty ? '?' : s;
  }

  String _status() {
    switch (call.phase.value) {
      case CallPhase.outgoing:
        return 'Calling…';
      case CallPhase.queued:
        final n = call.queuePosition.value;
        return n > 0 ? "You're #$n in line" : 'Waiting for a dispatcher…';
      case CallPhase.incoming:
        return 'Incoming call…';
      case CallPhase.connecting:
        return 'Connecting…';
      case CallPhase.active:
        if (call.reconnecting.value) return 'Reconnecting…';
        final from = call.answeredAt.value;
        return formatCallDuration(from == null ? 0 : DateTime.now().difference(from).inSeconds);
      case CallPhase.ended:
        return call.endedText.value.isEmpty ? 'Call ended' : call.endedText.value;
      case CallPhase.idle:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        // Hanging up is the way out of a live call; the call keeps running if the app goes to background
        canPop: !call.busy,
        child: Scaffold(
          backgroundColor: const Color(0xFF0B1F3A),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF14325C), Color(0xFF0B1F3A), Color(0xFF07152A)],
              ),
            ),
            child: SafeArea(
              child: Obx(() {
                final phase = call.phase.value;
                final ringing = phase == CallPhase.outgoing || phase == CallPhase.connecting || phase == CallPhase.queued;
                final ended = phase == CallPhase.ended;
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 13, color: Colors.white.withValues(alpha: 0.55)),
                        const SizedBox(width: 6),
                        Text('USCityLink voice call',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13)),
                      ],
                    ),
                    const Spacer(flex: 2),
                    _Avatar(initials: _initials(call.peerName.value), pulse: ringing ? _pulse : null, ended: ended),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        call.peerName.value,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.4),
                      ),
                    ),
                    if (call.peerSubtitle.value.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(call.peerSubtitle.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15)),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (call.reconnecting.value && !ended) ...[
                          const Icon(Icons.wifi_off_rounded, size: 16, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          _status(),
                          key: const Key('callStatus'),
                          style: TextStyle(
                            color: call.reconnecting.value && !ended ? const Color(0xFFFBBF24) : Colors.white.withValues(alpha: 0.85),
                            fontSize: 17,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    if (phase == CallPhase.queued) ...[
                      const SizedBox(height: 10),
                      Container(
                        key: const Key('queueBanner'),
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.hourglass_top_rounded, size: 16, color: Color(0xFFFBBF24)),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'All dispatchers are on other calls. Stay on the line — the next free dispatcher will answer.',
                                style: TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (call.remoteMuted.value && phase == CallPhase.active) ...[
                      const SizedBox(height: 8),
                      Text('They muted their microphone',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                    ],
                    const Spacer(flex: 3),
                    if (phase == CallPhase.incoming)
                      // Ringing while the app is open: answer here
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _BigCallButton(
                              key: const Key('declineButton'),
                              color: const Color(0xFFEF4444),
                              icon: Icons.call_end_rounded,
                              label: 'Decline',
                              onTap: () {
                                final id = call.callId;
                                if (id != null) call.declineCall(id);
                              },
                            ),
                            _BigCallButton(
                              key: const Key('acceptButton'),
                              color: const Color(0xFF22C55E),
                              icon: Icons.call_rounded,
                              label: 'Accept',
                              onTap: () {
                                final id = call.callId;
                                if (id != null) call.accept(id);
                              },
                            ),
                          ],
                        ),
                      )
                    else ...[
                      if (!ended)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _RoundButton(
                                key: const Key('muteButton'),
                                icon: call.muted.value ? Icons.mic_off_rounded : Icons.mic_none_rounded,
                                label: call.muted.value ? 'Unmute' : 'Mute',
                                active: call.muted.value,
                                onTap: phase == CallPhase.outgoing || phase == CallPhase.queued ? null : call.toggleMute,
                              ),
                              _RoundButton(
                                key: const Key('speakerButton'),
                                icon: call.speaker.value ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                                label: 'Speaker',
                                active: call.speaker.value,
                                onTap: call.toggleSpeaker,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 36),
                      if (!ended)
                        _BigCallButton(
                          key: const Key('hangupButton'),
                          color: const Color(0xFFEF4444),
                          icon: Icons.call_end_rounded,
                          label: phase == CallPhase.outgoing || phase == CallPhase.queued ? 'Cancel' : 'End',
                          onTap: call.hangup,
                        )
                      else
                        const SizedBox(height: 100),
                    ],
                    const SizedBox(height: 40),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, this.pulse, this.ended = false});

  final String initials;
  final Animation<double>? pulse;
  final bool ended;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 128,
      height: 128,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ended ? const Color(0xFF475569) : const Color(0xFF22C55E),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 4),
      ),
      child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w700)),
    );
    final p = pulse;
    if (p == null) return SizedBox(width: 200, height: 200, child: Center(child: circle));
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: p,
        builder: (context, child) => Stack(
          alignment: Alignment.center,
          children: [
            for (final offset in [0.0, 0.5])
              Builder(builder: (context) {
                final t = (p.value + offset) % 1.0;
                return Opacity(
                  opacity: (1 - t) * 0.5,
                  child: Container(
                    width: 128 + 72 * t,
                    height: 128 + 72 * t,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF22C55E), width: 2)),
                  ),
                );
              }),
            child!,
          ],
        ),
        child: circle,
      ),
    );
  }
}

class _BigCallButton extends StatelessWidget {
  const _BigCallButton({super.key, required this.color, required this.icon, required this.label, required this.onTap});

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({super.key, required this.icon, required this.label, required this.active, this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.14),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 64,
                height: 64,
                child: Icon(icon, color: active ? const Color(0xFF0B1F3A) : Colors.white, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
        ],
      ),
    );
  }
}
