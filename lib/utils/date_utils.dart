class DateUtils {
  /// Format: yyyy-MM-dd
  static String get today {
    final d = DateTime.now();
    return _format(d);
  }

  /// Format any DateTime to yyyy-MM-dd
  static String format(DateTime date) {
    return _format(date);
  }

  /// Get yesterday date
  static String get yesterday {
    final d = DateTime.now().subtract(const Duration(days: 1));
    return _format(d);
  }

  /// Get tomorrow date
  static String get tomorrow {
    final d = DateTime.now().add(const Duration(days: 1));
    return _format(d);
  }

  /// Format with time: yyyy-MM-dd HH:mm:ss
  static String formatWithTime(DateTime date) {
    return '${_format(date)} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')}';
  }

  /// Parse from yyyy-MM-dd string
  static DateTime parse(String date) {
    return DateTime.parse(date);
  }

  /// Internal formatter
  static String _format(DateTime d) {
    return '${d.year}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}
