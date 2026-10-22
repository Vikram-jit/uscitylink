import 'package:get/get.dart';
import 'package:uscitylink/services/staff/notification_settings_service.dart';
import 'package:uscitylink/utils/staff_feedback.dart';

class NotificationSettingsController extends GetxController {
  final _service = NotificationSettingsService();

  final mute = const NotificationMute().obs;
  final loading = false.obs;
  final saving = false.obs;

  /// A timed mute that has run out counts as on, even before the next refresh.
  bool get isMuted {
    final m = mute.value;
    if (!m.muted) return false;
    return m.forever || m.until == null || m.until!.isAfter(DateTime.now());
  }

  Future<void> load() async {
    loading.value = true;
    try {
      mute.value = await _service.get();
    } catch (e) {
      staffSnackBar('Error', e.toString());
    } finally {
      loading.value = false;
    }
  }

  Future<void> muteFor({int? minutes, bool forever = false}) => _save(minutes: minutes, forever: forever);

  Future<void> unmute() => _save();

  Future<void> _save({int? minutes, bool forever = false}) async {
    if (saving.value) return;
    saving.value = true;
    try {
      mute.value = await _service.set(minutes: minutes, forever: forever);
    } catch (e) {
      staffSnackBar('Could not update', e.toString());
    } finally {
      saving.value = false;
    }
  }
}
