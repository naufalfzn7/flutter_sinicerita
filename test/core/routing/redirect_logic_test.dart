import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/core/routing/redirect_logic.dart';
import 'package:sinicerita/providers/auth_provider.dart';

void main() {
  group('computeRedirect - GoRouter redirect logic', () {
    group('unauthenticated + flag not set (false)', () {
      test('redirects to /welcome from /splash when flag is false', () {
        final result = computeRedirect(
          status: AuthStatus.unauthenticated,
          firstLaunchCompleted: false,
          location: '/splash',
        );

        expect(result, '/welcome');
      });
    });

    group('unauthenticated + flag is true', () {
      test('redirects to /login from /splash when flag is true', () {
        final result = computeRedirect(
          status: AuthStatus.unauthenticated,
          firstLaunchCompleted: true,
          location: '/splash',
        );

        expect(result, '/login');
      });
    });

    group('authenticated user (regardless of flag)', () {
      test('redirects to /main from /splash when authenticated + flag false',
          () {
        final result = computeRedirect(
          status: AuthStatus.authenticated,
          firstLaunchCompleted: false,
          location: '/splash',
        );

        expect(result, '/main');
      });

      test('redirects to /main from /splash when authenticated + flag true',
          () {
        final result = computeRedirect(
          status: AuthStatus.authenticated,
          firstLaunchCompleted: true,
          location: '/splash',
        );

        expect(result, '/main');
      });
    });

    group('authenticated user cannot access /welcome', () {
      test('redirects to /main when authenticated user is on /welcome', () {
        final result = computeRedirect(
          status: AuthStatus.authenticated,
          firstLaunchCompleted: false,
          location: '/welcome',
        );

        expect(result, '/main');
      });

      test(
          'redirects to /main when authenticated user is on /welcome (flag true)',
          () {
        final result = computeRedirect(
          status: AuthStatus.authenticated,
          firstLaunchCompleted: true,
          location: '/welcome',
        );

        expect(result, '/main');
      });
    });

    group('flag read fails (error fallback → flag is false)', () {
      // When SecureStorage read fails, it catches the exception and returns
      // false. The AuthProvider then sets firstLaunchCompleted = false.
      // From the redirect's perspective, this is equivalent to flag == false.
      test('redirects to /welcome when flag is false (error fallback case)',
          () {
        final result = computeRedirect(
          status: AuthStatus.unauthenticated,
          firstLaunchCompleted: false, // simulates error fallback
          location: '/splash',
        );

        expect(result, '/welcome');
      });
    });

    group('additional edge cases', () {
      test('returns null when status is unknown on /splash (stay)', () {
        final result = computeRedirect(
          status: AuthStatus.unknown,
          firstLaunchCompleted: false,
          location: '/splash',
        );

        expect(result, isNull);
      });

      test('returns null when unauthenticated user is on /welcome (stay)', () {
        final result = computeRedirect(
          status: AuthStatus.unauthenticated,
          firstLaunchCompleted: false,
          location: '/welcome',
        );

        expect(result, isNull);
      });

      test('redirects unauthenticated user from /main to /login', () {
        final result = computeRedirect(
          status: AuthStatus.unauthenticated,
          firstLaunchCompleted: false,
          location: '/main',
        );

        expect(result, '/login');
      });

      test('authenticated user on /login is redirected to /main', () {
        final result = computeRedirect(
          status: AuthStatus.authenticated,
          firstLaunchCompleted: false,
          location: '/login',
        );

        expect(result, '/main');
      });

      test('authenticated user on /register is redirected to /main', () {
        final result = computeRedirect(
          status: AuthStatus.authenticated,
          firstLaunchCompleted: false,
          location: '/register',
        );

        expect(result, '/main');
      });
    });
  });
}
