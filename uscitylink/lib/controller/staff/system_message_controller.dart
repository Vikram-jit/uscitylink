import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/model/staff/compliance_models.dart';
import 'package:uscitylink/services/staff/system_message_service.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/utils/staff_feedback.dart';

/// System messages (yard gate events) — same behaviour as the web "System Messages" page:
/// search, completed-by and date filters, paging, an unread popup, and "Mark completed" that asks
/// for a note when no matching security gate log exists.
class SystemMessageController extends GetxController {
  static const minNoteLength = 10;
  final _service = SystemMessageService();

  final messages = <SystemMessage>[].obs;
  final unread = <SystemMessage>[].obs;
  final staff = <StaffUser>[].obs;
  final loading = false.obs;
  final markingId = ''.obs;

  final searchController = TextEditingController();
  final completedBy = ''.obs;
  final startDate = ''.obs; // YYYY-MM-DD
  final endDate = ''.obs;

  int _page = 1;
  int _totalPages = 1;
  Timer? _debounce;

  bool get hasMore => _page < _totalPages;
  bool get hasFilters => completedBy.value.isNotEmpty || startDate.value.isNotEmpty || endDate.value.isNotEmpty;

  @override
  void onClose() {
    _debounce?.cancel();
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadUnread() async {
    try {
      unread.assignAll(await _service.unread());
    } catch (_) {
      // Badge only: keep the last value if offline
    }
  }

  Future<void> loadStaff() async {
    if (staff.isNotEmpty) return;
    try {
      staff.assignAll(await _service.staffUsers());
    } catch (_) {}
  }

  Future<void> load({bool reset = true}) async {
    if (loading.value) return;
    loading.value = true;
    try {
      if (reset) _page = 1;
      final res = await _service.list(
        page: _page,
        search: searchController.text.trim(),
        completedBy: completedBy.value,
        startDate: startDate.value,
        endDate: endDate.value,
      );
      _totalPages = res.totalPages;
      if (reset) {
        messages.assignAll(res.messages);
      } else {
        final known = messages.map((m) => m.id).toSet();
        messages.addAll(res.messages.where((m) => !known.contains(m.id)));
      }
    } catch (e) {
      staffSnackBar('Error', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || loading.value) return;
    _page += 1;
    await load(reset: false);
  }

  void onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => load());
  }

  void setCompletedBy(String id) {
    completedBy.value = id;
    load();
  }

  void setDates(String start, String end) {
    startDate.value = start;
    endDate.value = end;
    load();
  }

  void clearFilters() {
    completedBy.value = '';
    startDate.value = '';
    endDate.value = '';
    load();
  }

  /// Returns the server's answer; when [CompleteResult.requiresNote] the screen asks for a note.
  Future<CompleteResult> complete(SystemMessage message, {String? note}) async {
    markingId.value = message.id;
    try {
      final result = await _service.complete(message.id, note: note);
      if (result.ok) {
        Utils.toastMessage(result.message);
        await Future.wait([load(), loadUnread()]);
      } else if (!result.requiresNote) {
        staffSnackBar('Not completed', result.message);
      }
      return result;
    } finally {
      markingId.value = '';
    }
  }
}
