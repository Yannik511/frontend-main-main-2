import 'package:flutter_test/flutter_test.dart';
import 'package:kreisel_frontend/models/review_model.dart';

void main() {
  group('Review Model', () {
    test('should parse complete Map with nested user and rental/item maps', () {
      final map = {
        'id': 10,
        'item': {'id': 5},
        'user': {
          'userId': 3,
          'fullName': 'Anna Schmidt',
        },
        'rental': {'id': 7},
        'rating': 4,
        'comment': 'Sehr gutes Produkt!',
        'createdAt': '2024-06-01T12:00:00Z',
      };

      final review = Review.fromMap(map);

      expect(review.id, 10);
      expect(review.itemId, 5);
      expect(review.userId, 3);
      expect(review.rentalId, 7);
      expect(review.rating, 4);
      expect(review.comment, 'Sehr gutes Produkt!');
      expect(review.createdAt, DateTime.parse('2024-06-01T12:00:00Z'));
      expect(review.username, 'Anna Schmidt');
    });

    test('should fallback correctly if user and item are flat', () {
      final map = {
        'id': 11,
        'itemId': 8,
        'userId': 2,
        'rentalId': 9,
        'rating': 3,
        'createdAt': '2023-01-01T10:00:00Z',
        'username': 'Max Mustermann',
        'comment': 'Okayish',
      };

      final review = Review.fromMap(map);

      expect(review.itemId, 8);
      expect(review.userId, 2);
      expect(review.rentalId, 9);
      expect(review.username, 'Max Mustermann');
      expect(review.comment, 'Okayish');
    });

    test('should generate correct map from Review instance', () {
      final review = Review(
        id: 1,
        itemId: 5,
        userId: 2,
        rentalId: 9,
        rating: 5,
        comment: 'Top!',
        createdAt: DateTime.utc(2024, 6, 24),
        username: 'Testuser',
      );

      final map = review.toMap();

      expect(map['rentalId'], 9);
      expect(map['rating'], 5);
      expect(map['comment'], 'Top!');
    });

    test('should exclude empty comment from map', () {
      final review = Review(
        id: 1,
        itemId: 5,
        userId: 2,
        rentalId: 9,
        rating: 5,
        comment: '',
        createdAt: DateTime.utc(2024, 6, 24),
        username: 'Testuser',
      );

      final map = review.toMap();

      expect(map.containsKey('comment'), isFalse);
    });

    test('should format date correctly using formattedDate', () {
      final review = Review(
        id: 1,
        itemId: 1,
        userId: 1,
        rentalId: 1,
        rating: 5,
        comment: 'Kommentar',
        createdAt: DateTime(2024, 4, 15),
        username: 'Benutzer',
      );

      expect(review.formattedDate, '15.04.2024');
    });
  });
}