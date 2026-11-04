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

class _CallViewState extends State<CallView>
    with SingleTickerProviderStateMixin {
  late final CallService call = widget.service ?? CallService.to;
  late final AnimationController _pulse;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Created here, not lazily: a call that opens straight into "on call" never touches it
    // before dispose()
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
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
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
    final s = parts.map((p) => p[0].toUpperCase()).join();
    return s.isEmpty ? '?' : s;
  }

  /// Staff list to add to the call or transfer it to.
  Future<void> _pickStaff(BuildContext context,
      {required bool transfer}) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF14325C),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => SafeArea(
        child: FutureBuilder(
          future: call.availableStaff(),
          builder: (context, snap) {
            final staff = snap.data ?? const [];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                  child: Text(
                    transfer
                        ? 'Transfer the call to — you leave when they pick up'
                        : 'Ask a staff member to join',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                if (snap.connectionState != ConnectionState.done)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                  )
                else if (staff.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No other staff online right now',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7))),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final s in staff)
                          ListTile(
                            key: Key('staff-${s.id}'),
                            enabled: !s.busy,
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF22C55E),
                              child: Text(_initials(s.name),
                                  style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(s.name,
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(s.busy ? 'On a call' : 'Online',
                                style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.6))),
                            onTap: () {
                              Navigator.of(sheet).pop();
                              call.addPerson(
                                  CallPeer(
                                      id: s.id, name: s.name, role: 'staff'),
                                  transfer: transfer);
                            },
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ),
    );
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
        return formatCallDuration(
            from == null ? 0 : DateTime.now().difference(from).inSeconds);
      case CallPhase.ended:
        return call.endedText.value.isEmpty
            ? 'Call ended'
            : call.endedText.value;
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
        // Leaving the screen while a voice message is being recorded throws the recording away
        onPopInvokedWithResult: (didPop, _) {
          if (didPop && call.voicemail.value == VoicemailState.recording)
            call.closeEndedScreen();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF0B1F3A),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF14325C),
                  Color(0xFF0B1F3A),
                  Color(0xFF07152A)
                ],
              ),
            ),
            child: SafeArea(
              // Scrolls only when the content is taller than the screen (short phones, big fonts, a
              // full group call); otherwise it fills the screen as before (Spacers keep working).
              // The Obx is inside the scroll wrapper: LayoutBuilder's builder isn't tracked by GetX.
              child: LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: IntrinsicHeight(
                      child: Obx(() {
                        final phase = call.phase.value;
                        final ringing = phase == CallPhase.outgoing ||
                            phase == CallPhase.connecting ||
                            phase == CallPhase.queued;
                        final ended = phase == CallPhase.ended;
                        return Column(
                          children: [
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock_outline_rounded,
                                    size: 13,
                                    color:
                                        Colors.white.withValues(alpha: 0.55)),
                                const SizedBox(width: 6),
                                Text('USCityLink voice call',
                                    style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.55),
                                        fontSize: 13)),
                              ],
                            ),
                            const Spacer(flex: 2),
                            _Avatar(
                                initials: _initials(call.peerName.value),
                                pulse: ringing ? _pulse : null,
                                ended: ended),
                            const SizedBox(height: 28),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                call.peerName.value,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.4),
                              ),
                            ),
                            if (call.peerSubtitle.value.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(call.peerSubtitle.value,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      fontSize: 15)),
                            ],
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (call.reconnecting.value && !ended) ...[
                                  const Icon(Icons.wifi_off_rounded,
                                      size: 16, color: Color(0xFFFBBF24)),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    _status(),
                                    key: const Key('callStatus'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: call.reconnecting.value && !ended
                                          ? const Color(0xFFFBBF24)
                                          : Colors.white
                                              .withValues(alpha: 0.85),
                                      fontSize: 17,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (phase == CallPhase.queued) ...[
                              const SizedBox(height: 10),
                              Container(
                                key: const Key('queueBanner'),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 32),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBBF24)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFFBBF24)
                                          .withValues(alpha: 0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.hourglass_top_rounded,
                                        size: 16, color: Color(0xFFFBBF24)),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'All dispatchers are on other calls. Stay on the line — the next free dispatcher will answer.',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            height: 1.35),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (call.recording.value &&
                                phase == CallPhase.active) ...[
                              const SizedBox(height: 10),
                              const _RecordedBadge(key: Key('recordedBadge')),
                            ] else if (phase == CallPhase.incoming &&
                                call.info.value?.recording == true) ...[
                              const SizedBox(height: 10),
                              Text('This call will be recorded',
                                  key: const Key('recordedNotice'),
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      fontSize: 13)),
                            ],
                            if ((call.isGroup || call.pending.isNotEmpty) &&
                                !ended &&
                                phase != CallPhase.incoming) ...[
                              const SizedBox(height: 14),
                              _Participants(call: call),
                            ],
                            if (call.remoteMuted.value &&
                                phase == CallPhase.active &&
                                !call.isGroup) ...[
                              const SizedBox(height: 8),
                              Text('They muted their microphone',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.6),
                                      fontSize: 13)),
                            ],
                            const Spacer(flex: 3),
                            if (phase == CallPhase.incoming)
                              // Ringing while the app is open: answer here
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 48),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  // Wrap, not Row: staff get 4 buttons (Mute, Speaker, Add, Transfer)
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: call.isStaffUser.value ? 18 : 64,
                                    runSpacing: 16,
                                    children: [
                                      _RoundButton(
                                        key: const Key('muteButton'),
                                        icon: call.muted.value
                                            ? Icons.mic_off_rounded
                                            : Icons.mic_none_rounded,
                                        label: call.muted.value
                                            ? 'Unmute'
                                            : 'Mute',
                                        active: call.muted.value,
                                        onTap: phase == CallPhase.outgoing ||
                                                phase == CallPhase.queued
                                            ? null
                                            : call.toggleMute,
                                      ),
                                      _RoundButton(
                                        key: const Key('speakerButton'),
                                        icon: call.speaker.value
                                            ? Icons.volume_up_rounded
                                            : Icons.volume_down_rounded,
                                        label: 'Speaker',
                                        active: call.speaker.value,
                                        onTap: call.toggleSpeaker,
                                      ),
                                      // Staff: bring someone in, or hand the call over (driver stays on)
                                      if (call.isStaffUser.value &&
                                          phase == CallPhase.active) ...[
                                        _RoundButton(
                                          key: const Key('addPersonButton'),
                                          icon: Icons.person_add_alt_1_rounded,
                                          label: 'Add',
                                          active: false,
                                          onTap: call.members.length +
                                                      call.pending.length +
                                                      1 <
                                                  CallService.maxParticipants
                                              ? () => _pickStaff(context,
                                                  transfer: false)
                                              : null,
                                        ),
                                        if (call.members
                                            .any((m) => m.role == 'driver'))
                                          _RoundButton(
                                            key: const Key('transferButton'),
                                            icon: Icons.swap_horiz_rounded,
                                            label: 'Transfer',
                                            active: false,
                                            onTap: () => _pickStaff(context,
                                                transfer: true),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 36),
                              if (!ended)
                                _BigCallButton(
                                  key: const Key('hangupButton'),
                                  color: const Color(0xFFEF4444),
                                  icon: Icons.call_end_rounded,
                                  label: phase == CallPhase.outgoing ||
                                          phase == CallPhase.queued
                                      ? 'Cancel'
                                      : 'End',
                                  onTap: call.hangup,
                                )
                              else if (call.voicemail.value !=
                                  VoicemailState.none)
                                _VoicemailPanel(call: call)
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
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.15), width: 4),
      ),
      child: Text(initials,
          style: const TextStyle(
              color: Colors.white, fontSize: 44, fontWeight: FontWeight.w700)),
    );
    final p = pulse;
    if (p == null)
      return SizedBox(width: 200, height: 200, child: Center(child: circle));
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
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF22C55E), width: 2)),
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
  const _BigCallButton(
      {super.key,
      required this.color,
      required this.icon,
      required this.label,
      required this.onTap});

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
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 10),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton(
      {super.key,
      required this.icon,
      required this.label,
      required this.active,
      this.onTap});

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
                child: Icon(icon,
                    color: active ? const Color(0xFF0B1F3A) : Colors.white,
                    size: 28),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
        ],
      ),
    );
  }
}

