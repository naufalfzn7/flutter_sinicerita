# Implementation Plan: Welcome Landing Page

## Overview

Implementasi halaman welcome/landing page untuk SiniCerita yang ditampilkan saat first launch. Melibatkan modifikasi SecureStorage, AuthProvider, GoRouter redirect logic, dan pembuatan WelcomeScreen widget baru. Semua perubahan terintegrasi dengan arsitektur existing (Provider + GoRouter).

## Tasks

- [x] 1. Extend SecureStorage dengan first-launch flag methods
  - [x] 1.1 Add first-launch flag key constant dan methods ke SecureStorage
    - Tambah `_firstLaunchKey` constant di `lib/core/storage/secure_storage.dart`
    - Implement `isFirstLaunchCompleted()` yang return `Future<bool>` (false jika key tidak ada atau exception)
    - Implement `setFirstLaunchCompleted()` yang write `'true'` ke storage
    - Error handling: catch exception dan return false sebagai fallback
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.5, 3.6_

  - [x] 1.2 Write unit tests for SecureStorage first-launch methods
    - Test `isFirstLaunchCompleted()` returns false when key doesn't exist
    - Test `isFirstLaunchCompleted()` returns true after `setFirstLaunchCompleted()` called
    - Test `isFirstLaunchCompleted()` returns false when storage throws exception
    - _Requirements: 2.4, 3.6_

- [x] 2. Add first-launch state to AuthProvider
  - [x] 2.1 Add `firstLaunchCompleted` field dan `completeFirstLaunch()` method ke AuthProvider
    - Tambah `bool _firstLaunchCompleted = false` field di `lib/providers/auth_provider.dart`
    - Tambah getter `bool get firstLaunchCompleted`
    - Di dalam `checkAuthStatus()`, baca flag dari storage sebelum set auth status: `_firstLaunchCompleted = await _apiClient.storage.isFirstLaunchCompleted()`
    - Implement `completeFirstLaunch()`: call `setFirstLaunchCompleted()` pada storage, set field ke true, call `notifyListeners()`
    - _Requirements: 2.1, 3.2, 3.3, 3.5_

  - [x] 2.2 Write unit tests for AuthProvider first-launch logic
    - Test `firstLaunchCompleted` defaults to false
    - Test `completeFirstLaunch()` sets field to true and calls notifyListeners
    - Test `checkAuthStatus()` reads flag from storage
    - _Requirements: 2.1, 3.5_

- [x] 3. Create WelcomeScreen widget
  - [x] 3.1 Implement WelcomeScreen di `lib/screens/auth/welcome_screen.dart`
    - Create `StatelessWidget` dengan layout: logo centered upper, tagline middle, tombol "Mulai" bottom
    - Logo: gunakan asset image app logo, horizontally centered
    - Tagline: teks Bahasa Indonesia yang mengandung "SiniCerita" dan deskripsi singkat tujuan app
    - Tombol "Mulai": full-width button di bagian bawah, on tap call `authProvider.completeFirstLaunch()` lalu `context.go('/login')`
    - Gunakan dark theme existing (AppTheme)
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1_

  - [x] 3.2 Write widget tests for WelcomeScreen
    - Test renders logo image widget
    - Test renders tagline text containing "SiniCerita"
    - Test renders "Mulai" button
    - Test tapping "Mulai" calls `completeFirstLaunch()` and navigates to /login
    - Test uses dark theme (Brightness.dark)
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1_

- [x] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Integrate WelcomeScreen with GoRouter
  - [x] 5.1 Add `/welcome` route dan modify redirect logic di `main.dart`
    - Tambah `GoRoute(path: '/welcome', builder: (...) => const WelcomeScreen())` ke router config
    - Modifikasi redirect function: saat status unauthenticated dan user di splash, cek `authProvider.firstLaunchCompleted`
    - Jika `firstLaunchCompleted == false` → redirect ke `/welcome`
    - Jika `firstLaunchCompleted == true` → redirect ke `/login`
    - Guard: authenticated user yang akses `/welcome` → redirect ke `/main`
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.6_

  - [x] 5.2 Write property test for routing decision correctness
    - **Property 1: Routing decision correctness**
    - **Validates: Requirements 2.2, 2.3, 2.4, 3.2, 3.3, 3.4, 3.6**
    - Generate random combinations of AuthStatus (unknown, authenticated, unauthenticated), flag state (true, false, error), dan current location (/splash, /welcome, /login, /main)
    - Verify redirect output matches the routing decision table dari design document untuk semua kombinasi
    - Gunakan loop-based approach dengan exhaustive input generation (semua kombinasi finite)

  - [x] 5.3 Write unit tests for GoRouter redirect logic
    - Test redirect returns `/welcome` when unauthenticated + flag not set
    - Test redirect returns `/login` when unauthenticated + flag is true
    - Test redirect returns `/main` when authenticated (regardless of flag)
    - Test authenticated user cannot access `/welcome` (redirected to `/main`)
    - Test redirect returns `/welcome` when flag read fails (error fallback)
    - _Requirements: 3.2, 3.3, 3.4, 3.6_

- [x] 6. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property test (5.2) validates universal correctness of routing decision table
- Unit tests validate specific examples and edge cases
- Dart tidak punya library PBT mainstream — gunakan exhaustive loop-based approach karena input space finite (3 × 3 × 5 = 45 kombinasi)
- Semua UI text dalam Bahasa Indonesia sesuai project convention

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2", "2.1"] },
    { "id": 2, "tasks": ["2.2", "3.1"] },
    { "id": 3, "tasks": ["3.2", "5.1"] },
    { "id": 4, "tasks": ["5.2", "5.3"] }
  ]
}
```
