import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:kreisel_frontend/models/item_model.dart';
import 'package:kreisel_frontend/models/rental_model.dart';
import 'package:kreisel_frontend/models/user_model.dart';
import 'package:kreisel_frontend/pages/admin_dashboard.dart';
import 'package:kreisel_frontend/pages/login_page.dart';

class TestAdminService implements AdminServiceInterface {
  List<Item> _items = [];
  List<Rental> _rentals = [];
  List<User> _users = [];
  Exception? _getAllItemsError;
  Exception? _getAllRentalsError;
  Exception? _getAllUsersError;
  Exception? _createItemError;
  Exception? _updateItemError;
  Exception? _deleteItemError;
  Exception? _canCreateItemsError;
  Exception? _uploadImageError;
  bool _isAuthenticatedResult = true;
  bool _ensureAuthenticatedResult = true;
  bool _canCreateItemsResult = true;
  bool _logoutCalled = false;
  Item? _createdItem;
  Item? _updatedItem;
  int? _deletedItemId;
  String? _uploadedImageUrl;
  int _loadDelayMilliseconds = 10;
  Uint8List? _mockImageBytes;
  String? _mockImageName;

  // Setup-methods for tests
  void setItems(List<Item> items) => _items = items;
  void setRentals(List<Rental> rentals) => _rentals = rentals;
  void setUsers(List<User> users) => _users = users;
  void setGetAllItemsError(Exception? error) => _getAllItemsError = error;
  void setGetAllRentalsError(Exception? error) => _getAllRentalsError = error;
  void setGetAllUsersError(Exception? error) => _getAllUsersError = error;
  void setCreateItemError(Exception? error) => _createItemError = error;
  void setUpdateItemError(Exception? error) => _updateItemError = error;
  void setDeleteItemError(Exception? error) => _deleteItemError = error;
  void setCanCreateItemsError(Exception? error) => _canCreateItemsError = error;
  void setUploadImageError(Exception? error) => _uploadImageError = error;
  void setIsAuthenticatedResult(bool result) => _isAuthenticatedResult = result;
  void setEnsureAuthenticatedResult(bool result) =>
      _ensureAuthenticatedResult = result;
  void setCanCreateItemsResult(bool result) => _canCreateItemsResult = result;
  void setUploadedImageUrl(String? url) => _uploadedImageUrl = url;
  void setLoadDelayMilliseconds(int ms) => _loadDelayMilliseconds = ms;
  void setMockImageBytes(Uint8List bytes) => _mockImageBytes = bytes;
  void setMockImageName(String name) => _mockImageName = name;

  // Status methods for test assertions
  bool get logoutCalled => _logoutCalled;
  Item? get createdItem => _createdItem;
  Item? get updatedItem => _updatedItem;
  int? get deletedItemId => _deletedItemId;
  String? get uploadedImageUrl => _uploadedImageUrl;
  Uint8List? get mockImageBytes => _mockImageBytes;
  String? get mockImageName => _mockImageName;

  // Reset method for tests
  void reset() {
    _items = [];
    _rentals = [];
    _users = [];
    _getAllItemsError = null;
    _getAllRentalsError = null;
    _getAllUsersError = null;
    _createItemError = null;
    _updateItemError = null;
    _deleteItemError = null;
    _canCreateItemsError = null;
    _uploadImageError = null;
    _isAuthenticatedResult = true;
    _ensureAuthenticatedResult = true;
    _canCreateItemsResult = true;
    _logoutCalled = false;
    _createdItem = null;
    _updatedItem = null;
    _deletedItemId = null;
    _uploadedImageUrl = null;
    _loadDelayMilliseconds = 10;
    _mockImageBytes = null;
    _mockImageName = null;
  }

  // AdminServiceInterface implementations
  @override
  Future<List<Item>> getAllItems(String location) async {
    await Future.delayed(Duration(milliseconds: _loadDelayMilliseconds));
    if (_getAllItemsError != null) {
      throw _getAllItemsError!;
    }
    return _items.where((item) => item.location == location).toList();
  }

  @override
  Future<List<Rental>> getAllRentals() async {
    await Future.delayed(Duration(milliseconds: _loadDelayMilliseconds));
    if (_getAllRentalsError != null) {
      throw _getAllRentalsError!;
    }
    return List<Rental>.from(_rentals);
  }

  @override
  Future<List<User>> getAllUsers() async {
    await Future.delayed(Duration(milliseconds: _loadDelayMilliseconds));
    if (_getAllUsersError != null) {
      throw _getAllUsersError!;
    }
    return List<User>.from(_users);
  }

