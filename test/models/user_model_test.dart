import 'package:flutter_test/flutter_test.dart';
import 'package:kreisel_frontend/models/user_model.dart';

void main() {
  group('User Model', () {
    test('should create User from valid JSON with all fields', () {
      final json = {
        'userId': 1,
        'email': 'max@example.com',
        'fullName': 'Max Mustermann',
        'role': 'ADMIN',
      };

      final user = User.fromJson(json);

      expect(user.userId, 1);
      expect(user.email, 'max@example.com');
      expect(user.fullName, 'Max Mustermann');
      expect(user.role, 'ADMIN');
    });

    test('should handle missing optional fields in JSON gracefully', () {
      final json = {
        'email': 'test@example.com',
        // userId fehlt → soll auf 0 gesetzt werden
      };

      final user = User.fromJson(json);

      expect(user.userId, 0);
      expect(user.email, 'test@example.com');
      expect(user.fullName, '');
      expect(user.role, 'USER'); // default fallback
    });

    test('should convert User to JSON correctly', () {
      final user = User(
        userId: 42,
        email: 'test@example.com',
        fullName: 'Test User',
        role: 'USER',
      );

      final json = user.toJson();

      expect(json['userId'], 42);
      expect(json['email'], 'test@example.com');
      expect(json['fullName'], 'Test User');
      expect(json['role'], 'USER');
    });

    test('should return userId via getter id', () {
      final user = User(
        userId: 99,
        email: 'x@x.de',
        fullName: 'X',
        role: 'USER',
      );

      expect(user.id, 99); // alias für userId
    });
  });
}