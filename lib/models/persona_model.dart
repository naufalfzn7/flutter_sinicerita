import 'package:equatable/equatable.dart';

/// Data class yang merepresentasikan persona AI dari backend.
///
/// Backend JSON shape (dari GET /api/personas dan GET /api/personas/:id):
/// ```json
/// {
///   "id": "uuid-string",
///   "name": "Persona Name",
///   "description": "Deskripsi persona",
///   "systemPrompt": "System prompt text" or null,
///   "avatarUrl": "https://cloudinary.com/..." or null,
///   "isActive": true,
///   "upvotes": 10,
///   "downvotes": 2,
///   "userRating": "UP" | "DOWN" | null
/// }
/// ```
class PersonaModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? systemPrompt;
  final String? avatarUrl;
  final bool isActive;
  final int upvotes;
  final int downvotes;
  final String? userRating; // 'UP', 'DOWN', or null (from detail endpoint)

  const PersonaModel({
    required this.id,
    required this.name,
    required this.description,
    this.systemPrompt,
    this.avatarUrl,
    required this.isActive,
    required this.upvotes,
    required this.downvotes,
    this.userRating,
  });

  factory PersonaModel.fromJson(Map<String, dynamic> json) {
    return PersonaModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      systemPrompt: json['systemPrompt'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isActive: (json['isActive'] as bool?) ?? true,
      upvotes: (json['upvotes'] as int?) ?? 0,
      downvotes: (json['downvotes'] as int?) ?? 0,
      userRating: json['userRating'] as String?,
    );
  }

  /// Create a copy with updated fields.
  ///
  /// Use [clearUserRating] = true to explicitly set userRating to null.
  /// Use [clearAvatarUrl] = true to explicitly set avatarUrl to null.
  /// If the clear flag is false (default), the corresponding param controls the value.
  PersonaModel copyWith({
    String? name,
    String? description,
    String? systemPrompt,
    String? avatarUrl,
    bool? isActive,
    int? upvotes,
    int? downvotes,
    String? userRating,
    bool clearUserRating = false,
    bool clearAvatarUrl = false,
  }) {
    return PersonaModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      isActive: isActive ?? this.isActive,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      userRating: clearUserRating ? null : (userRating ?? this.userRating),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        systemPrompt,
        avatarUrl,
        isActive,
        upvotes,
        downvotes,
        userRating,
      ];
}