  @override
  Future<Item> createItem(Item item) async {
    await Future.delayed(Duration(milliseconds: _loadDelayMilliseconds));
    if (_createItemError != null) {
      throw _createItemError!;
    }
    _createdItem = Item(
      id: _items.length + 1,
      name: item.name,
      available: item.available,
      description: item.description,
      brand: item.brand,
      imageUrl: item.imageUrl,
      averageRating: item.averageRating ?? 0.0,
      reviewCount: item.reviewCount ?? 0,
      location: item.location,
      gender: item.gender,
      category: item.category,
      subcategory: item.subcategory,
      size: item.size,
      zustand: item.zustand,
    );
    _items.add(_createdItem!);
    return _createdItem!;
  }

  @override
  Future<Item> updateItem(int id, Item item) async {
    await Future.delayed(Duration(milliseconds: _loadDelayMilliseconds));
    if (_updateItemError != null) {
      throw _updateItemError!;
    }
    _updatedItem = Item(
      id: id,
      name: item.name,
      available: item.available,
      description: item.description,
      brand: item.brand,
      imageUrl: item.imageUrl,
      averageRating: item.averageRating ?? 0.0,
      reviewCount: item.reviewCount ?? 0,
      location: item.location,
      gender: item.gender,
      category: item.category,
      subcategory: item.subcategory,
      size: item.size,
      zustand: item.zustand,
    );
    final index = _items.indexWhere((i) => i.id == id);
    if (index != -1) {
      _items[index] = _updatedItem!;
    }
    return _updatedItem!;
  }

