import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/services/call/call_service.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';

/// Driver dashboard: call dispatch (rings the free dispatchers of the driver's channel, or waits in
/// line when they're all busy). Only the Call and video buttons place a call: tapping the rest of
/// the banner does nothing, so a stray tap never rings dispatch. While a call is on, the whole
/// banner is a way back to it.
/// Hidden when calling is switched off for everyone.
class CallDispatchCard extends StatelessWidget {
  const CallDispatchCard(
      {super.key,
      required this.channelId,
      required this.channelName,
      this.service});

  final String? channelId;
  final String? channelName;

  /// For tests; the app uses the registered CallService.
  final CallService? service;

  static const _green = Color(0xFF16A34A);
  static const _greenDeep = Color(0xFF15803D);

  @override
  Widget build(BuildContext context) {
    final call = service ??
        (Get.isRegistered<CallService>() ? Get.find<CallService>() : null);
    if (call == null) return const SizedBox.shrink();
    return Obx(() {
      if (!call.enabled.value) return const SizedBox.shrink();
      final onCall = call.busy;
      final title = onCall ? 'On a call' : 'Call Dispatch';
      final subtitle = onCall
          ? '${call.peerName.value.isEmpty ? 'Dispatch' : call.peerName.value} · tap to return'
          : (channelName?.isNotEmpty == true
              ? '$channelName · talk to your dispatcher'
              : 'Talk to your dispatcher');
      void callDispatch({bool video = false}) => call.startCall(
            channelId: channelId,
            name: channelName?.isNotEmpty == true ? channelName! : 'Dispatch',
            subtitle: 'Dispatch',
            video: video,
          );
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: Material(
          key: const Key('callDispatchCard'),
          color: Colors.transparent,
          child: InkWell(
            key: const Key('callDispatchBanner'),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            onTap: onCall ? call.openCallScreen : null,
            child: Ink(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: onCall
                      ? const [Color(0xFF0F766E), Color(0xFF115E59)]
                      : const [_green, _greenDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadii.lg),
                boxShadow: [
                  BoxShadow(
                      color: _green.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      onCall
                          ? Icons.phone_in_talk_rounded
                          : Icons.headset_mic_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title,
                            style: AppText.labelLg
                                .copyWith(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.labelMd.copyWith(
                              color: Colors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  // Video call to dispatch (camera on)
                  if (!onCall) ...[
                    const SizedBox(width: AppSpacing.md),
                    Material(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: const CircleBorder(),
                      child: InkWell(
                        key: const Key('videoCallDispatchCard'),
                        customBorder: const CircleBorder(),
                        onTap: () => callDispatch(video: true),
                        child: const Padding(
                          padding: EdgeInsets.all(AppSpacing.sm + 2),
                          child: Icon(Icons.videocam_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: AppSpacing.md),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    child: InkWell(
                      key: const Key('callDispatchButton'),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      onTap: onCall ? call.openCallScreen : callDispatch,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.base,
                            vertical: AppSpacing.sm + 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                onCall
                                    ? Icons.open_in_new_rounded
                                    : Icons.call_rounded,
                                size: 16,
                                color: _greenDeep),
                            const SizedBox(width: 6),
                            Text(
                              onCall ? 'Open' : 'Call',
                              style:
                                  AppText.labelLg.copyWith(color: _greenDeep),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
