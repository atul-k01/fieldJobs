import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateFormat = DateFormat('EEE, MMM d, yyyy');
  static final DateFormat _shortDate = DateFormat('MMM d');
  static final DateFormat _timeFormat = DateFormat('h:mm a');

  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }

  static String formatShortDate(DateTime dateTime) {
    return _shortDate.format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  static bool isUpcoming(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return targetDate.isAfter(today);
  }
}
