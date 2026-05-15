import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

/// Pure validation function extracted for property testing.
/// Mirrors the validation logic in ChatScreen._computeCanSend.
///
/// Returns true if the input is valid for sending:
/// - Trimmed content is not empty (at least 1 character)
/// - Trimmed content length does not exceed 5000 characters
bool canSend(String input) {
  final trimmed = input.trim();
  return trimmed.isNotEmpty && trimmed.length <= 5000;
}

/// **Validates: Requirements 8.1, 8.2, 8.4**
void main() {
  group(
    'Feature: tahap-6-chat-room, '
    'Property 8: Input validation controls send button state',
    () {
      final random = Random(42);
      const iterations = 150;

      // Helper: generate a random string of given length using printable chars
      String generateString(Random rng, int length) {
        const chars =
            'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
            '!@#\$%^&*()_+-=[]{}|;:,.<>? ';
        return List.generate(
          length,
          (_) => chars[rng.nextInt(chars.length)],
        ).join();
      }

      // Helper: generate whitespace-only string
      String generateWhitespace(Random rng) {
        const whitespaceChars = [' ', '\t', '\n', '\r', '  ', '\t\t'];
        final length = rng.nextInt(20) + 1;
        return List.generate(
          length,
          (_) => whitespaceChars[rng.nextInt(whitespaceChars.length)],
        ).join();
      }

      // Helper: generate valid content (1-5000 chars after trim)
      String generateValidContent(Random rng) {
        final length = rng.nextInt(5000) + 1; // 1-5000
        return generateString(rng, length).trimRight().isEmpty
            ? 'a${generateString(rng, length - 1)}'
            : generateString(rng, length);
      }

      // --- Core property: canSend is true iff trimmed length in [1, 5000] ---

      test(
        'canSend returns false for empty string',
        () {
          expect(canSend(''), isFalse);
        },
      );

      test(
        'canSend returns false for whitespace-only strings '
        'across $iterations random inputs',
        () {
          for (var i = 0; i < iterations; i++) {
            final input = generateWhitespace(random);
            expect(
              canSend(input),
              isFalse,
              reason:
                  'Whitespace-only input "${input.replaceAll('\n', '\\n').replaceAll('\t', '\\t')}" '
                  '(length=${input.length}) should disable send button',
            );
          }
        },
      );

      test(
        'canSend returns true for strings with trimmed length 1-5000 '
        'across $iterations random inputs',
        () {
          for (var i = 0; i < iterations; i++) {
            final trimmedLength = random.nextInt(5000) + 1; // 1-5000
            final content = generateString(random, trimmedLength);
            // Ensure at least one non-whitespace char
            final nonWhitespace =
                content.trim().isEmpty ? 'a' * trimmedLength : content;
            // Add optional leading/trailing whitespace
            final leadingWs = random.nextBool() ? '  ' : '';
            final trailingWs = random.nextBool() ? '  ' : '';
            final input = '$leadingWs$nonWhitespace$trailingWs';

            // Verify trimmed length is within bounds
            final actualTrimmedLength = input.trim().length;
            if (actualTrimmedLength >= 1 && actualTrimmedLength <= 5000) {
              expect(
                canSend(input),
                isTrue,
                reason:
                    'Input with trimmed length=$actualTrimmedLength '
                    'should enable send button',
              );
            }
          }
        },
      );

      test(
        'canSend returns false for strings with trimmed length > 5000 '
        'across $iterations random inputs',
        () {
          for (var i = 0; i < iterations; i++) {
            final extraLength = random.nextInt(1000) + 1; // 1-1000 extra
            final totalLength = 5001 + extraLength;
            final content = generateString(random, totalLength);
            // Ensure non-whitespace content
            final nonWhitespace =
                content.trim().length <= 5000 ? 'a' * totalLength : content;

            expect(
              canSend(nonWhitespace),
              isFalse,
              reason:
                  'Input with trimmed length=${nonWhitespace.trim().length} '
                  '(> 5000) should disable send button',
            );
          }
        },
      );

      test(
        'canSend boundary: exactly 5000 chars after trim returns true '
        'across $iterations random inputs',
        () {
          for (var i = 0; i < iterations; i++) {
            final content = generateString(random, 5000);
            // Ensure exactly 5000 non-whitespace chars
            final nonWhitespace =
                content.trim().length < 5000
                    ? 'a' * 5000
                    : content.trim().substring(0, 5000);

            expect(
              canSend(nonWhitespace),
              isTrue,
              reason:
                  'Input with exactly 5000 trimmed chars should enable send button',
            );
          }
        },
      );

      test(
        'canSend boundary: exactly 5001 chars after trim returns false '
        'across $iterations random inputs',
        () {
          for (var i = 0; i < iterations; i++) {
            final content = generateString(random, 5001);
            // Ensure exactly 5001 non-whitespace chars
            final nonWhitespace =
                content.trim().length < 5001
                    ? 'a' * 5001
                    : content.trim().substring(0, 5001);

            expect(
              canSend(nonWhitespace),
              isFalse,
              reason:
                  'Input with exactly 5001 trimmed chars should disable send button',
            );
          }
        },
      );

      test(
        'canSend boundary: exactly 1 char after trim returns true',
        () {
          // Single non-whitespace characters
          const singleChars = 'abcABC123!@#';
          for (final char in singleChars.split('')) {
            expect(
              canSend(char),
              isTrue,
              reason: 'Single char "$char" should enable send button',
            );
          }
          // With surrounding whitespace
          for (final char in singleChars.split('')) {
            expect(
              canSend('  $char  '),
              isTrue,
              reason:
                  'Single char "$char" with whitespace should enable send button',
            );
          }
        },
      );

      test(
        'canSend with leading/trailing whitespace: result depends on trimmed content '
        'across $iterations random inputs',
        () {
          for (var i = 0; i < iterations; i++) {
            // Generate content with random leading/trailing whitespace
            final coreLength = random.nextInt(6000); // 0-5999
            final core = coreLength == 0 ? '' : generateString(random, coreLength);
            final leadingWs = generateWhitespace(random);
            final trailingWs = generateWhitespace(random);
            final input = '$leadingWs$core$trailingWs';

            final trimmed = input.trim();
            final expectedCanSend =
                trimmed.isNotEmpty && trimmed.length <= 5000;

            expect(
              canSend(input),
              expectedCanSend,
              reason:
                  'Input with trimmed length=${trimmed.length} '
                  '(isEmpty=${trimmed.isEmpty}): '
                  'expected canSend=$expectedCanSend',
            );
          }
        },
      );

      test(
        'canSend property: for ANY string, result equals '
        '(trimmed.isNotEmpty && trimmed.length <= 5000) '
        'across $iterations random inputs',
        () {
          for (var i = 0; i < iterations; i++) {
            // Generate completely random input
            final length = random.nextInt(7000); // 0-6999
            final input = length == 0 ? '' : generateString(random, length);

            final trimmed = input.trim();
            final expectedCanSend =
                trimmed.isNotEmpty && trimmed.length <= 5000;

            expect(
              canSend(input),
              expectedCanSend,
              reason:
                  'Property violation: input length=$length, '
                  'trimmed length=${trimmed.length}, '
                  'trimmed isEmpty=${trimmed.isEmpty} '
                  '→ expected=$expectedCanSend, got=${canSend(input)}',
            );
          }
        },
      );
    },
  );
}
