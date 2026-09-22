import '../utils/date_utils.dart';

/// امتدادات على [DateTime] للتنسيق والعرض العربي.
extension DateTimeX on DateTime {
  String get formatted => DateUtilsAr.formatDateTime(this);
  String get formattedTime => DateUtilsAr.formatTime(this);
  String get ago => DateUtilsAr.timeAgo(this);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
