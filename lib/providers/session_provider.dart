import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';
import '../models/completion_result.dart';
import '../models/message_model.dart';
import '../models/persona_model.dart';
import '../models/session_model.dart';
import 'auth_provider.dart';

/// Provider yang mengelola state sesi chat (fetch, create, delete).
///
/// Gunakan `context.read<SessionProvider>()` untuk method calls,
/// `context.watch<SessionProvider>()` untuk reactive rebuilds.
class SessionProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  // State — Session list
  List<SessionModel> _activeSessions = [];
  List<SessionModel> _completedSessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Pagination tracking per status
  int _activeCurrentPage = 1;
  int _activeTotalPages = 1;
  int _completedCurrentPage = 1;
  int _completedTotalPages = 1;

  // State — Session detail
  SessionModel? _sessionDetail;
  PersonaModel? _detailPersona;
  bool _isLoadingDetail = false;

  // State — Completion
  bool _isCompleting = false;

  // State — Chat
  List<MessageModel> _messages = [];
  bool _isTyping = false;
  bool _isSendingMessage = false;
  String? _currentChatSessionId;

  // Constructor
  SessionProvider({required ApiClient apiClient}) : _apiClient = apiClient;

  // Getters — Session list
  List<SessionModel> get activeSessions =>
      List.unmodifiable(_activeSessions);
  List<SessionModel> get completedSessions =>
      List.unmodifiable(_completedSessions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMoreActive => _activeCurrentPage < _activeTotalPages;
  bool get hasMoreCompleted => _completedCurrentPage < _completedTotalPages;
  bool get isCompleting => _isCompleting;

  // Getters — Session detail
  SessionModel? get sessionDetail => _sessionDetail;
  PersonaModel? get detailPersona => _detailPersona;
  bool get isLoadingDetail => _isLoadingDetail;

  // Getters — Chat
  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get isSendingMessage => _isSendingMessage;
  String? get currentChatSessionId => _currentChatSessionId;

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

  /// Complete sesi aktif dan return hasil analisis AI.
  ///
  /// - Set isCompleting = true selama API call
  /// - PATCH /api/sessions/:id/complete (no body)
  /// - Parse response.data['data'] → { scoreDelta, newPoints, summary }
  /// - Hitung previousPoints = newPoints - scoreDelta
  /// - Update session di local state (active → completed)
  /// - Panggil authProvider.updatePoints(newPoints)
  /// - Return CompletionResult jika sukses, null jika gagal
  Future<CompletionResult?> completeSession(
    String sessionId,
    AuthProvider authProvider,
  ) async {
    _isCompleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.patch(
        ApiEndpoints.sessionComplete(sessionId),
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final scoreDelta = data['scoreDelta'] as int;
      final newPoints = data['newPoints'] as int;
      final summary = data['summary'] as String;
      final previousPoints = newPoints - scoreDelta;

      // Update session in local state: active → completed
      final sessionIndex =
          _activeSessions.indexWhere((s) => s.id == sessionId);
      if (sessionIndex != -1) {
        final session = _activeSessions[sessionIndex];
        final completedSession = SessionModel(
          id: session.id,
          userId: session.userId,
          personaId: session.personaId,
          status: 'completed',
          scoreDelta: scoreDelta,
          analysisSummary: summary,
          createdAt: session.createdAt,
          startedAt: session.startedAt,
          completedAt: DateTime.now(),
        );

        _activeSessions = List.from(_activeSessions)..removeAt(sessionIndex);
        _completedSessions = [completedSession, ..._completedSessions];
      }

      // Update global health points
      authProvider.updatePoints(newPoints);

      _isCompleting = false;
      notifyListeners();

      return CompletionResult(
        scoreDelta: scoreDelta,
        newPoints: newPoints,
        previousPoints: previousPoints,
        summary: summary,
      );
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isCompleting = false;
      notifyListeners();
      return null;
    } finally {
      if (_isCompleting) {
        _isCompleting = false;
        notifyListeners();
      }
    }
  }

  /// Clear error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Session Detail Methods ─────────────────────────────────────────────────

  /// Fetch detail sesi berdasarkan session ID.
  ///
  /// GET /api/sessions/:id → parse SessionModel + embedded PersonaModel.
  /// Set isLoadingDetail true selama request, clear pada akhir.
  Future<void> fetchSessionDetail(String sessionId) async {
    _isLoadingDetail = true;
    _errorMessage = null;
    _sessionDetail = null;
    _detailPersona = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.sessionDetail(sessionId),
      );

      final data = response.data['data'] as Map<String, dynamic>;
      _sessionDetail = SessionModel.fromJson(data);

      // Parse embedded persona
      if (data['persona'] != null) {
        _detailPersona = PersonaModel.fromJson(
          data['persona'] as Map<String, dynamic>,
        );
      }

      _isLoadingDetail = false;
      notifyListeners();
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isLoadingDetail = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Reset semua detail-related state.
  void clearDetailState() {
    _sessionDetail = null;
    _detailPersona = null;
    _isLoadingDetail = false;
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Chat Methods ───────────────────────────────────────────────────────────

  /// Fetch riwayat pesan untuk sesi tertentu.
  ///
  /// Mengosongkan daftar pesan saat ini, set isLoading true,
  /// GET /api/sessions/:id/messages?page=1&limit=50,
  /// sort ascending by createdAt.
  Future<void> fetchMessages(String sessionId) async {
    _messages = [];
    _currentChatSessionId = sessionId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.sessionMessages(sessionId),
        queryParameters: {'page': 1, 'limit': 50},
      );

      final responseData = response.data['data'];
      if (responseData is! List) {
        throw const AppException(
          message: 'Format response tidak valid',
        );
      }

      final List<dynamic> data = responseData;
      _messages = data
          .map((json) =>
              MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort ascending by createdAt
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _isLoading = false;
      notifyListeners();
    } on AppException catch (e) {
      _errorMessage = e.message;
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

  /// Kirim pesan ke sesi chat.
  ///
  /// Menambahkan pesan optimistik, set isTyping true,
  /// POST /api/sessions/:id/messages body {content},
  /// parse userMessage dan aiReply dari response.
  ///
  /// Returns content string jika gagal (untuk restore ke input field),
  /// null jika berhasil.
  Future<String?> sendMessage(String sessionId, String content) async {
    _isSendingMessage = true;
    _errorMessage = null;
    notifyListeners();

    // Add optimistic user message
    final optimisticId = 'optimistic_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = MessageModel(
      id: optimisticId,
      sessionId: sessionId,
      role: 'user',
      content: content,
      createdAt: DateTime.now(),
    );

    _messages = [..._messages, optimisticMessage];
    _isTyping = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.sessionMessages(sessionId),
        data: {'content': content},
      );

      final responseData = response.data['data'];
      if (responseData is! Map<String, dynamic>) {
        throw const AppException(
          message: 'Format response tidak valid',
        );
      }

      final userMessage = MessageModel.fromJson(
        responseData['userMessage'] as Map<String, dynamic>,
      );
      final aiReply = MessageModel.fromJson(
        responseData['aiReply'] as Map<String, dynamic>,
      );

      // Replace optimistic message with server userMessage
      _messages = _messages
          .map((msg) => msg.id == optimisticId ? userMessage : msg)
          .toList();

      // Add aiReply
      _messages = [..._messages, aiReply];

      _isTyping = false;
      _isSendingMessage = false;
      notifyListeners();
      return null; // success
    } on AppException catch (e) {
      // Remove optimistic message
      _messages = _messages.where((msg) => msg.id != optimisticId).toList();
      _isTyping = false;
      _isSendingMessage = false;
      _errorMessage = e.message;
      notifyListeners();
      return content;
    } on DioException catch (e) {
      // Remove optimistic message
      _messages = _messages.where((msg) => msg.id != optimisticId).toList();
      final ex = AppException.fromDioError(e);
      _isTyping = false;
      _isSendingMessage = false;
      _errorMessage = ex.message;
      notifyListeners();
      return content;
    } catch (e) {
      // Remove optimistic message
      _messages = _messages.where((msg) => msg.id != optimisticId).toList();
      _isTyping = false;
      _isSendingMessage = false;
      _errorMessage = 'Terjadi kesalahan: $e';
      notifyListeners();
      return content;
    }
  }

  /// Reset semua chat-related state.
  void clearChatState() {
    _messages = [];
    _isTyping = false;
    _isSendingMessage = false;
    _currentChatSessionId = null;
    _errorMessage = null;
    notifyListeners();
  }
}
