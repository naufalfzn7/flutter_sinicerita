import '../../providers/auth_provider.dart';

/// Pure function yang menentukan target route berdasarkan kombinasi
/// auth status, first-launch flag, current location, dan role.
///
/// Returns `null` jika tidak perlu redirect (stay di current location).
/// Returns target route path jika perlu redirect.
///
/// Routing Decision Table (base):
/// | AuthStatus      | First Launch Flag | Current Location | Target Route    |
/// |-----------------|-------------------|------------------|-----------------|
/// | unknown         | any               | /splash          | null (stay)     |
/// | authenticated   | any               | any              | /main           |
/// | unauthenticated | false             | /splash          | /welcome        |
/// | unauthenticated | true              | /splash          | /login          |
/// | unauthenticated | any               | /welcome         | null (stay)     |
/// | authenticated   | any               | /welcome         | /main           |
///
/// Role-based guards (hanya jika authenticated):
/// | Role    | Location       | Target Route |
/// |---------|----------------|--------------|
/// | admin   | /admin/*       | null (stay)  |
/// | admin   | non-admin/auth | /admin       |
/// | user    | /admin/*       | /main        |
/// | user    | /main          | null (stay)  |
/// | unknown | any            | treat as "user" |
///
/// Unauthenticated at /admin/* → /login
String? computeRedirect({
  required AuthStatus status,
  required bool firstLaunchCompleted,
  required String location,
  String? role,
}) {
  final isOnSplash = location == '/splash';
  final isOnMain = location == '/main';
  final isOnAdmin = location == '/admin' || location.startsWith('/admin/');
  final isAuthRoute = location == '/login' ||
      location == '/register' ||
      location == '/welcome' ||
      location == '/splash' ||
      location.startsWith('/forgot-password') ||
      location.startsWith('/verify-otp') ||
      location.startsWith('/reset-password');

  // Splash handling: once status is resolved, redirect away from splash
  if (isOnSplash && status != AuthStatus.unknown) {
    if (status == AuthStatus.authenticated) {
      // Role-based redirect from splash
      final effectiveRole = (role == 'admin') ? 'admin' : 'user';
      return effectiveRole == 'admin' ? '/admin' : '/main';
    }
    // Unauthenticated: cek first-launch flag
    return firstLaunchCompleted ? '/login' : '/welcome';
  }

  // Guard: unauthenticated users trying to access /admin/* → /login
  if (status == AuthStatus.unauthenticated && isOnAdmin) return '/login';

  // Guard: authenticated users cannot access /welcome, /login, /register
  if (status == AuthStatus.authenticated && isAuthRoute && !isOnSplash) {
    final effectiveRole = (role == 'admin') ? 'admin' : 'user';
    return effectiveRole == 'admin' ? '/admin' : '/main';
  }

  // Auth guard: unauthenticated users can't access main
  if (status == AuthStatus.unauthenticated && isOnMain) return '/login';

  // Role-based guards (only when authenticated)
  if (status == AuthStatus.authenticated) {
    final effectiveRole = (role == 'admin') ? 'admin' : 'user';

    if (effectiveRole == 'admin') {
      // Admin at /admin/* → stay
      if (isOnAdmin) return null;
      // Admin at non-admin, non-auth route → redirect to /admin
      if (!isAuthRoute) return '/admin';
    } else {
      // User at /admin/* → redirect to /main
      if (isOnAdmin) return '/main';
    }
  }

  return null; // no redirect
}
