import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';
import '../models/user_model.dart';

/// Status autentikasi aplikasi.
///
/// - [unknown]: Belum dicek (app baru launch)
/// - [authenticated]: Token valid + user profile loaded
/// - [unauthenticated]: Tidak ada token atau token invalid/expired
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Provider yang mengelola state autentikasi (login, register, logout, fetch profile).
///
/// Gunakan `context.read<AuthProvider>()` untuk method calls,
/// `context.watch<AuthProvider>()` untuk reactive rebuilds.
class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  // State
  AuthStatus _status = AuthStatus.unknown;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _firstLaunchCompleted = false;

  // Constructor
  AuthProvider({required ApiClient apiClient}) : _apiClient = apiClient;

  // Getters
  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get firstLaunchCompleted => _firstLaunchCompleted;

  /// Mendaftarkan user baru, lalu otomatis login jika berhasil.
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.dio.post(
        ApiEndpoints.register,
        data: {'name': name, 'email': email, 'password': password},
      );

      // Auto-login setelah register berhasil.
      // login() akan mengelola _isLoading sendiri.
      return await login(email, password);
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login dengan email dan password.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      final data = response.data['data'] as Map<String, dynamic>;

      // Save tokens
      await _apiClient.storage.saveAccessToken(data['accessToken'] as String);
      await _apiClient.storage.saveRefreshToken(data['refreshToken'] as String);

      // Set current user
      _currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout user, clear tokens, dan set status ke unauthenticated.
  ///
  /// Selalu berhasil dari perspektif user — meskipun API call gagal,
  /// token tetap dihapus dan status di-set ke unauthenticated.
  Future<void> logout() async {
    try {
      final refreshToken = await _apiClient.storage.getRefreshToken();
      if (refreshToken != null) {
        await _apiClient.dio.post(
          ApiEndpoints.logout,
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Ignore errors — logout harus selalu "berhasil" dari sisi user.
    } finally {
      await _apiClient.storage.clearAll();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Refresh user profile data dari backend (GET /api/me).
  ///
  /// Dipanggil setelah edit profil berhasil untuk memperbarui currentUser.
  /// Tidak mengubah AuthStatus — hanya update data user.
  Future<void> fetchMe() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.me);
      _currentUser = UserModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
      notifyListeners();
    } on DioException catch (_) {
      // Silently fail — user data tetap pakai cache terakhir
    }
  }

  /// Update points di currentUser model secara sinkron.
  ///
  /// Dipanggil oleh SessionProvider setelah session completion berhasil.
  /// Membuat UserModel baru dengan points yang diupdate (immutable pattern).
  void updatePoints(int newPoints) {
    if (_currentUser == null) return;
    _currentUser = UserModel(
      id: _currentUser!.id,
      name: _currentUser!.name,
      email: _currentUser!.email,
      role: _currentUser!.role,
      points: newPoints,
      avatarUrl: _currentUser!.avatarUrl,
      createdAt: _currentUser!.createdAt,
    );
    notifyListeners();
  }

  /// Expose ApiClient untuk digunakan oleh screen yang butuh akses langsung
  /// (misalnya EditProfileScreen untuk multipart upload).
  ApiClient get apiClient => _apiClient;

  /// Cek apakah user sudah login (token valid) saat app launch.
  ///
  /// Dipanggil dari SplashScreen saat app pertama kali dibuka.
  /// - Jika tidak ada token → langsung unauthenticated
  /// - Jika ada token → GET /api/me untuk validasi + load profile
  /// - Jika request gagal (token expired, network error) → clear tokens, unauthenticated
  Future<void> checkAuthStatus() async {
    // Baca first-launch flag dari storage
    _firstLaunchCompleted = await _apiClient.storage.isFirstLaunchCompleted();

    final accessToken = await _apiClient.storage.getAccessToken();

    if (accessToken == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final response = await _apiClient.dio.get(ApiEndpoints.me);

      _currentUser = UserModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (_) {
      await _apiClient.storage.clearAll();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Set first-launch flag ke true (dipanggil dari WelcomeScreen).
  ///
  /// Menyimpan flag ke SecureStorage dan trigger notifyListeners()
  /// agar GoRouter redirect logic bisa membaca state terbaru.
  Future<void> completeFirstLaunch() async {
    await _apiClient.storage.setFirstLaunchCompleted();
    _firstLaunchCompleted = true;
    notifyListeners();
  }

  /// Request OTP ke email user untuk forgot password flow.
  ///
  /// Returns true jika berhasil (OTP terkirim), false jika gagal.
  /// Pada sukses, `successMessage` berisi pesan dari backend untuk SnackBar.
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );

      _successMessage = response.data['message'] as String?;
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verifikasi 6-digit OTP code yang dikirim ke email user.
  ///
  /// Returns true jika OTP valid, false jika gagal (errorMessage di-set).
  /// Pada sukses, `successMessage` berisi pesan dari backend untuk SnackBar.
  Future<bool> verifyOtp(String email, String code) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.verifyOtp,
        data: {'email': email, 'code': code},
      );

      _successMessage = response.data['message'] as String?;
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset password dengan email, OTP code, dan password baru.
  ///
  /// Returns true jika berhasil, false jika gagal (errorMessage di-set).
  /// Pada sukses, `successMessage` berisi pesan dari backend untuk SnackBar.
  Future<bool> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.resetPassword,
        data: {'email': email, 'code': code, 'newPassword': newPassword},
      );

      _successMessage = response.data['message'] as String?;
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
