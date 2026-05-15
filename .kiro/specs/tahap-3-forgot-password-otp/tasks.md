# Implementation Plan: Tahap 3 — Forgot Password & OTP

## Overview

Implement fitur Forgot Password untuk SiniCerita Flutter app: 3 method baru di AuthProvider (forgotPassword, verifyOtp, resetPassword), 3 screen baru (ForgotPasswordScreen, OtpVerificationScreen, ResetPasswordScreen), 3 route publik di GoRouter, dan update LoginScreen dengan link "Lupa Password?". Builds on existing Tahap 2 infrastructure (AuthProvider, GoRouter, Validators, ApiEndpoints).

## Tasks

- [x] 1. Add AuthProvider methods for forgot password flow
  - [x] 1.1 Add `successMessage` state field and getter to `lib/providers/auth_provider.dart`
    - Add `String? _successMessage;` private field
    - Add `String? get successMessage => _successMessage;` getter
    - This field stores the backend success message from response for SnackBar display
    - _Requirements: 1.5, 2.5, 3.6_

  - [x] 1.2 Implement `forgotPassword(String email)` method in `lib/providers/auth_provider.dart`
    - Returns `Future<bool>`
    - Set `_isLoading = true`, `_errorMessage = null`, `_successMessage = null`, `notifyListeners()`
    - POST to `ApiEndpoints.forgotPassword` with `{'email': email}`
    - On success: parse `response.data['message']` → set `_successMessage`, set `_isLoading = false`, `notifyListeners()`, return `true`
    - On `DioException`: convert via `AppException.fromDioError(e)`, set `_errorMessage = ex.message`, set `_isLoading = false`, `notifyListeners()`, return `false`
    - _Requirements: 4.1, 4.4, 4.5, 4.6_

  - [x] 1.3 Implement `verifyOtp(String email, String code)` method in `lib/providers/auth_provider.dart`
    - Returns `Future<bool>`
    - Set `_isLoading = true`, `_errorMessage = null`, `_successMessage = null`, `notifyListeners()`
    - POST to `ApiEndpoints.verifyOtp` with `{'email': email, 'code': code}`
    - On success: parse `response.data['message']` → set `_successMessage`, set `_isLoading = false`, `notifyListeners()`, return `true`
    - On `DioException`: convert via `AppException.fromDioError(e)`, set `_errorMessage = ex.message`, set `_isLoading = false`, `notifyListeners()`, return `false`
    - _Requirements: 4.2, 4.4, 4.5, 4.6_

  - [x] 1.4 Implement `resetPassword(String email, String code, String newPassword)` method in `lib/providers/auth_provider.dart`
    - Returns `Future<bool>`
    - Set `_isLoading = true`, `_errorMessage = null`, `_successMessage = null`, `notifyListeners()`
    - POST to `ApiEndpoints.resetPassword` with `{'email': email, 'code': code, 'newPassword': newPassword}`
    - On success: parse `response.data['message']` → set `_successMessage`, set `_isLoading = false`, `notifyListeners()`, return `true`
    - On `DioException`: convert via `AppException.fromDioError(e)`, set `_errorMessage = ex.message`, set `_isLoading = false`, `notifyListeners()`, return `false`
    - _Requirements: 4.3, 4.4, 4.5, 4.6_

- [x] 2. Create ForgotPasswordScreen
  - [x] 2.1 Create `lib/screens/auth/forgot_password_screen.dart`
    - `StatefulWidget` with `const` constructor
    - State fields: `_formKey = GlobalKey<FormState>()`, `_emailController = TextEditingController()`
    - Dispose `_emailController` in `dispose()`
    - UI Layout:
      - `Scaffold` with `AppBar` (title: "Lupa Password", auto back button)
      - `SingleChildScrollView` with padding 24
      - Subtitle `Text`: "Masukkan email untuk menerima kode OTP"
      - `Form` with `TextFormField` for email (validator: `Validators.validateEmail`, keyboardType: emailAddress, prefixIcon: email icon)
      - `ElevatedButton` "Kirim OTP" (full width, height 48)
    - Button logic:
      - Disabled when `context.watch<AuthProvider>().isLoading`
      - Show `CircularProgressIndicator` (width 20, height 20, strokeWidth 2) when loading
    - `_onSubmit()` method:
      - Validate form, return if invalid
      - `final email = _emailController.text.trim()`
      - `final success = await context.read<AuthProvider>().forgotPassword(email)`
      - `if (!mounted) return;`
      - If success: show green SnackBar with `context.read<AuthProvider>().successMessage`, then `context.push('/otp-verification', extra: email)`
      - If failure: show red SnackBar with `context.read<AuthProvider>().errorMessage`
    - SnackBar pattern: floating, margin top 16/left 16/right 16/bottom `MediaQuery.of(context).size.height - 150`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7_

