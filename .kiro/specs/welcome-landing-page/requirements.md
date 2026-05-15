# Requirements Document

## Introduction

Halaman welcome/landing page untuk aplikasi SiniCerita yang muncul sebagai layar pertama sebelum user diarahkan ke halaman login atau register. Halaman ini berfungsi sebagai pengenalan singkat aplikasi dengan pesan sambutan, logo SiniCerita, dan tombol "Mulai" untuk melanjutkan ke flow autentikasi.

## Glossary

- **Welcome_Screen**: Layar landing page pertama yang ditampilkan kepada user baru sebelum halaman login/register
- **Get_Started_Button**: Tombol call-to-action utama di Welcome_Screen yang mengarahkan user ke halaman login
- **App_Logo**: Aset gambar logo SiniCerita beserta teks nama aplikasi
- **GoRouter**: Library navigasi yang digunakan untuk routing antar halaman di aplikasi Flutter
- **First_Launch_Flag**: Status yang menandakan apakah user sudah pernah melihat Welcome_Screen sebelumnya

## Requirements

### Requirement 1: Tampilan Welcome Screen

**User Story:** Sebagai user baru, saya ingin melihat halaman sambutan saat pertama kali membuka aplikasi, sehingga saya mendapat kesan pertama yang baik tentang SiniCerita.

#### Acceptance Criteria

1. WHEN the app launches for the first time, THE Welcome_Screen SHALL display the App_Logo horizontally centered in the upper portion of the screen
2. WHEN the Welcome_Screen is displayed, THE Welcome_Screen SHALL show a welcome message text in Bahasa Indonesia below the App_Logo that contains the app name "SiniCerita" and a brief tagline describing the app's purpose
3. WHEN the Welcome_Screen is displayed, THE Welcome_Screen SHALL show the Get_Started_Button labeled "Mulai" at the bottom portion of the screen
4. THE Welcome_Screen SHALL use the existing dark theme defined in the app's AppTheme

### Requirement 2: Navigasi dari Welcome Screen

**User Story:** Sebagai user, saya ingin menekan tombol "Mulai" di halaman welcome, sehingga saya dapat melanjutkan ke halaman login untuk masuk atau mendaftar.

#### Acceptance Criteria

1. WHEN the user taps the Get_Started_Button, THE Welcome_Screen SHALL store the First_Launch_Flag to FlutterSecureStorage and then navigate the user to the '/login' route within 300ms
2. IF the First_Launch_Flag exists in FlutterSecureStorage at app launch, THEN THE GoRouter SHALL skip the Welcome_Screen and navigate directly to the '/login' route
3. IF the First_Launch_Flag does not exist in FlutterSecureStorage at app launch, THEN THE GoRouter SHALL navigate to the Welcome_Screen
4. IF reading the First_Launch_Flag from FlutterSecureStorage fails at app launch, THEN THE GoRouter SHALL navigate to the Welcome_Screen as a fallback

### Requirement 3: Integrasi dengan Router

**User Story:** Sebagai developer, saya ingin welcome screen terintegrasi dengan GoRouter yang sudah ada, sehingga flow navigasi tetap konsisten dengan arsitektur aplikasi.

#### Acceptance Criteria

1. THE GoRouter SHALL include a route path for the Welcome_Screen at '/welcome'
2. WHEN AuthStatus resolves from unknown to unauthenticated on the splash screen, IF the First_Launch_Flag in FlutterSecureStorage is not set or is false, THEN THE GoRouter redirect logic SHALL navigate to '/welcome'
3. WHEN AuthStatus resolves from unknown to unauthenticated on the splash screen, IF the First_Launch_Flag in FlutterSecureStorage is true, THEN THE GoRouter redirect logic SHALL navigate to '/login'
4. IF the user is authenticated, THEN THE GoRouter redirect logic SHALL navigate to '/main' and SHALL NOT allow navigation to '/welcome'
5. WHEN the user completes the Welcome_Screen and triggers navigation to '/login', THE system SHALL set the First_Launch_Flag to true in FlutterSecureStorage before performing the navigation
6. IF reading the First_Launch_Flag from FlutterSecureStorage fails, THEN THE GoRouter redirect logic SHALL treat the flag as false and navigate to '/welcome'
