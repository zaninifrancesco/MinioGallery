class User {
  final String username;
  final String email;
  final String role;

  User({required this.username, required this.email, required this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'USER',
    );
  }

  Map<String, dynamic> toJson() {
    return {'username': username, 'email': email, 'role': role};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.username == username &&
        other.email == email &&
        other.role == role;
  }

  @override
  int get hashCode => username.hashCode ^ email.hashCode ^ role.hashCode;

  @override
  String toString() {
    return 'User(username: $username, email: $email, role: $role)';
  }
}
