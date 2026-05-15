// Feature: admin-panel, Property 1: Route redirect correctness

import 'dart:math';

import 'package:glados/glados.dart';

import 'package:sinicerita/core/routing/redirect_logic.dart';
import 'package:sinicerita/providers/auth_provider.dart';

/// Custom generators for route redirect property tests.
extension RedirectGenerators on Any {
  /// Generates a random AuthStatus value.
  Generator<AuthStatus> get authStatus =>
      any.choose(AuthStatus.values);

  /// Generates a random role string: "admin", "user", null, or invalid.
  Generator<String?> get roleValue =>
      any.choose(<String?>['admin', 'user', null, 'moderator', 'superadmin', '']);

  /// Generates a random location path from realistic route paths.
  Generator<String> get routeLocation => any.choose(<String>[
        '/admin',
        '/admin/dashboard',
        '/admin/personas',
        '/admin/personas/create',
        '/admin/personas/abc123/edit',
        '/admin/users',
        '/admin/users/xyz789',
        '/main',
        '/login',
        '/register',
        '/welcome',
        '/splash',
        '/forgot-password',
        '/forgot-password/email',
        '/verify-otp',
        '/verify-otp/confirm',
        '/reset-password',
        '/reset-password/new',
        '/profile',
        '/chat',
        '/settings',
        '/some-random-route',
      ]);
}

