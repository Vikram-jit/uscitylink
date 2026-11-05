import 'package:get/get.dart';
import 'package:uscitylink/services/call/call_service.dart';
import 'package:uscitylink/services/staff/notification_settings_service.dart';
import 'package:uscitylink/utils/staff_feedback.dart';

class NotificationSettingsController extends GetxController {
  final _service = NotificationSettingsService();

  /// Message notifications
  final mute = const NotificationMute().obs;
  /// Incoming call alerts (separate from messages)
  final callMute = const NotificationMute().obs;
  final loading = false.obs;
  final saving = false.obs;
  /// Which setting is being saved (spinner on that card only)
  final savingKind = Rxn<MuteKind>();

  bool get isMuted => mute.value.active;
  bool get isCallMuted => callMute.value.active;

  Future<void> load() async {
    loading.value = true;
    try {
      _apply(await _service.get());
    } catch (e) {
      staffSnackBar('Error', e.toString());
    } finally {
      loading.value = false;
    }
  }

  Future<void> muteFor({MuteKind kind = MuteKind.messages, int? minutes, bool forever = false}) =>
      _save(kind: kind, minutes: minutes, forever: forever);

  Future<void> unmute({MuteKind kind = MuteKind.messages}) => _save(kind: kind);

  void _apply(NotificationSettings s) {
    mute.value = s.messages;
    callMute.value = s.calls;
    // Calls that reach the open app are ignored while call alerts are muted
    if (Get.isRegistered<CallService>()) Get.find<CallService>().callMute = s.calls;
  }

  Future<void> _save({MuteKind kind = MuteKind.messages, int? minutes, bool forever = false}) async {
    if (saving.value) return;
    saving.value = true;
    savingKind.value = kind;
    try {
      _apply(await _service.set(kind: kind, minutes: minutes, forever: forever));
    } catch (e) {
      staffSnackBar('Could not update', e.toString());
    } finally {
      saving.value = false;
      savingKind.value = null;
    }
  }
}
