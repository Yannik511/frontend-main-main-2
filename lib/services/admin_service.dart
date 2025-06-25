import 'dart:convert';
import 'dart:io'; // Add this import for File class
import 'dart:typed_data'; // Add this import for Uint8List
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kreisel_frontend/models/item_model.dart';
import 'package:kreisel_frontend/models/rental_model.dart';
import 'package:kreisel_frontend/models/user_model.dart';

class AdminService {
  static const String baseUrl = 'http://localhost:8080/api';
  static const String tokenKey = 'admin_token';

  // User Management with better error handling
  static Future<List<User>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: await _getAdminHeaders(),
      );

      print('DEBUG: Get users response: ${response.statusCode}');
      print('DEBUG: Get users body: "${response.body}"');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty) {
          return []; // Return empty list for empty response
        }

        final List<dynamic> data = jsonDecode(responseBody);
        return data.map((json) => User.fromJson(json)).toList();
      }

      throw Exception(_handleError(response));
    } catch (e) {
      print('DEBUG: Error getting users: $e');
      rethrow;
    }
  }

  static Future<User> getUserById(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId'),
      headers: await _getAdminHeaders(),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception(_handleError(response));
  }

  // Rental Management
  // Get all rentals with user details
  static Future<List<Rental>> getAllRentals() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rentals'),
        headers: await _getAdminHeaders(),
      );

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty) {
          return [];
        }

        final List<dynamic> data = jsonDecode(responseBody);
        final rentals = <Rental>[];

        for (var rentalJson in data) {
          if (rentalJson['user'] == null && rentalJson['userId'] != null) {
            try {
              final userResponse = await http.get(
                Uri.parse('$baseUrl/users/${rentalJson['userId']}'),
                headers: await _getAdminHeaders(),
              );

              if (userResponse.statusCode == 200) {
                final userData = jsonDecode(userResponse.body);
                print('DEBUG: Got user data for rental: $userData');
                // Add user data to rental JSON
                rentalJson['user'] = userData;
              }
            } catch (e) {
              print('DEBUG: Error fetching user ${rentalJson['userId']}: $e');
            }
          }

          rentals.add(Rental.fromJson(rentalJson));
        }

        print('DEBUG: Created ${rentals.length} rental objects');
        return rentals;
      }

      throw Exception(_handleError(response));
    } catch (e) {
      print('DEBUG: Error getting rentals: $e');
      rethrow;
    }
  }

  static Future<Rental> getRentalById(int rentalId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/rentals/$rentalId'),
      headers: await _getAdminHeaders(),
    );

    if (response.statusCode == 200) {
      return Rental.fromJson(jsonDecode(response.body));
    }
    throw Exception(_handleError(response));
  }

  // Item Management
  static Future<List<Item>> getAllItems(String location) async {
    try {
      print('DEBUG: Fetching items for location: $location');
      final headers = await _getAdminHeaders();

      final queryParams = {'location': location};
      final uri = Uri.parse(
        '$baseUrl/items',
      ).replace(queryParameters: queryParams);
      print('DEBUG: Request URI: $uri');

      final response = await http.get(uri, headers: headers);

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: "${response.body}"');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty) {
          return [];
        }

        final List<dynamic> data = jsonDecode(responseBody);
        return data.map((json) => Item.fromJson(json)).toList();
      }

      throw Exception(_handleError(response));
    } catch (e) {
      print('DEBUG: Error loading items: $e');
      rethrow;
    }
  }

  static Future<Item> getItemById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/items/$id'),
      headers: await _getAdminHeaders(),
    );

    if (response.statusCode == 200) {
      return Item.fromJson(jsonDecode(response.body));
    }
    throw Exception(_handleError(response));
  }

  static Future<Item> createItem(Item item) async {
    try {
      print('DEBUG: Starting item creation');

      // Use the same headers that work for getting users
      final headers = await _getAdminHeaders();

      print('DEBUG: Using headers: $headers');

      final response = await http.post(
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

      print('DEBUG: Create item response status: ${response.statusCode}');
      print('DEBUG: Create item response body: "${response.body}"');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty) {
          throw Exception('Server hat leere Antwort gesendet');
        }
        return Item.fromJson(jsonDecode(responseBody));
      }

      // Simple error handling
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(
          'Keine ausreichenden Berechtigungen für diese Operation',
        );
      }

      throw Exception(_handleError(response));
    } catch (e) {
      print('DEBUG: Create item error: $e');
      rethrow;
    }
  }

  static Future<Item> updateItem(int id, Item item) async {
    try {
      final token = await _getAdminToken();
      if (token == null || token.isEmpty) {
        throw Exception('Kein Admin-Token verfügbar. Bitte neu anmelden.');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      final response = await http.put(
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

      print('Update Item Response: ${response.statusCode}');
      print('Update Item Body: "${response.body}"');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty) {
          throw Exception('Server hat leere Antwort gesendet');
        }
        return Item.fromJson(jsonDecode(responseBody));
      }

      if (response.statusCode == 401) {
        await logout();
        throw Exception('Token abgelaufen. Bitte neu anmelden.');
      }

      if (response.statusCode == 403) {
        if (response.body.trim().isEmpty) {
          throw Exception(
            'Server-Konfigurationsproblem: Admin-Berechtigung wird nicht erkannt',
          );
        }
        throw Exception('Keine Admin-Berechtigung. Token ist ungültig.');
      }

      throw Exception(_handleError(response));
    } catch (e) {
      print('Update Item Error: $e');
      rethrow;
    }
  }

  static Future<void> deleteItem(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/items/$id'),
      headers: await _getAdminHeaders(),
    );

    if (response.statusCode == 401) {
      await logout();
      throw Exception('Token abgelaufen. Bitte neu anmelden.');
    }

    if (response.statusCode == 403 && response.body.trim().isEmpty) {
      throw Exception(
        'Server-Konfigurationsproblem: Admin-Berechtigung wird nicht erkannt',
      );
    }

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_handleError(response));
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    print('DEBUG: Cleared admin token');
  }

  static Future<bool> ensureAuthenticated() async {
    final isAuth = await isAdminAuthenticated();
    if (!isAuth) {
      await logout();
      return false;
    }
    return true;
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      print('DEBUG: Starting admin login for: $email');
      await logout(); // Clear existing tokens

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('DEBUG: Login response status: ${response.statusCode}');
      print('DEBUG: Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Simply check if user has ADMIN role
        if (data['role'] != 'ADMIN') {
          throw Exception('Keine Admin-Berechtigung');
        }

        // Save token
        final token = data['token'];
        if (token == null) throw Exception('Kein Token erhalten');
        await saveAdminToken(token);

        print('DEBUG: Admin login successful');
        return data;
      }

      throw Exception(_handleError(response));
    } catch (e) {
      print('DEBUG: Admin login error: $e');
      await logout();
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> register(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      print('DEBUG: Starting admin registration for: $email');

      if (!email.startsWith('admin')) {
        throw Exception('Admin-Email muss mit "admin" beginnen');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
        }),
      );

      print('DEBUG: Register response status: ${response.statusCode}');
      print('DEBUG: Register response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Verify admin role
        if (data['role'] != 'ADMIN') {
          throw Exception('Registrierung fehlgeschlagen - Keine Admin-Rolle');
        }

        // Save token
        final token = data['token'];
        if (token == null) throw Exception('Kein Token erhalten');
        await saveAdminToken(token);

        print('DEBUG: Admin registration successful');
        return data;
      }

      throw Exception(_handleError(response));
    } catch (e) {
      print('DEBUG: Admin registration error: $e');
      await logout(); // Clear token on error
      rethrow;
    }
  }

  static Future<void> saveAdminToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    print('DEBUG: Saved admin token');
  }

  static Future<String?> _getAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<Map<String, String>> _getAdminHeaders() async {
    final token = await _getAdminToken();
    if (token == null || token.isEmpty) {
      throw Exception('Kein Admin-Token verfügbar');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  static String _handleError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body['message'] ?? 'Unbekannter Fehler';
    } catch (e) {
      switch (response.statusCode) {
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
          return 'Fehler ${response.statusCode}';
      }
    }
  }

  static Future<bool> isAdminAuthenticated() async {
    try {
      final token = await _getAdminToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      // Test token validity by making a request
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: await _getAdminHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('DEBUG: Auth check error: $e');
      return false;
    }
  }

  // Helper method to check if a token exists
  static Future<bool> hasAdminToken() async {
    final token = await _getAdminToken();
    return token != null && token.isNotEmpty;
  }

  // Helper method to extract cookie from response headers
  static String? _extractCookie(Map<String, String> headers) {
    return headers['set-cookie'];
  }

  // Add this helper method to verify token format
  static bool _isValidTokenFormat(String token) {
    try {
      // Basic JWT format check: should be three dot-separated base64 strings
      final parts = token.split('.');
      if (parts.length != 3) return false;

      // Check if the middle part (payload) can be decoded
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final payloadJson = jsonDecode(payload);

      // Verify essential claims
      return payloadJson['sub'] != null && // Subject (usually user email)
          payloadJson['exp'] != null; // Expiration time
    } catch (e) {
      print('DEBUG: Token format validation failed: $e');
      return false;
    }
  }

  // Add this before creating an item
  static Future<bool> verifyAdminAccess() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: await _getAdminHeaders(),
      );

      print('DEBUG: Admin access check status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('DEBUG: Admin access check failed: $e');
      return false;
    }
  }

  static Future<bool> verifyTokenClaims(String token) async {
    // Basic token format check only
    return token.split('.').length == 3;
  }

  static Future<bool> canCreateItems() async {
    try {
      // If they're logged in as admin, they can create items
      final token = await _getAdminToken();
      return token != null;
    } catch (e) {
      return false;
    }
  }

  // Add this method to your AdminService class
  static Future<String?> uploadItemImage(int itemId, File imageFile) async {
    try {
      final token = await _getAdminToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // FIXED URL - remove duplicate "/api"
      var uploadUrl = Uri.parse('$baseUrl/items/$itemId/image');

      // Create a multipart request
      var request = http.MultipartRequest('POST', uploadUrl);

      // Add authorization
      request.headers['Authorization'] = 'Bearer $token';

      // Get file extension from path
      final String filename = imageFile.path.split('/').last;

      // Add the file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: filename,
        ),
      );

      // Send the request and get the response
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['imageUrl'];
      } else {
        print(
          'Image upload failed: ${response.statusCode} ${response.reasonPhrase}',
        );
        print('Response body: ${response.body}');
        throw Exception('Failed to upload image: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Uploads an image for an item using bytes data and returns the image URL
  ///
  /// [itemId] - The ID of the item to attach the image to
  /// [imageBytes] - The image bytes to upload
  /// [filename] - The filename for the uploaded image
  static Future<String?> uploadItemImageBytes(
    int itemId,
    Uint8List imageBytes,
    String filename,
  ) async {
    try {
      final token = await _getAdminToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      print(
        'DEBUG: Starting image upload for item $itemId with filename: $filename',
      );

      // FIXED URL - remove duplicate "/api"
      var uploadUrl = Uri.parse('$baseUrl/items/$itemId/image');
      print('DEBUG: Upload URL: $uploadUrl');

      // Create a multipart request
      var request = http.MultipartRequest('POST', uploadUrl);

      // Add authorization
      request.headers['Authorization'] = 'Bearer $token';
      print('DEBUG: Using auth header: ${request.headers['Authorization']}');

      // Add the file bytes to the request
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: filename,
          contentType: _getContentType(filename), // Add content type
        ),
      );

      // Send the request and get the response
      print('DEBUG: Sending request...');
      var streamedResponse = await request.send();
      print('DEBUG: Got response status: ${streamedResponse.statusCode}');
      var response = await http.Response.fromStream(streamedResponse);

      print('DEBUG: Image upload response: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['imageUrl'];
      } else {
        print('DEBUG: Image upload failed with status ${response.statusCode}');
        throw Exception(
          'Failed to upload image: ${response.statusCode} ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('ERROR: Image upload failed: $e');
      return null;
    }
  }

  /// Helper method to determine content type based on file extension
  static MediaType _getContentType(String filename) {
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
