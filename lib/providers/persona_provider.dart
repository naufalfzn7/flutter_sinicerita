import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';
import '../models/persona_model.dart';

/// Provider yang mengelola state persona (list, detail, rating).
///
/// Gunakan `context.read<PersonaProvider>()` untuk method calls,
/// `context.watch<PersonaProvider>()` untuk reactive rebuilds.
class PersonaProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  // State
  List<PersonaModel> _personas = [];
  PersonaModel? _selectedPersona;
  bool _isLoading = false;
  bool _isLoadingDetail = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;

  // Local cache untuk userRating (personaId → rating)
  // Digunakan jika backend tidak mengembalikan userRating di GET response
  final Map<String, String?> _ratingCache = {};

  // Constructor
  PersonaProvider({required ApiClient apiClient}) : _apiClient = apiClient;

  // Getters
  List<PersonaModel> get personas => _personas;
  PersonaModel? get selectedPersona => _selectedPersona;
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get errorMessage => _errorMessage;
  bool get hasMorePages => _currentPage < _totalPages;
  int get totalPersonas => _total;

  /// Fetch daftar persona dari API dengan pagination.
  ///
  /// [page] — halaman yang diminta (default 1)
  /// [limit] — jumlah item per halaman (default 10)
  Future<void> fetchPersonas({int page = 1, int limit = 10}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.personas,
        queryParameters: {'page': page, 'limit': limit},
      );

      final data = response.data['data'] as List<dynamic>;
      final meta = response.data['meta'] as Map<String, dynamic>;

      _personas = data
          .map((json) => PersonaModel.fromJson(json as Map<String, dynamic>))
          .toList();
      _currentPage = meta['page'] as int;
      _totalPages = meta['totalPages'] as int;
      _total = meta['total'] as int;
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch halaman berikutnya dan append ke list yang sudah ada.
  ///
  /// Tidak melakukan apa-apa jika sudah di halaman terakhir atau sedang loading.
  Future<void> fetchNextPage() async {
    if (!hasMorePages || _isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _apiClient.dio.get(
        ApiEndpoints.personas,
        queryParameters: {'page': nextPage, 'limit': 10},
      );

      final data = response.data['data'] as List<dynamic>;
      final meta = response.data['meta'] as Map<String, dynamic>;

      final newPersonas = data
          .map((json) => PersonaModel.fromJson(json as Map<String, dynamic>))
          .toList();

      _personas = [..._personas, ...newPersonas];
      _currentPage = meta['page'] as int;
      _totalPages = meta['totalPages'] as int;
      _total = meta['total'] as int;
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset ke halaman 1 dan replace seluruh list.
  ///
  /// Digunakan untuk pull-to-refresh.
  Future<void> refreshPersonas() async {
    _currentPage = 1;
    _totalPages = 1;
    await fetchPersonas(page: 1);
  }

  /// Fetch detail persona berdasarkan ID.
  ///
  /// Menyimpan hasilnya di [selectedPersona].
  /// Jika backend tidak mengembalikan userRating, gunakan cached value.
  Future<void> fetchPersonaDetail(String id) async {
    _isLoadingDetail = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.personaDetail(id),
      );

      var persona = PersonaModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );

      // Jika backend tidak return userRating tapi kita punya cache, gunakan cache
      if (persona.userRating == null && _ratingCache.containsKey(id)) {
        persona = persona.copyWith(userRating: _ratingCache[id]);
      }

      _selectedPersona = persona;
      _isLoadingDetail = false;
      notifyListeners();
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Rate persona dengan optimistic update.
  ///
  /// [id] — ID persona yang di-rate
  /// [type] — 'UP', 'DOWN', atau 'NONE' (toggle off)
  ///
  /// Vote state machine:
  /// - null/NONE + UP → upvotes+1, rating=UP
  /// - null/NONE + DOWN → downvotes+1, rating=DOWN
  /// - UP + DOWN → upvotes-1, downvotes+1, rating=DOWN
  /// - DOWN + UP → downvotes-1, upvotes+1, rating=UP
  /// - UP + UP (toggle off) → upvotes-1, rating=null, send NONE
  /// - DOWN + DOWN (toggle off) → downvotes-1, rating=null, send NONE
  ///
  /// Returns true jika berhasil, false jika gagal (state di-revert).
  Future<bool> ratePersona(String id, String type) async {
    // Cari persona di list dan selectedPersona
    final index = _personas.indexWhere((p) => p.id == id);
    final persona = index != -1 ? _personas[index] : _selectedPersona;

    if (persona == null) return false;

    final currentRating = persona.userRating;

    // Tentukan API type yang dikirim
    String apiType = type;
    // Jika toggle off (same action as current rating), kirim NONE
    if (currentRating == type) {
      apiType = 'NONE';
    }

    // Hitung optimistic state baru
    int newUpvotes = persona.upvotes;
    int newDownvotes = persona.downvotes;
    String? newRating;

    if (currentRating == null || currentRating == 'NONE') {
      // Belum ada rating
      if (type == 'UP') {
        newUpvotes += 1;
        newRating = 'UP';
      } else if (type == 'DOWN') {
        newDownvotes += 1;
        newRating = 'DOWN';
      }
    } else if (currentRating == 'UP') {
      if (type == 'DOWN') {
        // Switch dari UP ke DOWN
        newUpvotes -= 1;
        newDownvotes += 1;
        newRating = 'DOWN';
      } else if (type == 'UP') {
        // Toggle off UP
        newUpvotes -= 1;
        newRating = null;
      }
    } else if (currentRating == 'DOWN') {
      if (type == 'UP') {
        // Switch dari DOWN ke UP
        newDownvotes -= 1;
        newUpvotes += 1;
        newRating = 'UP';
      } else if (type == 'DOWN') {
        // Toggle off DOWN
        newDownvotes -= 1;
        newRating = null;
      }
    }

    // Simpan state lama untuk revert
    final oldPersona = persona;

    // Optimistic update
    final updatedPersona = persona.copyWith(
      upvotes: newUpvotes,
      downvotes: newDownvotes,
      userRating: newRating,
      clearUserRating: newRating == null,
    );

    _applyPersonaUpdate(id, updatedPersona);
    notifyListeners();

    // API call
    try {
      await _apiClient.dio.post(
        ApiEndpoints.personaRate(id),
        data: {'type': apiType},
      );
      // Cache rating lokal agar persist saat re-fetch detail
      _ratingCache[id] = newRating;
      return true;
    } on DioException catch (_) {
      // Revert on failure
      _applyPersonaUpdate(id, oldPersona);
      notifyListeners();
      return false;
    }
  }

  /// Resolve persona dari local list berdasarkan ID.
  ///
  /// Digunakan untuk menampilkan nama/avatar persona di session list
  /// tanpa perlu API call tambahan.
  PersonaModel? getById(String id) {
    return _personas.firstWhereOrNull((p) => p.id == id);
  }

  /// Clear error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Private Helpers ────────────────────────────────────────────────────────

  /// Apply updated persona ke list dan selectedPersona.
  void _applyPersonaUpdate(String id, PersonaModel updated) {
    final index = _personas.indexWhere((p) => p.id == id);
    if (index != -1) {
      _personas = List.from(_personas)..[index] = updated;
    }
    if (_selectedPersona?.id == id) {
      _selectedPersona = updated;
    }
  }
}