  @override
  Future<void> deleteItem(int id) async {
    await Future.delayed(Duration(milliseconds: _loadDelayMilliseconds));
    if (_deleteItemError != null) {
      throw _deleteItemError!;
    }
    _deletedItemId = id;
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<bool> isAdminAuthenticated() async {
    await Future.delayed(Duration(milliseconds: _loadDelayMilliseconds));
    return _isAuthenticatedResult;
  }

  @override
  Future<bool> ensureAuthenticated() async {
    await Future.delayed(Duration(milliseconds: _loadDelayMilliseconds));
    return _ensureAuthenticatedResult;
  }

  @override
  Future<bool> canCreateItems() async {
    await Future.delayed(Duration(milliseconds: _loadDelayMilliseconds));
    if (_canCreateItemsError != null) {
      throw _canCreateItemsError!;
    }
    return _canCreateItemsResult;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(Duration(milliseconds: _loadDelayMilliseconds));
    _logoutCalled = true;
  }

  @override
  Future<String?> uploadItemImageBytes(
    int itemId,
    Uint8List imageBytes,
    String filename,
  ) async {
    await Future.delayed(Duration(milliseconds: _loadDelayMilliseconds));
    if (_uploadImageError != null) {
      throw _uploadImageError!;
    }
    _mockImageBytes = imageBytes;
    _mockImageName = filename;
    return _uploadedImageUrl ?? 'https://example.com/image.jpg';
  }
}

void main() {
  late TestAdminService testAdminService;

  setUp(() {
    testAdminService = TestAdminService();
  });

  tearDown(() {
    testAdminService.reset();
  });

  group('AdminDashboard Widget Tests', () {
    testWidgets('AdminDashboard renders UI elements correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Admin Dashboard'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.text('Items'), findsOneWidget);
      expect(find.text('Rentals'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Location selector works correctly', (
      WidgetTester tester,
    ) async {
      testAdminService.setItems([
        Item(
          id: 1,
          name: 'Test Item Pasing',
          available: true,
          location: 'PASING',
          category: 'EQUIPMENT',
          subcategory: 'HELME',
          averageRating: 0.0,
          reviewCount: 0,
          gender: 'UNISEX',
          zustand: 'NEU',
        ),
        Item(
          id: 2,
          name: 'Test Item Karlstraße',
          available: true,
          location: 'KARLSTRASSE',
          category: 'EQUIPMENT',
          subcategory: 'SKI',
          averageRating: 0.0,
          reviewCount: 0,
          gender: 'UNISEX',
          zustand: 'NEU',
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test Item Pasing'), findsOneWidget);
      expect(find.text('Test Item Karlstraße'), findsNothing);

      await tester.tap(find.text('Karlstraße'));
      await tester.pumpAndSettle();

      expect(find.text('Test Item Pasing'), findsNothing);
      expect(find.text('Test Item Karlstraße'), findsOneWidget);
    });

    testWidgets('Tab navigation works correctly', (WidgetTester tester) async {
      testAdminService.setItems([
        Item(
          id: 1,
          name: 'Test Item',
          available: true,
          location: 'PASING',
          category: 'EQUIPMENT',
          subcategory: 'HELME',
          averageRating: 0.0,
          reviewCount: 0,
          gender: 'UNISEX',
          zustand: 'NEU',
        ),
      ]);

      testAdminService.setRentals([
        Rental(
          id: 1,
          item: Item(
            id: 1,
            name: 'Rented Item',
            available: false,
            category: 'EQUIPMENT',
            subcategory: 'HELME',
            averageRating: 0.0,
            reviewCount: 0,
            gender: 'UNISEX',
            zustand: 'NEU',
            location: 'PASING',
          ),
          user: User(
            userId: 1,
            email: 'test@hm.com',
            fullName: 'Test User',
            role: 'USER',
          ),
          rentalDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 7)),
          status: 'ACTIVE',
          extended: false,
        ),
      ]);

      testAdminService.setUsers([
        User(
          userId: 1,
          email: 'test@test.com',
          fullName: 'Test User',
          role: 'USER',
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Item'), findsOneWidget);

      await tester.tap(find.text('Rentals'));
      await tester.pumpAndSettle();

      expect(find.text('Rented Item'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);

      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@test.com'), findsOneWidget);
    });

    testWidgets('Empty states are displayed correctly', (
      WidgetTester tester,
    ) async {
      testAdminService.setItems([]);
      testAdminService.setRentals([]);
      testAdminService.setUsers([]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Keine Items für PASING gefunden'), findsOneWidget);

      await tester.tap(find.text('Rentals'));
      await tester.pumpAndSettle();
      expect(find.text('Keine Rentals gefunden'), findsOneWidget);

      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();
      expect(find.text('Keine Users gefunden'), findsOneWidget);
    });

    testWidgets('Item details are displayed correctly', (
      WidgetTester tester,
    ) async {
      testAdminService.setItems([
        Item(
          id: 1,
          name: 'Test Skihelm',
          available: true,
          location: 'PASING',
          category: 'EQUIPMENT',
          subcategory: 'HELME',
          brand: 'TestBrand',
          size: 'M',
          imageUrl: 'https://example.com/image.jpg',
          averageRating: 4.5,
          reviewCount: 10,
          gender: 'UNISEX',
          zustand: 'NEU',
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Skihelm'), findsOneWidget);
      expect(find.text('Standort: PASING'), findsOneWidget);
      expect(find.text('Status: Verfügbar'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('Delete item confirmation works', (WidgetTester tester) async {
      testAdminService.setItems([
        Item(
          id: 99,
          name: 'Item to Delete',
          available: true,
          location: 'PASING',
          category: 'EQUIPMENT',
          subcategory: 'HELME',
          gender: 'UNISEX',
          zustand: 'NEU',
          averageRating: 0.0,
          reviewCount: 0,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('Item löschen'), findsOneWidget);
      expect(
        find.text('Möchten Sie dieses Item wirklich löschen?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(find.text('Item to Delete'), findsOneWidget);
      expect(testAdminService.deletedItemId, isNull);

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();

      expect(testAdminService.deletedItemId, 99);
    });

    testWidgets('Authentication check redirects to login', (
      WidgetTester tester,
    ) async {
      testAdminService.setIsAuthenticatedResult(false);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboard(adminService: testAdminService),
          routes: {'/login': (context) => const LoginPage()},
        ),
      );
      await tester.pumpAndSettle();

      expect(testAdminService.logoutCalled, true);
    });

    testWidgets('Error handling displays error dialogs', (
      WidgetTester tester,
    ) async {
      testAdminService.setGetAllItemsError(Exception('Network error'));

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fehler'), findsOneWidget);
      expect(find.text('Exception: Network error'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    });

    testWidgets('User details dialog shows correct information', (
      WidgetTester tester,
    ) async {
      testAdminService.setUsers([
        User(
          userId: 123,
          email: 'test@example.com',
          fullName: 'Example User',
          role: 'USER',
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(find.text('User Details'), findsOneWidget);
      expect(find.text('Name: Example User'), findsOneWidget);
      expect(find.text('Email: test@example.com'), findsOneWidget);
      expect(find.text('ID: 123'), findsOneWidget);

      await tester.tap(find.text('Schließen'));
      await tester.pumpAndSettle();
    });

    testWidgets('Search functionality works for Users tab', (
      WidgetTester tester,
    ) async {
      testAdminService.setUsers([
        User(
          userId: 1,
          email: 'john@example.com',
          fullName: 'John Doe',
          role: 'USER',
        ),
        User(
          userId: 2,
          email: 'jane@example.com',
          fullName: 'Jane Smith',
          role: 'USER',
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);

      await tester.enterText(find.byType(CupertinoSearchTextField), 'jane');
      await tester.pump();
      await tester.pump(Duration(milliseconds: 600));

      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('John Doe'), findsNothing);
    });
    // Add these at the end of your test group
    testWidgets('Item copyWith extension functions correctly', (
      WidgetTester tester,
    ) async {
      final originalItem = Item(
        id: 123,
        name: 'Original Item',
        description: 'Original description',
        available: true,
        brand: 'Original Brand',
        size: 'M',
        location: 'PASING',
        gender: 'UNISEX',
        category: 'EQUIPMENT',
        subcategory: 'HELME',
        zustand: 'NEU',
        imageUrl: 'https://original.jpg',
        averageRating: 4.5,
        reviewCount: 10,
      );

      // Test partial updates with copyWith
      final updatedItem = originalItem.copyWith(
        name: 'Updated Name',
        brand: 'Updated Brand',
        available: false,
      );

      // Verify changed properties
      expect(updatedItem.id, 123); // Unchanged
      expect(updatedItem.name, 'Updated Name'); // Changed
      expect(updatedItem.brand, 'Updated Brand'); // Changed
      expect(updatedItem.available, false); // Changed

      // Verify unchanged properties
      expect(updatedItem.description, 'Original description');
      expect(updatedItem.size, 'M');
      expect(updatedItem.location, 'PASING');
      expect(updatedItem.imageUrl, 'https://original.jpg');
    });

   

    testWidgets('Permissions loading failure shows snackbar', (
      WidgetTester tester,
    ) async {
      // Set up service to throw on canCreateItems
      testAdminService.setCanCreateItemsError(Exception('Permission error'));

      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey:
              GlobalKey<ScaffoldMessengerState>(), // Required for SnackBar
          home: AdminDashboard(adminService: testAdminService),
        ),
      );

      await tester.pumpAndSettle();

      // Verify SnackBar is shown
      expect(find.text('Failed to load permissions'), findsOneWidget);
    });

    
    

    testWidgets('Transition from one error state to another works correctly', (
      WidgetTester tester,
    ) async {
      // First set an error on getAllItems
      testAdminService.setGetAllItemsError(Exception('First error'));

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      // First error dialog should be visible
      expect(find.text('Exception: First error'), findsOneWidget);

      // Dismiss first dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Now change to a different tab with a different error
      testAdminService.setGetAllRentalsError(Exception('Second error'));

      await tester.tap(find.text('Rentals'));
      await tester.pumpAndSettle();

      // Should show the second error
      expect(find.text('Exception: Second error'), findsOneWidget);
    });

    

    

    

    testWidgets('Exception during item update shows error dialog', (
      WidgetTester tester,
    ) async {
      testAdminService.setItems([
        Item(
          id: 1,
          name: 'Test Item',
          available: true,
          location: 'PASING',
          category: 'EQUIPMENT',
          subcategory: 'HELME',
          gender: 'UNISEX',
          zustand: 'NEU',
          averageRating: 0.0,
          reviewCount: 0,
        ),
      ]);
      testAdminService.setUpdateItemError(Exception('Failed to update item'));

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Exception: Failed to update item'), findsOneWidget);
    });

    testWidgets('Admin service returns empty lists gracefully', (
      WidgetTester tester,
    ) async {
      // Explicitly set empty lists (different from null)
      testAdminService.setItems([]);
      testAdminService.setRentals([]);
      testAdminService.setUsers([]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      // First tab should show empty state
      expect(find.text('Keine Items für PASING gefunden'), findsOneWidget);

      // Test rentals tab empty state
      await tester.tap(find.text('Rentals'));
      await tester.pumpAndSettle();
      expect(find.text('Keine Rentals gefunden'), findsOneWidget);

      // Test users tab empty state
      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();
      expect(find.text('Keine Users gefunden'), findsOneWidget);
    });
    testWidgets('All locations work correctly', (WidgetTester tester) async {
      testAdminService.setItems([
        Item(
          id: 1,
          name: 'Pasing Item',
          available: true,
          location: 'PASING',
          category: 'EQUIPMENT',
          subcategory: 'HELME',
          averageRating: 0.0,
          reviewCount: 0,
          gender: 'UNISEX',
          zustand: 'NEU',
        ),
        Item(
          id: 2,
          name: 'Karlstraße Item',
          available: true,
          location: 'KARLSTRASSE',
          category: 'EQUIPMENT',
          subcategory: 'SKI',
          averageRating: 0.0,
          reviewCount: 0,
          gender: 'UNISEX',
          zustand: 'NEU',
        ),
        Item(
          id: 3,
          name: 'Lothstraße Item',
          available: true,
          location: 'LOTHSTRASSE',
          category: 'EQUIPMENT',
          subcategory: 'BRILLEN',
          averageRating: 0.0,
          reviewCount: 0,
          gender: 'UNISEX',
          zustand: 'NEU',
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      // Test Pasing (default)
      expect(find.text('Pasing Item'), findsOneWidget);
      expect(find.text('Karlstraße Item'), findsNothing);
      expect(find.text('Lothstraße Item'), findsNothing);

      // Test Karlstraße
      await tester.tap(find.text('Karlstraße'));
      await tester.pumpAndSettle();
      expect(find.text('Pasing Item'), findsNothing);
      expect(find.text('Karlstraße Item'), findsOneWidget);
      expect(find.text('Lothstraße Item'), findsNothing);

      // Test Lothstraße
      await tester.tap(find.text('Lothstraße'));
      await tester.pumpAndSettle();
      expect(find.text('Pasing Item'), findsNothing);
      expect(find.text('Karlstraße Item'), findsNothing);
      expect(find.text('Lothstraße Item'), findsOneWidget);
    });

    testWidgets('Rentals search functionality works', (
      WidgetTester tester,
    ) async {
      testAdminService.setRentals([
        Rental(
          id: 1,
          item: Item(
            id: 1,
            name: 'Ski Item',
            available: false,
            category: 'EQUIPMENT',
            subcategory: 'SKI',
            averageRating: 0.0,
            reviewCount: 0,
            gender: 'UNISEX',
            zustand: 'NEU',
            location: 'PASING',
          ),
          user: User(
            userId: 1,
            email: 'john@example.com',
            fullName: 'John Doe',
            role: 'USER',
          ),
          rentalDate: DateTime.now(),
          endDate: DateTime.now().add(Duration(days: 7)),
          status: 'ACTIVE',
          extended: false,
        ),
        Rental(
          id: 2,
          item: Item(
            id: 2,
            name: 'Helmet Item',
            available: false,
            category: 'EQUIPMENT',
            subcategory: 'HELME',
            averageRating: 0.0,
            reviewCount: 0,
            gender: 'UNISEX',
            zustand: 'NEU',
            location: 'PASING',
          ),
          user: User(
            userId: 2,
            email: 'jane@example.com',
            fullName: 'Jane Smith',
            role: 'USER',
          ),
          rentalDate: DateTime.now(),
          endDate: DateTime.now().add(Duration(days: 5)),
          status: 'ACTIVE',
          extended: false,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rentals'));
      await tester.pumpAndSettle();

      expect(find.text('Ski Item'), findsOneWidget);
      expect(find.text('Helmet Item'), findsOneWidget);

      await tester.enterText(find.byType(CupertinoSearchTextField), 'john');
      await tester.pump();
      await tester.pump(Duration(milliseconds: 600));

      expect(find.text('Ski Item'), findsOneWidget);
      expect(find.text('Helmet Item'), findsNothing);
    });

    testWidgets('Create item dialog cancellation works', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Neues Item erstellen'), findsOneWidget);

      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(find.text('Neues Item erstellen'), findsNothing);
      expect(testAdminService.createdItem, isNull);
    });

    testWidgets('Create item with error handling', (WidgetTester tester) async {
      testAdminService.setCreateItemError(Exception('Creation failed'));

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, '').first,
        'Test Item',
      );
      await tester.tap(find.text('Erstellen'));
      await tester.pumpAndSettle();

      expect(find.text('Exception: Creation failed'), findsOneWidget);
    });

    testWidgets('Update item with error handling', (WidgetTester tester) async {
      testAdminService.setItems([
        Item(
          id: 1,
          name: 'Test Item',
          available: true,
          location: 'PASING',
          category: 'EQUIPMENT',
          subcategory: 'HELME',
          gender: 'UNISEX',
          zustand: 'NEU',
          averageRating: 0.0,
          reviewCount: 0,
        ),
      ]);
      testAdminService.setUpdateItemError(Exception('Update failed'));

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Exception: Update failed'), findsOneWidget);
    });

    testWidgets('Delete item with error handling', (WidgetTester tester) async {
      testAdminService.setItems([
        Item(
          id: 1,
          name: 'Test Item',
          available: true,
          location: 'PASING',
          category: 'EQUIPMENT',
          subcategory: 'HELME',
          gender: 'UNISEX',
          zustand: 'NEU',
          averageRating: 0.0,
          reviewCount: 0,
        ),
      ]);
      testAdminService.setDeleteItemError(Exception('Delete failed'));

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();

      expect(find.text('Exception: Delete failed'), findsOneWidget);
    });

    testWidgets('Pull to refresh works on Items tab', (
      WidgetTester tester,
    ) async {
      testAdminService.setItems([
        Item(
          id: 1,
          name: 'Test Item',
          available: true,
          location: 'PASING',
          category: 'EQUIPMENT',
          subcategory: 'HELME',
          gender: 'UNISEX',
          zustand: 'NEU',
          averageRating: 0.0,
          reviewCount: 0,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Item'), findsOneWidget);

      // Simulate pull to refresh
      await tester.fling(find.text('Test Item'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Test Item'), findsOneWidget);
    });

    testWidgets('Pull to refresh works on Rentals tab', (
      WidgetTester tester,
    ) async {
      testAdminService.setRentals([
        Rental(
          id: 1,
          item: Item(
            id: 1,
            name: 'Rented Item',
            available: false,
            category: 'EQUIPMENT',
            subcategory: 'HELME',
            averageRating: 0.0,
            reviewCount: 0,
            gender: 'UNISEX',
            zustand: 'NEU',
            location: 'PASING',
          ),
          user: User(
            userId: 1,
            email: 'test@example.com',
            fullName: 'Test User',
            role: 'USER',
          ),
          rentalDate: DateTime.now(),
          endDate: DateTime.now().add(Duration(days: 7)),
          status: 'ACTIVE',
          extended: false,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rentals'));
      await tester.pumpAndSettle();

      expect(find.text('Rented Item'), findsOneWidget);

      await tester.fling(find.text('Rented Item'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Rented Item'), findsOneWidget);
    });

    testWidgets('Pull to refresh works on Users tab', (
      WidgetTester tester,
    ) async {
      testAdminService.setUsers([
        User(
          userId: 1,
          email: 'test@example.com',
          fullName: 'Test User',
          role: 'USER',
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);

      await tester.fling(find.text('Test User'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('Logout button works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboard(adminService: testAdminService),
          routes: {'/login': (context) => const LoginPage()},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(testAdminService.logoutCalled, true);
    });

    testWidgets('Error in rentals tab shows error dialog', (
      WidgetTester tester,
    ) async {
      testAdminService.setGetAllRentalsError(Exception('Rentals error'));

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rentals'));
      await tester.pumpAndSettle();

      expect(find.text('Fehler'), findsOneWidget);
      expect(find.text('Exception: Rentals error'), findsOneWidget);
    });

    testWidgets('Error in users tab shows error dialog', (
      WidgetTester tester,
    ) async {
      testAdminService.setGetAllUsersError(Exception('Users error'));

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      expect(find.text('Fehler'), findsOneWidget);
      expect(find.text('Exception: Users error'), findsOneWidget);
    });

    testWidgets('Search field only appears on Rentals and Users tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      // Items tab - no search field
      expect(find.byType(CupertinoSearchTextField), findsNothing);

      // Rentals tab - search field present
      await tester.tap(find.text('Rentals'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoSearchTextField), findsOneWidget);

      // Users tab - search field present
      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoSearchTextField), findsOneWidget);
    });

    testWidgets('Location selector only appears on Items tab', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      // Items tab - location selector present
      expect(find.byType(CupertinoSegmentedControl<String>), findsOneWidget);

      // Rentals tab - no location selector
      await tester.tap(find.text('Rentals'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoSegmentedControl<String>), findsNothing);

      // Users tab - no location selector
      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoSegmentedControl<String>), findsNothing);
    });

    testWidgets('Search clears when switching tabs', (
      WidgetTester tester,
    ) async {
      testAdminService.setRentals([
        Rental(
          id: 1,
          item: Item(
            id: 1,
            name: 'Test Item',
            available: false,
            category: 'EQUIPMENT',
            subcategory: 'HELME',
            averageRating: 0.0,
            reviewCount: 0,
            gender: 'UNISEX',
            zustand: 'NEU',
            location: 'PASING',
          ),
          user: User(
            userId: 1,
            email: 'test@example.com',
            fullName: 'Test User',
            role: 'USER',
          ),
          rentalDate: DateTime.now(),
          endDate: DateTime.now().add(Duration(days: 7)),
          status: 'ACTIVE',
          extended: false,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rentals'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(CupertinoSearchTextField),
        'test search',
      );
      expect(
        find.widgetWithText(CupertinoSearchTextField, 'test search'),
        findsOneWidget,
      );

      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(CupertinoSearchTextField, 'test search'),
        findsNothing,
      );
    });

    testWidgets('Authentication error during delete triggers logout', (
      WidgetTester tester,
    ) async {
      testAdminService.setItems([
        Item(
          id: 1,
          name: 'Test Item',
          available: true,
          location: 'PASING',
          category: 'EQUIPMENT',
          subcategory: 'HELME',
          gender: 'UNISEX',
          zustand: 'NEU',
          averageRating: 0.0,
          reviewCount: 0,
        ),
      ]);
      testAdminService.setDeleteItemError(Exception('Token expired'));

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboard(adminService: testAdminService),
          routes: {'/login': (context) => const LoginPage()},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();

      expect(testAdminService.logoutCalled, true);
    });

    testWidgets('Authentication error during search triggers logout', (
      WidgetTester tester,
    ) async {
      testAdminService.setGetAllUsersError(Exception('401 Unauthorized'));

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboard(adminService: testAdminService),
          routes: {'/login': (context) => const LoginPage()},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Users'));
      await tester.pump();
      await tester.pump(Duration(milliseconds: 100));

      expect(testAdminService.logoutCalled, true);
    });

   
  });
}

bool _logoutCalled = false;
Item? _createdItem;
Item? _updatedItem;
int? _deletedItemId;
String? _uploadedImageUrl;

// Setup-methods for tests
void setItems(List<Item> items) => () {
  late TestAdminService testAdminService;

  setUp(() {
    testAdminService = TestAdminService();
  });

  tearDown(() {
    testAdminService.reset();
  });

  group('AdminDashboard Widget Tests', () {
    testWidgets('AdminDashboard renders UI elements correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );

      // Wait for async operations to complete
      await tester.pumpAndSettle();

      // Check AppBar
      expect(find.text('Admin Dashboard'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);

      // Check navigation buttons
      expect(find.text('Items'), findsOneWidget);
      expect(find.text('Rentals'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);

      // Check FloatingActionButton for Items tab
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Location selector works correctly', (
      WidgetTester tester,
    ) async {
      testAdminService.setItems([
        Item(
          id: 1,
          name: 'Test Item Pasing',
          available: true,
          location: 'PASING',
          category: 'EQUIPMENT',
          subcategory: 'HELME',
          averageRating: 0.0,
          reviewCount: 0,
          gender: 'UNISEX',
          zustand: 'NEU',
        ),
        Item(
          id: 2,
          name: 'Test Item Karlstraße',
          available: true,
          location: 'KARLSTRASSE',
          category: 'EQUIPMENT',
          subcategory: 'SKI',
          averageRating: 0.0,
          reviewCount: 0,
          gender: 'UNISEX',
          zustand: 'NEU',
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );

      await tester.pumpAndSettle();

      // Initially should show Pasing items
      expect(find.text('Test Item Pasing'), findsOneWidget);
      expect(find.text('Test Item Karlstraße'), findsNothing);

      // Change to Karlstraße
      await tester.tap(find.text('Karlstraße'));
      await tester.pumpAndSettle();

      // Should now show Karlstraße items
      expect(find.text('Test Item Pasing'), findsNothing);
      expect(find.text('Test Item Karlstraße'), findsOneWidget);
    });

    testWidgets('Tab navigation works correctly', (WidgetTester tester) async {
      // Setup data for different tabs
      testAdminService.setItems([
        Item(
          id: 1,
          name: 'Test Item',
          available: true,
          location: 'PASING',
          category: 'EQUIPMENT',
          subcategory: 'HELME',
          averageRating: 0.0,
          reviewCount: 0,
          gender: 'UNISEX',
          zustand: 'NEU',
        ),
      ]);

      testAdminService.setRentals([
        Rental(
          id: 1,
          item: Item(
            id: 1,
            name: 'Rented Item',
            available: false,
            category: 'EQUIPMENT',
            subcategory: 'HELME',
            averageRating: 0.0,
            reviewCount: 0,
            gender: 'UNISEX',
            zustand: 'NEU',
            location: 'PASING',
          ),
          user: User(
            userId: 1,
            email: 'test@hm.com',
            fullName: 'Test User',
            role: 'USER',
          ),
          rentalDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 7)),
          status: 'ACTIVE',
          extended: false,
        ),
      ]);

      testAdminService.setUsers([
        User(
          userId: 1,
          email: 'test@test.com',
          fullName: 'Test User',
          role: 'USER',
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      // Items tab should be visible by default
      expect(find.text('Test Item'), findsOneWidget);

      // Switch to Rentals tab
      await tester.tap(find.text('Rentals'));
      await tester.pumpAndSettle();

      expect(find.text('Rented Item'), findsOneWidget);
      expect(find.text('Status: ACTIVE'), findsOneWidget);
      expect(
        find.byType(FloatingActionButton),
        findsNothing,
      ); // FAB only on Items tab

      // Switch to Users tab
      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@test.com'), findsOneWidget);
    });

    testWidgets('Empty states are displayed correctly', (
      WidgetTester tester,
    ) async {
      testAdminService.setItems([]);
      testAdminService.setRentals([]);
      testAdminService.setUsers([]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      // Items tab - empty state
      expect(find.text('Keine Items für PASING gefunden'), findsOneWidget);

      // Rentals tab - empty state
      await tester.tap(find.text('Rentals'));
      await tester.pumpAndSettle();
      expect(find.text('Keine Rentals gefunden'), findsOneWidget);

      // Users tab - empty state
      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();
      expect(find.text('Keine Users gefunden'), findsOneWidget);
    });

    testWidgets('Item details are displayed correctly', (
      WidgetTester tester,
    ) async {
      testAdminService.setItems([
        Item(
          id: 1,
          name: 'Test Skihelm',
          available: true,
          location: 'PASING',
          category: 'EQUIPMENT',
          subcategory: 'HELME',
          brand: 'TestBrand',
          size: 'M',
          imageUrl: 'https://example.com/image.jpg',
          averageRating: 4.5,
          reviewCount: 10,
          gender: 'UNISEX',
          zustand: 'NEU',
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Skihelm'), findsOneWidget);
      expect(find.text('Standort: PASING'), findsOneWidget);
      expect(find.text('Status: Verfügbar'), findsOneWidget);
      expect(find.text('Kategorie: EQUIPMENT - HELME'), findsOneWidget);
      expect(find.text('Marke: TestBrand'), findsOneWidget);
      expect(find.text('Größe: M'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('Delete item confirmation works', (WidgetTester tester) async {
      testAdminService.setItems([
        Item(
          id: 99,
          name: 'Item to Delete',
          available: true,
          location: 'PASING',
          category: 'EQUIPMENT',
          subcategory: 'HELME',
          gender: 'UNISEX',
          zustand: 'NEU',
          averageRating: 0.0,
          reviewCount: 0,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Check if confirmation dialog shows up
      expect(find.text('Item löschen'), findsOneWidget);
      expect(
        find.text('Möchten Sie dieses Item wirklich löschen?'),
        findsOneWidget,
      );

      // Tap "Abbrechen" (cancel)
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      // Item should still be there
      expect(find.text('Item to Delete'), findsOneWidget);
      expect(testAdminService.deletedItemId, isNull);

      // Tap delete again and confirm
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();

      // Item should be deleted
      expect(testAdminService.deletedItemId, 99);
    });

    testWidgets('Authentication check redirects to login', (
      WidgetTester tester,
    ) async {
      // Mock failed authentication
      testAdminService.setIsAuthenticatedResult(false);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboard(adminService: testAdminService),
          routes: {
            '/': (context) => AdminDashboard(),
            '/login': (context) => const LoginPage(),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Should have called logout
      expect(testAdminService.logoutCalled, true);

      // Should attempt navigation to login page
      // Note: In this test environment, the navigation may not fully complete
      // without a more complex MaterialApp setup with real routes
    });

    testWidgets('Error handling displays error dialogs', (
      WidgetTester tester,
    ) async {
      testAdminService.setGetAllItemsError(Exception('Network error'));

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      // Error dialog should be shown
      expect(find.text('Fehler'), findsOneWidget);
      expect(find.text('Exception: Network error'), findsOneWidget);

      // Dismiss the dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    });

    testWidgets('User details dialog shows correct information', (
      WidgetTester tester,
    ) async {
      testAdminService.setUsers([
        User(
          userId: 123,
          email: 'test@example.com',
          fullName: 'Example User',
          role: 'USER',
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      // Navigate to Users tab
      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      // Tap info button
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      // Check user details dialog
      expect(find.text('User Details'), findsOneWidget);
      expect(find.text('Name: Example User'), findsOneWidget);
      expect(find.text('Email: test@example.com'), findsOneWidget);
      expect(find.text('ID: 123'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Schließen'));
      await tester.pumpAndSettle();
    });

    testWidgets('Search functionality works for Users tab', (
      WidgetTester tester,
    ) async {
      testAdminService.setUsers([
        User(
          userId: 1,
          email: 'john@example.com',
          fullName: 'John Doe',
          role: 'USER',
        ),
        User(
          userId: 2,
          email: 'jane@example.com',
          fullName: 'Jane Smith',
          role: 'USER',
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: AdminDashboard(adminService: testAdminService)),
      );
      await tester.pumpAndSettle();

      // Navigate to Users tab
      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      // Both users should be visible
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);

      // Enter search term
      await tester.enterText(find.byType(CupertinoSearchTextField), 'jane');
      await tester.pump(Duration(milliseconds: 600)); // Wait for debounce

      // Only matching user should remain visible
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('John Doe'), findsNothing);
    });
  });
};
