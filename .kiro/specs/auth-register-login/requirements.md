# Requirements Document

## Introduction

Tahap 2 dari aplikasi Flutter SiniCerita: implementasi fitur autentikasi lengkap meliputi registrasi akun baru, login, persistensi sesi (token JWT), dan navigasi berbasis status autentikasi. Fitur ini membangun di atas fondasi Tahap 1 (ApiClient, SecureStorage, Validators) dan menyediakan alur masuk/daftar yang aman serta user-friendly.

## Glossary

- **AuthProvider**: ChangeNotifier yang mengelola state autentikasi (login, register, logout, fetch profile)
- **UserModel**: Data class yang merepresentasikan user dari backend (id, name, email, role, points, avatarUrl, createdAt)
- **AuthStatus**: Enum dengan tiga nilai: `unknown` (belum dicek), `authenticated` (token valid), `unauthenticated` (tidak ada token/token invalid)
- **SecureStorage**: Wrapper FlutterSecureStorage untuk menyimpan access token dan refresh token
- **ApiClient**: Dio HTTP client dengan JWT interceptor untuk auto-refresh token
- **GoRouter**: Library navigasi deklaratif dengan redirect guard
- **Validators**: Utility class untuk validasi form client-side

## Requirements

### Requirement 1: User Data Model

**User Story:** As a developer, I want a UserModel class that maps to the backend user schema, so that user data can be parsed and serialized consistently throughout the app.

#### Acceptance Criteria

1. THE UserModel SHALL contain fields: id (String), name (String), email (String), role (String), points (int), avatarUrl (String?), createdAt (DateTime)
2. WHEN a valid JSON map from the backend is provided, THE UserModel.fromJson factory SHALL produce a UserModel instance with all fields correctly mapped
3. WHEN a UserModel instance calls toJson, THE UserModel SHALL produce a Map<String, dynamic> that matches the backend schema
4. WHEN the avatarUrl field is null in the JSON, THE UserModel SHALL set avatarUrl to null without error

### Requirement 2: Authentication State Management

**User Story:** As a user, I want the app to remember my login session, so that I don't have to log in every time I open the app.

#### Acceptance Criteria

1. THE AuthProvider SHALL expose an AuthStatus that is one of: unknown, authenticated, unauthenticated
2. THE AuthProvider SHALL expose the current UserModel when authenticated
3. WHEN checkAuthStatus is called and a valid access token exists in SecureStorage, THE AuthProvider SHALL fetch the user profile and set status to authenticated
4. WHEN checkAuthStatus is called and no access token exists, THE AuthProvider SHALL set status to unauthenticated
5. IF fetching the user profile fails during checkAuthStatus, THEN THE AuthProvider SHALL clear tokens and set status to unauthenticated

### Requirement 3: User Registration

**User Story:** As a new user, I want to create an account with my name, email, and password, so that I can access the SiniCerita platform.

#### Acceptance Criteria

1. WHEN a user submits valid registration data (name, email, password), THE AuthProvider SHALL send a POST request to /api/auth/register with the provided data
2. WHEN registration succeeds (201), THE AuthProvider SHALL automatically log the user in by calling the login method
3. IF the backend returns a 409 error (email already registered), THEN THE AuthProvider SHALL expose the exact backend error message
4. IF the backend returns a 400 validation error, THEN THE AuthProvider SHALL expose the exact backend error message

### Requirement 4: User Login

**User Story:** As a registered user, I want to log in with my email and password, so that I can access my account and chat sessions.

#### Acceptance Criteria

1. WHEN a user submits valid login credentials (email, password), THE AuthProvider SHALL send a POST request to /api/auth/login
2. WHEN login succeeds (200), THE AuthProvider SHALL save the accessToken and refreshToken to SecureStorage
3. WHEN login succeeds (200), THE AuthProvider SHALL parse the user object from response data and set currentUser
4. WHEN login succeeds (200), THE AuthProvider SHALL set AuthStatus to authenticated
5. IF the backend returns 401 with message "User tidak ditemukan" or "Password salah", THEN THE AuthProvider SHALL expose the exact backend error message

