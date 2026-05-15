import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/core/utils/home_helpers.dart';

/// **Feature: tahap-4-main-navigation-profile, Property 1: Greeting function**
///
/// **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.7**
///
/// For any hour value (0–23) and any user name (including null, empty string,
/// or strings of arbitrary length), the getGreeting function SHALL return a
/// string that:
/// - Starts with "Selamat pagi" if hour is 0–10
/// - Starts with "Selamat siang" if hour is 11–14
/// - Starts with "Selamat sore" if hour is 15–17
/// - Starts with "Selamat malam" if hour is 18–23
/// - Contains no name suffix if name is null or empty
/// - Truncates the name to 30 characters followed by "..." if name length > 30
void main() {
  group(
    'Property 1: Greeting function produces correct time-based greeting '
    'with proper name handling',
    () {
      const int iterations = 200;
      final random = Random(42); // Fixed seed for reproducibility

      /// Generate a random nullable string of 0-100 characters.
      /// Returns null ~20% of the time, empty ~10% of the time.
      String? generateRandomName(Random rng) {
        final roll = rng.nextInt(10);
        if (roll < 2) return null; // 20% null
        if (roll < 3) return ''; // 10% empty

        final length = rng.nextInt(101); // 0-100 chars
        if (length == 0) return '';

        const chars =
            'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ '
            '0123456789áéíóúñ';
        return String.fromCharCodes(
          List.generate(length, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
        );
      }

      /// Returns the expected greeting prefix for a given hour.
      String expectedPrefix(int hour) {
        if (hour >= 0 && hour <= 10) return 'Selamat pagi';
        if (hour >= 11 && hour <= 14) return 'Selamat siang';
        if (hour >= 15 && hour <= 17) return 'Selamat sore';
        return 'Selamat malam';
      }

      test(
        'correct greeting prefix for all hours and proper name handling '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final hour = random.nextInt(24); // 0-23
            final name = generateRandomName(random);
            final result = getGreeting(hour, name);
            final prefix = expectedPrefix(hour);

            // 1. Result starts with correct greeting prefix
            expect(
              result.startsWith(prefix),
              isTrue,
              reason: 'Iteration $i: hour=$hour, name=$name — '
                  'expected to start with "$prefix", got "$result"',
            );

            // 2. If name is null or empty, result equals just the prefix
            if (name == null || name.isEmpty) {
              expect(
                result,
                equals(prefix),
                reason: 'Iteration $i: hour=$hour, name=$name — '
                    'expected just prefix "$prefix", got "$result"',
              );
            } else {
              // 3. If name is provided and ≤30 chars, result contains full name
              if (name.length <= 30) {
                expect(
                  result,
                  equals('$prefix, $name'),
                  reason: 'Iteration $i: hour=$hour, name="$name" (len=${name.length}) — '
                      'expected "$prefix, $name", got "$result"',
                );
                expect(
                  result.contains('...'),
                  isFalse,
                  reason: 'Iteration $i: name ≤30 chars should not have ellipsis',
                );
              } else {
                // 4. If name is >30 chars, result contains first 30 chars + "..."
                final truncated = name.substring(0, 30);
                expect(
                  result,
                  equals('$prefix, $truncated...'),
                  reason: 'Iteration $i: hour=$hour, name length=${name.length} — '
                      'expected "$prefix, $truncated...", got "$result"',
                );
                // Should NOT contain the full name
                expect(
                  result.contains(name),
                  isFalse,
                  reason: 'Iteration $i: truncated result should not contain full name',
                );
              }
            }
          }
        },
      );
    },
  );
}
