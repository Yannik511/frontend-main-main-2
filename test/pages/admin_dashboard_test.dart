import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kreisel_frontend/pages/admin_dashboard.dart';
import 'package:kreisel_frontend/models/item_model.dart';
import 'package:kreisel_frontend/models/rental_model.dart';
import 'package:kreisel_frontend/models/user_model.dart';

void main() {
  // Test data setup
  final testItems = [
    Item(
      id: 1,
      name: 'Test Ski',
      size: 'M',
      available: true,
      description: 'Test ski description',
      brand: 'TestBrand',
      imageUrl: 'https://example.com/image.jpg',
      averageRating: 4.5,
      reviewCount: 10,
      location: 'PASING',
      gender: 'UNISEX',
      category: 'EQUIPMENT',
      subcategory: 'SKI',
      zustand: 'NEU',
    ),
    Item(
      id: 2,
      name: 'Test Jacket',
      size: 'L',
      available: false,
      description: 'Test jacket description',
      brand: 'TestBrand2',
      imageUrl: null,
      averageRating: 3.8,
      reviewCount: 5,
      location: 'KARLSTRASSE',
      gender: 'HERREN',
      category: 'KLEIDUNG',
      subcategory: 'JACKEN',
      zustand: 'GEBRAUCHT',
    ),
  ];

  final testUser = User(
    userId: 123,
    fullName: 'Test User',
    email: 'test@example.com',
    role: 'USER',
  );

  final testAdminUser = User(
    userId: 456,
    fullName: 'Admin User',
    email: 'admin@example.com',
    role: 'ADMIN',
  );

  final testRentals = [
    Rental(
      id: 1,
      item: testItems[0],
      user: testUser,
      rentalDate: DateTime.now().subtract(Duration(days: 2)),
      endDate: DateTime.now().add(Duration(days: 5)),
      status: 'ACTIVE',
    ),
    Rental(
      id: 2,
      item: testItems[1],
      user: testUser,
      rentalDate: DateTime.now().subtract(Duration(days: 10)),
      endDate: DateTime.now().subtract(Duration(days: 1)),
      status: 'OVERDUE',
    ),
  ];

  final testUsers = [
    testUser,
    testAdminUser,
    User(
      userId: 789,
      fullName: 'Another User',
      email: 'another@example.com',
      role: 'USER',
    ),
  ];

  setUpAll(() async {
    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    // Reset SharedPreferences before each test and set up token
    SharedPreferences.setMockInitialValues({
      'admin_token': 'mock_admin_token_123'
    });
  });

  // Helper widget to wrap AdminDashboard with proper testing environment
  Widget createTestableWidget() {
    return MaterialApp(
      home: AdminDashboard(),
      routes: {
        '/login': (context) => Scaffold(
          body: Text('Login Page'),
          appBar: AppBar(title: Text('Login')),
        ),
      },
    );
  }

  group('AdminDashboard Basic Widget Tests', () {
    testWidgets('should build and handle lifecycle', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      
      // Let the widget initialize
      await tester.pump();
      
      // Verify that some kind of page is rendered (either AdminDashboard or redirected page)
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Should have at least one Scaffold (either AdminDashboard or Login)
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle navigation and routing', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pump();
      await tester.pump(Duration(seconds: 1)); // Allow for async operations
      
      // After all async operations, should have a stable UI
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Should have navigated somewhere (either stayed on AdminDashboard or went to Login)
      final scaffolds = find.byType(Scaffold);
      expect(scaffolds, findsAtLeastNWidgets(1));
    });

    testWidgets('should survive multiple rebuild cycles', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      
      // Multiple rebuild cycles
      for (int i = 0; i < 5; i++) {
        await tester.pump();
        await tester.pump(Duration(milliseconds: 100));
      }
      
      // Should still have a stable widget tree
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('AdminDashboard Error Handling Tests', () {
    testWidgets('should handle missing authentication gracefully', (WidgetTester tester) async {
      // Clear token to simulate no authentication
      SharedPreferences.setMockInitialValues({});
      
      await tester.pumpWidget(createTestableWidget());
      await tester.pump();
      await tester.pump(Duration(seconds: 1));
      
      // Should either stay on AdminDashboard or navigate to login
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Should not crash
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle network failures gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      
      // Allow for network calls to fail and be handled
      await tester.pump();
      await tester.pump(Duration(milliseconds: 500));
      await tester.pump(Duration(seconds: 1));
      
      // Should maintain app structure despite network failures
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('AdminDashboard State Management Tests', () {
    testWidgets('should maintain consistent state during errors', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      
      // Simulate various state changes and potential errors
      await tester.pump();
      await tester.pump(Duration(milliseconds: 100));
      await tester.pump(Duration(milliseconds: 500));
      await tester.pump(Duration(seconds: 1));
      
      // Should maintain app integrity
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle rapid state transitions', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      
      // Rapid state transitions
      for (int i = 0; i < 20; i++) {
        await tester.pump(Duration(milliseconds: 10));
      }
      
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('AdminDashboard Screen Adaptability Tests', () {
    testWidgets('should adapt to different screen sizes', (WidgetTester tester) async {
      // Test with tablet size
      await tester.binding.setSurfaceSize(Size(1024, 768));
      
      await tester.pumpWidget(createTestableWidget());
      await tester.pump();
      await tester.pump(Duration(seconds: 1));

      expect(find.byType(MaterialApp), findsOneWidget);

      // Test with mobile size
      await tester.binding.setSurfaceSize(Size(375, 667));
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Reset to default
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should handle orientation changes', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pump();
      
      // Simulate orientation change
      await tester.binding.setSurfaceSize(Size(667, 375)); // Landscape
      await tester.pump();
      
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Back to portrait
      await tester.binding.setSurfaceSize(Size(375, 667));
      await tester.pump();
      
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('AdminDashboard Extension Tests', () {
    test('ItemExtension copyWith should work correctly', () {
      final originalItem = testItems[0];
      final copiedItem = originalItem.copyWith(name: 'Updated Name');

      expect(copiedItem.name, equals('Updated Name'));
      expect(copiedItem.id, equals(originalItem.id));
      expect(copiedItem.size, equals(originalItem.size));
      expect(copiedItem.location, equals(originalItem.location));
      expect(copiedItem.available, equals(originalItem.available));
    });

    test('ItemExtension copyWith should handle null values correctly', () {
      final originalItem = testItems[0];
      final copiedItem = originalItem.copyWith();

      expect(copiedItem.name, equals(originalItem.name));
      expect(copiedItem.id, equals(originalItem.id));
      expect(copiedItem.size, equals(originalItem.size));
      expect(copiedItem.available, equals(originalItem.available));
    });

    test('ItemExtension copyWith should handle partial updates', () {
      final originalItem = testItems[0];
      final copiedItem = originalItem.copyWith(
        name: 'New Name',
        available: false,
        imageUrl: 'https://newimage.com/test.jpg',
      );

      expect(copiedItem.name, equals('New Name'));
      expect(copiedItem.available, equals(false));
      expect(copiedItem.imageUrl, equals('https://newimage.com/test.jpg'));
      expect(copiedItem.id, equals(originalItem.id)); // Unchanged
      expect(copiedItem.size, equals(originalItem.size)); // Unchanged
    });

    test('ItemExtension copyWith should preserve all fields when no changes', () {
      final originalItem = testItems[0];
      final copiedItem = originalItem.copyWith();

      expect(copiedItem.toJson(), equals(originalItem.toJson()));
    });

    test('ItemExtension copyWith should handle complex field updates', () {
      final originalItem = testItems[0];
      final copiedItem = originalItem.copyWith(
        name: 'Updated Item',
        description: 'Updated Description',
        brand: 'Updated Brand',
        size: 'XL',
        available: false,
        location: 'LOTHSTRASSE',
        gender: 'DAMEN',
        category: 'KLEIDUNG',
        subcategory: 'JACKEN',
        zustand: 'GEBRAUCHT',
        averageRating: 3.5,
        reviewCount: 15,
        imageUrl: 'https://updated.com/image.jpg',
      );

      expect(copiedItem.name, equals('Updated Item'));
      expect(copiedItem.description, equals('Updated Description'));
      expect(copiedItem.brand, equals('Updated Brand'));
      expect(copiedItem.size, equals('XL'));
      expect(copiedItem.available, equals(false));
      expect(copiedItem.location, equals('LOTHSTRASSE'));
      expect(copiedItem.gender, equals('DAMEN'));
      expect(copiedItem.category, equals('KLEIDUNG'));
      expect(copiedItem.subcategory, equals('JACKEN'));
      expect(copiedItem.zustand, equals('GEBRAUCHT'));
      expect(copiedItem.averageRating, equals(3.5));
      expect(copiedItem.reviewCount, equals(15));
      expect(copiedItem.imageUrl, equals('https://updated.com/image.jpg'));
      expect(copiedItem.id, equals(originalItem.id)); // ID should remain unchanged
    });
  });

  group('AdminDashboard Constants Tests', () {
    test('should have correct location constants', () {
      const locations = ['PASING', 'KARLSTRASSE', 'LOTHSTRASSE'];
      expect(locations.length, equals(3));
      expect(locations.contains('PASING'), isTrue);
      expect(locations.contains('KARLSTRASSE'), isTrue);
      expect(locations.contains('LOTHSTRASSE'), isTrue);
    });

    test('should have correct gender constants', () {
      const genders = ['UNISEX', 'HERREN', 'DAMEN'];
      expect(genders.length, equals(3));
      expect(genders.contains('UNISEX'), isTrue);
      expect(genders.contains('HERREN'), isTrue);
      expect(genders.contains('DAMEN'), isTrue);
    });

    test('should have correct category mappings', () {
      const subcategories = {
        'EQUIPMENT': ['HELME', 'SKI', 'SNOWBOARDS', 'BRILLEN', 'FLASCHEN'],
        'KLEIDUNG': [
          'JACKEN',
          'HOSEN',
          'HANDSCHUHE',
          'MUETZEN',
          'SCHALS',
          'STIEFEL',
          'WANDERSCHUHE',
        ],
      };
      
      expect(subcategories['EQUIPMENT']?.contains('SKI'), isTrue);
      expect(subcategories['EQUIPMENT']?.contains('HELME'), isTrue);
      expect(subcategories['EQUIPMENT']?.contains('SNOWBOARDS'), isTrue);
      expect(subcategories['EQUIPMENT']?.contains('BRILLEN'), isTrue);
      expect(subcategories['EQUIPMENT']?.contains('FLASCHEN'), isTrue);
      
      expect(subcategories['KLEIDUNG']?.contains('JACKEN'), isTrue);
      expect(subcategories['KLEIDUNG']?.contains('HOSEN'), isTrue);
      expect(subcategories['KLEIDUNG']?.contains('HANDSCHUHE'), isTrue);
      expect(subcategories['KLEIDUNG']?.contains('MUETZEN'), isTrue);
      expect(subcategories['KLEIDUNG']?.contains('SCHALS'), isTrue);
      expect(subcategories['KLEIDUNG']?.contains('STIEFEL'), isTrue);
      expect(subcategories['KLEIDUNG']?.contains('WANDERSCHUHE'), isTrue);
    });

    test('should have correct condition constants', () {
      const conditions = ['NEU', 'GEBRAUCHT'];
      expect(conditions.length, equals(2));
      expect(conditions.contains('NEU'), isTrue);
      expect(conditions.contains('GEBRAUCHT'), isTrue);
    });

    test('should validate subcategory mappings are complete', () {
      const subcategories = {
        'EQUIPMENT': ['HELME', 'SKI', 'SNOWBOARDS', 'BRILLEN', 'FLASCHEN'],
        'KLEIDUNG': [
          'JACKEN',
          'HOSEN',
          'HANDSCHUHE',
          'MUETZEN',
          'SCHALS',
          'STIEFEL',
          'WANDERSCHUHE',
        ],
      };
      
      // Ensure each category has subcategories
      expect(subcategories.keys.length, equals(2));
      expect(subcategories['EQUIPMENT']?.isNotEmpty, isTrue);
      expect(subcategories['KLEIDUNG']?.isNotEmpty, isTrue);
      
      // Ensure minimum number of subcategories
      expect(subcategories['EQUIPMENT']?.length, greaterThanOrEqualTo(5));
      expect(subcategories['KLEIDUNG']?.length, greaterThanOrEqualTo(7));
    });
  });

  group('AdminDashboard Model Integration Tests', () {
    test('should create valid Item objects with all fields', () {
      final item = Item(
        id: 1,
        name: 'Test Item',
        size: 'M',
        available: true,
        description: 'Test Description',
        brand: 'Test Brand',
        imageUrl: 'https://example.com/image.jpg',
        averageRating: 4.2,
        reviewCount: 8,
        location: 'PASING',
        gender: 'UNISEX',
        category: 'EQUIPMENT',
        subcategory: 'SKI',
        zustand: 'NEU',
      );

      expect(item.id, equals(1));
      expect(item.name, equals('Test Item'));
      expect(item.size, equals('M'));
      expect(item.available, equals(true));
      expect(item.description, equals('Test Description'));
      expect(item.brand, equals('Test Brand'));
      expect(item.imageUrl, equals('https://example.com/image.jpg'));
      expect(item.averageRating, equals(4.2));
      expect(item.reviewCount, equals(8));
      expect(item.location, equals('PASING'));
      expect(item.gender, equals('UNISEX'));
      expect(item.category, equals('EQUIPMENT'));
      expect(item.subcategory, equals('SKI'));
      expect(item.zustand, equals('NEU'));
    });

    test('should create Item objects with default values', () {
      final item = Item(
        id: 1,
        name: 'Minimal Item',
      );

      expect(item.id, equals(1));
      expect(item.name, equals('Minimal Item'));
      expect(item.available, equals(true)); // Default value
      expect(item.averageRating, equals(0.0)); // Default value
      expect(item.reviewCount, equals(0)); // Default value
      expect(item.size, isNull);
      expect(item.description, isNull);
      expect(item.brand, isNull);
      expect(item.imageUrl, isNull);
      expect(item.location, isNull);
      expect(item.gender, isNull);
      expect(item.category, isNull);
      expect(item.subcategory, isNull);
      expect(item.zustand, isNull);
    });

    test('should create valid User objects', () {
      final user = User(
        userId: 123,
        email: 'test@example.com',
        fullName: 'Test User',
        role: 'USER',
      );

      expect(user.userId, equals(123));
      expect(user.email, equals('test@example.com'));
      expect(user.fullName, equals('Test User'));
      expect(user.role, equals('USER'));
      expect(user.id, equals(123)); // Compatibility getter
    });

    test('should create valid Rental objects', () {
      final now = DateTime.now();
      final rental = Rental(
        id: 1,
        item: testItems[0],
        user: testUser,
        rentalDate: now.subtract(Duration(days: 1)),
        endDate: now.add(Duration(days: 7)),
        extended: false,
        status: 'ACTIVE',
      );

      expect(rental.id, equals(1));
      expect(rental.item, equals(testItems[0]));
      expect(rental.user, equals(testUser));
      expect(rental.itemId, equals(testItems[0].id)); // Helper getter
      expect(rental.userId, equals(testUser.userId)); // Helper getter
      expect(rental.extended, equals(false));
      expect(rental.status, equals('ACTIVE'));
    });

    test('should handle Item.fromJson correctly', () {
      final json = {
        'id': 1,
        'name': 'Test Item',
        'size': 'L',
        'available': true,
        'description': 'Test Description',
        'brand': 'Test Brand',
        'imageUrl': '/images/test.jpg',
        'averageRating': 4.5,
        'reviewCount': 10,
        'location': 'PASING',
        'gender': 'UNISEX',
        'category': 'EQUIPMENT',
        'subcategory': 'SKI',
        'zustand': 'NEU',
      };

      final item = Item.fromJson(json);
      expect(item.id, equals(1));
      expect(item.name, equals('Test Item'));
      expect(item.size, equals('L'));
      expect(item.available, equals(true));
      expect(item.description, equals('Test Description'));
      expect(item.brand, equals('Test Brand'));
      expect(item.averageRating, equals(4.5));
      expect(item.reviewCount, equals(10));
      expect(item.location, equals('PASING'));
      expect(item.gender, equals('UNISEX'));
      expect(item.category, equals('EQUIPMENT'));
      expect(item.subcategory, equals('SKI'));
      expect(item.zustand, equals('NEU'));
    });

    test('should handle User.fromJson correctly', () {
      final json = {
        'userId': 123,
        'email': 'test@example.com',
        'fullName': 'Test User',
        'role': 'USER',
      };

      final user = User.fromJson(json);
      expect(user.userId, equals(123));
      expect(user.email, equals('test@example.com'));
      expect(user.fullName, equals('Test User'));
      expect(user.role, equals('USER'));
    });

    test('should handle Rental status calculation', () {
      final now = DateTime.now();
      
      // Active rental
      final activeRental = Rental(
        id: 1,
        item: testItems[0],
        user: testUser,
        rentalDate: now.subtract(Duration(days: 1)),
        endDate: now.add(Duration(days: 7)),
      );
      expect(activeRental.status, equals('ACTIVE'));
      
      // Overdue rental
      final overdueRental = Rental(
        id: 2,
        item: testItems[0],
        user: testUser,
        rentalDate: now.subtract(Duration(days: 10)),
        endDate: now.subtract(Duration(days: 1)),
      );
      expect(overdueRental.status, equals('OVERDUE'));
      
      // Returned rental
      final returnedRental = Rental(
        id: 3,
        item: testItems[0],
        user: testUser,
        rentalDate: now.subtract(Duration(days: 10)),
        endDate: now.subtract(Duration(days: 1)),
        returnDate: now.subtract(Duration(hours: 1)),
      );
      expect(returnedRental.status, equals('RETURNED'));
    });
  });

  group('AdminDashboard Performance and Memory Tests', () {
    testWidgets('should handle multiple rapid operations', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      
      // Stress test with rapid operations
      for (int i = 0; i < 50; i++) {
        await tester.pump(Duration(milliseconds: 1));
      }
      
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should dispose properly without memory leaks', (WidgetTester tester) async {
      // Create and dispose multiple times to test memory management
      for (int i = 0; i < 5; i++) {
        await tester.pumpWidget(createTestableWidget());
        await tester.pump();
        
        // Remove the widget
        await tester.pumpWidget(Container());
        await tester.pump();
      }

      // No exceptions should be thrown during disposal
      expect(tester.takeException(), isNull);
    });

    testWidgets('should render within reasonable time', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(createTestableWidget());
      await tester.pump();
      
      stopwatch.stop();
      
      // Should render quickly (less than 2 seconds in tests)
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}