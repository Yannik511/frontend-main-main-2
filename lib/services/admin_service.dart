import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kreisel_frontend/models/item_model.dart';
import 'package:kreisel_frontend/models/rental_model.dart';
import 'package:kreisel_frontend/models/user_model.dart';

// Network client abstraction
abstract class HttpClient {
  Future<http.Response> get(Uri url, {Map<String, String>? headers});
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  });
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  });
  Future<http.Response> delete(Uri url, {Map<String, String>? headers});
  Future<http.StreamedResponse> send(http.MultipartRequest request);
}

// Default HTTP implementation
class DefaultHttpClient implements HttpClient {
  final http.Client _client = http.Client();
  final Duration _timeout;

  DefaultHttpClient({Duration timeout = const Duration(seconds: 15)})
    : _timeout = timeout;

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _client.get(url, headers: headers).timeout(_timeout);
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _client.post(url, headers: headers, body: body).timeout(_timeout);
  }

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _client.put(url, headers: headers, body: body).timeout(_timeout);
  }

  @override
  Future<http.Response> delete(Uri url, {Map<String, String>? headers}) {
    return _client.delete(url, headers: headers).timeout(_timeout);
  }

  @override
  Future<http.StreamedResponse> send(http.MultipartRequest request) {
    return _client.send(request).timeout(_timeout);
  }
}

// Token storage abstraction
abstract class TokenStorage {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
}

// SharedPreferences implementation of token storage
class SharedPrefsTokenStorage implements TokenStorage {
  static const String tokenKey = 'admin_token';

  @override
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  @override
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }
}

// Standardized API response
class ApiResponse<T> {
  final T? data;
  final bool success;
  final String? errorMessage;
  final int? statusCode;

  ApiResponse({
    this.data,
    this.success = true,
    this.errorMessage,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {int? statusCode}) {
    return ApiResponse(data: data, success: true, statusCode: statusCode);
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      errorMessage: message,
      statusCode: statusCode,
    );
  }

  bool get isSuccess => success;
  bool get isError => !success;
}

// Admin service interface
abstract class AdminServiceInterface {
  Future<ApiResponse<List<Item>>> getAllItems(String location);
  Future<ApiResponse<List<Rental>>> getAllRentals();
  Future<ApiResponse<List<User>>> getAllUsers();
  Future<ApiResponse<Item>> createItem(Item item);
  Future<ApiResponse<Item>> updateItem(int id, Item item);
  Future<ApiResponse<void>> deleteItem(int id);
  Future<bool> isAdminAuthenticated();
  Future<bool> ensureAuthenticated();
  Future<bool> canCreateItems();
  Future<void> logout();
  Future<ApiResponse<String?>> uploadItemImageBytes(
    int itemId,
    Uint8List imageBytes,
    String filename,
  );
  Future<ApiResponse<Map<String, dynamic>>> login(
    String email,
    String password,
  );
  Future<ApiResponse<Map<String, dynamic>>> register(
    String fullName,
    String email,
    String password,
  );
}

// Main AdminService implementation
class AdminService implements AdminServiceInterface {
  // Singleton implementation
  static AdminService? _instance;

  static AdminService get instance {
    _instance ??= AdminService();
    return _instance!;
  }

  // For testing - allows injecting a mock
  @visibleForTesting
  static void setInstance(AdminService mockService) {
    _instance = mockService;
  }

  // Reset the singleton (useful for testing)
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  // Dependencies
  final HttpClient httpClient;
  final TokenStorage tokenStorage;
  final String baseUrl;
  bool _debugMode;

  // Constructor with dependency injection
  AdminService({
    HttpClient? httpClient,
    TokenStorage? tokenStorage,
    String? baseUrl,
    bool debugMode = false,
  }) : httpClient = httpClient ?? DefaultHttpClient(),
       tokenStorage = tokenStorage ?? SharedPrefsTokenStorage(),
       baseUrl = baseUrl ?? 'http://localhost:8080/api',
       _debugMode = debugMode;

