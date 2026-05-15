# Implementation Plan: Auth Register & Login

## Overview

Implement Tahap 2 authentication for SiniCerita Flutter app: UserModel, AuthProvider, GoRouter with auth guards, and three screens (Splash, Login, Register). Builds on existing Tahap 1 infrastructure (ApiClient, SecureStorage, Validators, AppException).

## Tasks

- [x] 1. Create UserModel data class
  - [x] 1.1 Create `lib/models/user_model.dart` with all fields (id, name, email, role, points, avatarUrl, createdAt)
    - Implement `factory UserModel.fromJson(Map<String, dynamic> json)` parsing `createdAt` as `DateTime.parse()`
    - Implement `Map<String, dynamic> toJson()` serializing `createdAt` as ISO 8601 string
    - Handle nullable `avatarUrl`
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

  - [ ]* 1.2 Write property test for UserModel serialization round-trip
    - **Property 1: UserModel serialization round-trip**
    - Generate random UserModel instances (including null/non-null avatarUrl), verify `fromJson(toJson(model))` produces equivalent model
    - **Validates: Requirements 1.2, 1.3, 1.4**

- [x] 2. Create AuthProvider with core auth logic
  - [x] 2.1 Create `lib/providers/auth_provider.dart` with AuthStatus enum and class skeleton
    - Define `AuthStatus { unknown, authenticated, unauthenticated }`
    - Extend `ChangeNotifier`
    - Accept `ApiClient` as constructor parameter
    - Expose getters: status, currentUser, isLoading, errorMessage
    - _Requirements: 2.1, 2.2_

  - [x] 2.2 Implement `login(String email, String password)` method
    - POST to `/api/auth/login` with `{email, password}`
    - On success: parse `response.data['data']` → save tokens to SecureStorage → set `_currentUser` from `data['user']` → set status to authenticated
    - On DioException: convert to AppException, set errorMessage, return false
    - Follow provider pattern: set isLoading, clear errorMessage, notifyListeners
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

  - [x] 2.3 Implement `register(String name, String email, String password)` method
    - POST to `/api/auth/register` with `{name, email, password}`
    - On success (201): call `login(email, password)` and return its result
    - On DioException: convert to AppException, set errorMessage, return false
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

  - [x] 2.4 Implement `logout()` method
    - Get refreshToken from SecureStorage
    - POST to `/api/auth/logout` with `{refreshToken}` in body (not header)
    - ALWAYS (regardless of API success/failure): clearAll() from SecureStorage, set currentUser = null, set status = unauthenticated, notifyListeners
    - _Requirements: 5.1, 5.2, 5.3_

  - [x] 2.5 Implement `checkAuthStatus()` method
    - Read accessToken from SecureStorage
    - If null → set status = unauthenticated, notifyListeners, return
    - If exists → GET `/api/me` → on success: set currentUser + authenticated
    - On failure: clearAll tokens, set status = unauthenticated
    - _Requirements: 2.3, 2.4, 2.5_

  - [ ]* 2.6 Write property tests for AuthProvider
    - **Property 2: AuthProvider state invariant** — after any operation, authenticated ↔ currentUser != null
    - **Property 3: Error message passthrough** — for any API error, errorMessage matches backend message exactly
    - **Property 4: Login persists tokens** — after successful login, tokens retrievable from storage
    - **Property 5: Logout always clears state** — regardless of API result, tokens cleared and status unauthenticated
    - **Validates: Requirements 2.1, 2.2, 3.3, 3.4, 4.2, 4.5, 5.2, 5.3**

- [x] 3. Update Validators utility
  - [x] 3.1 Add `validateName` and `validateConfirmPassword` to `lib/core/utils/validators.dart`
    - `validateName(String? value)` → "Nama tidak boleh kosong" if trimmed empty
    - `validateConfirmPassword(String? value, String? password)` → "Konfirmasi password tidak boleh kosong" / "Password tidak cocok"
    - Note: validateEmail and validatePassword already exist from Tahap 1
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [ ]* 3.2 Write property tests for Validators
    - **Property 6: Validators correctly classify inputs**
    - Generate random strings: empty, whitespace-only, valid emails, invalid emails, short passwords, valid passwords, matching/non-matching pairs
    - Verify each validator returns null for valid input and appropriate error message for invalid input
    - **Validates: Requirements 6.1, 6.2, 6.3, 6.4**

