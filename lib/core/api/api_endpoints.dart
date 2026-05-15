/// Centralized URL constants untuk semua API endpoints.
///
/// Gunakan class ini untuk referensi endpoint di seluruh aplikasi.
/// - `/ping` adalah SATU-SATUNYA endpoint tanpa prefix `/api/`
/// - Semua endpoint lain WAJIB pakai `/api/` prefix
abstract class ApiEndpoints {
  ApiEndpoints._();

  // ─── System ───────────────────────────────────────────────────────────────

  /// Health check endpoint (TANPA /api/ prefix)
  static const String ping = '/ping';

  // ─── Auth ─────────────────────────────────────────────────────────────────

  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String refresh = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String resetPassword = '/api/auth/reset-password';

  // ─── Profile ──────────────────────────────────────────────────────────────

  static const String me = '/api/me';
  static const String changePassword = '/api/me/password';

  // ─── Persona ──────────────────────────────────────────────────────────────

  static const String personas = '/api/personas';

  static String personaDetail(String id) => '/api/personas/$id';
  static String personaRate(String id) => '/api/personas/$id/rate';

  // ─── Session ──────────────────────────────────────────────────────────────

  static const String sessions = '/api/sessions';

  static String sessionDetail(String id) => '/api/sessions/$id';
  static String sessionMessages(String id) => '/api/sessions/$id/messages';
  static String sessionComplete(String id) => '/api/sessions/$id/complete';

  // ─── Admin ────────────────────────────────────────────────────────────────

  static const String adminPersonas = '/api/personas';

  static String adminPersonaDetail(String id) => '/api/personas/$id';

  static String adminPersonaDeactivate(String id) =>
      '/api/personas/$id/deactivate';

  static const String adminUsers = '/api/admin/users';

  static String adminUserDetail(String id) => '/api/admin/users/$id';
}
