import 'package:equatable/equatable.dart';

/// Data class yang merepresentasikan satu pesan dalam sesi chat.
///
/// Backend response shape:
/// ```json
/// {
///   "id": "uuid",
///   "sessionId": "uuid",
///   "role": "user" | "model",
///   "content": "...",
///   "createdAt": "2024-01-15T10:30:00.000Z"
/// }
/// ```
class MessageModel extends Equatable {
  final String id;
  final String sessionId;
  final String role; // 'user' | 'model'
  final String content;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('id') || json['id'] == null) {
      throw ArgumentError('Field "id" is required and cannot be null');
    }
    if (!json.containsKey('sessionId') || json['sessionId'] == null) {
      throw ArgumentError('Field "sessionId" is required and cannot be null');
    }
    if (!json.containsKey('role') || json['role'] == null) {
      throw ArgumentError('Field "role" is required and cannot be null');
    }
    if (!json.containsKey('content') || json['content'] == null) {
      throw ArgumentError('Field "content" is required and cannot be null');
    }
    if (!json.containsKey('createdAt') || json['createdAt'] == null) {
      throw ArgumentError('Field "createdAt" is required and cannot be null');
    }

    return MessageModel(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Serializes this instance to a JSON-compatible Map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'role': role,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Returns true jika pesan ini dikirim oleh user.
  bool get isUser => role == 'user';

  /// Returns true jika pesan ini dikirim oleh AI model.
  bool get isModel => role == 'model';

  @override
  List<Object?> get props => [id, sessionId, role, content, createdAt];
}
