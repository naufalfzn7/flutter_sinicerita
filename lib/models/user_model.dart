import 'package:equatable/equatable.dart';

/// Data class yang merepresentasikan user dari backend.
///
/// Backend JSON shape (dari GET /api/me dan login response):
/// ```json
/// {
///   "id": "uuid-string",
///   "name": "User Name",
///   "email": "user@example.com",
///   "role": "user",
///   "points": 50,
///   "avatarUrl": "https://cloudinary.com/..." or null,
///   "createdAt": "2024-01-01T00:00:00.000Z"
/// }
/// ```
class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final int points;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.points,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      points: json['points'] as int,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'points': points,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, email, role, points, avatarUrl, createdAt];
}
