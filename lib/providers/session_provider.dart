import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';
import '../models/session_model.dart';

/// Provider yang mengelola state sesi chat (fetch, create, delete).
///
/// Gunakan `context.read<SessionProvider>()` untuk method calls,
/// `context.watch<SessionProvider>()` untuk reactive rebuilds.
class SessionProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  // State
  List<SessionModel> _activeSessions = [];
  List<SessionModel> _completedSessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Pagination tracking per status
  int _activeCurrentPage = 1;
  int _activeTotalPages = 1;
  int _completedCurrentPage = 1;
  int _completedTotalPages = 1;

  // Constructor
  SessionProvider({required ApiClient apiClient}) : _apiClient = apiClient;

  // Getters
  List<SessionModel> get activeSessions =>
      List.unmodifiable(_activeSessions);
  List<SessionModel> get completedSessions =>
      List.unmodifiable(_completedSessions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMoreActive => _activeCurrentPage < _activeTotalPages;
  bool get hasMoreCompleted => _completedCurrentPage < _completedTotalPages;

  /// Fetch sessions filtered by status (active atau completed).
  ///
  /// - [status]: 'active' atau 'completed'
  /// - [page]: halaman yang diminta (default 1)
  /// - [limit]: jumlah item per halaman (default 10)
  ///
  /// Jika page == 1, list akan di-replace. Jika page > 1, append ke list.
  Future<void> fetchSessions({
    required String status,
    int page = 1,
    int limit = 10,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.sessions,
        queryParameters: {
          'status': status,
          'page': page,
          'limit': limit,
        },
      );

      final List<dynamic> data = response.data['data'] as List<dynamic>;
      final sessions = data
          .map((json) =>
              SessionModel.fromJson(json as Map<String, dynamic>))
          .toList();

      final meta = response.data['meta'] as Map<String, dynamic>;
      final currentPage = meta['page'] as int;
      final totalPages = meta['totalPages'] as int;

      if (status == 'active') {
        if (page == 1) {
          _activeSessions = sessions;
        } else {
          _activeSessions = [..._activeSessions, ...sessions];
        }
        _activeCurrentPage = currentPage;
        _activeTotalPages = totalPages;
      } else {
        if (page == 1) {
          _completedSessions = sessions;
        } else {
          _completedSessions = [..._completedSessions, ...sessions];
        }
        _completedCurrentPage = currentPage;
        _completedTotalPages = totalPages;
      }

      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Buat sesi baru dengan persona tertentu.
  ///
  /// Returns [SessionModel] jika berhasil, null jika gagal.
  /// Session baru otomatis ditambahkan ke awal list active sessions.
  Future<SessionModel?> createSession(String personaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.sessions,
        data: {'personaId': personaId},
      );

      final session = SessionModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );

      _activeSessions = [session, ..._activeSessions];
      _isLoading = false;
      notifyListeners();
      return session;
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Hapus sesi aktif secara optimistic.
  ///
  /// Session dihapus dari list terlebih dahulu (optimistic),
  /// lalu jika API gagal, session dikembalikan ke posisi semula.
  /// Returns true jika berhasil, false jika gagal.
  Future<bool> deleteSession(String sessionId) async {
    _errorMessage = null;

    // Optimistic removal
    final index = _activeSessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return false;

    final removedSession = _activeSessions[index];
    _activeSessions = List.from(_activeSessions)..removeAt(index);
    notifyListeners();

    try {
      await _apiClient.dio.delete(
        ApiEndpoints.sessionDetail(sessionId),
      );
      return true;
    } on DioException catch (e) {
      // Revert optimistic removal
      _activeSessions = List.from(_activeSessions)
        ..insert(index, removedSession);
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