/// Red "Recorded" mark: the call is recorded and both people are told so.
class _RecordedBadge extends StatelessWidget {
  const _RecordedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fiber_manual_record, size: 12, color: Color(0xFFEF4444)),
          SizedBox(width: 6),
          Text('Recorded',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Group call: who is on it (muted ones marked) and who is still being asked to join.
class _Participants extends StatelessWidget {
  const _Participants({required this.call});

  final CallService call;

  @override
  Widget build(BuildContext context) {
    Widget row(CallPeer p, {bool ringing = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  p.role == 'driver'
                      ? Icons.local_shipping_rounded
                      : Icons.headset_mic_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: ringing ? 0.45 : 0.8)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  ringing ? '${p.name} · ringing…' : p.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color:
                          Colors.white.withValues(alpha: ringing ? 0.55 : 0.9),
                      fontSize: 14),
                ),
              ),
              if (ringing && call.isStaffUser.value) ...[
                const SizedBox(width: 4),
                InkWell(
                  key: Key('cancelAdd-${p.id}'),
                  onTap: () => call.cancelAdd(p.id),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: Colors.white.withValues(alpha: 0.6)),
                ),
              ],
              if (call.mutedIds.contains(p.id)) ...[
                const SizedBox(width: 6),
                const Icon(Icons.mic_off_rounded,
                    size: 15, color: Color(0xFFFBBF24)),
              ],
            ],
          ),
        );
    return Padding(
      key: const Key('participants'),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      // Up to 6 people: scrolls instead of pushing the call controls off a small screen
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 128),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ...call.members.map((m) => row(m)),
              ...call.pending.map((p) => row(p, ringing: true)),
            ],
          ),
        ),
      ),
    );
  }
}

