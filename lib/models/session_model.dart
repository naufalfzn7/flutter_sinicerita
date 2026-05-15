import 'package:equatable/equatable.dart';

/// Data class yang merepresentasikan sesi chat dari backend.
///
/// Backend response shapes:
///
/// POST /api/sessions (create):
/// ```json
/// { "id", "userId", "personaId", "status", "startedAt", "createdAt" }
/// ```
///
/// GET /api/sessions (list):
/// ```json
/// { "id", "personaId", "status", "startedAt", "completedAt?", "createdAt" }
/// ```
///
/// GET /api/sessions/:id (detail):
/// ```json
/// { "id", "status", "scoreDelta?", "analysisSummary?", "startedAt", "completedAt?", "persona": {...} }
/// ```
class SessionModel extends Equatable {
  final String id;
  final String? userId;
  final String personaId;
  final String status; // 'active' | 'completed'
  final int? scoreDelta;
  final String? analysisSummary;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const SessionModel({
    required this.id,
    this.userId,
    required this.personaId,
    required this.status,
    this.scoreDelta,
    this.analysisSummary,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      personaId: json['personaId'] as String,
      status: json['status'] as String,
      scoreDelta: json['scoreDelta'] as int?,
      analysisSummary: json['analysisSummary'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  /// Waktu terakhir aktivitas sesi — digunakan untuk sorting.
  /// Prioritas: completedAt > startedAt > createdAt
  DateTime get lastActivityAt => completedAt ?? startedAt ?? createdAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        personaId,
        status,
        scoreDelta,
        analysisSummary,
        createdAt,
        startedAt,
        completedAt,
      ];
}
