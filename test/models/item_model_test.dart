import 'package:flutter_test/flutter_test.dart';
import 'package:kreisel_frontend/models/item_model.dart';

void main() {
  group('Item Model', () {
    test('fromJson() should correctly create an Item', () {
      final json = {
        'id': 1,
        'name': 'Skihelm',
        'size': 'M',
        'available': true,
        'description': 'Ein sicherer Helm',
        'brand': 'Uvex',
        'imageUrl': 'helmet.jpg',
        'averageRating': 4.5,
        'reviewCount': 12,
        'location': 'PASING',
        'gender': 'UNISEX',
        'category': 'SKI',
        'subcategory': 'HELMET',
        'zustand': 'NEU',
      };

      final item = Item.fromJson(json);

      expect(item.id, 1);
      expect(item.name, 'Skihelm');
      expect(item.size, 'M');
      expect(item.available, true);
      expect(item.description, 'Ein sicherer Helm');
      expect(item.brand, 'Uvex');
      expect(item.imageUrl, contains('helmet.jpg')); // imageUrl wird durch ApiService erweitert
      expect(item.averageRating, 4.5);
      expect(item.reviewCount, 12);
      expect(item.location, 'PASING');
      expect(item.gender, 'UNISEX');
      expect(item.category, 'SKI');
      expect(item.subcategory, 'HELMET');
      expect(item.zustand, 'NEU');
    });

    test('toJson() should correctly convert to Map', () {
      final item = Item(
        id: 2,
        name: 'Skibrille',
        size: 'L',
        available: false,
        description: 'Spiegelglas',
        brand: 'Oakley',
        imageUrl: 'https://example.com/glasses.png',
        averageRating: 0.0,
        reviewCount: 0,
        location: 'KARLSTRASSE',
        gender: 'FEMALE',
        category: 'SKI',
        subcategory: 'GLASSES',
        zustand: 'GUT',
      );

      final json = item.toJson();

      expect(json['id'], 2);
      expect(json['name'], 'Skibrille');
      expect(json['size'], 'L');
      expect(json['available'], false);
      expect(json['description'], 'Spiegelglas');
      expect(json['brand'], 'Oakley');
      expect(json['imageUrl'], 'https://example.com/glasses.png');
      expect(json['location'], 'KARLSTRASSE');
      expect(json['gender'], 'FEMALE');
      expect(json['category'], 'SKI');
      expect(json['subcategory'], 'GLASSES');
      expect(json['zustand'], 'GUT');
    });

    test('fromJson() handles missing and null fields gracefully', () {
  final json = {
    'id': null,
    'name': null,
    'available': null,
  };

  final item = Item.fromJson(json);

  expect(item.id, 0);
  expect(item.name, '');
  expect(item.available, true); // Defaultwert
});
  });
}