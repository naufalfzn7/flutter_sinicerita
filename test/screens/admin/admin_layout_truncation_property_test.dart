import 'dart:math';

import 'package:glados/glados.dart';
import 'package:sinicerita/screens/admin/admin_layout.dart';

// Feature: admin-panel, Property 2: Admin name truncation
//
// **Validates: Requirements 2.2**
//
// For any string used as admin display name, if the string length exceeds 20
// characters, the displayed text SHALL be truncated to 20 characters followed
// by an ellipsis character (U+2026). If the string length is 20 or fewer
// characters, it SHALL be displayed in full without modification.

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Glados property-based tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('Property 2: Admin name truncation (Glados)', () {
    Glados(any.lowercaseLetters).test(
      'strings with length > 20 are truncated to 20 chars + ellipsis',
      (name) {
        // Only test strings longer than 20 characters
        if (name.length <= 20) return;

        final result = AdminLayout.truncateName(name);

        // Result should be first 20 chars + ellipsis (U+2026)
        expect(result.length, equals(21));
        expect(result.substring(0, 20), equals(name.substring(0, 20)));
        expect(result[20], equals('\u2026'));
      },
    );

    Glados(any.lowercaseLetters).test(
      'strings with length <= 20 are returned unchanged',
      (name) {
        // Only test strings of 20 or fewer characters
        if (name.length > 20) return;

        final result = AdminLayout.truncateName(name);

        expect(result, equals(name));
      },
    );

    Glados(any.positiveIntOrZero).test(
      'truncation boundary: exactly 20 chars unchanged, 21 chars truncated',
      (seed) {
        // Generate a string of exactly 20 characters — should be unchanged
        final name20 = String.fromCharCodes(
          List.generate(20, (i) => 97 + ((seed + i) % 26)),
        );
        final result20 = AdminLayout.truncateName(name20);
        expect(result20, equals(name20));
        expect(result20.length, equals(20));

        // Generate a string of exactly 21 characters — should be truncated
        final name21 = String.fromCharCodes(
          List.generate(21, (i) => 97 + ((seed + i) % 26)),
        );
        final result21 = AdminLayout.truncateName(name21);
        expect(result21.length, equals(21));
        expect(result21.substring(0, 20), equals(name21.substring(0, 20)));
        expect(result21[20], equals('\u2026'));
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Iteration-based tests (150+ iterations for comprehensive coverage)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Property 2: Admin name truncation (iteration-based, 150 iterations)',
      () {
    const int iterations = 150;
    final random = Random(42);

    test('strings > 20 chars are truncated to 20 + ellipsis', () {
      for (var i = 0; i < iterations; i++) {
        // Generate random string with length 21..200
        final length = 21 + random.nextInt(180);
        final name = String.fromCharCodes(
          List.generate(length, (_) => 32 + random.nextInt(95)),
        );

        final result = AdminLayout.truncateName(name);

        expect(
          result.length,
          equals(21),
          reason: 'Iteration $i: truncated result should have length 21 '
              '(20 chars + ellipsis), got ${result.length} for input '
              'length ${name.length}',
        );
        expect(
          result.substring(0, 20),
          equals(name.substring(0, 20)),
          reason: 'Iteration $i: first 20 chars should match original',
        );
        expect(
          result[20],
          equals('\u2026'),
          reason: 'Iteration $i: last char should be ellipsis (U+2026)',
        );
      }
    });

    test('strings <= 20 chars are returned unchanged', () {
      for (var i = 0; i < iterations; i++) {
        // Generate random string with length 0..20
        final length = random.nextInt(21);
        final name = String.fromCharCodes(
          List.generate(length, (_) => 32 + random.nextInt(95)),
        );

        final result = AdminLayout.truncateName(name);

        expect(
          result,
          equals(name),
          reason: 'Iteration $i: string of length ${name.length} (<= 20) '
              'should be returned unchanged',
        );
      }
    });

    test('boundary: exactly 20 characters — unchanged', () {
      for (var i = 0; i < iterations; i++) {
        final name = String.fromCharCodes(
          List.generate(20, (_) => 65 + random.nextInt(26)),
        );

        final result = AdminLayout.truncateName(name);

        expect(
          result,
          equals(name),
          reason: 'Iteration $i: exactly 20 chars should be unchanged',
        );
        expect(result.length, equals(20));
      }
    });

    test('boundary: exactly 21 characters — truncated', () {
      for (var i = 0; i < iterations; i++) {
        final name = String.fromCharCodes(
          List.generate(21, (_) => 65 + random.nextInt(26)),
        );

        final result = AdminLayout.truncateName(name);

        expect(
          result.length,
          equals(21),
          reason: 'Iteration $i: 21-char input should produce 21-char result',
        );
        expect(
          result.substring(0, 20),
          equals(name.substring(0, 20)),
          reason: 'Iteration $i: first 20 chars should match',
        );
        expect(
          result[20],
          equals('\u2026'),
          reason: 'Iteration $i: char at index 20 should be ellipsis',
        );
      }
    });

    test('empty string is returned unchanged', () {
      final result = AdminLayout.truncateName('');
      expect(result, equals(''));
    });
  });
}
