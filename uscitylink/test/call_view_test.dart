import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/services/call/call_models.dart';
import 'package:uscitylink/services/call/call_service.dart';
import 'package:uscitylink/views/call/call_log_bubble.dart';
import 'package:uscitylink/views/call/call_view.dart';

/// Call screen states (lib/views/call/call_view.dart) and the call-log bubble.
void main() {
  Future<CallService> show(WidgetTester tester, void Function(CallService s) setup) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final service = CallService(); // not Get.put: no sockets / CallKit in tests
    service.peerName.value = 'Sukhdev Singh';
    service.peerSubtitle.value = 'Driver · U S CITYLINK INC';
    setup(service);
    await tester.pumpWidget(GetMaterialApp(home: CallView(service: service)));
    await tester.pump(const Duration(milliseconds: 50));
    return service;
  }

  String status(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('callStatus'))).data ?? '';

  testWidgets('outgoing: "Calling…", mute disabled until answered, hang up shown', (tester) async {
    await show(tester, (s) => s.phase.value = CallPhase.outgoing);
    expect(find.text('Sukhdev Singh'), findsOneWidget);
    expect(find.text('Driver · U S CITYLINK INC'), findsOneWidget);
    expect(status(tester), 'Calling…');
    expect(find.text('Cancel'), findsOneWidget);
    final mute = tester.widget<Opacity>(find.ancestor(of: find.text('Mute'), matching: find.byType(Opacity)).first);
    expect(mute.opacity, lessThan(1));
  });

  testWidgets('dispatch line: all busy → "You\'re #2 in line" with the waiting banner', (tester) async {
    final s = await show(tester, (s) {
      s.phase.value = CallPhase.queued;
      s.queuePosition.value = 2;
    });
    expect(status(tester), "You're #2 in line");
    expect(find.byKey(const Key('queueBanner')), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    s.queuePosition.value = 1;
    await tester.pump();
    expect(status(tester), "You're #1 in line");
    s.phase.value = CallPhase.outgoing;
    await tester.pump();
    expect(status(tester), 'Calling…');
    expect(find.byKey(const Key('queueBanner')), findsNothing);
  });

  testWidgets('recorded call: "Recorded" badge once connected, notice while it rings', (tester) async {
    const peer = CallPeer(id: 's1', name: 'Super Admin', role: 'staff');
    const recorded = CallInfo(
        callId: 'c1', type: 'audio', channelId: 'ch', channelName: 'U S CITYLINK INC', driverId: 'd1', from: peer, recording: true);
    final s = await show(tester, (s) {
      s.info.value = recorded;
      s.phase.value = CallPhase.incoming;
    });
    expect(find.byKey(const Key('recordedNotice')), findsOneWidget);
    expect(find.byKey(const Key('recordedBadge')), findsNothing);

    s.phase.value = CallPhase.active;
    s.recording.value = true;
    s.answeredAt.value = DateTime.now();
    await tester.pump();
    expect(find.byKey(const Key('recordedBadge')), findsOneWidget);
    expect(find.text('Recorded'), findsOneWidget);
    expect(find.byKey(const Key('recordedNotice')), findsNothing);
  });

  testWidgets('group call: everyone on it listed, muted marked, people being asked shown ringing', (tester) async {
    final s = await show(tester, (s) {
      s.peerName.value = 'Group call';
      s.phase.value = CallPhase.active;
      s.answeredAt.value = DateTime.now();
      s.members.assignAll(const [
        CallPeer(id: 'd1', name: 'Sukhdev Singh', role: 'driver'),
        CallPeer(id: 's2', name: 'Navneet', role: 'staff'),
      ]);
      s.pending.assignAll(const [CallPeer(id: 's3', name: 'Kashish', role: 'staff')]);
      s.mutedIds.add('s2');
    });
    expect(find.byKey(const Key('participants')), findsOneWidget);
    expect(find.text('Sukhdev Singh'), findsOneWidget);
    expect(find.text('Navneet'), findsOneWidget);
    expect(find.text('Kashish · ringing…'), findsOneWidget);
    expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);
    // Someone left: back to a normal 1-to-1 screen
    s.members.removeWhere((m) => m.id == 's2');
    s.pending.clear();
    await tester.pump();
    expect(find.byKey(const Key('participants')), findsNothing);
  });

  testWidgets('unanswered call: offers a voice message, then recording, then sent', (tester) async {
    final s = await show(tester, (s) {
      s.phase.value = CallPhase.ended;
      s.endedText.value = 'Nobody is available right now';
      s.voicemail.value = VoicemailState.offered;
    });
    expect(status(tester), 'Nobody is available right now');
    expect(find.text('Leave a message after the tone'), findsOneWidget);
    expect(find.byKey(const Key('voicemailRecord')), findsOneWidget);
    expect(find.byKey(const Key('voicemailClose')), findsOneWidget);

    // Recording (starts by itself after the beep): big seconds counter, hang up to send, delete link
    s.voicemail.value = VoicemailState.recording;
    s.voicemailSeconds.value = 7;
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('voicemailSeconds'))).data, '0:07');
    expect(find.text('Recording · up to 2:00'), findsOneWidget);
    expect(find.byKey(const Key('voicemailEnd')), findsOneWidget);
    expect(find.byKey(const Key('voicemailCancel')), findsOneWidget);
    s.voicemailSeconds.value = 110;
    await tester.pump();
    expect(find.text('10s left'), findsOneWidget);


    s.voicemail.value = VoicemailState.sending;
    await tester.pump();
    expect(find.text('Sending voice message…'), findsOneWidget);

    s.voicemail.value = VoicemailState.sent;
    await tester.pump();
    expect(find.text('Voice message sent'), findsWidgets);
  });

  testWidgets('hanging up sends the voice message', (tester) async {
    final s = await show(tester, (s) {
      s.phase.value = CallPhase.ended;
      s.voicemail.value = VoicemailState.recording;
      s.voicemailSeconds.value = 5;
    });
    await tester.tap(find.byKey(const Key('voicemailEnd')));
    await tester.pump(const Duration(milliseconds: 100));
    // No recorder in tests: sending is attempted, the recording is stopped and the screen leaves "recording"
    expect(s.voicemail.value, isNot(VoicemailState.recording));
    // No recorder in tests → "too short" snackbar; close it before the test tears the tree down
    await Get.closeCurrentSnackbar();
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a call that simply ended offers no voice message', (tester) async {
    await show(tester, (s) {
      s.phase.value = CallPhase.ended;
      s.endedText.value = 'Call ended · 1:02';
    });
    expect(find.byKey(const Key('voicemailRecord')), findsNothing);
  });

  testWidgets('staff on a call with a driver get Add and Transfer; drivers never do', (tester) async {
    const driver = CallPeer(id: 'd1', name: 'Sukhdev Singh', role: 'driver');
    final s = await show(tester, (s) {
      s.isStaffUser.value = true;
      s.phase.value = CallPhase.active;
      s.answeredAt.value = DateTime.now();
      s.members.assignAll(const [driver]);
    });
    expect(find.byKey(const Key('addPersonButton')), findsOneWidget);
    expect(find.byKey(const Key('transferButton')), findsOneWidget);

    // Full (6 people): Add is disabled
    s.members.assignAll([driver, for (var i = 2; i <= 6; i++) CallPeer(id: 's$i', name: 'Staff $i', role: 'staff')]);
    await tester.pump();
    final add = tester.widget<Opacity>(find.ancestor(of: find.text('Add'), matching: find.byType(Opacity)).first);
    expect(add.opacity, lessThan(1));

    // A driver's own app: no Add / Transfer
    s.isStaffUser.value = false;
    s.members.assignAll(const [CallPeer(id: 's1', name: 'Dispatch', role: 'staff')]);
    await tester.pump();
    expect(find.byKey(const Key('addPersonButton')), findsNothing);
    expect(find.byKey(const Key('transferButton')), findsNothing);
  });

  testWidgets('video call (driver): video layout, camera can\'t be turned off, flip + end shown', (tester) async {
    const staff = CallPeer(id: 's1', name: 'Navjot', role: 'staff');
    final s = await show(tester, (s) {
      s.peerName.value = 'Dispatch';
      s.isVideoCall.value = true;
      s.cameraOn.value = true;
      s.phase.value = CallPhase.active;
      s.answeredAt.value = DateTime.now();
      s.members.assignAll(const [staff]);
      s.remoteCamera.add('s1');
    });
    expect(find.byKey(const Key('videoLayout')), findsOneWidget);
    expect(find.byKey(const Key('tile-s1')), findsOneWidget);
    expect(find.byKey(const Key('selfView')), findsOneWidget);
    expect(find.byKey(const Key('videoCameraButton')), findsNothing, reason: 'drivers must keep the camera on');
    expect(find.byKey(const Key('flipCameraButton')), findsOneWidget);
    expect(find.byKey(const Key('videoHangupButton')), findsOneWidget);
    expect(find.byKey(const Key('videoAddButton')), findsNothing);
    // Staff on the same call: camera toggle + add/transfer
    s.isStaffUser.value = true;
    s.members.assignAll(const [CallPeer(id: 'd1', name: 'Sukhdev Singh', role: 'driver')]);
    await tester.pump();
    expect(find.byKey(const Key('videoCameraButton')), findsOneWidget);
    expect(find.byKey(const Key('videoAddButton')), findsOneWidget);
    expect(find.byKey(const Key('videoTransferButton')), findsOneWidget);
  });

  testWidgets('group video call shows a grid tile per person', (tester) async {
    await show(tester, (s) {
      s.isStaffUser.value = true;
      s.isVideoCall.value = true;
      s.phase.value = CallPhase.active;
      s.answeredAt.value = DateTime.now();
      s.members.assignAll(const [
        CallPeer(id: 'd1', name: 'Sukhdev Singh', role: 'driver'),
        CallPeer(id: 's2', name: 'Navjot', role: 'staff'),
        CallPeer(id: 's3', name: 'Kashish', role: 'staff'),
      ]);
      s.remoteCamera.addAll(['d1', 's2']);
    });
    expect(find.byKey(const Key('videoGrid')), findsOneWidget);
    for (final id in ['d1', 's2', 's3']) {
      expect(find.byKey(Key('tile-$id')), findsOneWidget);
    }
  });

  testWidgets('incoming video call: staff choose Voice or Video; drivers just answer (camera on)', (tester) async {
    const from = CallPeer(id: 'd1', name: 'Sukhdev Singh', role: 'driver');
    const video = CallInfo(callId: 'c1', type: 'video', channelId: 'ch', channelName: 'X', driverId: 'd1', from: from);
    final s = await show(tester, (s) {
      s.isStaffUser.value = true;
      s.info.value = video;
      s.phase.value = CallPhase.incoming;
    });
    expect(find.byKey(const Key('acceptVoiceButton')), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
    s.isStaffUser.value = false;
    await tester.pump();
    expect(find.byKey(const Key('acceptVoiceButton')), findsNothing);
    expect(find.byKey(const Key('acceptButton')), findsOneWidget);
  });

  testWidgets('voice call: Camera button turns it into video', (tester) async {
    await show(tester, (s) {
      s.phase.value = CallPhase.active;
      s.answeredAt.value = DateTime.now();
      s.members.assignAll(const [CallPeer(id: 's1', name: 'Dispatch', role: 'staff')]);
    });
    expect(find.byKey(const Key('cameraButton')), findsOneWidget);
    expect(find.byKey(const Key('videoLayout')), findsNothing);
  });

  testWidgets('call that is not recorded shows no recording badge', (tester) async {
    await show(tester, (s) {
      s.phase.value = CallPhase.active;
      s.answeredAt.value = DateTime.now();
    });
    expect(find.byKey(const Key('recordedBadge')), findsNothing);
  });

  testWidgets('incoming while the app is open: Accept and Decline, no call controls yet', (tester) async {
    await show(tester, (s) {
      s.peerName.value = 'U S CITYLINK INC';
      s.peerSubtitle.value = 'Dispatch · Super Admin';
      s.phase.value = CallPhase.incoming;
    });
    expect(status(tester), 'Incoming call…');
    expect(find.byKey(const Key('acceptButton')), findsOneWidget);
    expect(find.byKey(const Key('declineButton')), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.byKey(const Key('muteButton')), findsNothing);
    expect(find.byKey(const Key('hangupButton')), findsNothing);
  });

  testWidgets('on call: live timer, mute and speaker toggle', (tester) async {
    final s = await show(tester, (s) {
      s.phase.value = CallPhase.active;
      s.answeredAt.value = DateTime.now().subtract(const Duration(seconds: 65));
    });
    expect(status(tester), '1:05');
    await tester.tap(find.byKey(const Key('muteButton')));
    await tester.pump();
    expect(s.muted.value, isTrue);
    expect(find.text('Unmute'), findsOneWidget);
    await tester.tap(find.byKey(const Key('speakerButton')));
    await tester.pump();
    expect(s.speaker.value, isTrue);
  });

  testWidgets('network drop shows Reconnecting…; other side muted is shown', (tester) async {
    await show(tester, (s) {
      s.phase.value = CallPhase.active;
      s.answeredAt.value = DateTime.now();
      s.reconnecting.value = true;
      s.remoteMuted.value = true;
    });
    expect(status(tester), 'Reconnecting…');
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(find.text('They muted their microphone'), findsOneWidget);
  });

  testWidgets('ended: shows the outcome, no call controls', (tester) async {
    await show(tester, (s) {
      s.phase.value = CallPhase.ended;
      s.endedText.value = 'Call ended · 3:42';
    });
    expect(status(tester), 'Call ended · 3:42');
    expect(find.byKey(const Key('hangupButton')), findsNothing);
    expect(find.byKey(const Key('muteButton')), findsNothing);
  });

  testWidgets('call-log bubble wording for driver and staff', (tester) async {
    Widget bubble(String body, String dir, bool driver) => MaterialApp(
          home: Scaffold(body: CallLogBubble(message: MessageModel(body: body, messageDirection: dir), viewerIsDriver: driver)),
        );
    await tester.pumpWidget(bubble('Missed voice call', 'S', true));
    expect(find.textContaining('Dispatch called'), findsOneWidget);
    expect(find.byIcon(Icons.phone_missed_rounded), findsOneWidget);

    await tester.pumpWidget(bubble('Voice call · 3:42', 'R', true));
    expect(find.textContaining('You called dispatch'), findsOneWidget);
    expect(find.byIcon(Icons.call_made_rounded), findsOneWidget);

    await tester.pumpWidget(bubble('Voice call · 0:12', 'R', false));
    expect(find.textContaining('Driver called'), findsOneWidget);
    expect(find.byIcon(Icons.call_received_rounded), findsOneWidget);
  });

  test('duration format', () {
    expect(formatCallDuration(0), '0:00');
    expect(formatCallDuration(222), '3:42');
    expect(formatCallDuration(3725), '1:02:05');
  });
}
