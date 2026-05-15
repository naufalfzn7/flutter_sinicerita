import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Format scoreDelta dengan prefix tanda.
/// Positive: "+5", Negative: "-3" (natural), Zero: "0"
String formatScoreDelta(int delta) {
  if (delta > 0) return '+$delta';
  if (delta < 0) return '$delta';
  return '0';
}

/// Determine color for scoreDelta.
/// Positive: green, Negative: red, Zero: grey
Color getScoreDeltaColor(int delta) {
  if (delta > 0) return Colors.green;
  if (delta < 0) return Colors.red;
  return Colors.grey;
}

/// Check if analysis summary is effectively empty.
/// Returns true for null, empty string, or whitespace-only.
bool isAnalysisSummaryEmpty(String? summary) {
  return summary == null || summary.trim().isEmpty;
}

/// Truncate text to maxLength with ellipsis.
/// If text length exceeds maxLength, returns first maxLength characters + "...".
/// Otherwise returns the original text unchanged.
String truncateWithEllipsis(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}

/// Format DateTime to Indonesian locale string.
/// Example: "1 Januari 2024, 14:30"
String formatDateTimeIndonesian(DateTime dateTime) {
  return DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(dateTime);
}
