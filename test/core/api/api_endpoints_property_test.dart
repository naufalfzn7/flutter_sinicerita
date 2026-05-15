// Feature: admin-panel, Property 7: Parameterized endpoint path correctness

import 'dart:math';

import 'package:glados/glados.dart';

import 'package:sinicerita/core/api/api_endpoints.dart';

/// Custom generators for endpoint path property tests.
extension EndpointGenerators on Any {
  /// Generates a non-empty string suitable for use as an id parameter.
  /// Includes alphanumeric characters, UUIDs, and special but URL-safe chars.
  Generator<String> get nonEmptyIdString => any.nonEmptyLetterOrDigits;

  /// Generates UUID-like strings (common id format).
  Generator<String> get uuidLikeId =>
      any.letterOrDigits.map((s) => '${s.hashCode.abs().toRadixString(16)}-${s.length}');
}

void main() {
  // ─── Property 7: Parameterized endpoint path correctness ────────────────────

  /// **Feature: admin-panel, Property 7: Parameterized endpoint path correctness**
  ///
  /// **Validates: Requirements 10.2, 10.4**
  ///
  /// For any non-empty string `id`, `adminPersonaDetail(id)` SHALL return
  /// the string `/api/personas/$id` and `adminUserDetail(id)` SHALL return
  /// `/api/admin/users/$id`. The returned paths SHALL always start with `/api/`
  /// and contain the exact id without modification.
  group(
    'Property 7: Parameterized endpoint path correctness',
    () {
      Glados(any.nonEmptyIdString).test(
        'adminPersonaDetail(id) returns "/api/personas/\$id" for any non-empty id',
        (id) {
          final result = ApiEndpoints.adminPersonaDetail(id);

          expect(
            result,
            equals('/api/personas/$id'),
            reason: 'adminPersonaDetail("$id") should return "/api/personas/$id", '
                'got "$result"',
          );
        },
      );

      Glados(any.nonEmptyIdString).test(
        'adminUserDetail(id) returns "/api/admin/users/\$id" for any non-empty id',
        (id) {
          final result = ApiEndpoints.adminUserDetail(id);

          expect(
            result,
            equals('/api/admin/users/$id'),
            reason: 'adminUserDetail("$id") should return "/api/admin/users/$id", '
                'got "$result"',
          );
        },
      );

      Glados(any.nonEmptyIdString).test(
        'adminPersonaDetail(id) always starts with "/api/"',
        (id) {
          final result = ApiEndpoints.adminPersonaDetail(id);

          expect(
            result.startsWith('/api/'),
            isTrue,
            reason: 'adminPersonaDetail("$id") should start with "/api/", '
                'got "$result"',
          );
        },
      );

      Glados(any.nonEmptyIdString).test(
        'adminUserDetail(id) always starts with "/api/"',
        (id) {
          final result = ApiEndpoints.adminUserDetail(id);

          expect(
            result.startsWith('/api/'),
            isTrue,
            reason: 'adminUserDetail("$id") should start with "/api/", '
                'got "$result"',
          );
        },
      );

      Glados(any.nonEmptyIdString).test(
        'adminPersonaDetail(id) contains the exact id without modification',
        (id) {
          final result = ApiEndpoints.adminPersonaDetail(id);

          expect(
            result.contains(id),
            isTrue,
            reason: 'adminPersonaDetail("$id") should contain exact id "$id", '
                'got "$result"',
          );
          // Verify id is at the end of the path
          expect(
            result.endsWith(id),
            isTrue,
            reason: 'adminPersonaDetail("$id") should end with "$id", '
                'got "$result"',
          );
        },
      );

      Glados(any.nonEmptyIdString).test(
        'adminUserDetail(id) contains the exact id without modification',
        (id) {
          final result = ApiEndpoints.adminUserDetail(id);

          expect(
            result.contains(id),
            isTrue,
            reason: 'adminUserDetail("$id") should contain exact id "$id", '
                'got "$result"',
          );
          // Verify id is at the end of the path
          expect(
            result.endsWith(id),
            isTrue,
            reason: 'adminUserDetail("$id") should end with "$id", '
                'got "$result"',
          );
        },
      );

      // Additional iteration-based test for minimum 100 iterations coverage
      test(
        'adminPersonaDetail and adminUserDetail produce correct paths '
        'for 150 random id strings',
        () {
          const int iterations = 150;
          final random = Random(42);
          const chars =
              'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_';

          for (var i = 0; i < iterations; i++) {
            // Generate random non-empty id string (1-30 chars)
            final length = random.nextInt(30) + 1;
            final id = String.fromCharCodes(
              List.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
            );

            final personaResult = ApiEndpoints.adminPersonaDetail(id);
            final userResult = ApiEndpoints.adminUserDetail(id);

            expect(
              personaResult,
              equals('/api/personas/$id'),
              reason: 'Iteration $i: adminPersonaDetail("$id") failed',
            );
            expect(
              userResult,
              equals('/api/admin/users/$id'),
              reason: 'Iteration $i: adminUserDetail("$id") failed',
            );
            expect(personaResult.startsWith('/api/'), isTrue);
            expect(userResult.startsWith('/api/'), isTrue);
            expect(personaResult.endsWith(id), isTrue);
            expect(userResult.endsWith(id), isTrue);
          }
        },
      );
    },
  );
}
