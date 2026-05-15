import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/app_exception.dart';
import '../models/persona_model.dart';
import '../models/user_model.dart';

/// Provider yang mengelola state admin panel (persona CRUD + user list).
///
/// Gunakan `context.read<AdminProvider>()` untuk method calls,
/// `context.watch<AdminProvider>()` untuk reactive rebuilds.
class AdminProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  // ─── Persona Management State ───────────────────────────────────────────────

  List<PersonaModel> _personas = [];
  int _personaPage = 1;
  int _personaTotalPages = 1;
  int _personaTotal = 0;
  bool _isLoadingPersonas = false;
  bool _isLoadingMorePersonas = false;
  bool _isSubmittingPersona = false;
  bool _isDeletingPersona = false;
  bool _isHardDeleting = false;

  // ─── User Management State ──────────────────────────────────────────────────

  List<UserModel> _users = [];
  int _userPage = 1;
  int _userTotalPages = 1;
  bool _isLoadingUsers = false;
  bool _isLoadingMoreUsers = false;
  UserModel? _selectedUser;
  bool _isLoadingUserDetail = false;
  bool _isSubmittingUser = false;
  bool _isDeletingUser = false;

  // ─── Dashboard State ────────────────────────────────────────────────────────

  int _totalActivePersonas = 0;
  bool _isLoadingDashboard = false;

  // ─── Shared State ───────────────────────────────────────────────────────────

  String? _errorMessage;

  // Constructor
  AdminProvider({required ApiClient apiClient}) : _apiClient = apiClient;

  // ─── Persona Getters ────────────────────────────────────────────────────────

  List<PersonaModel> get personas => _personas;
  int get personaPage => _personaPage;
  int get personaTotalPages => _personaTotalPages;
  int get personaTotal => _personaTotal;
  bool get isLoadingPersonas => _isLoadingPersonas;
  bool get isLoadingMorePersonas => _isLoadingMorePersonas;
  bool get isSubmittingPersona => _isSubmittingPersona;
  bool get isDeletingPersona => _isDeletingPersona;
  bool get isHardDeleting => _isHardDeleting;

  // ─── User Getters ──────────────────────────────────────────────────────────

  List<UserModel> get users => _users;
  int get userPage => _userPage;
  int get userTotalPages => _userTotalPages;
  bool get isLoadingUsers => _isLoadingUsers;
  bool get isLoadingMoreUsers => _isLoadingMoreUsers;
  UserModel? get selectedUser => _selectedUser;
  bool get isLoadingUserDetail => _isLoadingUserDetail;
  bool get isSubmittingUser => _isSubmittingUser;
  bool get isDeletingUser => _isDeletingUser;

  // ─── Dashboard Getters ──────────────────────────────────────────────────────

  int get totalActivePersonas => _totalActivePersonas;
  bool get isLoadingDashboard => _isLoadingDashboard;

  // ─── Shared Getters ─────────────────────────────────────────────────────────

  String? get errorMessage => _errorMessage;

  /// Clear error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERSONA METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch daftar persona (termasuk inactive) dengan pagination.
  ///
  /// [refresh] = true → reset ke page 1 dan replace semua item.
  Future<void> fetchPersonas({bool refresh = false}) async {
    if (refresh) {
      _personaPage = 1;
      _personaTotalPages = 1;
    }

    _isLoadingPersonas = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.adminPersonas,
        queryParameters: {
          'includeInactive': true,
          'page': _personaPage,
          'limit': 10,
        },
      );

      final data = response.data['data'] as List<dynamic>;
      final meta = response.data['meta'] as Map<String, dynamic>;

      final fetchedPersonas = data
          .map((json) => PersonaModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (refresh || _personaPage == 1) {
        _personas = fetchedPersonas;
      } else {
        _personas = [..._personas, ...fetchedPersonas];
      }

      _personaPage = meta['page'] as int;
      _personaTotalPages = meta['totalPages'] as int;
      _personaTotal = meta['total'] as int;
      _isLoadingPersonas = false;
      notifyListeners();
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isLoadingPersonas = false;
      notifyListeners();
    }
  }

  /// Fetch halaman berikutnya persona dan append ke list.
  ///
  /// Tidak melakukan apa-apa jika sudah di halaman terakhir atau sedang loading.
  Future<void> fetchMorePersonas() async {
    if (_personaPage >= _personaTotalPages) return;
    if (_isLoadingMorePersonas) return;

    _isLoadingMorePersonas = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _personaPage + 1;
      final response = await _apiClient.dio.get(
        ApiEndpoints.adminPersonas,
        queryParameters: {
          'includeInactive': true,
          'page': nextPage,
          'limit': 10,
        },
      );

      final data = response.data['data'] as List<dynamic>;
      final meta = response.data['meta'] as Map<String, dynamic>;

      final newPersonas = data
          .map((json) => PersonaModel.fromJson(json as Map<String, dynamic>))
          .toList();

      _personas = [..._personas, ...newPersonas];
      _personaPage = meta['page'] as int;
      _personaTotalPages = meta['totalPages'] as int;
      _personaTotal = meta['total'] as int;
      _isLoadingMorePersonas = false;
      notifyListeners();
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isLoadingMorePersonas = false;
      notifyListeners();
    }
  }

  /// Buat persona baru.
  ///
  /// [data] — FormData berisi name, description, systemPrompt, image (optional).
  /// Returns true jika berhasil, false jika gagal.
  Future<bool> createPersona(FormData data) async {
    _isSubmittingPersona = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.adminPersonas,
        data: data,
      );

      final persona = PersonaModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );

      _personas = [persona, ..._personas];
      _personaTotal += 1;
      _isSubmittingPersona = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isSubmittingPersona = false;
      notifyListeners();
      return false;
    }
  }

  /// Update persona yang sudah ada.
  ///
  /// [id] — ID persona yang di-update.
  /// [data] — FormData berisi field yang berubah saja.
  /// Returns true jika berhasil, false jika gagal.
  Future<bool> updatePersona(String id, FormData data) async {
    _isSubmittingPersona = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.patch(
        ApiEndpoints.adminPersonaDetail(id),
        data: data,
      );

      final updatedPersona = PersonaModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );

      final index = _personas.indexWhere((p) => p.id == id);
      if (index != -1) {
        _personas = List.from(_personas)..[index] = updatedPersona;
      }

      _isSubmittingPersona = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isSubmittingPersona = false;
      notifyListeners();
      return false;
    }
  }

  /// Soft-delete (deactivate) persona via PATCH.
  ///
  /// [id] — ID persona yang di-deactivate.
  /// Returns true jika berhasil, false jika gagal.
  Future<bool> deletePersona(String id) async {
    _isDeletingPersona = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.dio.patch(
        ApiEndpoints.adminPersonaDeactivate(id),
      );

      // Update local state: set isActive to false
      final index = _personas.indexWhere((p) => p.id == id);
      if (index != -1) {
        _personas = List.from(_personas)
          ..[index] = _personas[index].copyWith(isActive: false);
      }

      _isDeletingPersona = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isDeletingPersona = false;
      notifyListeners();
      return false;
    }
  }

  /// Hard delete (hapus permanen) persona.
  ///
  /// [id] — ID persona yang dihapus permanen.
  /// Returns true jika berhasil, false jika gagal.
  Future<bool> hardDeletePersona(String id) async {
    _isHardDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.dio.delete(
        ApiEndpoints.adminPersonaDetail(id),
      );

      // Remove from local list and decrement total
      _personas = _personas.where((p) => p.id != id).toList();
      _personaTotal -= 1;

      _isHardDeleting = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isHardDeleting = false;
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch daftar user dengan pagination.
  ///
  /// [refresh] = true → reset ke page 1 dan replace semua item.
  Future<void> fetchUsers({bool refresh = false}) async {
    if (refresh) {
      _userPage = 1;
      _userTotalPages = 1;
    }

    _isLoadingUsers = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.adminUsers,
        queryParameters: {
          'page': _userPage,
          'limit': 10,
        },
      );

      final data = response.data['data'] as List<dynamic>;
      final meta = response.data['meta'] as Map<String, dynamic>;

      final fetchedUsers = data
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (refresh || _userPage == 1) {
        _users = fetchedUsers;
      } else {
        _users = [..._users, ...fetchedUsers];
      }

      _userPage = meta['page'] as int;
      _userTotalPages = meta['totalPages'] as int;
      _isLoadingUsers = false;
      notifyListeners();
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  /// Fetch halaman berikutnya user dan append ke list.
  ///
  /// Tidak melakukan apa-apa jika sudah di halaman terakhir atau sedang loading.
  Future<void> fetchMoreUsers() async {
    if (_userPage >= _userTotalPages) return;
    if (_isLoadingMoreUsers) return;

    _isLoadingMoreUsers = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _userPage + 1;
      final response = await _apiClient.dio.get(
        ApiEndpoints.adminUsers,
        queryParameters: {
          'page': nextPage,
          'limit': 10,
        },
      );

      final data = response.data['data'] as List<dynamic>;
      final meta = response.data['meta'] as Map<String, dynamic>;

      final newUsers = data
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();

      _users = [..._users, ...newUsers];
      _userPage = meta['page'] as int;
      _userTotalPages = meta['totalPages'] as int;
      _isLoadingMoreUsers = false;
      notifyListeners();
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isLoadingMoreUsers = false;
      notifyListeners();
    }
  }

  /// Fetch detail user berdasarkan ID.
  ///
  /// Menyimpan hasilnya di [selectedUser].
  Future<void> fetchUserDetail(String id) async {
    _isLoadingUserDetail = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.adminUserDetail(id),
      );

      _selectedUser = UserModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );

      _isLoadingUserDetail = false;
      notifyListeners();
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isLoadingUserDetail = false;
      notifyListeners();
    }
  }

  /// Buat user baru (admin only).
  ///
  /// [data] — Map berisi name, email, password, role (optional), points (optional).
  /// Returns true jika berhasil, false jika gagal.
  Future<bool> createUser(Map<String, dynamic> data) async {
    _isSubmittingUser = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.adminUsers,
        data: data,
      );

      final user = UserModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );

      _users = [user, ..._users];
      _isSubmittingUser = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isSubmittingUser = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user yang sudah ada (admin only).
  ///
  /// [id] — ID user yang di-update.
  /// [data] — Map berisi field yang berubah (name, email, password, role, points).
  /// Returns true jika berhasil, false jika gagal.
  Future<bool> updateUser(String id, Map<String, dynamic> data) async {
    _isSubmittingUser = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.patch(
        ApiEndpoints.adminUserDetail(id),
        data: data,
      );

      final updatedUser = UserModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );

      // Update in local list
      final index = _users.indexWhere((u) => u.id == id);
      if (index != -1) {
        _users = List.from(_users)..[index] = updatedUser;
      }

      // Update selectedUser if it's the same
      if (_selectedUser?.id == id) {
        _selectedUser = updatedUser;
      }

      _isSubmittingUser = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isSubmittingUser = false;
      notifyListeners();
      return false;
    }
  }

  /// Hapus user permanen (admin only).
  ///
  /// [id] — ID user yang dihapus.
  /// Returns true jika berhasil, false jika gagal.
  Future<bool> deleteUser(String id) async {
    _isDeletingUser = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.dio.delete(
        ApiEndpoints.adminUserDetail(id),
      );

      // Remove from local list
      _users = _users.where((u) => u.id != id).toList();

      _isDeletingUser = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isDeletingUser = false;
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DASHBOARD METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch statistik dashboard.
  ///
  /// Menggunakan endpoint persona dengan limit=1 untuk mendapatkan meta.total
  /// (jumlah total persona aktif) tanpa perlu fetch semua data.
  Future<void> fetchDashboardStats() async {
    _isLoadingDashboard = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.adminPersonas,
        queryParameters: {
          'includeInactive': true,
          'page': 1,
          'limit': 1,
        },
      );

      final meta = response.data['meta'] as Map<String, dynamic>;
      _totalActivePersonas = meta['total'] as int;

      _isLoadingDashboard = false;
      notifyListeners();
    } on DioException catch (e) {
      final ex = AppException.fromDioError(e);
      _errorMessage = ex.message;
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }
}
