import 'package:flutter_test/flutter_test.dart';
import 'package:kreisel_frontend/models/rental_model.dart';
import 'package:kreisel_frontend/models/user_model.dart';
import 'package:kreisel_frontend/models/item_model.dart';

void main() {
  group('Rental Model', () {
    final testUser = User(
      userId: 1,
      email: 'test@example.com',
      fullName: 'Test User',
      role: 'USER',
    );

    final testItem = Item(
      id: 1,
      name: 'Test Ski',
      available: true,
      location: 'Pasing',
      gender: 'UNISEX',
      category: 'SKI',
      subcategory: 'TOURING',
      zustand: 'GUT',
    );

    final rentalDate = DateTime(2024, 1, 1);
    final endDate = DateTime(2024, 1, 10);
    final returnDate = DateTime(2024, 1, 9);

    test('should create Rental from JSON with nested user and item', () {
      final rentalJson = {
        'id': 5,
        'user': testUser.toJson(),
        'item': testItem.toJson(),
        'rentalDate': rentalDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'returnDate': returnDate.toIso8601String(),
        'extended': true,
        'status': 'RETURNED',
      };

      final rental = Rental.fromJson(rentalJson);

      expect(rental.id, 5);
      expect(rental.user.email, 'test@example.com');
      expect(rental.item.name, 'Test Ski');
      expect(rental.extended, true);
      expect(rental.status, 'RETURNED');
    });

    test('should convert Rental to JSON', () {
      final rental = Rental(
        id: 99,
        item: testItem,
        user: testUser,
        rentalDate: rentalDate,
        endDate: endDate,
        returnDate: returnDate,
        extended: false,
      );

      final json = rental.toJson();

      expect(json['id'], 99);
      expect(json['user']['email'], 'test@example.com');
      expect(json['item']['name'], 'Test Ski');
      expect(json['status'], 'RETURNED');
    });

    test('should calculate status correctly as OVERDUE', () {
      final pastEndDate = DateTime.now().subtract(Duration(days: 5));

      final rental = Rental(
        id: 1,
        item: testItem,
        user: testUser,
        rentalDate: rentalDate,
        endDate: pastEndDate,
        returnDate: null,
      );

      expect(rental.status, 'OVERDUE');
    });

    test('should calculate status as ACTIVE for future end date', () {
      final futureEndDate = DateTime.now().add(Duration(days: 5));

      final rental = Rental(
        id: 2,
        item: testItem,
        user: testUser,
        rentalDate: rentalDate,
        endDate: futureEndDate,
        returnDate: null,
      );

      expect(rental.status, 'ACTIVE');
    });
  });
}