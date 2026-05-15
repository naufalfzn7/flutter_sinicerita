import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/core/utils/form_data_utils.dart';

// Feature: admin-panel, Property 5: Edit form sends only changed fields
//
// **Validates: Requirements 6.4**
//
// For any original persona data and modified persona data, the PATCH request
// FormData SHALL contain only the fields whose values differ between original
// and modified. Unchanged fields SHALL NOT be included in the request payload.

void main() {
  group(
    'Property 5: Edit form sends only changed fields',
    () {
      const int iterations = 150;
      final random = Random(42); // Fixed seed for reproducibility

      /// Generate a random non-empty string of given max length.
      String generateRandomString(Random rng, {int maxLength = 50}) {
        final length = rng.nextInt(maxLength) + 1; // 1 to maxLength
        const chars =
            'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
        return String.fromCharCodes(
          Iterable.generate(
            length,
            (_) => chars.codeUnitAt(rng.nextInt(chars.length)),
          ),
        );
      }

      /// Generate a random boolean.
      bool generateRandomBool(Random rng) => rng.nextBool();

      test(
        'FormData contains only fields that differ between original and modified '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            // Generate original values
            final originalName = generateRandomString(random, maxLength: 100);
            final originalDescription =
                generateRandomString(random, maxLength: 500);
            final originalSystemPrompt =
                generateRandomString(random, maxLength: 200);
            final originalIsActive = generateRandomBool(random);

            // Generate modified values — randomly decide which fields change
            final changeName = random.nextBool();
            final changeDescription = random.nextBool();
            final changeSystemPrompt = random.nextBool();
            final changeIsActive = random.nextBool();

            final modifiedName = changeName
                ? generateRandomString(random, maxLength: 100)
                : originalName;
            final modifiedDescription = changeDescription
                ? generateRandomString(random, maxLength: 500)
                : originalDescription;
            final modifiedSystemPrompt = changeSystemPrompt
                ? generateRandomString(random, maxLength: 200)
                : originalSystemPrompt;
            final modifiedIsActive =
                changeIsActive ? !originalIsActive : originalIsActive;

            final formData = buildDifferentialFormData(
              originalName: originalName,
              modifiedName: modifiedName,
              originalDescription: originalDescription,
              modifiedDescription: modifiedDescription,
              originalSystemPrompt: originalSystemPrompt,
              modifiedSystemPrompt: modifiedSystemPrompt,
              originalIsActive: originalIsActive,
              modifiedIsActive: modifiedIsActive,
            );

            // Extract field names from FormData
            final fieldNames =
                formData.fields.map((entry) => entry.key).toSet();

            // Verify: changed fields MUST be present
            if (modifiedName != originalName) {
              expect(
                fieldNames.contains('name'),
                isTrue,
                reason: 'Iteration $i: name changed from "$originalName" to '
                    '"$modifiedName" but not in FormData',
              );
            }
            if (modifiedDescription != originalDescription) {
              expect(
                fieldNames.contains('description'),
                isTrue,
                reason:
                    'Iteration $i: description changed but not in FormData',
              );
            }
            if (modifiedSystemPrompt != originalSystemPrompt) {
              expect(
                fieldNames.contains('systemPrompt'),
                isTrue,
                reason:
                    'Iteration $i: systemPrompt changed but not in FormData',
              );
            }
            if (modifiedIsActive != originalIsActive) {
              expect(
                fieldNames.contains('isActive'),
                isTrue,
                reason: 'Iteration $i: isActive changed from $originalIsActive '
                    'to $modifiedIsActive but not in FormData',
              );
            }

            // Verify: unchanged fields SHALL NOT be present
            if (modifiedName == originalName) {
              expect(
                fieldNames.contains('name'),
                isFalse,
                reason: 'Iteration $i: name unchanged ("$originalName") '
                    'but found in FormData',
              );
            }
            if (modifiedDescription == originalDescription) {
              expect(
                fieldNames.contains('description'),
                isFalse,
                reason: 'Iteration $i: description unchanged but found in '
                    'FormData',
              );
            }
            if (modifiedSystemPrompt == originalSystemPrompt) {
              expect(
                fieldNames.contains('systemPrompt'),
                isFalse,
                reason: 'Iteration $i: systemPrompt unchanged but found in '
                    'FormData',
              );
            }
            if (modifiedIsActive == originalIsActive) {
              expect(
                fieldNames.contains('isActive'),
                isFalse,
                reason: 'Iteration $i: isActive unchanged ($originalIsActive) '
                    'but found in FormData',
              );
            }
          }
        },
      );

      test(
        'FormData is empty when no fields change ($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final name = generateRandomString(random, maxLength: 100);
            final description = generateRandomString(random, maxLength: 500);
            final systemPrompt = generateRandomString(random, maxLength: 200);
            final isActive = generateRandomBool(random);

            final formData = buildDifferentialFormData(
              originalName: name,
              modifiedName: name,
              originalDescription: description,
              modifiedDescription: description,
              originalSystemPrompt: systemPrompt,
              modifiedSystemPrompt: systemPrompt,
              originalIsActive: isActive,
              modifiedIsActive: isActive,
            );

            expect(
              formData.fields.isEmpty,
              isTrue,
              reason: 'Iteration $i: no fields changed but FormData has '
                  '${formData.fields.length} entries: '
                  '${formData.fields.map((e) => e.key).toList()}',
            );
          }
        },
      );

      test(
        'FormData contains all fields when everything changes '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final originalName = generateRandomString(random, maxLength: 50);
            final originalDescription =
                generateRandomString(random, maxLength: 100);
            final originalSystemPrompt =
                generateRandomString(random, maxLength: 100);
            final originalIsActive = generateRandomBool(random);

            // Ensure modified values are always different
            String modifiedName;
            do {
              modifiedName = generateRandomString(random, maxLength: 50);
            } while (modifiedName == originalName);

            String modifiedDescription;
            do {
              modifiedDescription =
                  generateRandomString(random, maxLength: 100);
            } while (modifiedDescription == originalDescription);

            String modifiedSystemPrompt;
            do {
              modifiedSystemPrompt =
                  generateRandomString(random, maxLength: 100);
            } while (modifiedSystemPrompt == originalSystemPrompt);

            final modifiedIsActive = !originalIsActive;

            final formData = buildDifferentialFormData(
              originalName: originalName,
              modifiedName: modifiedName,
              originalDescription: originalDescription,
              modifiedDescription: modifiedDescription,
              originalSystemPrompt: originalSystemPrompt,
              modifiedSystemPrompt: modifiedSystemPrompt,
              originalIsActive: originalIsActive,
              modifiedIsActive: modifiedIsActive,
            );

            final fieldNames =
                formData.fields.map((entry) => entry.key).toSet();

            expect(
              fieldNames,
              containsAll(['name', 'description', 'systemPrompt', 'isActive']),
              reason: 'Iteration $i: all fields changed but FormData only has '
                  '$fieldNames',
            );
            expect(
              fieldNames.length,
              equals(4),
              reason: 'Iteration $i: expected exactly 4 fields, '
                  'got ${fieldNames.length}',
            );
          }
        },
      );

      test(
        'FormData field values match the modified values exactly '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final originalName = generateRandomString(random, maxLength: 50);
            final originalDescription =
                generateRandomString(random, maxLength: 100);
            final originalSystemPrompt =
                generateRandomString(random, maxLength: 100);
            final originalIsActive = generateRandomBool(random);

            // Ensure all fields are different
            String modifiedName;
            do {
              modifiedName = generateRandomString(random, maxLength: 50);
            } while (modifiedName == originalName);

            String modifiedDescription;
            do {
              modifiedDescription =
                  generateRandomString(random, maxLength: 100);
            } while (modifiedDescription == originalDescription);

            String modifiedSystemPrompt;
            do {
              modifiedSystemPrompt =
                  generateRandomString(random, maxLength: 100);
            } while (modifiedSystemPrompt == originalSystemPrompt);

            final modifiedIsActive = !originalIsActive;

            final formData = buildDifferentialFormData(
              originalName: originalName,
              modifiedName: modifiedName,
              originalDescription: originalDescription,
              modifiedDescription: modifiedDescription,
              originalSystemPrompt: originalSystemPrompt,
              modifiedSystemPrompt: modifiedSystemPrompt,
              originalIsActive: originalIsActive,
              modifiedIsActive: modifiedIsActive,
            );

            // Verify values match modified data
            final fieldMap = Map.fromEntries(formData.fields);

            expect(
              fieldMap['name'],
              equals(modifiedName),
              reason: 'Iteration $i: name value mismatch',
            );
            expect(
              fieldMap['description'],
              equals(modifiedDescription),
              reason: 'Iteration $i: description value mismatch',
            );
            expect(
              fieldMap['systemPrompt'],
              equals(modifiedSystemPrompt),
              reason: 'Iteration $i: systemPrompt value mismatch',
            );
            expect(
              fieldMap['isActive'],
              equals(modifiedIsActive.toString()),
              reason: 'Iteration $i: isActive value mismatch',
            );
          }
        },
      );

      test('boundary: null original values with non-null modified values', () {
        final formData = buildDifferentialFormData(
          originalName: null,
          modifiedName: 'New Name',
          originalDescription: null,
          modifiedDescription: 'New Description',
          originalSystemPrompt: null,
          modifiedSystemPrompt: 'New Prompt',
          originalIsActive: null,
          modifiedIsActive: true,
        );

        final fieldNames = formData.fields.map((e) => e.key).toSet();
        expect(fieldNames, containsAll(['name', 'description', 'systemPrompt', 'isActive']));
      });

      test('boundary: null modified values produce empty FormData', () {
        final formData = buildDifferentialFormData(
          originalName: 'Name',
          modifiedName: null,
          originalDescription: 'Desc',
          modifiedDescription: null,
          originalSystemPrompt: 'Prompt',
          modifiedSystemPrompt: null,
          originalIsActive: true,
          modifiedIsActive: null,
        );

        expect(formData.fields.isEmpty, isTrue);
      });
    },
  );
}
