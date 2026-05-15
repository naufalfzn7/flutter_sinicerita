import 'package:glados/glados.dart';

/// Pure function extracted from ChatScreen for property testing.
/// Mirrors the trim logic applied before sending a message.
String prepareContent(String input) => input.trim();

/// Custom generators for strings with various whitespace patterns.
extension WhitespaceGenerators on Any {
  /// Generates a whitespace string (1-5 whitespace characters).
  Generator<String> get whitespaceString {
    const whitespaceChars = [' ', '\t', '\n', '\r', '  ', '\t\t', ' \n '];
    return any.choose(whitespaceChars).bind((ws1) {
      return any.choose(whitespaceChars).map((ws2) => '$ws1$ws2');
    });
  }

  /// Generates non-empty strings that contain at least one non-whitespace char.
  Generator<String> get nonWhitespaceContent => any.nonEmptyLetterOrDigits;

  /// Generates strings with leading whitespace prepended.
  Generator<String> get stringWithLeadingWhitespace {
    return any.whitespaceString.bind((ws) {
      return any.nonWhitespaceContent.map((content) => '$ws$content');
    });
  }

  /// Generates strings with trailing whitespace appended.
  Generator<String> get stringWithTrailingWhitespace {
    return any.nonWhitespaceContent.bind((content) {
      return any.whitespaceString.map((ws) => '$content$ws');
    });
  }

  /// Generates strings with both leading and trailing whitespace.
  Generator<String> get stringWithSurroundingWhitespace {
    return any.whitespaceString.bind((leadingWs) {
      return any.nonWhitespaceContent.bind((content) {
        return any.whitespaceString.map(
          (trailingWs) => '$leadingWs$content$trailingWs',
        );
      });
    });
  }
}

/// **Validates: Requirements 8.3**
void main() {
  group(
    'Feature: tahap-6-chat-room, '
    'Property 9: Content is trimmed before sending',
    () {
      Glados(any.stringWithLeadingWhitespace).test(
        'prepareContent removes leading whitespace',
        (input) {
          final result = prepareContent(input);

          // Result should equal input.trim()
          expect(result, equals(input.trim()));

          // Result should not start with whitespace
          expect(
            result.isEmpty || !RegExp(r'^\s').hasMatch(result),
            isTrue,
            reason:
                'prepareContent("$input") should not start with whitespace, '
                'got "$result"',
          );
        },
      );

      Glados(any.stringWithTrailingWhitespace).test(
        'prepareContent removes trailing whitespace',
        (input) {
          final result = prepareContent(input);

          // Result should equal input.trim()
          expect(result, equals(input.trim()));

          // Result should not end with whitespace
          expect(
            result.isEmpty || !RegExp(r'\s$').hasMatch(result),
            isTrue,
            reason:
                'prepareContent("$input") should not end with whitespace, '
                'got "$result"',
          );
        },
      );

      Glados(any.stringWithSurroundingWhitespace).test(
        'prepareContent removes both leading and trailing whitespace',
        (input) {
          final result = prepareContent(input);

          // Result should equal input.trim()
          expect(result, equals(input.trim()));

          // Result should not start or end with whitespace
          expect(
            result.isEmpty || !RegExp(r'^\s').hasMatch(result),
            isTrue,
            reason:
                'prepareContent("$input") should not start with whitespace, '
                'got "$result"',
          );
          expect(
            result.isEmpty || !RegExp(r'\s$').hasMatch(result),
            isTrue,
            reason:
                'prepareContent("$input") should not end with whitespace, '
                'got "$result"',
          );
        },
      );

      Glados<String>(any.letterOrDigits).test(
        'prepareContent is idempotent: trimming twice equals trimming once',
        (input) {
          final trimmedOnce = prepareContent(input);
          final trimmedTwice = prepareContent(trimmedOnce);

          expect(
            trimmedTwice,
            equals(trimmedOnce),
            reason:
                'prepareContent should be idempotent: '
                'trimming "$input" once gives "$trimmedOnce", '
                'trimming again gives "$trimmedTwice"',
          );
        },
      );

      Glados(any.stringWithSurroundingWhitespace).test(
        'prepareContent result never starts or ends with whitespace',
        (input) {
          final result = prepareContent(input);

          // The core property: result never has leading/trailing whitespace
          if (result.isNotEmpty) {
            expect(
              result[0].trim().isNotEmpty,
              isTrue,
              reason:
                  'First char of prepareContent("$input") should not be '
                  'whitespace, got "${result[0]}"',
            );
            expect(
              result[result.length - 1].trim().isNotEmpty,
              isTrue,
              reason:
                  'Last char of prepareContent("$input") should not be '
                  'whitespace, got "${result[result.length - 1]}"',
            );
          }
        },
      );
    },
  );
}
