import 'dart:math';

import 'package:glados/glados.dart';
import 'package:sinicerita/core/utils/validators.dart';

// Feature: admin-panel, Property 3: Form validation rejects whitespace-only input
//
// **Validates: Requirements 5.2, 6.3**
//
// For any string composed entirely of whitespace characters (spaces, tabs,
// newlines, carriage returns, form feeds), the persona form validation SHALL
// reject it and report the field as required. For any string containing at
// least one non-whitespace character, the validation SHALL accept it (assuming
// length constraints are met).

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Glados property-based tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('Property 3: Form validation rejects whitespace-only input (Glados)',
      () {
    Glados(any.positiveIntOrZero).test(
      'whitespace-only strings are rejected with required error',
      (seed) {
        const whitespaceChars = [' ', '\t', '\n', '\r', '\f'];
        final random = Random(seed);

        // Generate a whitespace-only string of length 1..50
        final length = 1 + (seed % 50);
        final whitespaceStr = String.fromCharCodes(
          List.generate(length, (_) {
            final char = whitespaceChars[random.nextInt(whitespaceChars.length)];
            return char.codeUnitAt(0);
          }),
        );

        final result = Validators.validatePersonaField(whitespaceStr, 2000);

        expect(result, equals('Field ini wajib diisi'));
      },
    );

    Glados(any.lowercaseLetters).test(
      'strings with at least one non-whitespace char are accepted (within length)',
      (input) {
        // Skip empty strings (they would be rejected)
        if (input.isEmpty) return;

        // Ensure input is within max length
        final value = input.length > 100 ? input.substring(0, 100) : input;

        final result = Validators.validatePersonaField(value, 2000);

        expect(result, isNull);
      },
    );

    Glados(any.positiveIntOrZero).test(
      'null input is rejected with required error',
      (_) {
        final result = Validators.validatePersonaField(null, 2000);

        expect(result, equals('Field ini wajib diisi'));
      },
    );

    Glados(any.positiveIntOrZero).test(
      'empty string is rejected with required error',
      (_) {
        final result = Validators.validatePersonaField('', 100);

        expect(result, equals('Field ini wajib diisi'));
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Iteration-based tests (150+ iterations for comprehensive coverage)
  // ═══════════════════════════════════════════════════════════════════════════

  group(
      'Property 3: Form validation rejects whitespace-only input '
      '(iteration-based, 150 iterations)', () {
    const int iterations = 150;
    final random = Random(42);
    const whitespaceChars = [' ', '\t', '\n', '\r', '\f'];

    test('whitespace-only strings of varying length are rejected', () {
      for (var i = 0; i < iterations; i++) {
        // Generate random whitespace-only string of length 1..100
        final length = 1 + random.nextInt(100);
        final whitespaceStr = String.fromCharCodes(
          List.generate(length, (_) {
            final char = whitespaceChars[random.nextInt(whitespaceChars.length)];
            return char.codeUnitAt(0);
          }),
        );

        final result = Validators.validatePersonaField(whitespaceStr, 2000);

        expect(
          result,
          equals('Field ini wajib diisi'),
          reason: 'Iteration $i: whitespace-only string of length $length '
              'should be rejected',
        );
      }
    });

    test(
        'strings with at least one non-whitespace char are accepted '
        '(within max length)', () {
      for (var i = 0; i < iterations; i++) {
        // Generate a random string with at least one non-whitespace char
        // Length between 1..200, within maxLength of 2000
        final length = 1 + random.nextInt(200);
        final chars = List.generate(length, (_) {
          // Mix of printable ASCII chars (33..126 are non-whitespace)
          return 33 + random.nextInt(94);
        });

        // Optionally insert some whitespace to make it more realistic
        final insertCount = random.nextInt(5);
        for (var j = 0; j < insertCount && chars.length < 2000; j++) {
          final pos = random.nextInt(chars.length);
          final wsChar =
              whitespaceChars[random.nextInt(whitespaceChars.length)];
          chars.insert(pos, wsChar.codeUnitAt(0));
        }

        final value = String.fromCharCodes(chars);
        final result = Validators.validatePersonaField(value, 2000);

        expect(
          result,
          isNull,
          reason: 'Iteration $i: string with non-whitespace chars '
              '(length ${value.length}) should be accepted',
        );
      }
    });

    test('strings exceeding maxLength are rejected with length error', () {
      for (var i = 0; i < iterations; i++) {
        final maxLength = 10 + random.nextInt(90); // maxLength between 10..99
        // Generate string longer than maxLength with non-whitespace chars
        final length = maxLength + 1 + random.nextInt(50);
        final value = String.fromCharCodes(
          List.generate(length, (_) => 65 + random.nextInt(26)),
        );

        final result = Validators.validatePersonaField(value, maxLength);

        expect(
          result,
          equals('Maksimal $maxLength karakter'),
          reason: 'Iteration $i: string of length ${value.length} exceeding '
              'maxLength $maxLength should be rejected with length error',
        );
      }
    });

    test('single whitespace characters are all rejected', () {
      for (final ws in whitespaceChars) {
        final result = Validators.validatePersonaField(ws, 2000);
        expect(
          result,
          equals('Field ini wajib diisi'),
          reason: 'Single whitespace char "${ws.replaceAll('\n', '\\n')
              .replaceAll('\t', '\\t')
              .replaceAll('\r', '\\r')
              .replaceAll('\f', '\\f')}" '
              'should be rejected',
        );
      }
    });

    test('null input is rejected', () {
      final result = Validators.validatePersonaField(null, 100);
      expect(result, equals('Field ini wajib diisi'));
    });

    test('empty string is rejected', () {
      final result = Validators.validatePersonaField('', 100);
      expect(result, equals('Field ini wajib diisi'));
    });

    test('string at exactly maxLength with non-whitespace is accepted', () {
      for (var i = 0; i < iterations; i++) {
        final maxLength = 5 + random.nextInt(95); // 5..99
        final value = String.fromCharCodes(
          List.generate(maxLength, (_) => 65 + random.nextInt(26)),
        );

        final result = Validators.validatePersonaField(value, maxLength);

        expect(
          result,
          isNull,
          reason: 'Iteration $i: string at exactly maxLength $maxLength '
              'should be accepted',
        );
      }
    });
  });
}
