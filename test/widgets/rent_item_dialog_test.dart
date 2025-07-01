//import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreisel_frontend/models/item_model.dart';
import 'package:kreisel_frontend/services/api_service.dart';
import 'package:kreisel_frontend/widgets/rent_item_dialog.dart'; // Adjust import path as needed
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kreisel_frontend/models/user_model.dart';

// Mock implementations
class MockHttpClient implements HttpClientInterface {
  final Map<String, http.Response> _responseMap = {};
  final List<Map<String, dynamic>> _requests = [];

  void setResponse(String endpoint, http.Response response) {
    _responseMap[endpoint] = response;
  }

  List<Map<String, dynamic>> get requests => _requests;

  void reset() {
    _responseMap.clear();
    _requests.clear();
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    _requests.add({'method': 'GET', 'url': url.toString(), 'headers': headers});

    final endpoint = _getEndpoint(url);
    if (_responseMap.containsKey(endpoint)) {
      return _responseMap[endpoint]!;
    }

    return http.Response('{"message": "Not found"}', 404);
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    _requests.add({
      'method': 'POST',
      'url': url.toString(),
      'headers': headers,
      'body': body,
    });

    final endpoint = _getEndpoint(url);
    if (_responseMap.containsKey(endpoint)) {
      return _responseMap[endpoint]!;
    }

    return http.Response('{"message": "Not found"}', 404);
  }

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    _requests.add({
      'method': 'PUT',
      'url': url.toString(),
      'headers': headers,
      'body': body,
    });

    final endpoint = _getEndpoint(url);
    if (_responseMap.containsKey(endpoint)) {
      return _responseMap[endpoint]!;
    }

    return http.Response('{"message": "Not found"}', 404);
  }

  @override
  Future<http.Response> delete(Uri url, {Map<String, String>? headers}) async {
    _requests.add({
      'method': 'DELETE',
      'url': url.toString(),
      'headers': headers,
    });

    final endpoint = _getEndpoint(url);
    if (_responseMap.containsKey(endpoint)) {
      return _responseMap[endpoint]!;
    }

    return http.Response('{"message": "Not found"}', 404);
  }

  String _getEndpoint(Uri url) {
    final path = url.path;
    if (path.contains('/rentals/rent')) {
      return 'rentItem';
    } else if (path.contains('/users/me')) {
      return 'getCurrentUser';
    }
    return path;
  }
}

class MockTokenStorage implements TokenStorageInterface {
  String? _token;
  String? _cookie;

  @override
  Future<String?> getCookie() async {
    return _cookie;
  }

  @override
  Future<String?> getToken() async {
    return _token;
  }

  @override
  Future<void> removeTokens() async {
    _token = null;
    _cookie = null;
  }

  @override
  Future<void> saveCookie(String cookie) async {
    _cookie = cookie;
  }

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  void setToken(String? token) {
    _token = token;
  }
}