void main() {
  // ─── Property 1: Route redirect correctness ─────────────────────────────────

  /// **Feature: admin-panel, Property 1: Route redirect correctness**
  ///
  /// **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.6**
  ///
  /// For any combination of (authStatus, role, location), the `computeRedirect`
  /// function SHALL produce the correct redirect target according to these rules:
  /// - Authenticated admin at any non-admin route (except auth routes) → `/admin`
  /// - Authenticated admin at `/admin/*` → null (stay)
  /// - Authenticated user at `/admin/*` → `/main`
  /// - Authenticated user at `/main` → null (stay)
  /// - Unauthenticated at `/admin/*` → `/login`
  /// - Unknown/invalid role → treated as "user"
  group(
    'Property 1: Route redirect correctness',
    () {
      // Helper to determine if a location is an auth route
      bool isAuthRoute(String location) {
        return location == '/login' ||
            location == '/register' ||
            location == '/welcome' ||
            location == '/splash' ||
            location.startsWith('/forgot-password') ||
            location.startsWith('/verify-otp') ||
            location.startsWith('/reset-password');
      }

      // Helper to determine if a location is an admin route
      bool isAdminRoute(String location) {
        return location == '/admin' || location.startsWith('/admin/');
      }

      // ─── Glados-based property tests ──────────────────────────────────────

      Glados2(any.roleValue, any.routeLocation).test(
        'authenticated admin at /admin/* → null (stay)',
        (role, location) {
          // Only test admin role at admin routes
          if (role != 'admin' || !isAdminRoute(location)) return;

          final result = computeRedirect(
            status: AuthStatus.authenticated,
            firstLaunchCompleted: true,
            location: location,
            role: role,
          );

          expect(
            result,
            isNull,
            reason: 'Authenticated admin at "$location" should stay (null), '
                'got "$result"',
          );
        },
      );

      Glados2(any.roleValue, any.routeLocation).test(
        'authenticated admin at non-admin, non-auth route → /admin',
        (role, location) {
          // Only test admin role at non-admin, non-auth routes
          if (role != 'admin' ||
              isAdminRoute(location) ||
              isAuthRoute(location)) return;

          final result = computeRedirect(
            status: AuthStatus.authenticated,
            firstLaunchCompleted: true,
            location: location,
            role: role,
          );

          expect(
            result,
            equals('/admin'),
            reason: 'Authenticated admin at non-admin route "$location" '
                'should redirect to "/admin", got "$result"',
          );
        },
      );

      Glados2(any.roleValue, any.routeLocation).test(
        'authenticated user at /admin/* → /main',
        (role, location) {
          // Only test user role (or non-admin) at admin routes
          final effectiveRole = (role == 'admin') ? 'admin' : 'user';
          if (effectiveRole != 'user' || !isAdminRoute(location)) return;

          final result = computeRedirect(
            status: AuthStatus.authenticated,
            firstLaunchCompleted: true,
            location: location,
            role: role,
          );

          expect(
            result,
            equals('/main'),
            reason: 'Authenticated user (role="$role") at admin route '
                '"$location" should redirect to "/main", got "$result"',
          );
        },
      );

      Glados(any.routeLocation).test(
        'unauthenticated at /admin/* → /login',
        (location) {
          if (!isAdminRoute(location)) return;

          final result = computeRedirect(
            status: AuthStatus.unauthenticated,
            firstLaunchCompleted: true,
            location: location,
          );

          expect(
            result,
            equals('/login'),
            reason: 'Unauthenticated at admin route "$location" should '
                'redirect to "/login", got "$result"',
          );
        },
      );

      Glados(any.routeLocation).test(
        'unknown/invalid role is treated as "user" — redirected from /admin/*',
        (location) {
          if (!isAdminRoute(location)) return;

          // Test with null role (unknown)
          final resultNull = computeRedirect(
            status: AuthStatus.authenticated,
            firstLaunchCompleted: true,
            location: location,
            role: null,
          );

          expect(
            resultNull,
            equals('/main'),
            reason: 'Authenticated with null role at "$location" should '
                'redirect to "/main" (treated as user), got "$resultNull"',
          );

          // Test with invalid role
          final resultInvalid = computeRedirect(
            status: AuthStatus.authenticated,
            firstLaunchCompleted: true,
            location: location,
            role: 'moderator',
          );

          expect(
            resultInvalid,
            equals('/main'),
            reason: 'Authenticated with role="moderator" at "$location" should '
                'redirect to "/main" (treated as user), got "$resultInvalid"',
          );
        },
      );

      // ─── Iteration-based comprehensive property test (150+ iterations) ────

      test(
        'computeRedirect produces correct redirect for 200 random '
        '(status, role, location) combinations',
        () {
          const int iterations = 200;
          final random = Random(42); // Fixed seed for reproducibility

          final statuses = AuthStatus.values;
          final roles = <String?>['admin', 'user', null, 'moderator', ''];
          final locations = <String>[
            '/admin',
            '/admin/dashboard',
            '/admin/personas',
            '/admin/personas/create',
            '/admin/personas/abc123/edit',
            '/admin/users',
            '/admin/users/xyz789',
            '/main',
            '/login',
            '/register',
            '/welcome',
            '/splash',
            '/forgot-password',
            '/forgot-password/email',
            '/verify-otp',
            '/verify-otp/confirm',
            '/reset-password',
            '/reset-password/new',
            '/profile',
            '/chat',
            '/settings',
            '/some-random-route',
          ];

          for (var i = 0; i < iterations; i++) {
            final status = statuses[random.nextInt(statuses.length)];
            final role = roles[random.nextInt(roles.length)];
            final location = locations[random.nextInt(locations.length)];
            final firstLaunchCompleted = random.nextBool();

            final result = computeRedirect(
              status: status,
              firstLaunchCompleted: firstLaunchCompleted,
              location: location,
              role: role,
            );

            final isAdmin = isAdminRoute(location);
            final isAuth = isAuthRoute(location);
            final effectiveRole = (role == 'admin') ? 'admin' : 'user';

            // Verify role-based routing rules for authenticated users
            if (status == AuthStatus.authenticated && !isAuth) {
              if (effectiveRole == 'admin') {
                if (isAdmin) {
                  // Admin at /admin/* → stay
                  expect(
                    result,
                    isNull,
                    reason: 'Iteration $i: authenticated admin at "$location" '
                        'should stay (null), got "$result"',
                  );
                } else {
                  // Admin at non-admin, non-auth → /admin
                  expect(
                    result,
                    equals('/admin'),
                    reason: 'Iteration $i: authenticated admin at "$location" '
                        'should redirect to "/admin", got "$result"',
                  );
                }
              } else {
                if (isAdmin) {
                  // User at /admin/* → /main
                  expect(
                    result,
                    equals('/main'),
                    reason: 'Iteration $i: authenticated user (role="$role") '
                        'at "$location" should redirect to "/main", '
                        'got "$result"',
                  );
                }
              }
            }

            // Verify unauthenticated at /admin/* → /login
            if (status == AuthStatus.unauthenticated && isAdmin) {
              expect(
                result,
                equals('/login'),
                reason: 'Iteration $i: unauthenticated at "$location" should '
                    'redirect to "/login", got "$result"',
              );
            }
          }
        },
      );

      // ─── Specific rule verification tests ─────────────────────────────────

      test(
        'authenticated admin at auth routes is redirected to /admin',
        () {
          final authRoutes = [
            '/login',
            '/register',
            '/welcome',
            '/forgot-password',
            '/verify-otp',
            '/reset-password',
          ];

          for (final route in authRoutes) {
            final result = computeRedirect(
              status: AuthStatus.authenticated,
              firstLaunchCompleted: true,
              location: route,
              role: 'admin',
            );

            expect(
              result,
              equals('/admin'),
              reason: 'Authenticated admin at auth route "$route" should '
                  'redirect to "/admin", got "$result"',
            );
          }
        },
      );

      test(
        'authenticated user at /main → null (stay)',
        () {
          final userRoles = <String?>['user', null, '', 'moderator'];

          for (final role in userRoles) {
            final result = computeRedirect(
              status: AuthStatus.authenticated,
              firstLaunchCompleted: true,
              location: '/main',
              role: role,
            );

            expect(
              result,
              isNull,
              reason: 'Authenticated user (role="$role") at "/main" should '
                  'stay (null), got "$result"',
            );
          }
        },
      );

      test(
        'unknown role is always treated as "user" — same behavior as role="user"',
        () {
          final unknownRoles = <String?>[null, '', 'moderator', 'superadmin'];
          final testLocations = [
            '/admin',
            '/admin/dashboard',
            '/admin/users',
            '/main',
            '/profile',
          ];

          for (final role in unknownRoles) {
            for (final location in testLocations) {
              final resultUnknown = computeRedirect(
                status: AuthStatus.authenticated,
                firstLaunchCompleted: true,
                location: location,
                role: role,
              );

              final resultUser = computeRedirect(
                status: AuthStatus.authenticated,
                firstLaunchCompleted: true,
                location: location,
                role: 'user',
              );

              expect(
                resultUnknown,
                equals(resultUser),
                reason: 'Role "$role" at "$location" should behave same as '
                    'role="user". Got "$resultUnknown" vs "$resultUser"',
              );
            }
          }
        },
      );
    },
  );
}
