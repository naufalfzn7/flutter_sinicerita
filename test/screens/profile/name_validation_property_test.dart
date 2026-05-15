import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

/// Pure validation function extracted for property testing.
/// Mirrors the _validateName logic in EditProfileScreen.
///
/// Returns error message string if invalid, null if valid.
String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Nama tidak boleh kosong';
  }
  if (value.trim().length > 50) {
    return 'Nama maksimal 50 karakter';
  }
  return null; // valid
}

/// **Validates: Requirements 13.8**
void main() {
  group(
    'Feature: tahap-4-main-navigation-profile, '
    'Property 12: Name validation',
    () {
      final random = Random(42);
      const iterations = 150;

      // Helper: generate a random whitespace-only string
      String generateWhitespaceString(Random rng) {
        const whitespaceChars = [' ', '\t', '\n', '\r', '\u000B', '\u000C'];
        final length = rng.nextInt(20) + 1; // 1-20 chars
        return List.generate(
          length,
          (_) => whitespaceChars[rng.nextInt(whitespaceChars.length)],
        ).join();
      }

      // Helper: generate a valid name string (1-50 chars with at least one non-whitespace)
      String generateValidName(Random rng) {
        const chars =
            'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
            'àáâãäåæçèéêëìíîïðñòóôõöùúûüýþÿ ';
        final length = rng.nextInt(50) + 1; // 1-50 chars
        final buffer = StringBuffer();
        // Ensure at least one non-whitespace character
        buffer.write(chars[rng.nextInt(chars.length - 1)]); // exclude last char (space)
        for (var i = 1; i < length; i++) {
          buffer.write(chars[rng.nextInt(chars.length)]);
        }
        return buffer.toString();
      }

      // Helper: generate a string > 50 chars (after trim)
      String generateTooLongName(Random rng) {
        const chars =
            'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        final length = 51 + rng.nextInt(50); // 51-100 chars
        return List.generate(
          length,
          (_) => chars[rng.nextInt(chars.length)],
        ).join();
      }

      test('rejects null input', () {
        final result = validateName(null);
        expect(result, isNotNull);
        expect(result, 'Nama tidak boleh kosong');
      });

      test('rejects empty string', () {
        final result = validateName('');
        expect(result, isNotNull);
        expect(result, 'Nama tidak boleh kosong');
      });

      test('rejects whitespace-only strings across $iterations random inputs',
          () {
        for (var i = 0; i < iterations; i++) {
          final whitespaceStr = generateWhitespaceString(random);
          final result = validateName(whitespaceStr);
          expect(
            result,
            isNotNull,
            reason:
                'Whitespace-only string "${whitespaceStr.replaceAll('\n', '\\n').replaceAll('\t', '\\t').replaceAll('\r', '\\r')}" '
                '(length=${whitespaceStr.length}) should be rejected',
          );
          expect(result, 'Nama tidak boleh kosong');
        }
      });

      test(
          'accepts valid names (non-empty, has non-whitespace, ≤50 chars) '
          'across $iterations random inputs', () {
        for (var i = 0; i < iterations; i++) {
          final validName = generateValidName(random);
          final result = validateName(validName);
          expect(
            result,
            isNull,
            reason:
                'Valid name "$validName" (trimmed length=${validName.trim().length}) '
                'should be accepted',
          );
        }
      });

      test('rejects strings longer than 50 chars across $iterations random inputs',
          () {
        for (var i = 0; i < iterations; i++) {
          final longName = generateTooLongName(random);
          final result = validateName(longName);
          expect(
            result,
            isNotNull,
            reason:
                'Name with trimmed length=${longName.trim().length} should be rejected',
          );
          expect(result, 'Nama maksimal 50 karakter');
        }
      });

      test('accepts exactly 50 character names across $iterations random inputs',
          () {
        const chars =
            'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        for (var i = 0; i < iterations; i++) {
          // Generate exactly 50 non-whitespace chars
          final name = List.generate(
            50,
            (_) => chars[random.nextInt(chars.length)],
          ).join();
          final result = validateName(name);
          expect(
            result,
            isNull,
            reason: 'Name with exactly 50 chars should be accepted',
          );
        }
      });

      test('rejects exactly 51 character names across $iterations random inputs',
          () {
        const chars =
            'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        for (var i = 0; i < iterations; i++) {
          // Generate exactly 51 non-whitespace chars
          final name = List.generate(
            51,
            (_) => chars[random.nextInt(chars.length)],
          ).join();
          final result = validateName(name);
          expect(
            result,
            isNotNull,
            reason: 'Name with exactly 51 chars should be rejected',
          );
          expect(result, 'Nama maksimal 50 karakter');
        }
      });

      test(
          'handles names with leading/trailing whitespace correctly '
          'across $iterations random inputs', () {
        const chars = 'abcdefghijklmnopqrstuvwxyz';
        for (var i = 0; i < iterations; i++) {
          // Generate a core name of 1-45 chars (so trimmed ≤ 50)
          final coreLength = random.nextInt(45) + 1;
          final core = List.generate(
            coreLength,
            (_) => chars[random.nextInt(chars.length)],
          ).join();

          // Add random leading/trailing whitespace
          final leadingSpaces = ' ' * (random.nextInt(5) + 1);
          final trailingSpaces = ' ' * (random.nextInt(5) + 1);
          final nameWithSpaces = '$leadingSpaces$core$trailingSpaces';

          final result = validateName(nameWithSpaces);
          // The trimmed length is coreLength which is ≤ 45, so should pass
          expect(
            result,
            isNull,
            reason:
                'Name "$nameWithSpaces" with trimmed content "$core" '
                '(length=$coreLength) should be accepted',
          );
        }
      });
    },
  );
}
