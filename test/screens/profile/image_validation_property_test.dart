import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

/// Pure validation function extracted for testability.
/// Matches the logic in EditProfileScreen._pickImage().
bool isValidImage(int fileSize, String extension) {
  const maxSize = 5 * 1024 * 1024; // 5MB
  const validExtensions = ['jpg', 'jpeg', 'png'];
  return fileSize <= maxSize &&
      validExtensions.contains(extension.toLowerCase());
}

/// **Feature: tahap-4-main-navigation-profile, Property 11: Image validation**
///
/// **Validates: Requirements 13.3**
///
/// For any file with a given size (in bytes) and format (extension),
/// the image validation function SHALL:
/// - Accept files that are JPEG or PNG AND size ≤ 5 MB
/// - Reject files that are not JPEG or PNG regardless of size
/// - Reject files that exceed 5 MB regardless of format
void main() {
  group(
    'Property 11: Image file validation correctly accepts/rejects '
    'based on size and format',
    () {
      const int iterations = 200;
      final random = Random(42); // Fixed seed for reproducibility
      const maxTestSize = 20 * 1024 * 1024; // 20MB
      const maxValidSize = 5 * 1024 * 1024; // 5MB
      const allFormats = [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'bmp',
        'webp',
        'svg',
        'tiff',
      ];
      const validFormats = ['jpg', 'jpeg', 'png'];

      test(
        'accepts JPEG/PNG ≤ 5MB and rejects all others '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final fileSize = random.nextInt(maxTestSize + 1); // 0 to 20MB
            final format = allFormats[random.nextInt(allFormats.length)];
            final result = isValidImage(fileSize, format);

            final isValidFormat = validFormats.contains(format.toLowerCase());
            final isValidSize = fileSize <= maxValidSize;

            if (isValidFormat && isValidSize) {
              expect(
                result,
                isTrue,
                reason: 'Iteration $i: size=$fileSize, format=$format — '
                    'should ACCEPT (valid format + size ≤ 5MB)',
              );
            } else if (!isValidFormat) {
              expect(
                result,
                isFalse,
                reason: 'Iteration $i: size=$fileSize, format=$format — '
                    'should REJECT (invalid format)',
              );
            } else {
              // isValidFormat && !isValidSize
              expect(
                result,
                isFalse,
                reason: 'Iteration $i: size=$fileSize, format=$format — '
                    'should REJECT (size > 5MB)',
              );
            }
          }
        },
      );

      test(
        'rejects invalid formats regardless of size '
        '($iterations random iterations)',
        () {
          const invalidFormats = ['gif', 'bmp', 'webp', 'svg', 'tiff'];

          for (var i = 0; i < iterations; i++) {
            final fileSize = random.nextInt(maxValidSize + 1); // 0 to 5MB
            final format =
                invalidFormats[random.nextInt(invalidFormats.length)];
            final result = isValidImage(fileSize, format);

            expect(
              result,
              isFalse,
              reason: 'Iteration $i: size=$fileSize, format=$format — '
                  'should REJECT (invalid format even with valid size)',
            );
          }
        },
      );

      test(
        'rejects oversized files regardless of format '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            // Generate size strictly > 5MB
            final fileSize =
                maxValidSize + 1 + random.nextInt(maxTestSize - maxValidSize);
            final format = allFormats[random.nextInt(allFormats.length)];
            final result = isValidImage(fileSize, format);

            expect(
              result,
              isFalse,
              reason: 'Iteration $i: size=$fileSize, format=$format — '
                  'should REJECT (size > 5MB regardless of format)',
            );
          }
        },
      );

      test('boundary: exactly 5MB with valid format is accepted', () {
        expect(isValidImage(maxValidSize, 'jpg'), isTrue);
        expect(isValidImage(maxValidSize, 'jpeg'), isTrue);
        expect(isValidImage(maxValidSize, 'png'), isTrue);
      });

      test('boundary: 5MB + 1 byte with valid format is rejected', () {
        expect(isValidImage(maxValidSize + 1, 'jpg'), isFalse);
        expect(isValidImage(maxValidSize + 1, 'jpeg'), isFalse);
        expect(isValidImage(maxValidSize + 1, 'png'), isFalse);
      });

      test('boundary: 0 bytes with valid format is accepted', () {
        expect(isValidImage(0, 'jpg'), isTrue);
        expect(isValidImage(0, 'jpeg'), isTrue);
        expect(isValidImage(0, 'png'), isTrue);
      });

      test('case insensitivity: uppercase extensions are handled', () {
        expect(isValidImage(1024, 'JPG'), isTrue);
        expect(isValidImage(1024, 'JPEG'), isTrue);
        expect(isValidImage(1024, 'PNG'), isTrue);
        expect(isValidImage(1024, 'GIF'), isFalse);
        expect(isValidImage(1024, 'BMP'), isFalse);
      });
    },
  );
}
