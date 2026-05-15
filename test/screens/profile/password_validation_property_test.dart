import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

/// Pure validation functions extracted for property testing.
/// Mirrors the validation logic in ChangePasswordScreen.

String? validateOldPassword(String? value) {
  if (value == null || value.isEmpty) return 'Password lama tidak boleh kosong';
  return null;
}

String? validateNewPassword(String? value) {
  if (value == null || value.isEmpty) return 'Password baru tidak boleh kosong';
  if (value.length < 8) return 'Password baru minimal 8 karakter';
  if (value.length > 128) return 'Password baru maksimal 128 karakter';
  return null;
}

String? validateConfirmPassword(String? value, String newPassword) {
  if (value == null || value.isEmpty) {
    return 'Konfirmasi password tidak boleh kosong';
  }
  if (value != newPassword) return 'Konfirmasi password tidak cocok';
  return null;
}

/// Combined validation: returns true only when ALL three pass.
bool isPasswordFormValid(
  String oldPassword,
  String newPassword,
  String confirmPassword,
) {
  return validateOldPassword(oldPassword) == null &&
      validateNewPassword(newPassword) == null &&
      validateConfirmPassword(confirmPassword, newPassword) == null;
}

/// **Validates: Requirements 14.2**
void main() {
  group(
    'Feature: tahap-4-main-navigation-profile, '
    'Property 13: Password validation',
    () {
      final random = Random(42);
      const iterations = 150;

      // Helper: generate a random string of given length
      String generateString(Random rng, int length) {
        const chars =
            'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
            '!@#\$%^&*()_+-=[]{}|;:,.<>?';
        return List.generate(
          length,
          (_) => chars[rng.nextInt(chars.length)],
        ).join();
      }

      // Helper: generate a valid password (8-128 chars)
      String generateValidPassword(Random rng) {
        final length = rng.nextInt(121) + 8; // 8-128
        return generateString(rng, length);
      }

      // --- validateOldPassword tests ---

      test('validateOldPassword rejects null', () {
        expect(validateOldPassword(null), isNotNull);
        expect(validateOldPassword(null), 'Password lama tidak boleh kosong');
      });

      test('validateOldPassword rejects empty string', () {
        expect(validateOldPassword(''), isNotNull);
        expect(validateOldPassword(''), 'Password lama tidak boleh kosong');
      });

      test(
        'validateOldPassword accepts any non-empty string '
        'across $iterations random inputs',
        () {
          for (var i = 0; i < iterations; i++) {
            final length = random.nextInt(200) + 1; // 1-200 chars
            final password = generateString(random, length);
            final result = validateOldPassword(password);
            expect(
              result,
              isNull,
              reason:
                  'Non-empty old password "$password" (length=$length) '
                  'should be accepted',
            );
          }
        },
      );

      // --- validateNewPassword tests ---

      test('validateNewPassword rejects null', () {
        expect(validateNewPassword(null), isNotNull);
        expect(validateNewPassword(null), 'Password baru tidak boleh kosong');
      });

      test('validateNewPassword rejects empty string', () {
        expect(validateNewPassword(''), isNotNull);
        expect(validateNewPassword(''), 'Password baru tidak boleh kosong');
      });

      test(
        'validateNewPassword rejects strings shorter than 8 chars '
        'across $iterations random inputs',
        () {
          for (var i = 0; i < iterations; i++) {
            final length = random.nextInt(7) + 1; // 1-7 chars
            final password = generateString(random, length);
            final result = validateNewPassword(password);
            expect(
              result,
              isNotNull,
              reason:
                  'Short password "$password" (length=$length) '
                  'should be rejected',
            );
            expect(result, 'Password baru minimal 8 karakter');
          }
        },
      );

      test(
        'validateNewPassword rejects strings longer than 128 chars '
        'across $iterations random inputs',
        () {
          for (var i = 0; i < iterations; i++) {
            final length = 129 + random.nextInt(72); // 129-200 chars
            final password = generateString(random, length);
            final result = validateNewPassword(password);
            expect(
              result,
              isNotNull,
              reason:
                  'Long password (length=$length) should be rejected',
            );
            expect(result, 'Password baru maksimal 128 karakter');
          }
        },
      );

      test(
        'validateNewPassword accepts strings of 8-128 chars '
        'across $iterations random inputs',
        () {
          for (var i = 0; i < iterations; i++) {
            final password = generateValidPassword(random);
            final result = validateNewPassword(password);
            expect(
              result,
              isNull,
              reason:
                  'Valid password (length=${password.length}) '
                  'should be accepted',
            );
          }
        },
      );

      test('validateNewPassword boundary: exactly 8 chars accepted', () {
        for (var i = 0; i < iterations; i++) {
          final password = generateString(random, 8);
          expect(
            validateNewPassword(password),
            isNull,
            reason: 'Password with exactly 8 chars should be accepted',
          );
        }
      });

      test('validateNewPassword boundary: exactly 128 chars accepted', () {
        for (var i = 0; i < iterations; i++) {
          final password = generateString(random, 128);
          expect(
            validateNewPassword(password),
            isNull,
            reason: 'Password with exactly 128 chars should be accepted',
          );
        }
      });

      // --- validateConfirmPassword tests ---

      test('validateConfirmPassword rejects null', () {
        expect(validateConfirmPassword(null, 'anypassword'), isNotNull);
        expect(
          validateConfirmPassword(null, 'anypassword'),
          'Konfirmasi password tidak boleh kosong',
        );
      });

      test('validateConfirmPassword rejects empty string', () {
        expect(validateConfirmPassword('', 'anypassword'), isNotNull);
        expect(
          validateConfirmPassword('', 'anypassword'),
          'Konfirmasi password tidak boleh kosong',
        );
      });

      test(
        'validateConfirmPassword rejects mismatched passwords '
        'across $iterations random inputs',
        () {
          for (var i = 0; i < iterations; i++) {
            final newPassword = generateValidPassword(random);
            // Generate a different confirm password
            String confirmPassword;
            do {
              final length = random.nextInt(200) + 1;
              confirmPassword = generateString(random, length);
            } while (confirmPassword == newPassword);

            final result = validateConfirmPassword(confirmPassword, newPassword);
            expect(
              result,
              isNotNull,
              reason:
                  'Mismatched confirm "$confirmPassword" vs new "$newPassword" '
                  'should be rejected',
            );
            expect(result, 'Konfirmasi password tidak cocok');
          }
        },
      );

      test(
        'validateConfirmPassword accepts matching passwords '
        'across $iterations random inputs',
        () {
          for (var i = 0; i < iterations; i++) {
            final password = generateValidPassword(random);
            final result = validateConfirmPassword(password, password);
            expect(
              result,
              isNull,
              reason:
                  'Matching confirm password "$password" should be accepted',
            );
          }
        },
      );

      // --- Combined isPasswordFormValid tests ---

      test(
        'isPasswordFormValid returns true ONLY when all three validations pass '
        'across $iterations random inputs',
        () {
          for (var i = 0; i < iterations; i++) {
            final oldPassword = generateValidPassword(random);
            final newPassword = generateValidPassword(random);
            final confirmPassword = newPassword; // matching

            final result = isPasswordFormValid(
              oldPassword,
              newPassword,
              confirmPassword,
            );
            expect(
              result,
              isTrue,
              reason:
                  'All valid inputs should produce true: '
                  'old="$oldPassword", new="$newPassword", confirm="$confirmPassword"',
            );
          }
        },
      );

      test(
        'isPasswordFormValid returns false when old password is empty',
        () {
          for (var i = 0; i < iterations; i++) {
            final newPassword = generateValidPassword(random);
            final result = isPasswordFormValid('', newPassword, newPassword);
            expect(
              result,
              isFalse,
              reason: 'Empty old password should make form invalid',
            );
          }
        },
      );

      test(
        'isPasswordFormValid returns false when new password is too short '
        'across $iterations random inputs',
        () {
          for (var i = 0; i < iterations; i++) {
            final oldPassword = generateValidPassword(random);
            final length = random.nextInt(7) + 1; // 1-7 chars
            final newPassword = generateString(random, length);
            final result = isPasswordFormValid(
              oldPassword,
              newPassword,
              newPassword,
            );
            expect(
              result,
              isFalse,
              reason:
                  'New password too short (length=$length) '
                  'should make form invalid',
            );
          }
        },
      );

      test(
        'isPasswordFormValid returns false when new password is too long '
        'across $iterations random inputs',
        () {
          for (var i = 0; i < iterations; i++) {
            final oldPassword = generateValidPassword(random);
            final length = 129 + random.nextInt(72); // 129-200 chars
            final newPassword = generateString(random, length);
            final result = isPasswordFormValid(
              oldPassword,
              newPassword,
              newPassword,
            );
            expect(
              result,
              isFalse,
              reason:
                  'New password too long (length=$length) '
                  'should make form invalid',
            );
          }
        },
      );

      test(
        'isPasswordFormValid returns false when confirm does not match new '
        'across $iterations random inputs',
        () {
          for (var i = 0; i < iterations; i++) {
            final oldPassword = generateValidPassword(random);
            final newPassword = generateValidPassword(random);
            String confirmPassword;
            do {
              final length = random.nextInt(200) + 1;
              confirmPassword = generateString(random, length);
            } while (confirmPassword == newPassword);

            final result = isPasswordFormValid(
              oldPassword,
              newPassword,
              confirmPassword,
            );
            expect(
              result,
              isFalse,
              reason:
                  'Mismatched confirm should make form invalid: '
                  'new="$newPassword", confirm="$confirmPassword"',
            );
          }
        },
      );

      test(
        'isPasswordFormValid with random triples: passes ONLY when all conditions met '
        'across $iterations random inputs',
        () {
          for (var i = 0; i < iterations; i++) {
            // Randomly decide which conditions to satisfy
            final oldEmpty = random.nextBool();
            final newTooShort = random.nextBool();
            final newTooLong = !newTooShort && random.nextBool();
            final confirmMismatch = random.nextBool();

            // Generate old password
            final oldPassword = oldEmpty
                ? ''
                : generateString(random, random.nextInt(50) + 1);

            // Generate new password
            String newPassword;
            if (newTooShort) {
              newPassword = generateString(random, random.nextInt(7) + 1);
            } else if (newTooLong) {
              newPassword = generateString(random, 129 + random.nextInt(72));
            } else {
              newPassword = generateValidPassword(random);
            }

            // Generate confirm password
            String confirmPassword;
            if (confirmMismatch) {
              do {
                confirmPassword =
                    generateString(random, random.nextInt(200) + 1);
              } while (confirmPassword == newPassword);
            } else {
              confirmPassword = newPassword;
            }

            final result = isPasswordFormValid(
              oldPassword,
              newPassword,
              confirmPassword,
            );

            // Determine expected result
            final oldValid = oldPassword.isNotEmpty;
            final newValid =
                newPassword.length >= 8 && newPassword.length <= 128;
            final confirmValid = confirmPassword == newPassword;
            final expectedValid = oldValid && newValid && confirmValid;

            expect(
              result,
              expectedValid,
              reason:
                  'Form validity mismatch: '
                  'old="${oldPassword.isEmpty ? "(empty)" : oldPassword.substring(0, oldPassword.length.clamp(0, 10))}..." '
                  '(empty=$oldEmpty), '
                  'new length=${newPassword.length} '
                  '(tooShort=$newTooShort, tooLong=$newTooLong), '
                  'confirm matches=${confirmPassword == newPassword} '
                  '→ expected=$expectedValid, got=$result',
            );
          }
        },
      );
    },
  );
}
