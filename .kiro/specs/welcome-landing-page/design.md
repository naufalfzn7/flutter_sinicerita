# Design Document: Welcome Landing Page

## Overview

Halaman welcome/landing page sederhana yang ditampilkan saat user pertama kali membuka aplikasi SiniCerita. Halaman ini menampilkan logo, tagline, dan tombol "Mulai" yang mengarahkan ke flow autentikasi. Fitur ini menggunakan `FlutterSecureStorage` untuk menyimpan flag first-launch dan terintegrasi dengan GoRouter redirect logic yang sudah ada.

**Keputusan desain utama:**
- Tidak membuat provider baru — logic first-launch flag cukup sederhana untuk ditangani langsung di `SecureStorage` wrapper dan router redirect
- Memodifikasi `SecureStorage` untuk menambah method read/write first-launch flag
- Memodifikasi GoRouter redirect function untuk memeriksa flag sebelum routing ke `/login`
- Welcome screen adalah stateless widget sederhana tanpa state management kompleks

## Architecture

```mermaid
flowchart TD
    A[App Launch] --> B[SplashScreen]
    B --> C{checkAuthStatus}
    C -->|authenticated| D[/main]
    C -->|unauthenticated| E{First Launch Flag?}
    E -->|not set / false / read error| F[/welcome]
    E -->|true| G[/login]
    F --> H[User taps 'Mulai']
    H --> I[Store flag = true]
    I --> G
```

**Flow navigasi:**
1. App launch → SplashScreen → `checkAuthStatus()`
2. Jika authenticated → redirect ke `/main`
3. Jika unauthenticated → cek first-launch flag di SecureStorage
4. Flag belum ada / false / read error → tampilkan `/welcome`
5. Flag sudah true → langsung ke `/login`
6. User tap "Mulai" → simpan flag → navigate ke `/login`

### Integrasi dengan Arsitektur Existing

- **GoRouter**: Tambah route `/welcome` dan modifikasi redirect logic di `_createRouter()`
- **SecureStorage**: Tambah key constant dan method untuk first-launch flag
- **SplashScreen**: Tidak perlu diubah — GoRouter redirect yang handle routing
- **AuthProvider**: Tidak perlu diubah — tetap expose `AuthStatus` via `refreshListenable`

## Components and Interfaces

### 1. SecureStorage (Modified)

Tambah method untuk manage first-launch flag:

```dart
// Tambahan di SecureStorage class
static const String _firstLaunchKey = 'first_launch_completed';

Future<bool> isFirstLaunchCompleted() async {
  try {
    final value = await _storage.read(key: _firstLaunchKey);
    return value == 'true';
  } catch (_) {
    return false; // fallback: treat as not completed
  }
}

Future<void> setFirstLaunchCompleted() async {
  await _storage.write(key: _firstLaunchKey, value: 'true');
}
```

### 2. WelcomeScreen (New)

File: `lib/screens/auth/welcome_screen.dart`

```dart
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  // Displays: logo, tagline, "Mulai" button
  // On tap: store flag → context.go('/login')
}
```

**Responsibilities:**
- Render UI (logo centered upper, tagline middle, button bottom)
- Handle button tap: write flag to storage, then navigate

### 3. GoRouter Redirect (Modified)

Modifikasi `_createRouter()` di `main.dart`:
- Tambah route `/welcome`
- Modifikasi redirect: saat status unauthenticated dan di splash, cek flag dulu sebelum redirect

**Interface perubahan redirect:**

```dart
// Pseudo-logic redirect baru
if (isOnSplash && status != AuthStatus.unknown) {
  if (status == AuthStatus.authenticated) return '/main';
  // unauthenticated: cek flag
  final flagCompleted = await secureStorage.isFirstLaunchCompleted();
  return flagCompleted ? '/login' : '/welcome';
}

// Guard: authenticated users cannot access /welcome
if (status == AuthStatus.authenticated && location == '/welcome') {
  return '/main';
}
```

**Catatan**: Karena GoRouter `redirect` adalah synchronous function, kita perlu strategi untuk async flag check. Solusi: baca flag di `checkAuthStatus()` dan expose hasilnya via AuthProvider atau baca flag sebelum router dibuat.

**Keputusan**: Baca flag sekali saat app startup (sebelum `runApp`) dan pass ke router sebagai initial state. Atau lebih baik: tambah field `_firstLaunchCompleted` di AuthProvider yang di-set saat `checkAuthStatus()`.

### 4. AuthProvider (Minor Addition)

Tambah field untuk first-launch flag state agar bisa diakses synchronously oleh router redirect:

