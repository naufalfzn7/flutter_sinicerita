import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/core/routing/redirect_logic.dart';
import 'package:sinicerita/providers/auth_provider.dart';

/// **Validates: Requirements 2.2, 2.3, 2.4, 3.2, 3.3, 3.4, 3.6**
///
/// Property 1: Routing decision correctness
///
/// For any combination of auth status, first-launch flag state, and current
/// location, the redirect function SHALL produce the correct target route as
/// defined by the routing decision table.
///
/// Approach: Exhaustive loop-based (Dart tidak punya PBT library mainstream).
/// Input space finite: 3 AuthStatus × 2 flag states × 5 locations = 30 kombinasi.
void main() {
  group(
      'Property 1: Routing decision correctness — '
      'For any combination of auth status, flag state, and location, '
      'redirect produces the correct route', () {
    // All possible input values
    const allStatuses = AuthStatus.values; // unknown, authenticated, unauthenticated
    const allFlagStates = [true, false];
    const allLocations = ['/splash', '/welcome', '/login', '/main', '/register'];

    /// Expected redirect result based on the routing decision table from design.md.
    ///
    /// Decision table:
    /// | AuthStatus      | First Launch Flag | Current Location | Target Route |
    /// |-----------------|-------------------|------------------|--------------|
    /// | unknown         | any               | /splash          | null (stay)  |
    /// | authenticated   | any               | any              | /main        |
    /// | unauthenticated | false             | /splash          | /welcome     |
    /// | unauthenticated | true              | /splash          | /login       |
    /// | unauthenticated | any               | /welcome         | null (stay)  |
    /// | authenticated   | any               | /welcome         | /main        |
    ///
    /// Additional rules (from implementation):
    /// - authenticated + /login → /main
    /// - authenticated + /register → /main
    /// - unauthenticated + /main → /login
    /// - unknown + non-splash → null (stay, waiting for auth resolution)
    String? expectedRedirect(
      AuthStatus status,
      bool firstLaunchCompleted,
      String location,
    ) {
      // Rule 1: unknown status — only splash stays, others also stay
      // (router doesn't redirect until auth status resolves)
      if (status == AuthStatus.unknown) {
        return null;
      }

      // Rule 2: authenticated users always go to /main from protected routes
      if (status == AuthStatus.authenticated) {
        if (location == '/splash' ||
            location == '/welcome' ||
            location == '/login' ||
            location == '/register') {
          return '/main';
        }
        // Already on /main → stay
        return null;
      }

      // Rule 3: unauthenticated users
      if (status == AuthStatus.unauthenticated) {
        // From splash: check flag
        if (location == '/splash') {
          return firstLaunchCompleted ? '/login' : '/welcome';
        }
        // On /main: redirect to /login (auth guard)
        if (location == '/main') {
          return '/login';
        }
        // On /welcome, /login, /register: stay
        return null;
      }

      return null;
    }

    // Exhaustive test: iterate ALL combinations
    for (final status in allStatuses) {
      for (final flag in allFlagStates) {
        for (final location in allLocations) {
          final expected = expectedRedirect(status, flag, location);
          final description =
              'status=$status, flag=$flag, location=$location → ${expected ?? "null (stay)"}';

          test(description, () {
            final result = computeRedirect(
              status: status,
              firstLaunchCompleted: flag,
              location: location,
            );

            expect(result, expected,
                reason: 'Routing decision mismatch for: $description');
          });
        }
      }
    }

    // Summary test: verify all combinations were covered
    test('exhaustive coverage: all ${allStatuses.length * allFlagStates.length * allLocations.length} combinations tested', () {
      final totalCombinations =
          allStatuses.length * allFlagStates.length * allLocations.length;
      expect(totalCombinations, 30);

      // Verify the function handles every combination without throwing
      for (final status in allStatuses) {
        for (final flag in allFlagStates) {
          for (final location in allLocations) {
            expect(
              () => computeRedirect(
                status: status,
                firstLaunchCompleted: flag,
                location: location,
              ),
              returnsNormally,
              reason:
                  'computeRedirect should not throw for status=$status, flag=$flag, location=$location',
            );
          }
        }
      }
    });
  });
}
