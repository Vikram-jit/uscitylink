import 'package:get/get.dart';
import 'package:uscitylink/services/staff/call_log_service.dart';

/// Staff → Call log: every call (same list as the web dashboard), filtered All / Missed / Answered.
class CallLogController extends GetxController {
  CallLogController({CallLogService? service}) : _service = service ?? CallLogService();
  final CallLogService _service;

  static const filters = {
    'All': null,
    'Missed': 'missed,cancelled,declined,busy',
    'Answered': 'completed',
  };

  final filter = 'All'.obs;
  final calls = <CallLogEntry>[].obs;
  final loading = false.obs;
  final loadingMore = false.obs;
  final error = ''.obs;
  int _page = 1;
  int _total = 0;

  bool get hasMore => calls.length < _total;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> setFilter(String f) async {
    if (filter.value == f) return;
    filter.value = f;
    calls.clear();
    await load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = '';
    try {
      final page = await _service.list(status: filters[filter.value], page: 1);
      _page = 1;
      _total = page.total;
      calls.assignAll(page.calls);
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (loading.value || loadingMore.value || !hasMore) return;
    loadingMore.value = true;
    try {
      final page = await _service.list(status: filters[filter.value], page: _page + 1);
      _page += 1;
      _total = page.total;
      calls.addAll(page.calls.where((c) => !calls.any((x) => x.id == c.id)));
    } catch (_) {
      // the next scroll tries again
    } finally {
      loadingMore.value = false;
    }
  }

  Future<CallLogDetail> detail(String callId) => _service.detail(callId);

  Future<CallRecordingLink> recordingLink(String callId) => _service.recordingLink(callId);
}
