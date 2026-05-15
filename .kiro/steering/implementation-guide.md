---
inclusion: manual
---

# Implementation Guide — Tahap-per-Tahap

Referensi ini berisi ringkasan setiap tahap implementasi. Untuk detail lengkap (kode, test guide), buka `flutter-implementation.md`.

#[[file:flutter-implementation.md]]

## Workflow per Tahap

1. Implementasikan kode untuk satu tahap
2. Berikan Manual Emulator Test Guide (checklist skenario)
3. User test di emulator dan lapor hasil
4. Jika ada bug → perbaiki di tahap yang sama
5. Semua checklist ✅ PASS → lanjut tahap berikutnya

## Tahap 1: Fondasi
- `flutter create`, dependencies, folder structure
- `api_endpoints.dart`, `secure_storage.dart`, `api_client.dart` (Dio + interceptor)
- `api_response.dart`, `app_exception.dart`
- `main.dart` minimal dengan Ping test
- Android: `INTERNET` permission + `usesCleartextTraffic=true`

## Tahap 2: Auth (Register & Login)
- `user_model.dart`
- `auth_provider.dart` (register, login, logout, fetchMe, checkAuthStatus)
- LoginScreen, RegisterScreen, SplashScreen
- Token persistence → auto-login

## Tahap 3: Forgot Password & OTP
- ForgotEmailScreen → OtpScreen → ResetPasswordScreen
- `pin_code_fields` untuk input OTP 6 digit
- Countdown 60 detik untuk "Kirim Ulang"

## Tahap 4: Main Navigation & Profil
- MainScreen (BottomNav: Home, Persona, Profil)
- ProfileScreen, EditProfileScreen (multipart upload), ChangePasswordScreen
- Logout dengan dialog konfirmasi

## Tahap 5: Persona List & Rating
- `persona_model.dart`, `persona_provider.dart`
- PersonaListScreen (paginated, shimmer, pull-to-refresh)
- PersonaDetailScreen (rating UP/DOWN/NONE, optimistic update)

## Tahap 6: Chat Room (Core Feature)
- `message_model.dart`, `session_model.dart`, `session_provider.dart`
- ChatScreen (bubble layout, typing indicator, auto-scroll)
- Create session dari PersonaDetailScreen

## Tahap 7: Session Completion & Scoring
- `completeSession()` → SessionSummaryScreen
- Animasi counter poin (TweenAnimationBuilder)
- Refresh poin di profil setelah complete

## Tahap 8: Session History & Delete
- HomeScreen TabBar (Aktif / Selesai)
- Swipe-to-delete (hanya active sessions)
- SessionSummaryScreen read-only mode
- Empty state

## Tahap 9: Finalisasi & Polish
- Verifikasi token rotation end-to-end
- GoRouter redirect guard
- Global error mapping
- Shimmer di semua list
- Pull-to-refresh everywhere
- Animasi & transisi halus