- [x] 4. Checkpoint - Core logic complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Configure GoRouter and rewrite main.dart
  - [x] 5.1 Rewrite `lib/main.dart` with MultiProvider + GoRouter
    - Instantiate SecureStorage, ApiClient, AuthProvider
    - Wrap app with `MultiProvider` providing AuthProvider (and ApiClient if needed by other providers later)
    - Create GoRouter with `initialLocation: '/splash'`
    - Set `refreshListenable: authProvider` so router reacts to auth changes
    - Define routes: /splash, /login, /register, /main
    - Implement redirect logic:
      - If authenticated AND on /login or /register → redirect to /main
      - If unauthenticated AND on /main → redirect to /login
      - If unknown → no redirect (splash handles it)
    - Use `MaterialApp.router` with `routerConfig: router`
    - _Requirements: 10.1, 10.2, 10.3, 10.4_

  - [ ]* 5.2 Write property test for router redirect guards
    - **Property 7: Router redirect guards**
    - For any combination of (AuthStatus, targetLocation), verify correct redirect behavior
    - **Validates: Requirements 10.2, 10.3**

- [x] 6. Implement SplashScreen
  - [x] 6.1 Create `lib/screens/auth/splash_screen.dart`
    - Show app logo/branding centered on screen
    - In `initState`, call `authProvider.checkAuthStatus()` after frame renders (use `WidgetsBinding.instance.addPostFrameCallback`)
    - GoRouter handles navigation automatically via refreshListenable when status changes
    - Add `if (!mounted) return;` safety check after async gap
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [x] 7. Implement LoginScreen
  - [x] 7.1 Create `lib/screens/auth/login_screen.dart`
    - Form with `GlobalKey<FormState>`
    - Email field with `Validators.validateEmail`
    - Password field with `Validators.validatePassword` and `obscureText: true`
    - "Masuk" button: validate form → call `context.read<AuthProvider>().login(email, password)`
    - On success: `context.go('/main')` (or let GoRouter redirect handle it)
    - On failure: show red SnackBar with `authProvider.errorMessage`
    - Disable button while `authProvider.isLoading` (use `context.watch<AuthProvider>().isLoading`)
    - Navigation link to `/register` at bottom
    - `if (!mounted) return;` after every async gap
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

- [x] 8. Implement RegisterScreen
  - [x] 8.1 Create `lib/screens/auth/register_screen.dart`
    - Form with `GlobalKey<FormState>`
    - Name field with `Validators.validateName`
    - Email field with `Validators.validateEmail`
    - Password field with `Validators.validatePassword` and `obscureText: true`
    - Confirm password field with `Validators.validateConfirmPassword(value, passwordController.text)` and `obscureText: true`
    - "Daftar" button: validate form → call `context.read<AuthProvider>().register(name, email, password)`
    - On success: `context.go('/main')`
    - On failure: show red SnackBar with `authProvider.errorMessage`
    - Disable button while `authProvider.isLoading`
    - Navigation link back to `/login`
    - `if (!mounted) return;` after every async gap
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

- [x] 9. Create MainScreen placeholder
  - [x] 9.1 Create `lib/screens/main/main_screen.dart`
    - Simple Scaffold showing current user name from `context.watch<AuthProvider>().currentUser?.name`
    - Logout button that calls `context.read<AuthProvider>().logout()`
    - This is a temporary placeholder — will be replaced in Tahap 4 with BottomNavigationBar
    - _Requirements: 10.1_

- [x] 10. Final checkpoint - Full integration
  - Ensure all tests pass, ask the user if questions arise.
  - Verify complete flows: register → auto-login → main, login → main, logout → login
  - Verify redirect guards: authenticated user can't access /login, unauthenticated user can't access /main

## Task Dependency Graph

```json
{
  "waves": [
    {
      "wave": 1,
      "tasks": ["1"],
      "description": "Create UserModel data class"
    },
    {
      "wave": 2,
      "tasks": ["2"],
      "description": "Create AuthProvider with core auth logic"
    },
    {
      "wave": 3,
      "tasks": ["3"],
      "description": "Update Validators utility"
    },
    {
      "wave": 4,
      "tasks": ["4"],
      "description": "Checkpoint - Core logic complete"
    },
    {
      "wave": 5,
      "tasks": ["5"],
      "description": "Configure GoRouter and rewrite main.dart"
    },
    {
      "wave": 6,
      "tasks": ["6", "7", "8", "9"],
      "description": "Implement screens (Splash, Login, Register, MainScreen placeholder)"
    },
    {
      "wave": 7,
      "tasks": ["10"],
      "description": "Final checkpoint - Full integration"
    }
  ]
}
```

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- The existing `Validators` class already has `validateEmail` and `validatePassword` — task 3.1 only adds the missing methods
- All UI text must be in Bahasa Indonesia per project conventions
- Use `context.read<T>()` for method calls in callbacks, `context.watch<T>()` for reactive rebuilds
