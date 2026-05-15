import '../../providers/auth_provider.dart';

/// Pure function yang menentukan target route berdasarkan kombinasi
/// auth status, first-launch flag, dan current location.
///
/// Returns `null` jika tidak perlu redirect (stay di current location).
/// Returns target route path jika perlu redirect.
///
/// Routing Decision Table:
/// | AuthStatus      | First Launch Flag | Current Location | Target Route    |
/// |-----------------|-------------------|------------------|-----------------|
/// | unknown         | any               | /splash          | null (stay)     |
/// | authenticated   | any               | any              | /main           |
/// | unauthenticated | false             | /splash          | /welcome        |
/// | unauthenticated | true              | /splash          | /login          |
/// | unauthenticated | any               | /welcome         | null (stay)     |
/// | authenticated   | any               | /welcome         | /main           |
String? computeRedirect({
  required AuthStatus status,
  required bool firstLaunchCompleted,
  required String location,
}) {
  final isOnSplash = location == '/splash';
  final isOnMain = location == '/main';

  // Splash handling: once status is resolved, redirect away from splash
  if (isOnSplash && status != AuthStatus.unknown) {
    if (status == AuthStatus.authenticated) return '/main';
    // Unauthenticated: cek first-launch flag
    return firstLaunchCompleted ? '/login' : '/welcome';
  }

  // Guard: authenticated users cannot access /welcome, /login, /register
  if (status == AuthStatus.authenticated &&
      (location == '/login' ||
          location == '/register' ||
          location == '/welcome')) {
    return '/main';
  }

  // Auth guard: unauthenticated users can't access main
  if (status == AuthStatus.unauthenticated && isOnMain) return '/login';

  return null; // no redirect
}
