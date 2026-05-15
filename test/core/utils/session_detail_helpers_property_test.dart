// Feature: session-detail-completed
// Properties 2, 3, 4, 5: Helper function property tests

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:glados/glados.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:sinicerita/core/utils/session_detail_helpers.dart';

/// Custom generators for property tests.
extension SessionDetailGenerators on Any {
  /// Generates whitespace-only strings (spaces, tabs, newlines).
  Generator<String> get whitespaceOnlyString {
    const whitespaceChars = [' ', '\t', '\n', '\r', '  ', '\t\t', ' \n '];
    return any.choose(whitespaceChars).bind((ws1) {
      return any.choose(whitespaceChars).map((ws2) => '$ws1$ws2');
    });
  }

  /// Generates strings guaranteed to have at least one non-whitespace char.
  Generator<String> get nonEmptyNonWhitespaceString {
    return any.nonEmptyLetterOrDigits;
  }

  /// Generates strings longer than a given length.
  Generator<String> longStringMinLength(int minLength) {
    return any.letterOrDigits.map((base) {
      if (base.length > minLength) return base;
      // Pad to exceed minLength
      final padding = 'A' * (minLength + 1 - base.length);
      return '$base$padding';
    });
  }

  /// Generates strings with length <= a given max.
  Generator<String> shortStringMaxLength(int maxLength) {
    return any.letterOrDigits.map((base) {
      if (base.length <= maxLength) return base;
      return base.substring(0, maxLength);
    });
  }
}

