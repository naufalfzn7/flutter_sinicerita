# Requirements Document

## Introduction

Fitur "Lupa Password" (Forgot Password) untuk aplikasi SiniCerita Flutter. Fitur ini memungkinkan user yang lupa password untuk melakukan reset melalui verifikasi OTP yang dikirim ke email. Flow terdiri dari 3 langkah: request OTP → verifikasi OTP → set password baru. Semua endpoint bersifat publik (tanpa auth token).

## Glossary

- **App**: Aplikasi Flutter SiniCerita
- **AuthProvider**: ChangeNotifier yang mengelola state autentikasi dan method API call
- **ForgotPasswordScreen**: Halaman input email untuk request OTP
- **OtpVerificationScreen**: Halaman input 6-digit OTP code
- **ResetPasswordScreen**: Halaman input password baru dan konfirmasi
- **OTP**: One-Time Password, kode 6 digit yang dikirim ke email user
- **SnackBar**: Komponen notifikasi di bagian atas layar
- **GoRouter**: Library navigasi deklaratif yang digunakan di app

## Requirements

### Requirement 1: Request OTP via Email

**User Story:** As a user who forgot their password, I want to request an OTP code by entering my email, so that I can verify my identity and reset my password.

#### Acceptance Criteria

1. WHEN a user navigates to ForgotPasswordScreen, THE App SHALL display an email input field and a "Kirim OTP" button
2. WHEN a user submits an empty or invalid email format, THE App SHALL display a client-side validation error without calling the API
3. WHEN a user submits a valid email, THE AuthProvider SHALL call POST /api/auth/forgot-password with the email in the request body
4. WHILE the API call is in progress, THE App SHALL disable the "Kirim OTP" button and show a loading indicator
5. WHEN the API returns success, THE App SHALL display the backend success message in a green SnackBar and navigate to OtpVerificationScreen passing the email
6. IF the API returns an error, THEN THE App SHALL display the backend error message exactly as received in a red SnackBar
7. WHEN navigating to OtpVerificationScreen, THE App SHALL pass the email address so it can be used in subsequent API calls

### Requirement 2: Verify OTP Code

**User Story:** As a user who received an OTP, I want to enter the 6-digit code to verify my identity, so that I can proceed to reset my password.

#### Acceptance Criteria

1. WHEN a user navigates to OtpVerificationScreen, THE App SHALL display a 6-digit PIN input field using pin_code_fields package and a "Verifikasi" button
2. WHEN a user has not entered all 6 digits, THE App SHALL keep the "Verifikasi" button disabled
3. WHEN a user submits a complete 6-digit code, THE AuthProvider SHALL call POST /api/auth/verify-otp with email and code in the request body
4. WHILE the API call is in progress, THE App SHALL disable the "Verifikasi" button and show a loading indicator
5. WHEN the API returns success, THE App SHALL display the backend success message in a green SnackBar and navigate to ResetPasswordScreen passing email and code
6. IF the API returns an error, THEN THE App SHALL display the backend error message exactly as received in a red SnackBar
7. WHEN navigating to ResetPasswordScreen, THE App SHALL pass both the email and OTP code so they can be used in the reset API call

### Requirement 3: Reset Password

**User Story:** As a user who verified their OTP, I want to set a new password, so that I can regain access to my account.

#### Acceptance Criteria

1. WHEN a user navigates to ResetPasswordScreen, THE App SHALL display a new password field, a confirm password field, and a "Reset Password" button
2. WHEN a user submits with password shorter than 8 characters or empty fields, THE App SHALL display client-side validation errors without calling the API
3. WHEN a user submits with non-matching password and confirmation, THE App SHALL display a client-side validation error "Password tidak cocok"
4. WHEN a user submits valid matching passwords, THE AuthProvider SHALL call POST /api/auth/reset-password with email, code, and newPassword in the request body
5. WHILE the API call is in progress, THE App SHALL disable the "Reset Password" button and show a loading indicator
6. WHEN the API returns success, THE App SHALL display the backend success message in a green SnackBar and navigate to the login screen
7. IF the API returns an error, THEN THE App SHALL display the backend error message exactly as received in a red SnackBar

### Requirement 4: AuthProvider Methods

**User Story:** As a developer, I want AuthProvider to expose forgotPassword, verifyOtp, and resetPassword methods, so that screens can call them following the existing provider pattern.

#### Acceptance Criteria

1. THE AuthProvider SHALL expose a `forgotPassword(String email)` method that returns `Future<bool>` and sets errorMessage on failure
2. THE AuthProvider SHALL expose a `verifyOtp(String email, String code)` method that returns `Future<bool>` and sets errorMessage on failure
3. THE AuthProvider SHALL expose a `resetPassword(String email, String code, String newPassword)` method that returns `Future<bool>` and sets errorMessage on failure
4. WHEN any of the three methods is called, THE AuthProvider SHALL set isLoading to true, clear errorMessage, and call notifyListeners before the API call
5. WHEN any of the three methods completes (success or failure), THE AuthProvider SHALL set isLoading to false and call notifyListeners
6. IF a DioException occurs, THEN THE AuthProvider SHALL convert it to AppException and set errorMessage to the exception message

### Requirement 5: Navigation and Routing

**User Story:** As a user, I want to navigate between forgot password screens smoothly, so that the flow feels intuitive and I can go back if needed.

#### Acceptance Criteria

1. THE GoRouter SHALL define routes /forgot-password, /otp-verification, and /reset-password as public routes without auth guard redirect
2. WHEN an authenticated user navigates to /forgot-password, /otp-verification, or /reset-password, THE GoRouter SHALL allow access without redirecting to /main
3. WHEN a user taps "Lupa Password?" on the login screen, THE App SHALL navigate to /forgot-password
4. WHEN a user taps the back button on any of the three screens, THE App SHALL navigate to the previous screen
5. WHEN password reset is successful, THE App SHALL navigate to /login replacing the navigation stack

### Requirement 6: Data Passing Between Screens

**User Story:** As a developer, I want email and OTP code to be passed between screens via route parameters, so that each screen has the data it needs for API calls.

#### Acceptance Criteria

1. WHEN navigating from ForgotPasswordScreen to OtpVerificationScreen, THE App SHALL pass the email as a route extra parameter
2. WHEN navigating from OtpVerificationScreen to ResetPasswordScreen, THE App SHALL pass both email and code as route extra parameters
3. IF a user navigates directly to OtpVerificationScreen or ResetPasswordScreen without required parameters, THEN THE App SHALL redirect to /forgot-password