- [x] 3. Create OtpVerificationScreen
  - [x] 3.1 Create `lib/screens/auth/otp_verification_screen.dart`
    - `StatefulWidget` with required `String email` parameter
    - `const OtpVerificationScreen({super.key, required this.email})`
    - State fields: `_otpController = TextEditingController()`, `bool _isComplete = false`
    - Dispose `_otpController` in `dispose()`
    - UI Layout:
      - `Scaffold` with `AppBar` (title: "Verifikasi OTP", auto back button)
      - `SingleChildScrollView` with padding 24
      - Subtitle `Text`: "Masukkan 6 digit kode yang dikirim ke ${widget.email}"
      - `PinCodeTextField` from `pin_code_fields` package:
        - `appContext: context`, `length: 6`, `controller: _otpController`
        - `keyboardType: TextInputType.number`
        - `animationType: AnimationType.fade`
        - `enableActiveFill: true`
        - `pinTheme`: box shape, borderRadius 8, fieldHeight 50, fieldWidth 45, white fill colors, primary active/selected color, grey[300] inactive color
        - `onChanged: _onOtpChanged`
      - `ElevatedButton` "Verifikasi" (full width, height 48)
    - `_onOtpChanged(String value)`: `setState(() { _isComplete = value.length == 6; })`
    - Button logic:
      - Disabled when `!_isComplete || context.watch<AuthProvider>().isLoading`
      - Show `CircularProgressIndicator` when loading
    - `_onVerify()` method:
      - `final code = _otpController.text`
      - `final success = await context.read<AuthProvider>().verifyOtp(widget.email, code)`
      - `if (!mounted) return;`
      - If success: show green SnackBar with `successMessage`, then `context.push('/reset-password', extra: {'email': widget.email, 'code': code})`
      - If failure: show red SnackBar with `errorMessage`
    - SnackBar pattern: same floating pattern as ForgotPasswordScreen
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

- [x] 4. Create ResetPasswordScreen
  - [x] 4.1 Create `lib/screens/auth/reset_password_screen.dart`
    - `StatefulWidget` with required `String email` and `String code` parameters
    - `const ResetPasswordScreen({super.key, required this.email, required this.code})`
    - State fields: `_formKey`, `_passwordController`, `_confirmPasswordController`, `bool _obscurePassword = true`, `bool _obscureConfirmPassword = true`
    - Dispose both controllers in `dispose()`
    - UI Layout:
      - `Scaffold` with `AppBar` (title: "Reset Password", auto back button)
      - `SingleChildScrollView` with padding 24
      - Subtitle `Text`: "Masukkan password baru"
      - `Form` with:
        - Password `TextFormField` (validator: `Validators.validatePassword`, obscureText toggle, prefixIcon: lock, suffixIcon: visibility toggle)
        - Confirm Password `TextFormField` (validator: `Validators.validateConfirmPassword(value, _passwordController.text)`, obscureText toggle, prefixIcon: lock, suffixIcon: visibility toggle)
      - `ElevatedButton` "Reset Password" (full width, height 48)
    - Button logic:
      - Disabled when `context.watch<AuthProvider>().isLoading`
      - Show `CircularProgressIndicator` when loading
    - `_onSubmit()` method:
      - Validate form, return if invalid
      - `final success = await context.read<AuthProvider>().resetPassword(widget.email, widget.code, _passwordController.text)`
      - `if (!mounted) return;`
      - If success: show green SnackBar with `successMessage`, then `context.go('/login')` (replaces stack)
      - If failure: show red SnackBar with `errorMessage`
    - SnackBar pattern: same floating pattern
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [x] 5. Update GoRouter in main.dart
  - [x] 5.1 Add 3 new routes and update redirect logic in `lib/main.dart`
    - Add imports for `ForgotPasswordScreen`, `OtpVerificationScreen`, `ResetPasswordScreen`
    - Add 3 new `GoRoute` entries after `/register`:
      - `/forgot-password` → `builder: (_, __) => const ForgotPasswordScreen()`
      - `/otp-verification` → validate `state.extra as String?`, if null return `ForgotPasswordScreen()`, else return `OtpVerificationScreen(email: email)`
      - `/reset-password` → validate `state.extra as Map<String, String>?`, check `extras['email']` and `extras['code']` exist, if invalid return `ForgotPasswordScreen()`, else return `ResetPasswordScreen(email: ..., code: ...)`
    - Update redirect logic:
      - Change `isOnAuth` to include forgot password routes: `location == '/login' || location == '/register' || location == '/forgot-password' || location == '/otp-verification' || location == '/reset-password'`
      - Auth guard for authenticated users: only redirect from `/login` and `/register` to `/main` (NOT from forgot password routes)
      - Keep existing: unauthenticated on `/main` → redirect to `/login`
    - _Requirements: 5.1, 5.2, 6.1, 6.2, 6.3_

