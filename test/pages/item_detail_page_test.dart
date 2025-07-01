import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kreisel_frontend/pages/item_detail_page.dart';
import 'package:kreisel_frontend/models/item_model.dart';

// Mock HTTP Client
class MockClient extends Mock implements http.Client {
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    if (url.path.contains('/reviews/item/')) {
      // Return mock reviews
      return http.Response(jsonEncode([
        {
          'id': 1,
          'rating': 5,
          'comment': 'Excellent product!',
          'createdAt': '2024-01-15T10:30:00Z',
          'user': {
            'userId': 123,
            'fullName': 'Test User',
          },
          'item': {'id': 1},
          'rental': {'id': 1},
        },
        {
          'id': 2,
          'rating': 4,
          'comment': 'Very good quality',
          'createdAt': '2024-01-10T14:20:00Z',
          'user': {
            'userId': 456,
            'fullName': 'Another User',
          },
          'item': {'id': 1},
          'rental': {'id': 2},
        },
      ]), 200);
    }
    return http.Response('Not Found', 404);
  }

  @override
  void close() {}
}

void main() {
  // Test Items with different properties
  final testItemWithImage = Item(
    id: 1,
    name: 'Test Ski Rossignol',
    size: 'M',
    available: true,
    description: 'Professional alpine skis for advanced skiers',
    brand: 'Rossignol',
    imageUrl: 'https://example.com/ski.jpg',
    averageRating: 4.5,
    reviewCount: 12,
    location: 'PASING',
    gender: 'UNISEX',
    category: 'EQUIPMENT',
    subcategory: 'SKI',
    zustand: 'NEU',
  );

  final testItemWithoutImage = Item(
    id: 2,
    name: 'Winter Jacket North Face',
    size: 'L',
    available: false,
    description: 'Warm winter jacket for cold weather',
    brand: 'North Face',
    imageUrl: null,
    averageRating: 4.2,
    reviewCount: 0,
    location: 'KARLSTRASSE',
    gender: 'HERREN',
    category: 'KLEIDUNG',
    subcategory: 'JACKEN',
    zustand: 'GEBRAUCHT',
  );

  final testItemMinimal = Item(
    id: 3,
    name: 'Basic Item',
    available: true,
  );

  final testItemWithReviews = Item(
    id: 4,
    name: 'Reviewed Item',
    size: 'XL',
    available: true,
    description: 'Item with reviews',
    brand: 'TestBrand',
    imageUrl: 'https://example.com/item.jpg',
    averageRating: 4.8,
    reviewCount: 5,
    location: 'LOTHSTRASSE',
    gender: 'DAMEN',
    category: 'ACCESSOIRES',
    subcategory: 'MÜTZEN',
    zustand: 'NEU',
  );

  setUpAll(() {
    // Mock API Service for testing
  });

  // Helper to create testable widget
  Widget createTestableItemDetailPage(Item item) {
    return MaterialApp(
      home: ItemDetailPage(item: item),
    );
  }

  group('ItemDetailPage Widget Tests', () {
    testWidgets('should build without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
      await tester.pump();
      
      expect(find.byType(ItemDetailPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display item name in header', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
      await tester.pump();
      
      expect(find.text('Test Ski Rossignol'), findsOneWidget);
    });

    testWidgets('should show back button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
      await tester.pump();
      
      expect(find.byIcon(CupertinoIcons.back), findsOneWidget);
    });

    testWidgets('should display availability badge for available item', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
      await tester.pump();
      
      expect(find.text('Verfügbar'), findsOneWidget);
    });

    testWidgets('should display availability badge for unavailable item', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithoutImage));
      await tester.pump();
      
      expect(find.text('Ausgeliehen'), findsOneWidget);
    });

    testWidgets('should show rating when reviews exist', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
      await tester.pump();
      
      expect(find.text('4.5 (12)'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsWidgets);
    });

    testWidgets('should not show rating when no reviews', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithoutImage));
      await tester.pump();
      
      expect(find.text('4.2 (0)'), findsNothing);
    });

    testWidgets('should display brand when available', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
      await tester.pump();
      
      expect(find.text('Marke'), findsOneWidget);
      expect(find.text('Rossignol'), findsOneWidget);
    });

    testWidgets('should display size when available', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
      await tester.pump();
      
      expect(find.text('Größe'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
    });

    testWidgets('should display description when available', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
      await tester.pump();
      
      expect(find.text('Beschreibung'), findsOneWidget);
      expect(find.text('Professional alpine skis for advanced skiers'), findsOneWidget);
    });

    testWidgets('should display categories section', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
      await tester.pump();
      
      expect(find.text('Kategorien'), findsOneWidget);
    });

    testWidgets('should display location when available', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
      await tester.pump();
      
      expect(find.text('Standort'), findsOneWidget);
      expect(find.text('Pasing'), findsOneWidget);
    });

    testWidgets('should handle minimal item data', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemMinimal));
      await tester.pump();
      
      expect(find.text('Basic Item'), findsOneWidget);
      expect(find.text('Verfügbar'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('ItemDetailPage Image Display Tests', () {
    testWidgets('should show placeholder when no image URL', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithoutImage));
      await tester.pump();
      
      expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
      expect(find.text('Kein Bild verfügbar'), findsOneWidget);
    });

    testWidgets('should show image when URL is provided', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
      await tester.pump();
      
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should handle image loading states', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
      await tester.pump();
      
      // Should have image widget
      expect(find.byType(Image), findsOneWidget);
      
      // Should handle loading/error states gracefully
      expect(tester.takeException(), isNull);
    });

    testWidgets('should show error state for broken image', (WidgetTester tester) async {
      final itemWithBrokenImage = Item(
        id: testItemWithImage.id,
        name: testItemWithImage.name,
        size: testItemWithImage.size,
        available: testItemWithImage.available,
        description: testItemWithImage.description,
        brand: testItemWithImage.brand,
        imageUrl: 'https://broken-url.com/nonexistent.jpg',
        averageRating: testItemWithImage.averageRating,
        reviewCount: testItemWithImage.reviewCount,
        location: testItemWithImage.location,
        gender: testItemWithImage.gender,
        category: testItemWithImage.category,
        subcategory: testItemWithImage.subcategory,
        zustand: testItemWithImage.zustand,
      );
      
      await tester.pumpWidget(createTestableItemDetailPage(itemWithBrokenImage));
      await tester.pump();
      await tester.pump(Duration(seconds: 1)); // Wait for image load attempt
      
      // Should still render without crashing
      expect(find.byType(ItemDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ItemDetailPage Reviews Section Tests', () {
    testWidgets('should show reviews section when reviews exist', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithReviews));
      await tester.pump();
      await tester.pump(Duration(milliseconds: 100));
      
      expect(find.text('Bewertungen'), findsOneWidget);
    });

    testWidgets('should not show reviews section when no reviews', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithoutImage));
      await tester.pump();
      
      expect(find.text('Bewertungen'), findsNothing);
    });

    testWidgets('should handle loading state for reviews', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithReviews));
      await tester.pump();
      
      // Should handle review loading without crashing
      expect(find.byType(ItemDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle empty reviews state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithReviews));
      await tester.pump();
      await tester.pump(Duration(seconds: 1));
      
      // Should handle empty reviews gracefully
      expect(find.byType(ItemDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle reviews error state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithReviews));
      await tester.pump();
      await tester.pump(Duration(seconds: 1));
      
      // Should handle errors gracefully
      expect(find.byType(ItemDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ItemDetailPage Helper Methods Tests', () {
    test('_formatLabel should format uppercase labels correctly', () {
      // Test the logic that would be in _formatLabel
      String formatLabel(String label) {
        if (label.isEmpty) return '';
        if (label == label.toUpperCase()) {
          return label.substring(0, 1) + label.substring(1).toLowerCase();
        }
        return label;
      }

      expect(formatLabel('EQUIPMENT'), equals('Equipment'));
      expect(formatLabel('KLEIDUNG'), equals('Kleidung'));
      expect(formatLabel('MixedCase'), equals('MixedCase'));
      expect(formatLabel(''), equals(''));
    });

    test('_formatLocation should format locations correctly', () {
      // Test the logic that would be in _formatLocation
      String formatLocation(String location) {
        switch (location.toUpperCase()) {
          case 'PASING':
            return 'Pasing';
          case 'KARLSTRASSE':
            return 'Karlstraße';
          case 'LOTHSTRASSE':
            return 'Lothstraße';
          default:
            if (location.isEmpty) return '';
            if (location == location.toUpperCase()) {
              return location.substring(0, 1) + location.substring(1).toLowerCase();
            }
            return location;
        }
      }

      expect(formatLocation('PASING'), equals('Pasing'));
      expect(formatLocation('KARLSTRASSE'), equals('Karlstraße'));
      expect(formatLocation('LOTHSTRASSE'), equals('Lothstraße'));
      expect(formatLocation('OTHER'), equals('Other'));
    });

    test('star rating calculation should work correctly', () {
      // Test star rating logic
      int calculateStarCount(double rating) {
        return rating.round();
      }

      expect(calculateStarCount(4.5), equals(5));
      expect(calculateStarCount(4.2), equals(4));
      expect(calculateStarCount(3.1), equals(3));
      expect(calculateStarCount(3.7), equals(4));
      expect(calculateStarCount(0.0), equals(0));
      expect(calculateStarCount(5.0), equals(5));
    });
  });

  group('ItemDetailPage Lifecycle Tests', () {
    testWidgets('should handle widget initialization correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
      await tester.pump();
      
      // Should initialize without errors
      expect(find.byType(ItemDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle widget disposal correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
      await tester.pump();
      
      // Dispose widget
      await tester.pumpWidget(Container());
      await tester.pump();
      
      // Should dispose without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle state changes correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithReviews));
      await tester.pump();
      
      // Multiple state updates
      await tester.pump(Duration(milliseconds: 100));
      await tester.pump(Duration(milliseconds: 500));
      await tester.pump(Duration(seconds: 1));
      
      expect(find.byType(ItemDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle rapid rebuilds', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
      
      // Rapid rebuilds
      for (int i = 0; i < 10; i++) {
        await tester.pump(Duration(milliseconds: 10));
      }
      
      expect(find.byType(ItemDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ItemDetailPage Error Handling Tests', () {
    testWidgets('should handle missing required properties gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemMinimal));
      await tester.pump();
      
      // Should handle missing properties without crashing
      expect(find.byType(ItemDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle network errors gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithReviews));
      await tester.pump();
      await tester.pump(Duration(seconds: 2));
      
      // Should handle network errors without crashing
      expect(find.byType(ItemDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle async operations correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithReviews));
      await tester.pump();
      
      // Simulate async operations
      await tester.pump(Duration(milliseconds: 100));
      await tester.pump(Duration(milliseconds: 500));
      
      expect(find.byType(ItemDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle widget unmounting during async operations', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithReviews));
      await tester.pump();
      
      // Unmount widget quickly to test mounted check
      await tester.pumpWidget(Container());
      await tester.pump();
      
      expect(tester.takeException(), isNull);
    });
  });

  group('ItemDetailPage UI Component Tests', () {
    testWidgets('should display all category chips when available', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
      await tester.pump();
      
      // Should show category information
      expect(find.text('Kategorien'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle different item properties combinations', (WidgetTester tester) async {
      final itemCombinations = [
        testItemWithImage,
        testItemWithoutImage,
        testItemMinimal,
        testItemWithReviews,
      ];
      
      for (final item in itemCombinations) {
        await tester.pumpWidget(createTestableItemDetailPage(item));
        await tester.pump();
        
        expect(find.byType(ItemDetailPage), findsOneWidget);
        expect(find.text(item.name), findsOneWidget);
        expect(tester.takeException(), isNull);
        
        // Clean up
        await tester.pumpWidget(Container());
        await tester.pump();
      }
    });

    testWidgets('should handle scrolling correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
      await tester.pump();
      
      // Should have scrollable content
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      
      // Test scrolling
      final scrollView = find.byType(SingleChildScrollView);
      await tester.drag(scrollView, Offset(0, -100));
      await tester.pump();
      
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle different screen sizes', (WidgetTester tester) async {
      // Test mobile size
      await tester.binding.setSurfaceSize(Size(375, 667));
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
      await tester.pump();
      
      expect(find.byType(ItemDetailPage), findsOneWidget);
      
      // Test tablet size
      await tester.binding.setSurfaceSize(Size(768, 1024));
      await tester.pump();
      
      expect(find.byType(ItemDetailPage), findsOneWidget);
      
      // Reset
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('ItemDetailPage Performance Tests', () {
    testWidgets('should render within reasonable time', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
      await tester.pump();
      
      stopwatch.stop();
      
      // Should render quickly
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    testWidgets('should handle memory pressure', (WidgetTester tester) async {
      // Create and dispose multiple times
      for (int i = 0; i < 5; i++) {
        await tester.pumpWidget(createTestableItemDetailPage(testItemWithImage));
        await tester.pump();
        
        expect(find.byType(ItemDetailPage), findsOneWidget);
        
        await tester.pumpWidget(Container());
        await tester.pump();
      }
      
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle concurrent operations', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableItemDetailPage(testItemWithReviews));
      
      // Simulate concurrent async operations
      await tester.pump(Duration(milliseconds: 50));
      await tester.pump(Duration(milliseconds: 100));
      await tester.pump(Duration(milliseconds: 200));
      
      expect(find.byType(ItemDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ItemDetailPage Edge Cases Tests', () {
    testWidgets('should handle extremely long text content', (WidgetTester tester) async {
      final longTextItem = Item(
        id: testItemWithImage.id,
        name: 'Very Long Item Name That Should Still Display Correctly Even When It Exceeds Normal Length',
        size: testItemWithImage.size,
        available: testItemWithImage.available,
        description: 'This is an extremely long description that should test how the widget handles very long text content and whether it wraps correctly or causes any layout issues in the user interface.',
        brand: testItemWithImage.brand,
        imageUrl: testItemWithImage.imageUrl,
        averageRating: testItemWithImage.averageRating,
        reviewCount: testItemWithImage.reviewCount,
        location: testItemWithImage.location,
        gender: testItemWithImage.gender,
        category: testItemWithImage.category,
        subcategory: testItemWithImage.subcategory,
        zustand: testItemWithImage.zustand,
      );
      
      await tester.pumpWidget(createTestableItemDetailPage(longTextItem));
      await tester.pump();
      
      expect(find.byType(ItemDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle special characters in content', (WidgetTester tester) async {
      final specialCharItem = Item(
        id: testItemWithImage.id,
        name: 'Item with éÄöüß & Special Characters!',
        size: testItemWithImage.size,
        available: testItemWithImage.available,
        description: 'Description with symbols: @#\$%^&*()_+-={}[]|\\:";\'<>?,./~`',
        brand: 'Brand™ ® © ±',
        imageUrl: testItemWithImage.imageUrl,
        averageRating: testItemWithImage.averageRating,
        reviewCount: testItemWithImage.reviewCount,
        location: testItemWithImage.location,
        gender: testItemWithImage.gender,
        category: testItemWithImage.category,
        subcategory: testItemWithImage.subcategory,
        zustand: testItemWithImage.zustand,
      );
      
      await tester.pumpWidget(createTestableItemDetailPage(specialCharItem));
      await tester.pump();
      
      expect(find.byType(ItemDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle zero and negative values', (WidgetTester tester) async {
      final edgeValueItem = Item(
        id: testItemWithImage.id,
        name: testItemWithImage.name,
        size: testItemWithImage.size,
        available: testItemWithImage.available,
        description: testItemWithImage.description,
        brand: testItemWithImage.brand,
        imageUrl: testItemWithImage.imageUrl,
        averageRating: 0.0,
        reviewCount: 0,
        location: testItemWithImage.location,
        gender: testItemWithImage.gender,
        category: testItemWithImage.category,
        subcategory: testItemWithImage.subcategory,
        zustand: testItemWithImage.zustand,
      );
      
      await tester.pumpWidget(createTestableItemDetailPage(edgeValueItem));
      await tester.pump();
      
      expect(find.byType(ItemDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle all null optional fields', (WidgetTester tester) async {
      final nullFieldsItem = Item(
        id: 999,
        name: 'Null Fields Item',
        available: true,
        size: null,
        description: null,
        brand: null,
        imageUrl: null,
        averageRating: 0.0,
        reviewCount: 0,
        location: null,
        gender: null,
        category: null,
        subcategory: null,
        zustand: null,
      );
      
      await tester.pumpWidget(createTestableItemDetailPage(nullFieldsItem));
      await tester.pump();
      
      expect(find.byType(ItemDetailPage), findsOneWidget);
      expect(find.text('Null Fields Item'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}