  // Enable/disable debug mode
  void setDebugMode(bool enabled) {
    _debugMode = enabled;
  }

  // Logging helper
  void _log(String message) {
    if (_debugMode) {
      print('AdminService: $message');
    }
  }

  // MARK: - Authentication Methods

  @override
  Future<ApiResponse<Map<String, dynamic>>> login(
    String email,
    String password,
  ) async {
    try {
      _log('Starting admin login for: $email');
      await tokenStorage.clearToken(); // Clear existing tokens

      final response = await httpClient.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if user has ADMIN role
        if (data['role'] != 'ADMIN') {
          return ApiResponse.error('Keine Admin-Berechtigung', statusCode: 403);
        }

        // Save token
        final token = data['token'];
        if (token == null) {
          return ApiResponse.error(
            'Kein Token erhalten',
            statusCode: response.statusCode,
          );
        }

        await tokenStorage.saveToken(token);
        _log('Admin login successful');
        return ApiResponse.success(data, statusCode: response.statusCode);
      }

      return _handleErrorResponse(response);
    } catch (e) {
      _log('Admin login error: $e');
      await tokenStorage.clearToken();
      return ApiResponse.error('Verbindungsfehler: $e');
    }
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> register(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      _log('Starting admin registration for: $email');

      if (!email.startsWith('admin')) {
        return ApiResponse.error('Admin-Email muss mit "admin" beginnen');
      }

      final response = await httpClient.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Verify admin role
        if (data['role'] != 'ADMIN') {
          return ApiResponse.error(
            'Registrierung fehlgeschlagen - Keine Admin-Rolle',
            statusCode: 403,
          );
        }

        // Save token
        final token = data['token'];
        if (token == null) {
          return ApiResponse.error(
            'Kein Token erhalten',
            statusCode: response.statusCode,
          );
        }

        await tokenStorage.saveToken(token);
        return ApiResponse.success(data, statusCode: response.statusCode);
      }