### Requirement 5: User Logout

**User Story:** As a logged-in user, I want to log out, so that my session is terminated and my tokens are invalidated.

#### Acceptance Criteria

1. WHEN logout is called, THE AuthProvider SHALL send a POST request to /api/auth/logout with the refreshToken in the body
2. WHEN logout completes (success or failure), THE AuthProvider SHALL clear all tokens from SecureStorage
3. WHEN logout completes, THE AuthProvider SHALL set currentUser to null and AuthStatus to unauthenticated

### Requirement 6: Client-Side Form Validation

**User Story:** As a user, I want immediate feedback on invalid form input, so that I can correct mistakes before submitting.

#### Acceptance Criteria

1. WHEN an email field is empty or has invalid format, THE Validators SHALL return an appropriate error message in Bahasa Indonesia
2. WHEN a password field is empty or has fewer than 8 characters, THE Validators SHALL return an appropriate error message in Bahasa Indonesia
3. WHEN a name field is empty (after trimming), THE Validators SHALL return an appropriate error message in Bahasa Indonesia
4. WHEN a confirm password field does not match the password field, THE Validators SHALL return an appropriate error message in Bahasa Indonesia

### Requirement 7: Splash Screen

**User Story:** As a user, I want to see a branded splash screen on app launch, so that the app feels polished while it checks my login status.

#### Acceptance Criteria

1. WHEN the SplashScreen is displayed, THE SplashScreen SHALL show the app logo or branding
2. WHEN the SplashScreen initializes, THE SplashScreen SHALL call checkAuthStatus on the AuthProvider
3. WHEN checkAuthStatus resolves to authenticated, THE SplashScreen SHALL navigate to the /main route
4. WHEN checkAuthStatus resolves to unauthenticated, THE SplashScreen SHALL navigate to the /login route

### Requirement 8: Login Screen

**User Story:** As a user, I want a login form with email and password fields, so that I can authenticate into the app.

#### Acceptance Criteria

1. THE LoginScreen SHALL display email and password input fields with client-side validation
2. WHEN the user taps the "Masuk" button with valid input, THE LoginScreen SHALL call login on the AuthProvider
3. WHEN login succeeds, THE LoginScreen SHALL navigate to the /main route
4. IF login fails, THEN THE LoginScreen SHALL display a red SnackBar with the exact backend error message
5. WHILE the AuthProvider isLoading is true, THE LoginScreen SHALL disable the "Masuk" button
6. THE LoginScreen SHALL provide a navigation link to the RegisterScreen

### Requirement 9: Register Screen

**User Story:** As a new user, I want a registration form with name, email, password, and confirm password fields, so that I can create an account.

#### Acceptance Criteria

1. THE RegisterScreen SHALL display name, email, password, and confirm password input fields with client-side validation
2. WHEN the user taps the "Daftar" button with valid input, THE RegisterScreen SHALL call register on the AuthProvider
3. WHEN registration and auto-login succeed, THE RegisterScreen SHALL navigate to the /main route
4. IF registration fails, THEN THE RegisterScreen SHALL display a red SnackBar with the exact backend error message
5. WHILE the AuthProvider isLoading is true, THE RegisterScreen SHALL disable the "Daftar" button
6. THE RegisterScreen SHALL provide a navigation link back to the LoginScreen

### Requirement 10: Route Configuration and Auth Guard

**User Story:** As a developer, I want GoRouter configured with auth-based redirect guards, so that unauthenticated users cannot access protected routes.

#### Acceptance Criteria

1. THE GoRouter SHALL define routes for /splash, /login, /register, and /main
2. WHEN an authenticated user navigates to /login or /register, THE GoRouter redirect guard SHALL redirect to /main
3. WHEN an unauthenticated user navigates to /main, THE GoRouter redirect guard SHALL redirect to /login
4. THE main.dart SHALL wrap the app with MultiProvider including AuthProvider
