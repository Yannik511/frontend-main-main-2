class User {
  final int userId;
  final String email;
  final String fullName;
  final String role;

  User({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('DEBUG: Parsing user JSON: $json'); // Add debug logging
    try {
      return User(
        userId: json['userId'] ?? json['id'] ?? 0,
        email: json['email'] ?? '',
        fullName: json['fullName'] ?? '',
        role: json['role'] ?? 'USER',
      );
    } catch (e) {
      print('DEBUG: Error parsing user: $e');
      print('DEBUG: Problematic JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    'fullName': fullName,
    'role': role,
  };

  // Compatibility getter
  int get id => userId;
}