      return _handleErrorResponse(response);
    } catch (e) {
      _log('Admin registration error: $e');
      await logout(); // Clear token on error
      return ApiResponse.error('Verbindungsfehler: $e');
    }
  }

  @override
  Future<void> logout() async {
    await tokenStorage.clearToken();
    _log('Cleared admin token');
  }

  @override
  Future<bool> isAdminAuthenticated() async {
    try {
      final token = await tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      // Test token validity by making a request
      final response = await httpClient.get(
        Uri.parse('$baseUrl/users'),
        headers: await _getAdminHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      _log('Authentication check error: $e');
      return false;
    }
  }

  @override
  Future<bool> ensureAuthenticated() async {
    final isAuth = await isAdminAuthenticated();
    if (!isAuth) {
      await logout();
      return false;
    }
    return true;
  }

  @override
  Future<bool> canCreateItems() async {
    try {
      final token = await tokenStorage.getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // MARK: - User Management Methods

  @override
  Future<ApiResponse<List<User>>> getAllUsers() async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/users'),
        headers: await _getAdminHeaders(),
      );

      _log('Get users response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty) {
          return ApiResponse.success([]);
        }

        final List<dynamic> data = jsonDecode(responseBody);
        final users = data.map((json) => User.fromJson(json)).toList();
        return ApiResponse.success(users, statusCode: response.statusCode);
      }

      return _handleErrorResponse(response);
    } catch (e) {
      _log('Error getting users: $e');
      return ApiResponse.error('Fehler beim Laden der Benutzer: $e');
    }
  }

  Future<ApiResponse<User>> getUserById(int userId) async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: await _getAdminHeaders(),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(
          User.fromJson(jsonDecode(response.body)),
          statusCode: response.statusCode,
        );
      }

      return _handleErrorResponse(response);
    } catch (e) {
      return ApiResponse.error('Fehler beim Laden des Benutzers: $e');
    }
  }

  // MARK: - Rental Management Methods

  @override
  Future<ApiResponse<List<Rental>>> getAllRentals() async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/rentals'),
        headers: await _getAdminHeaders(),
      );

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty) {
          return ApiResponse.success([]);
        }

        final List<dynamic> data = jsonDecode(responseBody);
        final rentals = <Rental>[];

        for (var rentalJson in data) {
          if (rentalJson['user'] == null && rentalJson['userId'] != null) {
            try {
              final userResponse = await httpClient.get(
                Uri.parse('$baseUrl/users/${rentalJson['userId']}'),
                headers: await _getAdminHeaders(),
              );

              if (userResponse.statusCode == 200) {
                final userData = jsonDecode(userResponse.body);
                _log('Got user data for rental: $userData');
                // Add user data to rental JSON
                rentalJson['user'] = userData;
              }
            } catch (e) {
              _log('Error fetching user ${rentalJson['userId']}: $e');
            }
          }

          rentals.add(Rental.fromJson(rentalJson));
        }

        return ApiResponse.success(rentals, statusCode: response.statusCode);
      }

      return _handleErrorResponse(response);
    } catch (e) {
      _log('Error getting rentals: $e');
      return ApiResponse.error('Fehler beim Laden der Ausleihen: $e');
    }
  }

  Future<ApiResponse<Rental>> getRentalById(int rentalId) async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/rentals/$rentalId'),
        headers: await _getAdminHeaders(),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(
          Rental.fromJson(jsonDecode(response.body)),
          statusCode: response.statusCode,
        );
      }

      return _handleErrorResponse(response);
    } catch (e) {
      return ApiResponse.error('Fehler beim Laden der Ausleihe: $e');
    }
  }

  // MARK: - Item Management Methods

  @override
  Future<ApiResponse<List<Item>>> getAllItems(String location) async {
    try {
      _log('Fetching items for location: $location');

      final queryParams = {'location': location};
      final uri = Uri.parse(
        '$baseUrl/items',
      ).replace(queryParameters: queryParams);

      final response = await httpClient.get(
        uri,
        headers: await _getAdminHeaders(),
      );

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty) {
          return ApiResponse.success([]);
        }

        final List<dynamic> data = jsonDecode(responseBody);
        final items = data.map((json) => Item.fromJson(json)).toList();
        return ApiResponse.success(items, statusCode: response.statusCode);
      }

      return _handleErrorResponse(response);
    } catch (e) {
      _log('Error loading items: $e');
      return ApiResponse.error('Fehler beim Laden der Gegenstände: $e');
    }
  }

  Future<ApiResponse<Item>> getItemById(int id) async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/items/$id'),
        headers: await _getAdminHeaders(),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(
          Item.fromJson(jsonDecode(response.body)),
          statusCode: response.statusCode,
        );
      }

      return _handleErrorResponse(response);
    } catch (e) {
      return ApiResponse.error('Fehler beim Laden des Gegenstands: $e');
    }
  }

  @override
  Future<ApiResponse<Item>> createItem(Item item) async {
    try {
      final headers = await _getAdminHeaders();

      final response = await httpClient.post(
        Uri.parse('$baseUrl/items'),
        headers: headers,
        body: jsonEncode({
          'name': item.name,
          'description': item.description,
          'brand': item.brand,
          'size': item.size,
          'available': true,
          'location': item.location,
          'gender': item.gender,
          'category': item.category,
          'subcategory': item.subcategory,
          'zustand': item.zustand,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty) {
          return ApiResponse.error('Server hat leere Antwort gesendet');
        }
        return ApiResponse.success(
          Item.fromJson(jsonDecode(responseBody)),
          statusCode: response.statusCode,
        );
      }

      // Special error handling
      if (response.statusCode == 401 || response.statusCode == 403) {
        return ApiResponse.error(
          'Keine ausreichenden Berechtigungen für diese Operation',
          statusCode: response.statusCode,
        );
      }

      return _handleErrorResponse(response);
    } catch (e) {
      _log('Create item error: $e');
      return ApiResponse.error('Fehler beim Erstellen des Gegenstands: $e');
    }
  }

  @override
  Future<ApiResponse<Item>> updateItem(int id, Item item) async {
    try {
      final token = await tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        return ApiResponse.error(
          'Kein Admin-Token verfügbar. Bitte neu anmelden.',
        );
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      final response = await httpClient.put(
        Uri.parse('$baseUrl/items/$id'),
        headers: headers,
        body: jsonEncode({
          'name': item.name,
          'description': item.description,
          'brand': item.brand,
          'size': item.size,
          'available': item.available,
          'location': item.location,
          'gender': item.gender,
          'category': item.category,
          'subcategory': item.subcategory,
          'zustand': item.zustand,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty) {
          return ApiResponse.error('Server hat leere Antwort gesendet');
        }
        return ApiResponse.success(
          Item.fromJson(jsonDecode(responseBody)),
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode == 401) {
        await logout();
        return ApiResponse.error(
          'Token abgelaufen. Bitte neu anmelden.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode == 403) {
        return ApiResponse.error(
          'Keine Admin-Berechtigung. Token ist ungültig.',
          statusCode: response.statusCode,
        );
      }

      return _handleErrorResponse(response);
    } catch (e) {
      _log('Update Item Error: $e');
      return ApiResponse.error('Fehler beim Aktualisieren des Gegenstands: $e');
    }
  }

  @override
  Future<ApiResponse<void>> deleteItem(int id) async {
    try {
      final response = await httpClient.delete(
        Uri.parse('$baseUrl/items/$id'),
        headers: await _getAdminHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse.success(null, statusCode: response.statusCode);
      }

      if (response.statusCode == 401) {
        await logout();
        return ApiResponse.error(
          'Token abgelaufen. Bitte neu anmelden.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode == 403) {
        return ApiResponse.error(
          'Keine Admin-Berechtigung. Token ist ungültig.',
          statusCode: response.statusCode,
        );
      }

      return _handleErrorResponse(response);
    } catch (e) {
      return ApiResponse.error('Fehler beim Löschen des Gegenstands: $e');
    }
  }

  @override
  Future<ApiResponse<String?>> uploadItemImageBytes(
    int itemId,
    Uint8List imageBytes,
    String filename,
  ) async {
    try {
      final token = await tokenStorage.getToken();
      if (token == null) {
        return ApiResponse.error('Nicht authentifiziert');
      }

      // Create upload URL
      var uploadUrl = Uri.parse('$baseUrl/items/$itemId/image');

      // Create a multipart request
      var request = http.MultipartRequest('POST', uploadUrl);

      // Add authorization
      request.headers['Authorization'] = 'Bearer $token';

      // Add the file bytes to the request
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: filename,
          contentType: _getContentType(filename),
        ),
      );

      // Send the request
      var streamedResponse = await httpClient.send(request);
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ApiResponse.success(
          jsonData['imageUrl'],
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          'Fehler beim Hochladen des Bildes: ${response.statusCode} ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      _log('Image upload failed: $e');
      return ApiResponse.error('Fehler beim Hochladen des Bildes: $e');
    }
  }

  // MARK: - Helper Methods

  Future<Map<String, String>> _getAdminHeaders() async {
    final token = await tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Kein Admin-Token verfügbar');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  ApiResponse<T> _handleErrorResponse<T>(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final message =
          body['message'] ?? _getDefaultErrorMessage(response.statusCode);
      return ApiResponse.error(message, statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.error(
        _getDefaultErrorMessage(response.statusCode),
        statusCode: response.statusCode,
      );
    }
  }

  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Ungültige Anfrage';
      case 401:
        return 'Nicht authentifiziert';
      case 403:
        return 'Keine Berechtigung';
      case 404:
        return 'Nicht gefunden';
      case 500:
        return 'Server-Fehler';
      default:
        return 'Fehler $statusCode';
    }
  }

  /// Helper method to determine content type based on file extension
  MediaType _getContentType(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      default:
        return MediaType('image', 'jpeg'); // Default to JPEG
    }
  }
}