/// After my call wasn't answered: leave a voice message in the chat (like a phone's voicemail).
/// It starts recording by itself after a beep; hanging up sends it ("Delete" throws it away).
class _VoicemailPanel extends StatelessWidget {
  const _VoicemailPanel({required this.call});

  final CallService call;

  // Own Obx: this widget builds outside the screen's Obx, so the ticking seconds must be watched here
  @override
  Widget build(BuildContext context) => Obx(_content);

  Widget _content() {
    final white70 = Colors.white.withValues(alpha: 0.7);
    switch (call.voicemail.value) {
      case VoicemailState.offered:
        // Before the beep (or if recording couldn't start): explain, and allow starting by hand
        return Column(
          key: const Key('voicemailOffer'),
          children: [
            Text('Leave a message after the tone',
                style: TextStyle(color: white70, fontSize: 15)),
            const SizedBox(height: 18),
            _BigCallButton(
              key: const Key('voicemailRecord'),
              color: const Color(0xFF2563EB),
              icon: Icons.mic_rounded,
              label: 'Record now',
              onTap: call.startVoicemail,
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('voicemailClose'),
              onPressed: call.closeEndedScreen,
              child:
                  Text('Close', style: TextStyle(color: white70, fontSize: 15)),
            ),
          ],
        );
      case VoicemailState.recording:
        final s = call.voicemailSeconds.value;
        final left = CallService.voicemailMaxSeconds - s;
        return Padding(
          key: const Key('voicemailRecording'),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _BlinkingDot(),
                  const SizedBox(width: 10),
                  Text(
                    formatCallDuration(s),
                    key: const Key('voicemailSeconds'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w300,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              Text(
                left <= 15
                    ? '${left}s left'
                    : 'Recording · up to ${formatCallDuration(CallService.voicemailMaxSeconds)}',
                style: TextStyle(
                    color: left <= 15 ? const Color(0xFFFBBF24) : white70,
                    fontSize: 14),
              ),
              const SizedBox(height: 28),
              // Hang up = the message is sent (like a phone's voicemail)
              _BigCallButton(
                key: const Key('voicemailEnd'),
                color: const Color(0xFFEF4444),
                icon: Icons.call_end_rounded,
                label: 'End · sends message',
                onTap: call.sendVoicemail,
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                key: const Key('voicemailCancel'),
                onPressed: call.closeEndedScreen,
                icon: Icon(Icons.delete_outline_rounded,
                    size: 18, color: white70),
                label: Text("Delete, don't send",
                    style: TextStyle(color: white70, fontSize: 14)),
              ),
            ],
          ),
        );
      case VoicemailState.sending:
        return Column(
          key: const Key('voicemailSending'),
          children: [
            const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3)),
            const SizedBox(height: 14),
            Text('Sending voice message…',
                style: TextStyle(color: white70, fontSize: 15)),
            const SizedBox(height: 40),
          ],
        );
      case VoicemailState.sent:
        return const Column(
          key: Key('voicemailSent'),
          children: [
            Icon(Icons.check_circle_rounded,
                color: Color(0xFF22C55E), size: 48),
            SizedBox(height: 10),
            Text('Voice message sent',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            SizedBox(height: 40),
          ],
        );
      case VoicemailState.none:
        return const SizedBox(height: 100);
    }
  }
}

/// Red recording dot that blinks.
class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.25).animate(_c),
        child: const Icon(Icons.fiber_manual_record,
            color: Color(0xFFEF4444), size: 16),
      );
}