- [x] 6. Update LoginScreen with "Lupa Password?" link
  - [x] 6.1 Add "Lupa Password?" link to `lib/screens/auth/login_screen.dart`
    - Add between the password field and the "Masuk" button (after SizedBox(height: 24) before button)
    - Use `Align(alignment: Alignment.centerRight)` with `GestureDetector`
    - Text: "Lupa Password?" with primary color and fontWeight bold
    - `onTap: () => context.push('/forgot-password')`
    - Add `SizedBox(height: 16)` between the link and the button
    - _Requirements: 5.3_

- [x] 7. Final checkpoint — Integration verification
  - Verify complete flow: login → forgot-password → otp-verification → reset-password → login
  - Verify redirect guards: direct navigation to /otp-verification without extras → redirects to ForgotPasswordScreen
  - Verify redirect guards: direct navigation to /reset-password without extras → redirects to ForgotPasswordScreen
  - Verify authenticated users can still access forgot password routes
  - Verify back button navigation works on all 3 screens
  - Verify client-side validation on ForgotPasswordScreen (empty/invalid email)
  - Verify client-side validation on ResetPasswordScreen (short password, mismatched passwords)
  - Verify OTP button disabled until 6 digits entered
  - Verify all buttons disabled during loading state
  - Verify SnackBar shows exact backend messages (green for success, red for error)
  - _Requirements: 1.1–6.3 (all)_

## Task Dependency Graph

```json
{
  "waves": [
    {
      "wave": 1,
      "tasks": ["1"],
      "description": "Add AuthProvider methods (forgotPassword, verifyOtp, resetPassword) — no UI dependency"
    },
    {
      "wave": 2,
      "tasks": ["2", "3", "4"],
      "description": "Create screens (ForgotPassword, OtpVerification, ResetPassword) — depend on AuthProvider methods"
    },
    {
      "wave": 3,
      "tasks": ["5"],
      "description": "Update GoRouter with 3 new routes and redirect logic — depends on screen files for imports"
    },
    {
      "wave": 4,
      "tasks": ["6"],
      "description": "Update LoginScreen with 'Lupa Password?' link — depends on /forgot-password route being defined"
    },
    {
      "wave": 5,
      "tasks": ["7"],
      "description": "Final checkpoint — integration verification of complete flow"
    }
  ]
}
```

## Notes

- All 3 API endpoints (`forgotPassword`, `verifyOtp`, `resetPassword`) are already defined in `ApiEndpoints` class
- `pin_code_fields: ^8.0.1` is already in pubspec.yaml
- Existing `Validators.validateEmail`, `Validators.validatePassword`, and `Validators.validateConfirmPassword` are reused
- All UI text in Bahasa Indonesia per project conventions
- Use `context.read<T>()` for method calls in callbacks, `context.watch<T>()` for reactive rebuilds
- `context.push()` for forward navigation (allows back), `context.go()` for replace (reset password → login)
- SnackBar pattern matches existing login/register screens (floating, positioned near top)
- `if (!mounted) return;` after every async gap to prevent setState on disposed widget
