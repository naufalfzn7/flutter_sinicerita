import 'package:intl/intl.dart';

/// Returns time-based greeting string.
/// Extracted as pure function for testability.
///
/// Time ranges:
/// - 00:00–10:59 → "Selamat pagi"
/// - 11:00–14:59 → "Selamat siang"
/// - 15:00–17:59 → "Selamat sore"
/// - 18:00–23:59 → "Selamat malam"
///
/// If [userName] is provided and non-empty, appends ", {name}" to the greeting.
/// Names longer than 30 characters are truncated with "...".
String getGreeting(int hour, String? userName) {
  final String timeGreeting;
  if (hour >= 0 && hour < 11) {
    timeGreeting = 'Selamat pagi';
  } else if (hour >= 11 && hour < 15) {
    timeGreeting = 'Selamat siang';
  } else if (hour >= 15 && hour < 18) {
    timeGreeting = 'Selamat sore';
  } else {
    timeGreeting = 'Selamat malam';
  }

  if (userName == null || userName.isEmpty) {
    return timeGreeting;
  }

  final displayName =
      userName.length > 30 ? '${userName.substring(0, 30)}...' : userName;
  return '$timeGreeting, $displayName';
}

/// Returns daily tip index based on date.
/// Same tip shown all day, different tip each day.
///
/// Uses day-of-year as seed for consistent daily rotation.
/// Returns an index in the range [0, tipsCount).
int getDailyTipIndex(DateTime date, int tipsCount) {
  final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
  return dayOfYear % tipsCount;
}

/// Returns status text and color category based on points.
///
/// Point ranges:
/// - 0–39 → red, "Kamu butuh perhatian lebih, yuk cerita"
/// - 40–69 → yellow, "Keadaanmu cukup stabil, tetap semangat"
/// - 70–100 → green, "Keadaanmu baik, pertahankan ya!"
({String text, String colorCategory}) getScoreStatus(int points) {
  if (points <= 39) {
    return (
      text: 'Kamu butuh perhatian lebih, yuk cerita',
      colorCategory: 'red',
    );
  } else if (points <= 69) {
    return (
      text: 'Keadaanmu cukup stabil, tetap semangat',
      colorCategory: 'yellow',
    );
  } else {
    return (text: 'Keadaanmu baik, pertahankan ya!', colorCategory: 'green');
  }
}

/// Formats a DateTime as relative time string in Bahasa Indonesia.
/// Returns "Baru saja", "X menit lalu", "X jam lalu", or formatted date if > 24h.
String formatRelativeTime(DateTime dateTime, DateTime now) {
  final diff = now.difference(dateTime);

  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';

  // Older than 24h: show date
  return DateFormat('dd MMM yyyy', 'id').format(dateTime);
}
