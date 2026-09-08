/// Represents a logged-in user, including their role.
/// Roles match the Authority & Permission Matrix from the design script.
class User {
  final String id;
  final String name;
  final String username;
  final String role; // e.g. "Auditor", "Data Manager", "System Admin"
  final String department;
  final String email;
  final DateTime createdAt;
  final String? token; // JWT, once real auth is wired up

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.department,
    required this.email,
    required this.createdAt,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'] as String,
      name: json['name'] as String? ?? '',
      username: json['username'] as String,
      role: json['role'] as String,
      department: json['department'] as String? ?? '',
      email: json['email'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'role': role,
        'department': department,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
        'token': token,
      };
}