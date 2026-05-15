/// Typed model untuk parsing response envelope dari backend.
///
/// Backend response shape:
/// ```json
/// {
///   "success": true,
///   "message": "...",
///   "data": { ... } | [ ... ],
///   "meta": { "total": N, "page": N, "limit": N, "totalPages": N },
///   "errors": [{ "field": "...", "message": "..." }]
/// }
/// ```
class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;
  final ApiMeta? meta;
  final List<ApiFieldError>? errors;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.meta,
    this.errors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'],
      meta: json['meta'] != null
          ? ApiMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
      errors: json['errors'] != null
          ? (json['errors'] as List<dynamic>)
              .map((e) => ApiFieldError.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

class ApiMeta {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const ApiMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory ApiMeta.fromJson(Map<String, dynamic> json) {
    return ApiMeta(
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}

class ApiFieldError {
  final String field;
  final String message;

  const ApiFieldError({
    required this.field,
    required this.message,
  });

  factory ApiFieldError.fromJson(Map<String, dynamic> json) {
    return ApiFieldError(
      field: json['field'] as String,
      message: json['message'] as String,
    );
  }
}
