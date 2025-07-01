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

    group('Constructor Tests', () {
      test('should create Rental with all parameters', () {
        final rental = Rental(
          id: 1,
          item: testItem,
          user: testUser,
          rentalDate: rentalDate,
          endDate: endDate,
          returnDate: returnDate,
          extended: true,
          status: 'CUSTOM_STATUS',
        );

        expect(rental.id, 1);
        expect(rental.item, testItem);
        expect(rental.user, testUser);
        expect(rental.rentalDate, rentalDate);
        expect(rental.endDate, endDate);
        expect(rental.returnDate, returnDate);
        expect(rental.extended, true);
        expect(rental.status, 'CUSTOM_STATUS');
      });

      test('should create Rental with default values', () {
        final rental = Rental(
          id: 1,
          item: testItem,
          user: testUser,
          rentalDate: rentalDate,
          endDate: endDate,
        );

        expect(rental.id, 1);
        expect(rental.item, testItem);
        expect(rental.user, testUser);
        expect(rental.rentalDate, rentalDate);
        expect(rental.endDate, endDate);
        expect(rental.returnDate, null);
        expect(rental.extended, false);
        expect(rental.status, isNotEmpty); // Will be calculated
      });

      test('should calculate status when not provided', () {
        final futureEndDate = DateTime.now().add(Duration(days: 5));
        final rental = Rental(
          id: 1,
          item: testItem,
          user: testUser,
          rentalDate: rentalDate,
          endDate: futureEndDate,
        );

        expect(rental.status, 'ACTIVE');
      });
    });

    group('Status Calculation Tests', () {
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

      test('should calculate status as RETURNED when returnDate is provided', () {
        final rental = Rental(
          id: 3,
          item: testItem,
          user: testUser,
          rentalDate: rentalDate,
          endDate: endDate,
          returnDate: returnDate,
        );

        expect(rental.status, 'RETURNED');
      });
    });

    group('fromJson Tests', () {
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

      test('should create Rental from JSON with flat structure (no nested objects)', () {
        final rentalJson = {
          'id': 10,
          'userId': 1,
          'userEmail': 'flat@example.com',
          'userFullName': 'Flat User',
          'userRole': 'USER',
          'itemId': 2,
          'itemName': 'Flat Item',
          'location': 'KARLSTRASSE',
          'gender': 'HERREN',
          'category': 'EQUIPMENT',
          'subcategory': 'HELMET',
          'zustand': 'NEU',
          'rentalDate': rentalDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'extended': false,
          'status': 'ACTIVE',
        };

        final rental = Rental.fromJson(rentalJson);

        expect(rental.id, 10);
        expect(rental.user.email, 'flat@example.com');
        expect(rental.user.fullName, 'Flat User');
        expect(rental.user.userId, 1);
        expect(rental.item.name, 'Flat Item');
        expect(rental.item.id, 2);
        expect(rental.extended, false);
        expect(rental.status, 'ACTIVE');
      });

      test('should create Rental from JSON with string ID', () {
        final rentalJson = {
          'id': '15', // String ID
          'user': testUser.toJson(),
          'item': testItem.toJson(),
          'rentalDate': rentalDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'extended': false,
          'status': 'ACTIVE',
        };

        final rental = Rental.fromJson(rentalJson);

        expect(rental.id, 15);
        expect(rental.status, 'ACTIVE');
      });

      test('should handle missing optional fields gracefully', () {
        final rentalJson = {
          'id': 20,
          'user': testUser.toJson(),
          'item': testItem.toJson(),
          'rentalDate': rentalDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          // Missing: returnDate, extended, status
        };

        final rental = Rental.fromJson(rentalJson);

        expect(rental.id, 20);
        expect(rental.returnDate, null);
        expect(rental.extended, false);
        expect(rental.status, 'ACTIVE'); // Default fallback
      });

      test('should handle fallback values for missing user/item fields', () {
        final rentalJson = {
          'id': 25,
          // Missing user and item objects, using fallback fields
          'userId': 0,
          'userEmail': '',
          'userFullName': '',
          'userRole': 'USER',
          'itemId': 0,
          'itemName': '',
          'location': '',
          'gender': '',
          'category': '',
          'subcategory': '',
          'rentalDate': rentalDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        };

        final rental = Rental.fromJson(rentalJson);

        expect(rental.id, 25);
        expect(rental.user.userId, 0);
        expect(rental.user.email, '');
        expect(rental.item.id, 0);
        expect(rental.item.name, '');
        expect(rental.item.zustand, 'GEBRAUCHT'); // Default zustand
      });

      test('should throw error when parsing invalid JSON', () {
        final invalidJson = {
          'id': 'invalid_id_that_cannot_be_parsed_as_int',
          'rentalDate': 'invalid_date',
          'endDate': 'invalid_date',
        };

        expect(() => Rental.fromJson(invalidJson), throwsException);
      });
    });

    group('toJson Tests', () {
      test('should convert Rental to JSON with returnDate', () {
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
        expect(json['returnDate'], returnDate.toIso8601String());
        expect(json['extended'], false);
        expect(json['status'], 'RETURNED');
      });

      test('should convert Rental to JSON without returnDate', () {
        final rental = Rental(
          id: 100,
          item: testItem,
          user: testUser,
          rentalDate: rentalDate,
          endDate: endDate,
          returnDate: null, // Explicitly null
          extended: true,
        );

        final json = rental.toJson();

        expect(json['id'], 100);
        expect(json['user']['email'], 'test@example.com');
        expect(json['item']['name'], 'Test Ski');
        expect(json.containsKey('returnDate'), false); // Should not be included
        expect(json['extended'], true);
        expect(json['rentalDate'], rentalDate.toIso8601String());
        expect(json['endDate'], endDate.toIso8601String());
      });
    });

    group('Helper Getters Tests', () {
      test('should return correct itemId through getter', () {
        final rental = Rental(
          id: 1,
          item: testItem,
          user: testUser,
          rentalDate: rentalDate,
          endDate: endDate,
        );

        expect(rental.itemId, testItem.id);
        expect(rental.itemId, 1);
      });

      test('should return correct userId through getter', () {
        final rental = Rental(
          id: 1,
          item: testItem,
          user: testUser,
          rentalDate: rentalDate,
          endDate: endDate,
        );

        expect(rental.userId, testUser.userId);
        expect(rental.userId, 1);
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle rental with exact current time as endDate', () {
        final exactlyNow = DateTime.now();
        
        final rental = Rental(
          id: 1,
          item: testItem,
          user: testUser,
          rentalDate: rentalDate,
          endDate: exactlyNow,
        );

        // Status could be either ACTIVE or OVERDUE depending on exact timing
        expect(['ACTIVE', 'OVERDUE'].contains(rental.status), true);
      });

      test('should preserve all date information in JSON conversion', () {
        final specificDate = DateTime(2024, 3, 15, 14, 30, 45);
        final rental = Rental(
          id: 1,
          item: testItem,
          user: testUser,
          rentalDate: specificDate,
          endDate: specificDate.add(Duration(days: 7)),
          returnDate: specificDate.add(Duration(days: 5)),
        );

        final json = rental.toJson();
        final reconstructed = Rental.fromJson(json);

        expect(reconstructed.rentalDate, rental.rentalDate);
        expect(reconstructed.endDate, rental.endDate);
        expect(reconstructed.returnDate, rental.returnDate);
      });

      
    });
  });
}