void main() {
  late MockHttpClient mockHttpClient;
  late MockTokenStorage mockTokenStorage;
  const String testBaseUrl = 'http://test-api.example.com/api';

  // Test data
  final testItem = Item(
    id: 123,
    name: 'Test Skis',
    brand: 'Alpine Pro',
    size: 'M',
    available: true,
    location: 'PASING',
    gender: 'UNISEX',
    category: 'EQUIPMENT',
    subcategory: 'SKI',
    zustand: 'NEU',
  );

  // Function to create the test widget
  Widget createTestWidget({
    required Item item,
    required VoidCallback onRented,
  }) {
    return MaterialApp(
      home: Material(
        child: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showCupertinoDialog(
                  context: context,
                  builder:
                      (context) =>
                          RentItemDialog(item: item, onRented: onRented),
                );
              },
              child: Text('Open Dialog'),
            );
          },
        ),
      ),
    );
  }

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockTokenStorage = MockTokenStorage();

    // Set up mock token
    mockTokenStorage.setToken('test_token');

    // Configure ApiService to use mocks
    ApiService.configure(
      httpClient: mockHttpClient,
      tokenStorage: mockTokenStorage,
      baseUrl: testBaseUrl,
    );

    // Mock user data
    ApiService.currentUser = User(
      userId: 1,
      fullName: 'Test User',
      email: 'test@hm.edu',
      role: 'USER',
    );

    // Set up SharedPreferences mock
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    // Reset mocks
    mockHttpClient.reset();

    // Reset ApiService to default
    ApiService.resetToDefault();
  });

  group('RentItemDialog UI Tests', () {
    testWidgets('displays item information correctly', (
      WidgetTester tester,
    ) async {
      // ignore: unused_local_variable
      bool rentCallbackCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          item: testItem,
          onRented: () => rentCallbackCalled = true,
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Check if dialog title contains the item name
      expect(find.text('Test Skis ausleihen'), findsOneWidget);

      // Check if item details are displayed
      expect(find.text('Marke: Alpine Pro'), findsOneWidget);
      expect(find.text('Größe: M'), findsOneWidget);

      // Check for duration selection options
      expect(find.text('Ausleihdauer wählen:'), findsOneWidget);
      expect(find.text('1 Mnt.'), findsOneWidget);
      expect(find.text('2 Mnte.'), findsOneWidget);
      expect(find.text('3 Mnte.'), findsOneWidget);

      // Check for buttons
      expect(find.text('Abbrechen'), findsOneWidget);
      expect(find.text('Jetzt ausleihen'), findsOneWidget);

      // Check for return date
      expect(find.textContaining('Rückgabedatum:'), findsOneWidget);
    });

    testWidgets('selecting different durations updates return date', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(item: testItem, onRented: () {}),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Initial date (1 month)
      final initialDateText =
          (tester.widget(find.textContaining('Rückgabedatum:')) as Text).data;

      // Select 2 months
      await tester.tap(find.text('2 Mnte.'));
      await tester.pumpAndSettle();

      // Get updated date text
      final updatedDateText =
          (tester.widget(find.textContaining('Rückgabedatum:')) as Text).data;

      // Dates should be different
      expect(initialDateText != updatedDateText, true);

      // Select 3 months
      await tester.tap(find.text('3 Mnte.'));
      await tester.pumpAndSettle();

      // Get new updated date text
      final finalDateText =
          (tester.widget(find.textContaining('Rückgabedatum:')) as Text).data;

      // All dates should be different
      expect(initialDateText != finalDateText, true);
      expect(updatedDateText != finalDateText, true);
    });
  });

  group('Rent Item Functionality Tests', () {
    

    

    testWidgets('unauthorized rental shows login error', (
      WidgetTester tester,
    ) async {
      // ignore: unused_local_variable
      bool rentCallbackCalled = false;

      // Set up mock response for unauthorized rental
      mockHttpClient.setResponse(
        'rentItem',
        http.Response('{"message": "Unauthorized"}', 401),
      );

      await tester.pumpWidget(
        createTestWidget(
          item: testItem,
          onRented: () => rentCallbackCalled = true,
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap the rent button
      await tester.tap(find.text('Jetzt ausleihen'));
      await tester.pump(); // Start loading state
      await tester.pumpAndSettle(); // Wait for operation to complete

      // Check for error dialog with login message
      expect(find.text('Fehler beim Ausleihen'), findsOneWidget);
      expect(find.textContaining('Session abgelaufen'), findsOneWidget);

      // Check that token was cleared
      expect(await mockTokenStorage.getToken(), isNull);
    });

    testWidgets('cancel button closes the dialog without renting', (
      WidgetTester tester,
    ) async {
      bool rentCallbackCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          item: testItem,
          onRented: () => rentCallbackCalled = true,
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap the cancel button
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Test Skis ausleihen'), findsNothing);

      // API should not have been called
      expect(mockHttpClient.requests.isEmpty, true);
      expect(rentCallbackCalled, false);
    });

    testWidgets('handles item with missing optional fields', (
      WidgetTester tester,
    ) async {
      final itemWithoutBrandSize = Item(
        id: 456,
        name: 'Basic Item',
        available: true,
        location: 'PASING',
        gender: 'UNISEX',
        category: 'EQUIPMENT',
        subcategory: 'HELME',
        zustand: 'NEU',
      );

      await tester.pumpWidget(
        createTestWidget(item: itemWithoutBrandSize, onRented: () {}),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Check that dialog still opens with required fields
      expect(find.text('Basic Item ausleihen'), findsOneWidget);

      // Optional fields should not appear
      expect(find.text('Marke:'), findsNothing);
      expect(find.text('Größe:'), findsNothing);
    });

    

    testWidgets('handles forbidden status with correct error message', (
      WidgetTester tester,
    ) async {
      // Set up mock response for forbidden status
      mockHttpClient.setResponse(
        'rentItem',
        http.Response('{"message": "Access denied"}', 403),
      );

      await tester.pumpWidget(
        createTestWidget(item: testItem, onRented: () {}),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap the rent button
      await tester.tap(find.text('Jetzt ausleihen'));
      await tester.pump(); // Start loading state
      await tester.pumpAndSettle(); // Wait for operation to complete

      // Check for error dialog with permission message
      expect(find.text('Fehler beim Ausleihen'), findsOneWidget);
      expect(find.textContaining('Keine Berechtigung'), findsOneWidget);

      // Check that token was cleared due to 403 status
      expect(await mockTokenStorage.getToken(), isNull);
    });
  });
}
