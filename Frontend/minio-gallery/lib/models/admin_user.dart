class AdminUser {
  final int id;
  final String username;
  final String email;
  final String role;
  final bool enabled;
  final DateTime createdAt;
  final int imageCount;

  AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.enabled,
    required this.createdAt,
    required this.imageCount,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'USER',
      enabled: json['enabled'] ?? true,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      imageCount: json['imageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
      'imageCount': imageCount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminUser &&
        other.id == id &&
        other.username == username &&
        other.email == email &&
        other.role == role &&
        other.enabled == enabled;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      username.hashCode ^
      email.hashCode ^
      role.hashCode ^
      enabled.hashCode;

  @override
  String toString() {
    return 'AdminUser(id: $id, username: $username, email: $email, role: $role, enabled: $enabled, imageCount: $imageCount)';
  }
}
