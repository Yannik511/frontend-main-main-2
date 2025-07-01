import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kreisel_frontend/models/item_model.dart';
import 'package:kreisel_frontend/models/rental_model.dart';
import 'package:kreisel_frontend/models/user_model.dart';
import 'package:kreisel_frontend/services/admin_service.dart';

// Mock model implementations for testing
class MockRental extends Rental {
  MockRental({
    required super.id,
    required int userId,
    required super.item,
    required super.user,
    required String super.status,
    String? startDate,
    String? endDate,
  }) : super(
         rentalDate: DateTime.parse(startDate ?? "2023-01-01T00:00:00Z"),
         endDate: DateTime.parse(endDate ?? "2023-01-02T00:00:00Z"),
       );

  static MockRental fromJson(Map<String, dynamic> json) {
    final item = Item(
      id: json['item']['id'] ?? 0,
      name: json['item']['name'] ?? 'Unknown',
      available: json['item']['available'] ?? true,
      location: 'PASING',
      gender: 'UNISEX',
      category: 'EQUIPMENT',
      subcategory: 'HELME',
      zustand: 'NEU',
    );

    final Map<String, dynamic> userData =
        json['user'] ??
        {
          'userId': json['userId'],
          'fullName': 'Test User',
          'email': 'test@example.com',
          'role': 'USER',
        };

    final user = User(
      userId: userData['userId'],
      fullName: userData['fullName'],
      email: userData['email'],
      role: userData['role'] ?? 'USER',
    );

    return MockRental(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      item: item,
      user: user,
      status: json['status'] ?? 'ACTIVE',
      startDate: json['startDate'],
      endDate: json['endDate'],
    );
  }
}

// Manual mock implementations
class MockHttpClient implements HttpClient {
  Map<String, Function> stubbedResponses = {};
  List<Map<String, dynamic>> capturedRequests = [];

  void stubResponse(String method, String path, Function response) {
    stubbedResponses['$method:$path'] = response;
  }

  dynamic _recordRequest(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    capturedRequests.add({
      'method': method,
      'url': url.toString(),
      'headers': headers,
      'body': body,
    });
  }

  http.Response _getResponse(String method, String path) {
    final key = '$method:$path';
    String? matchingKey;

    // Try exact match first
    if (stubbedResponses.containsKey(key)) {
      matchingKey = key;
    } else {
      // Try to find a partial match
      for (final k in stubbedResponses.keys) {
        final kMethod = k.split(':')[0];
        final kPath = k.split(':')[1];
        if (kMethod == method && path.contains(kPath)) {
          matchingKey = k;
          break;
        }
      }

      // If still not found, look for wildcards
      if (matchingKey == null) {
        for (final k in stubbedResponses.keys) {
          if (k.contains('*')) {
            final kMethod = k.split(':')[0];
            if (kMethod == method) {
              matchingKey = k;
              break;
            }
          }
        }
      }
    }

    if (matchingKey == null) {
      // Provide default responses for common status codes
      if (path.contains('/400')) {
        return http.Response('Bad Request', 400);
      } else if (path.contains('/401')) {
        return http.Response(json.encode({'message': 'Unauthorized'}), 401);
      } else if (path.contains('/403')) {
        return http.Response(json.encode({'message': 'Forbidden'}), 403);
      } else if (path.contains('/404')) {
        return http.Response(json.encode({'message': 'Not Found'}), 404);
      } else if (path.contains('/500')) {
        return http.Response(json.encode({'message': 'Server Error'}), 500);
      }

      // If we get here, we have no stub for this request
      return http.Response('Not Found', 404);
    }

    final responseFunc = stubbedResponses[matchingKey];
    if (responseFunc == null) {
      throw Exception('Unstubbed request: $method $path');
    }
    return responseFunc();
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    _recordRequest('GET', url, headers: headers);
    return _getResponse('GET', url.path);
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    _recordRequest('POST', url, headers: headers, body: body);
    return _getResponse('POST', url.path);
  }

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    _recordRequest('PUT', url, headers: headers, body: body);
    return _getResponse('PUT', url.path);
  }

  @override
  Future<http.Response> delete(Uri url, {Map<String, String>? headers}) async {
    _recordRequest('DELETE', url, headers: headers);
    return _getResponse('DELETE', url.path);
  }

  @override
  Future<http.StreamedResponse> send(http.MultipartRequest request) async {
    _recordRequest('MULTIPART', request.url, headers: request.headers);

    final responseFunc = stubbedResponses['MULTIPART:${request.url.path}'];
    if (responseFunc == null) {
      throw Exception('Unstubbed multipart request: ${request.url}');
    }

    final response = responseFunc();
    if (response is http.Response) {
      return http.StreamedResponse(
        Stream.value(utf8.encode(response.body)),
        response.statusCode,
        headers: response.headers,
      );
    } else {
      throw Exception('Invalid stubbed response type');
    }
  }

  // Helper methods for verification
  bool requestMade(String method, String pathContains) {
    return capturedRequests.any(
      (req) =>
          req['method'] == method &&
          (req['url'] as String).contains(pathContains),
    );
  }

  Map<String, dynamic>? getRequestBody(String method, String pathContains) {
    final request = capturedRequests.firstWhere(
      (req) =>
          req['method'] == method &&
          (req['url'] as String).contains(pathContains),
      orElse: () => {},
    );

    if (request.isEmpty || request['body'] == null) return null;

    if (request['body'] is String) {
      try {
        return json.decode(request['body'] as String);
      } catch (_) {
        return {'rawContent': request['body']};
      }
    }

    return {'rawContent': request['body']};
  }

  void reset() {
    capturedRequests.clear();
    stubbedResponses.clear();
  }
}

