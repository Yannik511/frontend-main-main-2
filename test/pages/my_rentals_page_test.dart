import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreisel_frontend/pages/my_rentals_page.dart';
import 'package:kreisel_frontend/models/rental_model.dart';
import 'package:kreisel_frontend/models/item_model.dart';
import 'package:kreisel_frontend/models/user_model.dart';

// Mock API Service für Tests
class MockRentalsApiService implements RentalsApiService {
  bool shouldThrowError = false;
  List<Rental> mockActiveRentals = [];
  List<Rental> mockPastRentals = [];
  bool returnRentalCalled = false;
  bool extendRentalCalled = false;
  
  @override
  Future<List<Rental>> getUserActiveRentals() async {
    if (shouldThrowError) throw Exception('API Error');
    return mockActiveRentals;
  }
  
  @override
  Future<List<Rental>> getUserRentalHistory() async {
    if (shouldThrowError) throw Exception('API Error');
    return mockPastRentals;
  }
  
  @override
  Future<void> returnRental(int rentalId) async {
    if (shouldThrowError) throw Exception('Return Error');
    returnRentalCalled = true;
  }
  
  @override
  Future<void> extendRental({required int rentalId, required DateTime newEndDate}) async {
    if (shouldThrowError) throw Exception('Extend Error');
    extendRentalCalled = true;
  }
}