```dart
bool _firstLaunchCompleted = false;
bool get firstLaunchCompleted => _firstLaunchCompleted;

// Di dalam checkAuthStatus(), sebelum set status:
Future<void> checkAuthStatus() async {
  // Baca first-launch flag
  _firstLaunchCompleted = await _apiClient.storage.isFirstLaunchCompleted();
  
  // ... existing auth check logic ...
}

// Method untuk set flag (dipanggil dari WelcomeScreen)
Future<void> completeFirstLaunch() async {
  await _apiClient.storage.setFirstLaunchCompleted();
  _firstLaunchCompleted = true;
  notifyListeners(); // trigger router redirect
}
```

## Data Models

Tidak ada model data baru. Fitur ini hanya menggunakan:

| Data | Storage | Key | Value |
|------|---------|-----|-------|
| First Launch Flag | FlutterSecureStorage | `first_launch_completed` | `'true'` atau null |

**State yang relevan:**

```dart
// Di AuthProvider
bool _firstLaunchCompleted = false; // default: belum pernah launch
```

**Routing Decision Table:**

| AuthStatus | First Launch Flag | Current Location | Target Route |
|------------|-------------------|------------------|--------------|
| unknown | any | /splash | null (stay) |
| authenticated | any | any | /main |
| unauthenticated | not set / false / error | /splash | /welcome |
| unauthenticated | true | /splash | /login |
| unauthenticated | any | /welcome | null (stay) |
| authenticated | any | /welcome | /main |

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Routing decision correctness

*For any* combination of auth status (unknown, authenticated, unauthenticated), first-launch flag state (true, false/not-set, read-error), and current location (/splash, /welcome, /login, /main), the redirect function SHALL produce the correct target route as defined by the routing decision table: authenticated users always route to /main (never /welcome), unauthenticated users without a completed first-launch flag route to /welcome, and unauthenticated users with a completed first-launch flag route to /login.

**Validates: Requirements 2.2, 2.3, 2.4, 3.2, 3.3, 3.4, 3.6**

## Error Handling

| Scenario | Handling | User Impact |
|----------|----------|-------------|
| FlutterSecureStorage read fails (flag) | Catch exception, return `false` | User sees welcome screen (safe fallback) |
| FlutterSecureStorage write fails (set flag) | Catch exception, still navigate to /login | User may see welcome again next launch (acceptable) |
| Navigation timeout (>300ms) | No explicit timeout — GoRouter navigates immediately | Negligible risk |

**Design rationale**: Semua error di-handle dengan fallback ke welcome screen. Ini aman karena worst case user hanya melihat welcome screen lagi — tidak ada data loss atau broken state.

## Testing Strategy

### Unit Tests

**Routing redirect logic** (pure function test):
- Test redirect returns `/welcome` when unauthenticated + flag not set
- Test redirect returns `/login` when unauthenticated + flag is true
- Test redirect returns `/main` when authenticated (regardless of flag)
- Test redirect returns `/welcome` when flag read fails (error fallback)
- Test authenticated user cannot access `/welcome` (redirected to `/main`)

**SecureStorage flag methods:**
- Test `isFirstLaunchCompleted()` returns false when key doesn't exist
- Test `isFirstLaunchCompleted()` returns true after `setFirstLaunchCompleted()`
- Test `isFirstLaunchCompleted()` returns false when storage throws

**AuthProvider.completeFirstLaunch():**
- Test sets `_firstLaunchCompleted` to true
- Test calls `notifyListeners()`
- Test writes to storage

### Property-Based Tests

**Library**: `dart_quickcheck` atau custom property test runner (Dart tidak punya library PBT mainstream yang mature — gunakan loop-based approach dengan random input generation)

**Property 1 implementation**: Generate random combinations of:
- `AuthStatus` ∈ {unknown, authenticated, unauthenticated}
- `flagState` ∈ {true, false, error}
- `currentLocation` ∈ {'/splash', '/welcome', '/login', '/main', '/register'}

Verify redirect output matches the decision table for all 100+ generated combinations.

Tag: **Feature: welcome-landing-page, Property 1: Routing decision correctness — For any combination of auth status, flag state, and location, redirect produces the correct route**

### Widget Tests

- WelcomeScreen renders logo, tagline text containing "SiniCerita", and "Mulai" button
- Tapping "Mulai" calls `completeFirstLaunch()` and navigates to `/login`
- WelcomeScreen uses dark theme (Brightness.dark)

### Integration Tests

- Full flow: fresh app launch → splash → welcome → tap Mulai → login screen
- Subsequent launch: app launch → splash → login (skips welcome)