void main() {
  // Initialize Indonesian locale for date formatting tests.
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Property 2: ScoreDelta display formatting correctness
  // **Validates: Requirements 2.1, 2.2, 7.3**
  // ═══════════════════════════════════════════════════════════════════════════
  group(
    'Property 2: ScoreDelta display formatting correctness',
    () {
      Glados(any.intInRange(1, 21)).test(
        'formatScoreDelta returns string starting with "+" for positive delta',
        (delta) {
          final formatted = formatScoreDelta(delta);
          expect(
            formatted,
            startsWith('+'),
            reason: 'Positive delta=$delta should have "+" prefix, '
                'got "$formatted"',
          );
          expect(
            formatted,
            equals('+$delta'),
            reason: 'Positive delta=$delta should format as "+$delta", '
                'got "$formatted"',
          );
        },
      );

      Glados(any.intInRange(-20, 0)).test(
        'formatScoreDelta returns string starting with "-" for negative delta',
        (delta) {
          final formatted = formatScoreDelta(delta);
          expect(
            formatted,
            startsWith('-'),
            reason: 'Negative delta=$delta should start with "-", '
                'got "$formatted"',
          );
          expect(
            formatted,
            equals('$delta'),
            reason: 'Negative delta=$delta should format as "$delta", '
                'got "$formatted"',
          );
        },
      );

      test('formatScoreDelta returns "0" for zero delta', () {
        final formatted = formatScoreDelta(0);
        expect(formatted, equals('0'));
      });

      Glados(any.intInRange(1, 21)).test(
        'getScoreDeltaColor returns green for positive delta',
        (delta) {
          expect(
            getScoreDeltaColor(delta),
            equals(Colors.green),
            reason: 'Positive delta=$delta should be green',
          );
        },
      );

      Glados(any.intInRange(-20, 0)).test(
        'getScoreDeltaColor returns red for negative delta',
        (delta) {
          expect(
            getScoreDeltaColor(delta),
            equals(Colors.red),
            reason: 'Negative delta=$delta should be red',
          );
        },
      );

      test('getScoreDeltaColor returns grey for zero delta', () {
        expect(getScoreDeltaColor(0), equals(Colors.grey));
      });

      // Combined property: formatting and color are consistent with sign
      Glados(any.intInRange(-20, 21)).test(
        'scoreDelta formatting and color are consistent with sign',
        (delta) {
          final formatted = formatScoreDelta(delta);
          final color = getScoreDeltaColor(delta);

          if (delta > 0) {
            expect(formatted, startsWith('+'));
            expect(color, equals(Colors.green));
          } else if (delta < 0) {
            expect(formatted, startsWith('-'));
            expect(color, equals(Colors.red));
          } else {
            expect(formatted, equals('0'));
            expect(color, equals(Colors.grey));
          }
        },
      );
    },
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Property 3: Empty summary detection
  // **Validates: Requirements 3.3, 7.2**
  // ═══════════════════════════════════════════════════════════════════════════
  group(
    'Property 3: Empty summary detection',
    () {
      test('isAnalysisSummaryEmpty returns true for null', () {
        expect(isAnalysisSummaryEmpty(null), isTrue);
      });

      test('isAnalysisSummaryEmpty returns true for empty string', () {
        expect(isAnalysisSummaryEmpty(''), isTrue);
      });

      Glados(any.whitespaceOnlyString).test(
        'isAnalysisSummaryEmpty returns true for whitespace-only strings',
        (whitespace) {
          expect(
            isAnalysisSummaryEmpty(whitespace),
            isTrue,
            reason: 'Whitespace-only string "$whitespace" should be detected '
                'as empty',
          );
        },
      );

      Glados(any.nonEmptyNonWhitespaceString).test(
        'isAnalysisSummaryEmpty returns false for strings with '
        'non-whitespace chars',
        (text) {
          expect(
            isAnalysisSummaryEmpty(text),
            isFalse,
            reason: 'String "$text" with non-whitespace chars should not be '
                'detected as empty',
          );
        },
      );

      // Random iteration test covering mixed cases
      test(
        'isAnalysisSummaryEmpty: consistent with trim().isEmpty across '
        '100 random inputs',
        () {
          final random = Random(42);
          const chars = 'abcdefghijklmnopqrstuvwxyz \t\n\r';

          for (var i = 0; i < 100; i++) {
            final length = random.nextInt(20);
            final buffer = StringBuffer();
            for (var j = 0; j < length; j++) {
              buffer.write(chars[random.nextInt(chars.length)]);
            }
            final input = buffer.toString();
            final expected = input.trim().isEmpty;

            expect(
              isAnalysisSummaryEmpty(input),
              equals(expected),
              reason: 'Iteration $i: isAnalysisSummaryEmpty("$input") '
                  'should be $expected',
            );
          }
        },
      );
    },
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Property 4: Analysis summary truncation
  // **Validates: Requirements 7.1**
  // ═══════════════════════════════════════════════════════════════════════════
  group(
    'Property 4: Analysis summary truncation',
    () {
      Glados(any.shortStringMaxLength(50)).test(
        'truncateWithEllipsis returns unchanged string when length <= 50',
        (text) {
          if (text.isEmpty) return; // skip empty strings
          final result = truncateWithEllipsis(text, 50);
          expect(
            result,
            equals(text),
            reason: 'String of length ${text.length} (<= 50) should be '
                'unchanged, got "$result"',
          );
        },
      );

      Glados(any.longStringMinLength(50)).test(
        'truncateWithEllipsis truncates and adds "..." when length > 50',
        (text) {
          // Ensure text is actually > 50 chars
          if (text.length <= 50) return;

          final result = truncateWithEllipsis(text, 50);

          expect(
            result.length,
            equals(53),
            reason: 'Truncated result should be 53 chars (50 + "..."), '
                'got ${result.length}',
          );
          expect(
            result,
            endsWith('...'),
            reason: 'Truncated result should end with "..."',
          );
          expect(
            result.substring(0, 50),
            equals(text.substring(0, 50)),
            reason: 'First 50 chars should match original',
          );
        },
      );

      // Random iteration test for truncation correctness
      test(
        'truncateWithEllipsis: preserves or shortens correctly across '
        '100 random inputs',
        () {
          final random = Random(42);
          const chars = 'abcdefghijklmnopqrstuvwxyz0123456789 ';

          for (var i = 0; i < 100; i++) {
            // Generate strings of varying lengths (1 to 100)
            final length = random.nextInt(100) + 1;
            final buffer = StringBuffer();
            for (var j = 0; j < length; j++) {
              buffer.write(chars[random.nextInt(chars.length)]);
            }
            final text = buffer.toString();
            final result = truncateWithEllipsis(text, 50);

            if (text.length <= 50) {
              expect(
                result,
                equals(text),
                reason: 'Iteration $i: text of length ${text.length} '
                    'should be unchanged',
              );
            } else {
              expect(result.length, equals(53),
                  reason: 'Iteration $i: should be 53 chars');
              expect(result, endsWith('...'),
                  reason: 'Iteration $i: should end with "..."');
              expect(result.substring(0, 50), equals(text.substring(0, 50)),
                  reason: 'Iteration $i: first 50 chars should match');
            }
          }
        },
      );
    },
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Property 5: Date formatting produces valid Indonesian locale output
  // **Validates: Requirements 4.2**
  // ═══════════════════════════════════════════════════════════════════════════
  group(
    'Property 5: Date formatting produces valid Indonesian locale output',
    () {
      /// Indonesian month names for validation.
      const indonesianMonths = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];

      /// Pattern: "d MMMM yyyy, HH:mm"
      /// Examples: "1 Januari 2024, 14:30", "15 Desember 2023, 09:05"
      final dateFormatPattern = RegExp(
        r'^\d{1,2} (Januari|Februari|Maret|April|Mei|Juni|Juli|Agustus|September|Oktober|November|Desember) \d{4}, \d{2}:\d{2}$',
      );

      // Generate random DateTimes for property testing
      test(
        'formatDateTimeIndonesian produces valid pattern across '
        '100 random DateTimes',
        () {
          final random = Random(42);

          for (var i = 0; i < 100; i++) {
            final year = 2000 + random.nextInt(30); // 2000-2029
            final month = random.nextInt(12) + 1; // 1-12
            final day = random.nextInt(28) + 1; // 1-28 (safe for all months)
            final hour = random.nextInt(24); // 0-23
            final minute = random.nextInt(60); // 0-59

            final dateTime = DateTime(year, month, day, hour, minute);
            final result = formatDateTimeIndonesian(dateTime);

            // Verify pattern match
            expect(
              dateFormatPattern.hasMatch(result),
              isTrue,
              reason: 'Iteration $i: formatDateTimeIndonesian($dateTime) = '
                  '"$result" should match pattern "d MMMM yyyy, HH:mm"',
            );

            // Verify correct month name
            final expectedMonth = indonesianMonths[month - 1];
            expect(
              result.contains(expectedMonth),
              isTrue,
              reason: 'Iteration $i: result "$result" should contain '
                  'month "$expectedMonth" for month=$month',
            );

            // Verify correct year
            expect(
              result.contains('$year'),
              isTrue,
              reason: 'Iteration $i: result "$result" should contain '
                  'year "$year"',
            );

            // Verify 24-hour time format (HH:mm)
            final timePart = result.split(', ').last;
            final hourStr = timePart.split(':')[0];
            final minuteStr = timePart.split(':')[1];
            expect(
              int.parse(hourStr),
              equals(hour),
              reason: 'Iteration $i: hour should be $hour, got $hourStr',
            );
            expect(
              int.parse(minuteStr),
              equals(minute),
              reason: 'Iteration $i: minute should be $minute, '
                  'got $minuteStr',
            );
          }
        },
      );

      // Glados-based test with integer seeds to generate DateTimes
      Glados2(any.intInRange(1, 13), any.intInRange(1, 29)).test(
        'formatDateTimeIndonesian uses correct Indonesian month name',
        (month, day) {
          final dateTime = DateTime(2024, month, day, 10, 30);
          final result = formatDateTimeIndonesian(dateTime);

          final expectedMonth = indonesianMonths[month - 1];
          expect(
            result.contains(expectedMonth),
            isTrue,
            reason: 'Month $month should produce "$expectedMonth" in result, '
                'got "$result"',
          );
        },
      );

      Glados2(any.intInRange(0, 24), any.intInRange(0, 60)).test(
        'formatDateTimeIndonesian uses 24-hour time format',
        (hour, minute) {
          final dateTime = DateTime(2024, 6, 15, hour, minute);
          final result = formatDateTimeIndonesian(dateTime);

          // Extract time part after ", "
          final timePart = result.split(', ').last;
          final parts = timePart.split(':');
          final parsedHour = int.parse(parts[0]);
          final parsedMinute = int.parse(parts[1]);

          expect(
            parsedHour,
            equals(hour),
            reason: 'Hour should be $hour in 24h format, got $parsedHour '
                'in "$result"',
          );
          expect(
            parsedMinute,
            equals(minute),
            reason: 'Minute should be $minute, got $parsedMinute '
                'in "$result"',
          );
        },
      );

      // Verify day is correctly formatted (no leading zero)
      Glados(any.intInRange(1, 29)).test(
        'formatDateTimeIndonesian formats day without leading zero',
        (day) {
          final dateTime = DateTime(2024, 3, day, 8, 5);
          final result = formatDateTimeIndonesian(dateTime);

          // Day should appear at the start without leading zero
          expect(
            result,
            startsWith('$day '),
            reason: 'Day $day should appear without leading zero at start, '
                'got "$result"',
          );
        },
      );
    },
  );
}
