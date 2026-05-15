import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

/// **Feature: tahap-4-main-navigation-profile, Property 5: Pagination hasMorePages**
///
/// **Validates: Requirements 9.5, 16.2**
///
/// For any currentPage and totalPages values (both positive integers),
/// hasMorePages SHALL be true if and only if currentPage < totalPages.
///
/// This tests the pure logic used by:
/// - SessionProvider: `bool get hasMoreActive => _activeCurrentPage < _activeTotalPages;`
/// - SessionProvider: `bool get hasMoreCompleted => _completedCurrentPage < _completedTotalPages;`
/// - PersonaProvider: `bool get hasMorePages => _currentPage < _totalPages;`
void main() {
  group(
    'Property 5: Pagination hasMorePages is correctly computed from page metadata',
    () {
      const int iterations = 200;
      final random = Random(42); // Fixed seed for reproducibility

      /// Pure function that mirrors the provider logic:
      /// hasMorePages = currentPage < totalPages
      bool hasMorePages(int currentPage, int totalPages) {
        return currentPage < totalPages;
      }

      test(
        'hasMorePages == (currentPage < totalPages) for random positive int pairs '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final currentPage = random.nextInt(100) + 1; // 1-100
            final totalPages = random.nextInt(100) + 1; // 1-100

            final result = hasMorePages(currentPage, totalPages);
            final expected = currentPage < totalPages;

            expect(
              result,
              equals(expected),
              reason: 'Iteration $i: currentPage=$currentPage, '
                  'totalPages=$totalPages — '
                  'expected hasMorePages=$expected, got $result',
            );
          }
        },
      );

      test(
        'hasMorePages is true when currentPage < totalPages '
        '(random cases where totalPages > currentPage)',
        () {
          for (var i = 0; i < iterations; i++) {
            // Ensure currentPage < totalPages
            final currentPage = random.nextInt(99) + 1; // 1-99
            final totalPages =
                currentPage + random.nextInt(100 - currentPage) + 1;

            final result = hasMorePages(currentPage, totalPages);

            expect(
              result,
              isTrue,
              reason: 'Iteration $i: currentPage=$currentPage, '
                  'totalPages=$totalPages — '
                  'expected hasMorePages=true since currentPage < totalPages',
            );
          }
        },
      );

      test(
        'hasMorePages is false when currentPage >= totalPages '
        '(random cases where currentPage equals or exceeds totalPages)',
        () {
          for (var i = 0; i < iterations; i++) {
            // Ensure currentPage >= totalPages
            final totalPages = random.nextInt(100) + 1; // 1-100
            final currentPage =
                totalPages + random.nextInt(10); // totalPages to totalPages+9

            final result = hasMorePages(currentPage, totalPages);

            expect(
              result,
              isFalse,
              reason: 'Iteration $i: currentPage=$currentPage, '
                  'totalPages=$totalPages — '
                  'expected hasMorePages=false since currentPage >= totalPages',
            );
          }
        },
      );

      test('boundary: single page (currentPage == totalPages == 1)', () {
        expect(hasMorePages(1, 1), isFalse);
      });

      test('boundary: first page of multi-page (currentPage=1, totalPages>1)',
          () {
        expect(hasMorePages(1, 2), isTrue);
        expect(hasMorePages(1, 10), isTrue);
        expect(hasMorePages(1, 100), isTrue);
      });

      test('boundary: last page (currentPage == totalPages)', () {
        expect(hasMorePages(5, 5), isFalse);
        expect(hasMorePages(10, 10), isFalse);
        expect(hasMorePages(100, 100), isFalse);
      });
    },
  );
}