void main() {
  group('MyRentalsPage Comprehensive Tests', () {
    late MockRentalsApiService mockApiService;
    late User testUser;
    late Item testItem1;
    late Item testItem2;
    late List<Rental> testActiveRentals;
    late List<Rental> testPastRentals;

    setUpAll(() {
      testUser = User(
        userId: 123,
        fullName: 'Test User',
        email: 'test@example.com',
        role: 'USER',
      );

      testItem1 = Item(
        id: 1,
        name: 'Test Ski Rossignol',
        size: 'M',
        available: false,
        description: 'Professional alpine skis',
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

      testItem2 = Item(
        id: 2,
        name: 'Winter Jacket',
        size: 'L',
        available: true,
        description: 'Warm winter jacket',
        brand: 'North Face',
        imageUrl: null,
        averageRating: 4.2,
        reviewCount: 8,
        location: 'KARLSTRASSE',
        gender: 'HERREN',
        category: 'KLEIDUNG',
        subcategory: 'JACKEN',
        zustand: 'GEBRAUCHT',
      );

      testActiveRentals = [
        Rental(
          id: 1,
          item: testItem1,
          user: testUser,
          rentalDate: DateTime.now().subtract(Duration(days: 5)),
          endDate: DateTime.now().add(Duration(days: 10)),
          status: 'ACTIVE',
        ),
        Rental(
          id: 2,
          item: testItem2,
          user: testUser,
          rentalDate: DateTime.now().subtract(Duration(days: 15)),
          endDate: DateTime.now().subtract(Duration(days: 2)),
          status: 'OVERDUE',
        ),
      ];

      testPastRentals = [
        Rental(
          id: 3,
          item: testItem1,
          user: testUser,
          rentalDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now().subtract(Duration(days: 5)),
          returnDate: DateTime.now().subtract(Duration(days: 3)),
          status: 'RETURNED',
        ),
      ];
    });

    setUp(() {
      mockApiService = MockRentalsApiService();
      mockApiService.mockActiveRentals = testActiveRentals;
      mockApiService.mockPastRentals = testPastRentals;
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MyRentalsPage(apiService: mockApiService),
      );
    }

    group('Widget Creation and Lifecycle', () {
      testWidgets('should create widget successfully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(MyRentalsPage), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.text('Meine Ausleihen'), findsOneWidget);
      });

      testWidgets('should show loading state initially', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      });

      testWidgets('should load data successfully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump(); // Wait for loadRentals to complete
        
        expect(find.byType(CupertinoActivityIndicator), findsNothing);
        expect(find.text('Test Ski Rossignol'), findsAtLeastNWidgets(1));
        expect(find.text('Winter Jacket'), findsOneWidget);
      });
    });

    group('Loading and Error States', () {
      testWidgets('should handle API errors gracefully', (WidgetTester tester) async {
        mockApiService.shouldThrowError = true;
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump(); // Wait for error
        
        expect(find.byType(CupertinoActivityIndicator), findsNothing);
        expect(find.text('Fehler'), findsOneWidget);
      });

      testWidgets('should show empty state when no rentals', (WidgetTester tester) async {
        mockApiService.mockActiveRentals = [];
        mockApiService.mockPastRentals = [];
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();
        
        expect(find.text('Keine aktiven Ausleihen'), findsOneWidget);
        expect(find.text('Keine vergangenen Ausleihen'), findsOneWidget);
      });
    });

    group('Data Display Tests', () {
      testWidgets('should display active rentals correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();
        
        expect(find.text('Aktuelle Ausleihen (2)'), findsOneWidget);
        expect(find.text('Test Ski Rossignol'), findsAtLeastNWidgets(1));
        expect(find.text('Winter Jacket'), findsOneWidget);
        expect(find.text('Status: ACTIVE'), findsOneWidget);
        expect(find.text('Status: OVERDUE'), findsOneWidget);
      });

      testWidgets('should display past rentals correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();
        
        expect(find.text('Vergangene Ausleihen (1)'), findsOneWidget);
        expect(find.textContaining('Ausgeliehen:'), findsOneWidget);
        expect(find.textContaining('Zurückgegeben:'), findsOneWidget);
      });

      testWidgets('should show OVERDUE status in red', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();
        
        final overdueText = tester.widget<Text>(find.text('Status: OVERDUE'));
        expect(overdueText.style?.color, equals(Colors.red));
      });
    });

    group('Button Interactions', () {
      testWidgets('should show extend rental dialog', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();
        
        await tester.tap(find.text('Verlängern').first);
        await tester.pump();
        
        expect(find.text('Ausleihe verlängern'), findsOneWidget);
        expect(find.textContaining('Neues Rückgabedatum:'), findsOneWidget);
      });

      testWidgets('should show return rental dialog', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();
        
        await tester.tap(find.text('Zurückgeben').first);
        await tester.pump();
        
        expect(find.text('Item zurückgeben'), findsOneWidget);
        expect(find.textContaining('wirklich zurückgeben'), findsOneWidget);
      });

      

      testWidgets('should handle extend rental confirmation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();
        
        await tester.tap(find.text('Verlängern').first);
        await tester.pump();
        
        await tester.tap(find.text('Verlängern').last);
        await tester.pump();
        await tester.pump();
        
        expect(mockApiService.extendRentalCalled, isTrue);
        expect(find.text('Erfolgreich'), findsOneWidget);
      });

      testWidgets('should handle return rental confirmation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();
        
        await tester.tap(find.text('Zurückgeben').first);
        await tester.pump();
        
        await tester.tap(find.text('Zurückgeben').last);
        await tester.pump();
        await tester.pump();
        
        expect(mockApiService.returnRentalCalled, isTrue);
        expect(find.text('Erfolgreich'), findsOneWidget);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle extend rental error', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();
        
        mockApiService.shouldThrowError = true;
        
        await tester.tap(find.text('Verlängern').first);
        await tester.pump();
        
        await tester.tap(find.text('Verlängern').last);
        await tester.pump();
        await tester.pump();
        
        expect(find.text('Fehler'), findsOneWidget);
        expect(find.textContaining('fehlgeschlagen'), findsOneWidget);
      });

      testWidgets('should handle return rental error', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();
        
        mockApiService.shouldThrowError = true;
        
        await tester.tap(find.text('Zurückgeben').first);
        await tester.pump();
        
        await tester.tap(find.text('Zurückgeben').last);
        await tester.pump();
        await tester.pump();
        
        expect(find.text('Fehler'), findsOneWidget);
        expect(find.textContaining('fehlgeschlagen'), findsOneWidget);
      });
    });

    group('Widget Builder Tests', () {
      late MyRentalsPageState state;

      setUp(() {
        state = MyRentalsPage(apiService: mockApiService).createState();
      });

      testWidgets('should build empty state widget', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: state.buildEmptyState('Test Message'),
          ),
        ));

        expect(find.text('Test Message'), findsOneWidget);
        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('should build active rental card', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: state.buildActiveRentalCard(testActiveRentals.first),
          ),
        ));

        expect(find.text('Test Ski Rossignol'), findsOneWidget);
        expect(find.text('Verlängern'), findsOneWidget);
        expect(find.text('Zurückgeben'), findsOneWidget);
        expect(find.byType(CupertinoButton), findsNWidgets(2));
      });

      testWidgets('should build past rental card', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: state.buildPastRentalCard(testPastRentals.first),
          ),
        ));

        expect(find.text('Test Ski Rossignol'), findsOneWidget);
        expect(find.text('Bewerten'), findsOneWidget);
        expect(find.textContaining('Ausgeliehen:'), findsOneWidget);
        expect(find.textContaining('Zurückgegeben:'), findsOneWidget);
      });
    });

    group('Utility Function Tests', () {
      late MyRentalsPageState state;

      setUp(() {
        state = MyRentalsPage(apiService: mockApiService).createState();
      });

      test('should format dates correctly', () {
        expect(state.formatDate(DateTime(2024, 1, 1)), equals('01.01.2024'));
        expect(state.formatDate(DateTime(2024, 12, 25)), equals('25.12.2024'));
        expect(state.formatDate(DateTime(2023, 6, 15)), equals('15.06.2023'));
        expect(state.formatDate(DateTime(2024, 2, 29)), equals('29.02.2024'));
      });

      test('should handle debug rentals without error', () {
        expect(() => state.debugRentals(), returnsNormally);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle null return date', (WidgetTester tester) async {
        final rentalWithoutReturn = Rental(
          id: 999,
          item: testItem1,
          user: testUser,
          rentalDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now().subtract(Duration(days: 5)),
          returnDate: null,
          status: 'RETURNED',
        );

        mockApiService.mockPastRentals = [rentalWithoutReturn];

        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();

        expect(find.text('Zurückgegeben: N/A'), findsOneWidget);
      });

      testWidgets('should handle very long item names', (WidgetTester tester) async {
        final longNameItem = Item(
          id: 999,
          name: 'This is a very very very very very very long item name that should not break the layout',
          available: true,
          location: 'PASING',
          gender: 'UNISEX',
          category: 'EQUIPMENT',
          subcategory: 'SKI',
          zustand: 'NEU',
        );

        final longNameRental = Rental(
          id: 999,
          item: longNameItem,
          user: testUser,
          rentalDate: DateTime.now().subtract(Duration(days: 5)),
          endDate: DateTime.now().add(Duration(days: 10)),
          status: 'ACTIVE',
        );

        mockApiService.mockActiveRentals = [longNameRental];

        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();

        expect(find.textContaining('This is a very very'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Refresh Functionality', () {
      testWidgets('should handle pull to refresh', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();

        final refreshIndicator = find.byType(RefreshIndicator);
        expect(refreshIndicator, findsOneWidget);

        await tester.drag(refreshIndicator, Offset(0, 300));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });

    group('Dialog Dismissal Tests', () {
      testWidgets('should dismiss dialogs with cancel buttons', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();
        
        // Test extend dialog cancel
        await tester.tap(find.text('Verlängern').first);
        await tester.pump();
        
        await tester.tap(find.text('Abbrechen'));
        await tester.pump();
        
        expect(find.text('Ausleihe verlängern'), findsNothing);
        
        // Test return dialog cancel
        await tester.tap(find.text('Zurückgeben').first);
        await tester.pump();
        
        await tester.tap(find.text('Abbrechen'));
        await tester.pump();
        
        expect(find.text('Item zurückgeben'), findsNothing);
      });
    });

    
  });
}