extension DateFormatExtension on String? {
  String formatDate() {
    if (this == null || this!.isEmpty) return "-";
    try {
      final d = DateTime.parse(this!);
      return "${d.day.toString().padLeft(2, '0')}/"
          "${d.month.toString().padLeft(2, '0')}/"
          "${d.year}";
    } catch (_) {
      return "-";
    }
  }
}