class MockTokenStorage implements TokenStorage {
  String? _storedToken;
  bool _clearCalled = false;
  int saveCount = 0;
  int getCount = 0;
  int clearCount = 0;

  // Add a field to store an optional error to throw
  Exception? _getTokenError;

  void throwOnGetToken(Exception error) {
    _getTokenError = error;
  }

  @override
  Future<void> saveToken(String token) async {
    _storedToken = token;
    saveCount++;
  }

  @override
  Future<String?> getToken() async {
    getCount++;
    if (_getTokenError != null) {
      throw _getTokenError!;
    }
    return _storedToken;
  }

  @override
  Future<void> clearToken() async {
    _clearCalled = true;
    clearCount++;
    _storedToken = null;
  }

  bool get tokenCleared => _clearCalled;

  void reset() {
    _storedToken = null;
    _clearCalled = false;
    saveCount = 0;
    getCount = 0;
    clearCount = 0;
    _getTokenError = null;
  }
}

void main() {
  late MockHttpClient mockHttpClient;
  late MockTokenStorage mockTokenStorage;
  late AdminService adminService;

  const String testBaseUrl = 'http://test-api.example.com';

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockTokenStorage = MockTokenStorage();

    adminService = AdminService(
      httpClient: mockHttpClient,
      tokenStorage: mockTokenStorage,
      baseUrl: testBaseUrl,
    );

    // Add fallback error responses
    mockHttpClient.stubResponse(
      'GET',
      '/400',
      () => http.Response('Bad Request', 400),
    );
    mockHttpClient.stubResponse(
      'GET',
      '/401',
      () => http.Response('Unauthorized', 401),
    );
    mockHttpClient.stubResponse(
      'GET',
      '/403',
      () => http.Response('Forbidden', 403),
    );
    mockHttpClient.stubResponse(
      'GET',
      '/404',
      () => http.Response('Not Found', 404),
    );
    mockHttpClient.stubResponse(
      'GET',
      '/500',
      () => http.Response('Server Error', 500),
    );
  });

  group('Authentication Tests', () {
    test(
      'isAdminAuthenticated returns true when token is valid and API call succeeds',
      () async {
        // Arrange
        await mockTokenStorage.saveToken('valid_token');
        mockHttpClient.stubResponse(
          'GET',
          '/users',
          () => http.Response('[]', 200),
        );

        // Act
        final result = await adminService.isAdminAuthenticated();

        // Assert
        expect(result, true);
        expect(mockHttpClient.requestMade('GET', '/users'), true);
      },
    );

    test('isAdminAuthenticated returns false when token is missing', () async {
      // Act
      final result = await adminService.isAdminAuthenticated();

      // Assert
      expect(result, false);
      expect(mockHttpClient.requestMade('GET', '/users'), false);
    });

    test('isAdminAuthenticated returns false on network error', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      mockHttpClient.stubResponse(
        'GET',
        '/users',
        () => throw Exception('Network error'),
      );

      // Act
      final result = await adminService.isAdminAuthenticated();

      // Assert
      expect(result, false);
    });

    test('login stores token on success', () async {
      // Arrange
      final testEmail = 'admin@example.com';
      final testPassword = 'password123';

      mockHttpClient.stubResponse(
        'POST',
        '/auth/login',
        () => http.Response(
          json.encode({
            'token': 'new_valid_token',
            'userId': 1,
            'email': testEmail,
            'role': 'ADMIN',
          }),
          200,
        ),
      );

      // Act
      final result = await adminService.login(testEmail, testPassword);
      final storedToken = await mockTokenStorage.getToken();

      // Assert
      expect(storedToken, 'new_valid_token');
      expect(result.isSuccess, true);
      expect(result.data?['email'], testEmail);
      expect(result.data?['role'], 'ADMIN');

      // Verify request was made with correct data
      final requestBody = mockHttpClient.getRequestBody('POST', '/auth/login');
      expect(requestBody?['email'], testEmail);
      expect(requestBody?['password'], testPassword);
    });

    test(
      'login returns error response when server returns non-200 status',
      () async {
        // Arrange
        final testEmail = 'admin@example.com';
        final testPassword = 'password123';

        mockHttpClient.stubResponse(
          'POST',
          '/auth/login',
          () => http.Response(
            json.encode({'message': 'Invalid credentials'}),
            401,
          ),
        );

        // Act
        final result = await adminService.login(testEmail, testPassword);

        // Assert
        expect(result.isSuccess, false);
        expect(result.errorMessage, contains('Invalid credentials'));
        expect(result.statusCode, 401);

        // Verify logout was called
        expect(mockTokenStorage.tokenCleared, true);
      },
    );

    test('login returns error when response is not JSON', () async {
      // Arrange
      final testEmail = 'admin@example.com';
      final testPassword = 'password123';

      mockHttpClient.stubResponse(
        'POST',
        '/auth/login',
        () => http.Response('Not JSON data', 200),
      );

      // Act
      final result = await adminService.login(testEmail, testPassword);

      // Assert
      expect(result.isSuccess, false);
      expect(result.errorMessage, isNotNull);
    });

    test('login returns error when user is not admin', () async {
      // Arrange
      final testEmail = 'user@example.com';
      final testPassword = 'password123';

      mockHttpClient.stubResponse(
        'POST',
        '/auth/login',
        () => http.Response(
          json.encode({
            'token': 'user_token',
            'userId': 2,
            'email': testEmail,
            'role': 'USER', // Not ADMIN
          }),
          200,
        ),
      );

      // Act
      final result = await adminService.login(testEmail, testPassword);

      // Assert
      expect(result.isSuccess, false);
      expect(result.errorMessage, contains('Keine Admin-Berechtigung'));
      expect(result.statusCode, 403);
    });

    test('login returns error when token is missing in response', () async {
      // Arrange
      final testEmail = 'admin@example.com';
      final testPassword = 'password123';

      mockHttpClient.stubResponse(
        'POST',
        '/auth/login',
        () => http.Response(
          json.encode({
            'userId': 1,
            'email': testEmail,
            'role': 'ADMIN',
            // Missing token
          }),
          200,
        ),
      );

      // Act
      final result = await adminService.login(testEmail, testPassword);

      // Assert
      expect(result.isSuccess, false);
      expect(result.errorMessage, contains('Kein Token erhalten'));
    });

    test('register validates email starts with admin', () async {
      // Arrange
      final testName = 'Regular User';
      final testEmail = 'regular@example.com'; // Not starting with admin
      final testPassword = 'password123';

      // Act
      final result = await adminService.register(
        testName,
        testEmail,
        testPassword,
      );

      // Assert
      expect(result.isSuccess, false);
      expect(
        result.errorMessage,
        contains('Admin-Email muss mit "admin" beginnen'),
      );

      // Verify no HTTP request was made
      expect(mockHttpClient.capturedRequests.isEmpty, true);
    });

    test('register sends correct data and stores token on success', () async {
      // Arrange
      final testName = 'New Admin';
      final testEmail = 'admin.new@example.com';
      final testPassword = 'admin123';

      mockHttpClient.stubResponse(
        'POST',
        '/auth/register',
        () => http.Response(
          json.encode({
            'token': 'new_admin_token',
            'userId': 5,
            'fullName': testName,
            'email': testEmail,
            'role': 'ADMIN',
          }),
          200,
        ),
      );

      // Act
      final result = await adminService.register(
        testName,
        testEmail,
        testPassword,
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.data?['token'], 'new_admin_token');
      expect(result.data?['role'], 'ADMIN');

      // Verify token was stored
      expect(await mockTokenStorage.getToken(), 'new_admin_token');

      // Verify request body
      final requestBody = mockHttpClient.getRequestBody(
        'POST',
        '/auth/register',
      );
      expect(requestBody?['fullName'], testName);
      expect(requestBody?['email'], testEmail);
      expect(requestBody?['password'], testPassword);
    });

    test(
      'register returns error when response indicates non-admin role',
      () async {
        // Arrange
        final testName = 'New User';
        final testEmail = 'admin.user@example.com';
        final testPassword = 'admin123';

        mockHttpClient.stubResponse(
          'POST',
          '/auth/register',
          () => http.Response(
            json.encode({
              'token': 'user_token',
              'userId': 6,
              'fullName': testName,
              'email': testEmail,
              'role': 'USER', // Not ADMIN
            }),
            200,
          ),
        );

        // Act
        final result = await adminService.register(
          testName,
          testEmail,
          testPassword,
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.errorMessage, contains('Keine Admin-Rolle'));
      },
    );

    test('register handles error response codes', () async {
      // Arrange
      final testName = 'Duplicate Admin';
      final testEmail = 'admin.duplicate@example.com';
      final testPassword = 'admin123';

      mockHttpClient.stubResponse(
        'POST',
        '/auth/register',
        () => http.Response(
          json.encode({'message': 'Email already in use'}),
          409, // Conflict
        ),
      );

      // Act
      final result = await adminService.register(
        testName,
        testEmail,
        testPassword,
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.errorMessage, contains('Email already in use'));
      expect(result.statusCode, 409);
    });

    test('ensureAuthenticated returns true when authenticated', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      mockHttpClient.stubResponse(
        'GET',
        '/users',
        () => http.Response('[]', 200),
      );

      // Act
      final result = await adminService.ensureAuthenticated();

      // Assert
      expect(result, true);
    });

    test(
      'ensureAuthenticated returns false and logs out when not authenticated',
      () async {
        // Arrange
        mockHttpClient.stubResponse(
          'GET',
          '/users',
          () => http.Response('Unauthorized', 401),
        );

        // Act
        final result = await adminService.ensureAuthenticated();

        // Assert
        expect(result, false);
        expect(mockTokenStorage.tokenCleared, true);
      },
    );

    test('logout clears token storage', () async {
      // Arrange
      await mockTokenStorage.saveToken('token_to_clear');

      // Act
      await adminService.logout();

      // Assert
      expect(mockTokenStorage.tokenCleared, true);
      expect(await mockTokenStorage.getToken(), null);
    });

    test('canCreateItems returns true when token exists', () async {
      // Arrange
      await mockTokenStorage.saveToken('existing_token');

      // Act
      final result = await adminService.canCreateItems();

      // Assert
      expect(result, true);
    });

    test('canCreateItems returns false when token is null', () async {
      // Act
      final result = await adminService.canCreateItems();

      // Assert
      expect(result, false);
    });

    test('canCreateItems returns false on error', () async {
      // Arrange
      await mockTokenStorage.saveToken('token');
      mockTokenStorage.throwOnGetToken(Exception('Storage error'));

      // Act
      final result = await adminService.canCreateItems();

      // Assert
      expect(result, false);
    });
  });

  group('Item Management Tests', () {
    test('getAllItems returns empty list for empty response', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      const location = 'PASING';

      mockHttpClient.stubResponse(
        'GET',
        '/items',
        () => http.Response('', 200),
      ); // Empty response

      // Act
      final result = await adminService.getAllItems(location);

      // Assert
      expect(result.isSuccess, true);
      expect(result.data, isEmpty);
    });

    test('getAllItems returns list of items from API', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      const location = 'PASING';

      mockHttpClient.stubResponse(
        'GET',
        '/items',
        () => http.Response(
          json.encode([
            {
              'id': 1,
              'name': 'Test Item 1',
              'description': 'Test description',
              'brand': 'Test brand',
              'size': 'M',
              'available': true,
              'location': 'PASING',
              'gender': 'UNISEX',
              'category': 'EQUIPMENT',
              'subcategory': 'HELME',
              'zustand': 'NEU',
              'imageUrl': 'https://example.com/image1.jpg',
            },
            {
              'id': 2,
              'name': 'Test Item 2',
              'description': 'Another test',
              'brand': 'Another brand',
              'size': 'L',
              'available': true,
              'location': 'PASING',
              'gender': 'HERREN',
              'category': 'KLEIDUNG',
              'subcategory': 'JACKEN',
              'zustand': 'GEBRAUCHT',
              'imageUrl': null,
            },
          ]),
          200,
        ),
      );

      // Act
      final result = await adminService.getAllItems(location);

      // Assert
      expect(result.isSuccess, true);
      expect(result.data?.length, 2);
      expect(result.data?[0].id, 1);
      expect(result.data?[0].name, 'Test Item 1');
      expect(result.data?[0].location, 'PASING');
      expect(result.data?[1].id, 2);
      expect(result.data?[1].name, 'Test Item 2');
      expect(result.data?[1].imageUrl, isNull);
    });

    test('getAllItems returns error when not authenticated', () async {
      // Arrange
      const location = 'PASING';

      // Act
      final result = await adminService.getAllItems(location);

      // Assert
      expect(result.isSuccess, false);
      expect(result.errorMessage, contains('Kein Admin-Token verfügbar'));
    });

    test('getAllItems returns error when server returns error', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      const location = 'PASING';

      mockHttpClient.stubResponse(
        'GET',
        '/items',
        () => http.Response(
          json.encode({'message': 'Internal server error'}),
          500,
        ),
      );

      // Act
      final result = await adminService.getAllItems(location);

      // Assert
      expect(result.isSuccess, false);
      expect(result.statusCode, 500);
      expect(result.errorMessage, contains('Internal server error'));
    });

    test('getItemById returns item with specified ID', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      const itemId = 42;

      mockHttpClient.stubResponse(
        'GET',
        '/items/$itemId',
        () => http.Response(
          json.encode({
            'id': itemId,
            'name': 'Specific Item',
            'description': 'Item description',
            'brand': 'Brand X',
            'size': 'XL',
            'available': true,
            'location': 'KARLSTRASSE',
            'gender': 'UNISEX',
            'category': 'EQUIPMENT',
            'subcategory': 'SKI',
            'zustand': 'GEBRAUCHT',
            'imageUrl': 'https://example.com/item42.jpg',
          }),
          200,
        ),
      );

      // Act
      final result = await adminService.getItemById(itemId);

      // Assert
      expect(result.isSuccess, true);
      expect(result.data?.id, itemId);
      expect(result.data?.name, 'Specific Item');
      expect(result.data?.category, 'EQUIPMENT');
      expect(result.data?.imageUrl, 'https://example.com/item42.jpg');
    });

    test('getItemById returns error when item not found', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      const itemId = 999;

      mockHttpClient.stubResponse(
        'GET',
        '/items/$itemId',
        () => http.Response(json.encode({'message': 'Item not found'}), 404),
      );

      // Act
      final result = await adminService.getItemById(itemId);

      // Assert
      expect(result.isSuccess, false);
      expect(result.statusCode, 404);
      expect(result.errorMessage, contains('Item not found'));
    });

    test(
      'createItem sends correct data to API and returns created item',
      () async {
        // Arrange
        await mockTokenStorage.saveToken('valid_token');
        final testItem = Item(
          id: 0, // New item has no ID yet
          name: 'New Item',
          description: 'New item description',
          brand: 'Test Brand',
          size: 'S',
          available: true,
          location: 'PASING',
          gender: 'DAMEN',
          category: 'KLEIDUNG',
          subcategory: 'HOSEN',
          zustand: 'NEU',
        );

        mockHttpClient.stubResponse(
          'POST',
          '/items',
          () => http.Response(
            json.encode({
              'id': 5, // Server assigned ID
              'name': 'New Item',
              'description': 'New item description',
              'brand': 'Test Brand',
              'size': 'S',
              'available': true,
              'location': 'PASING',
              'gender': 'DAMEN',
              'category': 'KLEIDUNG',
              'subcategory': 'HOSEN',
              'zustand': 'NEU',
              'imageUrl': '',
            }),
            201,
          ),
        );

        // Act
        final result = await adminService.createItem(testItem);

        // Assert
        expect(result.isSuccess, true);
        expect(result.data?.id, 5); // Check server-assigned ID
        expect(result.data?.name, testItem.name);
        expect(result.data?.description, testItem.description);
        expect(result.data?.brand, testItem.brand);

        // Verify correct data was sent
        final requestBody = mockHttpClient.getRequestBody('POST', '/items');
        expect(requestBody?['name'], testItem.name);
        expect(requestBody?['description'], testItem.description);
        expect(requestBody?['brand'], testItem.brand);
      },
    );

    test(
      'createItem returns error when server returns empty response',
      () async {
        // Arrange
        await mockTokenStorage.saveToken('valid_token');
        final testItem = Item(
          id: 0,
          name: 'Test Item',
          description: '',
          brand: '',
          size: '',
          available: true,
          location: 'PASING',
          gender: 'UNISEX',
          category: 'EQUIPMENT',
          subcategory: 'HELME',
          zustand: 'NEU',
        );

        mockHttpClient.stubResponse(
          'POST',
          '/items',
          () => http.Response('', 201),
        ); // Empty response

        // Act
        final result = await adminService.createItem(testItem);

        // Assert
        expect(result.isSuccess, false);
        expect(result.errorMessage, contains('leere Antwort'));
      },
    );

    test('createItem returns error when unauthorized', () async {
      // Arrange
      await mockTokenStorage.saveToken('invalid_token');
      final testItem = Item(
        id: 0,
        name: 'Test Item',
        description: '',
        brand: '',
        size: '',
        available: true,
        location: 'PASING',
        gender: 'UNISEX',
        category: 'EQUIPMENT',
        subcategory: 'HELME',
        zustand: 'NEU',
      );

      mockHttpClient.stubResponse(
        'POST',
        '/items',
        () => http.Response(json.encode({'message': 'Unauthorized'}), 401),
      );

      // Act
      final result = await adminService.createItem(testItem);

      // Assert
      expect(result.isSuccess, false);
      expect(result.statusCode, 401);
      // Die AdminService gibt eine spezifische deutsche Fehlermeldung zurück
      expect(result.errorMessage, contains('Keine ausreichenden Berechtigungen für diese Operation'));
    });

    test('updateItem updates an existing item', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      const itemId = 5;
      final updatedItem = Item(
        id: itemId,
        name: 'Updated Item',
        description: 'Updated description',
        brand: 'Updated Brand',
        size: 'XL',
        available: false, // Changed availability
        location: 'LOTHSTRASSE',
        gender: 'HERREN',
        category: 'EQUIPMENT',
        subcategory: 'SKI',
        zustand: 'GEBRAUCHT',
      );

      mockHttpClient.stubResponse(
        'PUT',
        '/items/$itemId',
        () => http.Response(
          json.encode({
            'id': itemId,
            'name': 'Updated Item',
            'description': 'Updated description',
            'brand': 'Updated Brand',
            'size': 'XL',
            'available': false,
            'location': 'LOTHSTRASSE',
            'gender': 'HERREN',
            'category': 'EQUIPMENT',
            'subcategory': 'SKI',
            'zustand': 'GEBRAUCHT',
            'imageUrl': 'https://example.com/image.jpg',
          }),
          200,
        ),
      );

      // Act
      final result = await adminService.updateItem(itemId, updatedItem);

      // Assert
      expect(result.isSuccess, true);
      expect(result.data?.id, itemId);
      expect(result.data?.name, updatedItem.name);
      expect(result.data?.available, false);
      expect(result.data?.location, 'LOTHSTRASSE');
      expect(result.data?.imageUrl, 'https://example.com/image.jpg');

      // Verify correct data was sent
      final requestBody = mockHttpClient.getRequestBody(
        'PUT',
        '/items/$itemId',
      );
      expect(requestBody?['name'], updatedItem.name);
      expect(requestBody?['available'], false);
    });

    test('updateItem returns error when token missing', () async {
      // Arrange
      const itemId = 5;
      final updatedItem = Item(
        id: itemId,
        name: 'Item Name',
        description: '',
        brand: '',
        size: '',
        available: true,
        location: 'PASING',
        gender: 'UNISEX',
        category: 'EQUIPMENT',
        subcategory: 'HELME',
        zustand: 'NEU',
      );

      // Act
      final result = await adminService.updateItem(itemId, updatedItem);

      // Assert
      expect(result.isSuccess, false);
      expect(result.errorMessage, contains('Kein Admin-Token verfügbar'));
    });

    test(
      'updateItem returns error when server returns empty response',
      () async {
        // Arrange
        await mockTokenStorage.saveToken('valid_token');
        const itemId = 5;
        final updatedItem = Item(
          id: itemId,
          name: 'Item Name',
          description: '',
          brand: '',
          size: '',
          available: true,
          location: 'PASING',
          gender: 'UNISEX',
          category: 'EQUIPMENT',
          subcategory: 'HELME',
          zustand: 'NEU',
        );

        mockHttpClient.stubResponse(
          'PUT',
          '/items/$itemId',
          () => http.Response('', 200),
        ); // Empty response

        // Act
        final result = await adminService.updateItem(itemId, updatedItem);

        // Assert
        expect(result.isSuccess, false);
        expect(result.errorMessage, contains('leere Antwort'));
      },
    );

    test('updateItem logs out and returns error when unauthorized', () async {
      // Arrange
      await mockTokenStorage.saveToken('expired_token');
      const itemId = 5;
      final updatedItem = Item(
        id: itemId,
        name: 'Item Name',
        description: '',
        brand: '',
        size: '',
        available: true,
        location: 'PASING',
        gender: 'UNISEX',
        category: 'EQUIPMENT',
        subcategory: 'HELME',
        zustand: 'NEU',
      );

      mockHttpClient.stubResponse(
        'PUT',
        '/items/$itemId',
        () => http.Response(json.encode({'message': 'Token expired'}), 401),
      );

      // Act
      final result = await adminService.updateItem(itemId, updatedItem);

      // Assert
      expect(result.isSuccess, false);
      expect(result.statusCode, 401);
      // Der AdminService gibt eine spezifische deutsche Fehlermeldung bei 401 zurück
      expect(result.errorMessage, contains('Token abgelaufen. Bitte neu anmelden.'));
      expect(mockTokenStorage.tokenCleared, true);
    });

   test('updateItem handles forbidden status', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      const itemId = 5;
      final updatedItem = Item(
        id: itemId,
        name: 'Item Name',
        description: '',
        brand: '',
        size: '',
        available: true,
        location: 'PASING',
        gender: 'UNISEX',
        category: 'EQUIPMENT',
        subcategory: 'HELME',
        zustand: 'NEU',
      );

      mockHttpClient.stubResponse(
        'PUT',
        '/items/$itemId',
        () => http.Response(json.encode({'message': 'Forbidden'}), 403),
      );

      // Act
      final result = await adminService.updateItem(itemId, updatedItem);

      // Assert
      expect(result.isSuccess, false);
      expect(result.statusCode, 403);
      // Der AdminService gibt eine spezifische deutsche Fehlermeldung zurück
      expect(result.errorMessage, contains('Keine Admin-Berechtigung. Token ist ungültig.'));
    });

    test('deleteItem sends delete request for item', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      const itemId = 3;

      mockHttpClient.stubResponse(
        'DELETE',
        '/items/$itemId',
        () => http.Response('', 204),
      ); // No content response

      // Act
      final result = await adminService.deleteItem(itemId);

      // Assert
      expect(result.isSuccess, true);
      expect(mockHttpClient.requestMade('DELETE', '/items/$itemId'), true);
    });

   test('deleteItem returns error when unauthorized', () async {
      // Arrange
      await mockTokenStorage.saveToken('expired_token');
      const itemId = 3;

      mockHttpClient.stubResponse(
        'DELETE',
        '/items/$itemId',
        () => http.Response(json.encode({'message': 'Unauthorized'}), 401),
      );

      // Act
      final result = await adminService.deleteItem(itemId);

      // Assert
      expect(result.isSuccess, false);
      expect(result.statusCode, 401);
      // Der AdminService gibt eine spezifische deutsche Fehlermeldung bei 401 zurück
      expect(result.errorMessage, contains('Token abgelaufen. Bitte neu anmelden.'));
    });

    test('deleteItem returns error on server error', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      const itemId = 3;

      mockHttpClient.stubResponse(
        'DELETE',
        '/items/$itemId',
        () => http.Response(
          json.encode({'message': 'Internal server error'}),
          500,
        ),
      );

      // Act
      final result = await adminService.deleteItem(itemId);

      // Assert
      expect(result.isSuccess, false);
      expect(result.statusCode, 500);
      expect(result.errorMessage, contains('Internal server error'));
    });

    test('deleteItem handles forbidden status code', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      const itemId = 3;

      mockHttpClient.stubResponse(
        'DELETE',
        '/items/$itemId',
        () => http.Response(json.encode({'message': 'Forbidden'}), 403),
      );

      // Act
      final result = await adminService.deleteItem(itemId);

      // Assert
      expect(result.isSuccess, false);
      expect(result.statusCode, 403);
      // Der AdminService gibt eine spezifische deutsche Fehlermeldung bei 403 zurück
      expect(result.errorMessage, contains('Keine Admin-Berechtigung. Token ist ungültig.'));
    });
  });

  group('User Management Tests', () {
    test('getAllUsers returns list of users from API', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      final usersJson = [
        {
          'userId': 1,
          'fullName': 'Admin User',
          'email': 'admin@example.com',
          'role': 'ADMIN',
        },
        {
          'userId': 2,
          'fullName': 'Regular User',
          'email': 'user@example.com',
          'role': 'USER',
        },
      ];

      mockHttpClient.stubResponse(
        'GET',
        '/users',
        () => http.Response(json.encode(usersJson), 200),
      );

      // Act
      final result = await adminService.getAllUsers();

      // Assert
      expect(result.isSuccess, true);
      expect(result.data?.length, 2);
      expect(result.data?[0].userId, 1);
      expect(result.data?[0].fullName, 'Admin User');
      expect(result.data?[0].email, 'admin@example.com');
      expect(result.data?[1].userId, 2);
      expect(result.data?[1].fullName, 'Regular User');
    });

    test('getAllUsers returns empty list for empty response', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      mockHttpClient.stubResponse(
        'GET',
        '/users',
        () => http.Response('', 200),
      ); // Empty response

      // Act
      final result = await adminService.getAllUsers();

      // Assert
      expect(result.isSuccess, true);
      expect(result.data, isEmpty);
    });

    test('getAllUsers returns error when not authenticated', () async {
      // Arrange
      mockHttpClient.stubResponse(
        'GET',
        '/users',
        () => http.Response(json.encode({'message': 'Unauthorized'}), 401),
      );

      // Act
      final result = await adminService.getAllUsers();

      // Assert
      expect(result.isSuccess, false);
      // Der AdminService prüft zuerst, ob ein Token vorhanden ist, bevor er die HTTP-Anfrage macht
      // Da kein Token gesetzt wurde, wird diese Fehlermeldung zurückgegeben
      expect(result.errorMessage, contains('Kein Admin-Token verfügbar'));
    });

    test('getUserById returns single user', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      const userId = 1;
      final userJson = {
        'userId': userId,
        'fullName': 'Admin User',
        'email': 'admin@example.com',
        'role': 'ADMIN',
      };

      mockHttpClient.stubResponse(
        'GET',
        '/users/$userId',
        () => http.Response(json.encode(userJson), 200),
      );

      // Act
      final result = await adminService.getUserById(userId);

      // Assert
      expect(result.isSuccess, true);
      expect(result.data?.userId, userId);
      expect(result.data?.fullName, 'Admin User');
      expect(result.data?.email, 'admin@example.com');
    });

    test('getUserById returns error when user not found', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      const userId = 999;

      mockHttpClient.stubResponse(
        'GET',
        '/users/$userId',
        () => http.Response(json.encode({'message': 'User not found'}), 404),
      );

      // Act
      final result = await adminService.getUserById(userId);

      // Assert
      expect(result.isSuccess, false);
      expect(result.statusCode, 404);
      expect(result.errorMessage, contains('User not found'));
    });
  });

  group('Rental Management Tests', () {
    test('getAllRentals returns list of rentals with user data', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      final rentalsJson = [
        {
          'id': 1,
          'userId': 2,
          'itemId': 5,
          'rentalDate': '2023-06-01T10:00:00Z', // Korrigiert: rentalDate statt startDate
          'endDate': '2023-06-05T10:00:00Z',
          'status': 'ACTIVE',
          'item': {
            'id': 5, 
            'name': 'Ski Helmet', 
            'available': false,
            // Hinzugefügte erforderliche Felder für Item.fromJson
            'location': 'PASING',
            'gender': 'UNISEX',
            'category': 'EQUIPMENT',
            'subcategory': 'HELME',
            'zustand': 'NEU'
          },
          // User data is missing and needs to be fetched separately
        },
        {
          'id': 2,
          'userId': 3,
          'itemId': 8,
          'rentalDate': '2023-05-15T14:00:00Z', // Korrigiert: rentalDate statt startDate
          'endDate': '2023-05-20T14:00:00Z',
          'status': 'RETURNED',
          'item': {
            'id': 8, 
            'name': 'Ski Goggles', 
            'available': true,
            // Hinzugefügte erforderliche Felder für Item.fromJson
            'location': 'KARLSTRASSE',
            'gender': 'UNISEX',
            'category': 'ACCESSOIRES',
            'subcategory': 'BRILLEN',
            'zustand': 'GEBRAUCHT'
          },
          'user': {
            'userId': 3,
            'fullName': 'Another User',
            'email': 'another@example.com',
            'role': 'USER' // Hinzugefügte role für User.fromJson
          },
        },
      ];

      final userJson = {
        'userId': 2,
        'fullName': 'Regular User',
        'email': 'user@example.com',
        'role': 'USER',
      };

      mockHttpClient.stubResponse(
        'GET',
        '/rentals',
        () => http.Response(json.encode(rentalsJson), 200),
      );

      mockHttpClient.stubResponse(
        'GET',
        '/users/2',
        () => http.Response(json.encode(userJson), 200),
      );

      // Act
      final result = await adminService.getAllRentals();

      // Assert
      expect(result.isSuccess, true);
      expect(result.data?.length, 2);

      // Jetzt können wir auch die Inhalte testen, da alle erforderlichen Felder vorhanden sind
      expect(result.data?[0].id, 1);
      expect(result.data?[0].status, 'ACTIVE');
      expect(result.data?[0].item.name, 'Ski Helmet');
      expect(result.data?[0].user.fullName, 'Regular User'); // User wurde via API nachgeladen

      expect(result.data?[1].id, 2);
      expect(result.data?[1].status, 'RETURNED');
      expect(result.data?[1].item.name, 'Ski Goggles');
      expect(result.data?[1].user.fullName, 'Another User'); // User war bereits im JSON

      // Verifikation der API-Aufrufe
      expect(mockHttpClient.requestMade('GET', '/rentals'), true);
      expect(mockHttpClient.requestMade('GET', '/users/2'), true);
    });
    test('getAllRentals returns empty list for empty response', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      mockHttpClient.stubResponse(
        'GET',
        '/rentals',
        () => http.Response('', 200),
      ); // Empty response

      // Act
      final result = await adminService.getAllRentals();

      // Assert
      expect(result.isSuccess, true);
      expect(result.data, isEmpty);
    });

    test('getAllRentals returns list of rentals with user data', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      final rentalsJson = [
        {
          'id': 1,
          'userId': 2,
          'itemId': 5,
          'rentalDate': '2023-06-01T10:00:00Z', // Korrigiert von startDate zu rentalDate
          'endDate': '2023-06-05T10:00:00Z',
          'status': 'ACTIVE',
          'item': {
            'id': 5, 
            'name': 'Ski Helmet', 
            'available': false,
            // Hinzugefügte erforderliche Felder für Item.fromJson
            'location': 'PASING',
            'gender': 'UNISEX',
            'category': 'EQUIPMENT',
            'subcategory': 'HELME',
            'zustand': 'NEU'
          },
          // User data is missing and needs to be fetched separately
        },
        {
          'id': 2,
          'userId': 3,
          'itemId': 8,
          'rentalDate': '2023-05-15T14:00:00Z', // Korrigiert von startDate zu rentalDate
          'endDate': '2023-05-20T14:00:00Z',
          'status': 'RETURNED',
          'item': {
            'id': 8, 
            'name': 'Ski Goggles', 
            'available': true,
            // Hinzugefügte erforderliche Felder für Item.fromJson
            'location': 'KARLSTRASSE',
            'gender': 'UNISEX',
            'category': 'ACCESSOIRES',
            'subcategory': 'BRILLEN',
            'zustand': 'GEBRAUCHT'
          },
          'user': {
            'userId': 3,
            'fullName': 'Another User',
            'email': 'another@example.com',
            'role': 'USER'
          },
        },
      ];

      final userJson = {
        'userId': 2,
        'fullName': 'Regular User',
        'email': 'user@example.com',
        'role': 'USER',
      };

      mockHttpClient.stubResponse(
        'GET',
        '/rentals',
        () => http.Response(json.encode(rentalsJson), 200),
      );

      mockHttpClient.stubResponse(
        'GET',
        '/users/2',
        () => http.Response(json.encode(userJson), 200),
      );

      // Act
      final result = await adminService.getAllRentals();

      // Assert
      expect(result.isSuccess, true);
      expect(result.data?.length, 2);

      // Weitere Verifikationen der geparsten Daten
      expect(result.data?[0].id, 1);
      expect(result.data?[0].status, 'ACTIVE');
      expect(result.data?[0].item.name, 'Ski Helmet');
      expect(result.data?[0].user.fullName, 'Regular User'); // User wurde via API nachgeladen

      expect(result.data?[1].id, 2);
      expect(result.data?[1].status, 'RETURNED');
      expect(result.data?[1].item.name, 'Ski Goggles');
      expect(result.data?[1].user.fullName, 'Another User'); // User war bereits im JSON

      // Verifikation der API-Aufrufe
      expect(mockHttpClient.requestMade('GET', '/rentals'), true);
      expect(mockHttpClient.requestMade('GET', '/users/2'), true);
    });

    test('getRentalById returns error when rental not found', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      const rentalId = 999;

      mockHttpClient.stubResponse(
        'GET',
        '/rentals/$rentalId',
        () => http.Response(json.encode({'message': 'Rental not found'}), 404),
      );

      // Act
      final result = await adminService.getRentalById(rentalId);

      // Assert
      expect(result.isSuccess, false);
      expect(result.statusCode, 404);
      expect(result.errorMessage, contains('Rental not found'));
    });
  });

  group('Image Upload Tests', () {
    test(
      'uploadItemImageBytes successfully uploads image and returns URL',
      () async {
        // Arrange
        await mockTokenStorage.saveToken('valid_token');
        const itemId = 5;
        final imageBytes = Uint8List.fromList([
          1,
          2,
          3,
          4,
          5,
        ]); // Sample image data
        final filename = 'test_image.jpg';

        mockHttpClient.stubResponse(
          'MULTIPART',
          '/items/$itemId/image',
          () => http.Response(
            json.encode({
              'imageUrl': 'https://example.com/images/test_image.jpg',
            }),
            200,
          ),
        );

        // Act
        final result = await adminService.uploadItemImageBytes(
          itemId,
          imageBytes,
          filename,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, 'https://example.com/images/test_image.jpg');
        expect(
          mockHttpClient.requestMade('MULTIPART', '/items/$itemId/image'),
          true,
        );
      },
    );

    test('uploadItemImageBytes returns error when upload fails', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');
      const itemId = 5;
      final imageBytes = Uint8List.fromList([
        1,
        2,
        3,
        4,
        5,
      ]); // Sample image data
      final filename = 'test_image.jpg';

      mockHttpClient.stubResponse(
        'MULTIPART',
        '/items/$itemId/image',
        () => http.Response(json.encode({'message': 'Upload failed'}), 400),
      );

      // Act
      final result = await adminService.uploadItemImageBytes(
        itemId,
        imageBytes,
        filename,
      );

      // Assert
      expect(result.isSuccess, false);
      // Der AdminService gibt eine spezifische deutsche Fehlermeldung zurück
      expect(result.errorMessage, contains('Fehler beim Hochladen des Bildes'));
    });

    test('uploadItemImageBytes returns error when not authenticated', () async {
      // Arrange
      const itemId = 5;
      final imageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final filename = 'test_image.jpg';

      // Act
      final result = await adminService.uploadItemImageBytes(
        itemId,
        imageBytes,
        filename,
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.errorMessage, contains('Nicht authentifiziert'));
    });

    test(
      'uploadItemImageBytes handles different file types correctly',
      () async {
        // Arrange
        await mockTokenStorage.saveToken('valid_token');
        const itemId = 5;
        final imageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

        // Set up responses for different image types
        mockHttpClient.stubResponse(
          'MULTIPART',
          '/items/$itemId/image',
          () => http.Response(json.encode({'imageUrl': 'url_jpg'}), 200),
        );

        // Act - test each file type
        final jpgResult = await adminService.uploadItemImageBytes(
          itemId,
          imageBytes,
          'image.jpg',
        );
        final pngResult = await adminService.uploadItemImageBytes(
          itemId,
          imageBytes,
          'image.png',
        );
        final gifResult = await adminService.uploadItemImageBytes(
          itemId,
          imageBytes,
          'image.gif',
        );
        final unknownResult = await adminService.uploadItemImageBytes(
          itemId,
          imageBytes,
          'image.xyz',
        );

        // Assert
        expect(jpgResult.data, 'url_jpg');
        expect(pngResult.data, 'url_jpg');
        expect(gifResult.data, 'url_jpg');
        expect(unknownResult.data, 'url_jpg');
      },
    );
  });

  group('Error Handling Tests', () {
    test('handles different HTTP status codes correctly', () async {
      // Arrange
      await mockTokenStorage.saveToken('valid_token');

      // Mock responses for all status codes
      mockHttpClient.stubResponse(
        'GET',
        '/items/404',
        () => http.Response(
          json.encode({'message': 'Custom error message'}),
          404,
        ),
      );

      mockHttpClient.stubResponse(
        'GET',
        '/items/400',
        () => http.Response('Bad Request', 400),
      );

      mockHttpClient.stubResponse(
        'GET',
        '/items/401',
        () => http.Response('Unauthorized', 401),
      );

      mockHttpClient.stubResponse(
        'GET',
        '/items/403',
        () => http.Response('Forbidden', 403),
      );

      mockHttpClient.stubResponse(
        'GET',
        '/items/500',
        () => http.Response('Server Error', 500),
      );

      mockHttpClient.stubResponse(
        'GET',
        '/items/599',
        () => http.Response('Unknown error', 599),
      );

      // Act & Assert for each code
      final result404 = await adminService.getItemById(404);
      final result400 = await adminService.getItemById(400);
      final result401 = await adminService.getItemById(401);
      final result403 = await adminService.getItemById(403);
      final result500 = await adminService.getItemById(500);
      final result599 = await adminService.getItemById(599);

      // Assert all are errors with appropriate status codes
      expect(result404.isSuccess, false);
      expect(result404.statusCode, 404);

      expect(result400.isSuccess, false);
      expect(result400.statusCode, 400);

      expect(result401.isSuccess, false);
      expect(result401.statusCode, 401);

      expect(result403.isSuccess, false);
      expect(result403.statusCode, 403);

      expect(result500.isSuccess, false);
      expect(result500.statusCode, 500);

      expect(result599.isSuccess, false);
      expect(result599.statusCode, 599);
    });
  });
}
