import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kreisel_frontend/models/user_model.dart';
import 'package:kreisel_frontend/models/item_model.dart';
import 'package:kreisel_frontend/models/rental_model.dart';
import 'package:kreisel_frontend/models/review_model.dart';
import 'dart:async';

// ===== INTERFACES FÜR TESTABILITY =====

abstract class HttpClientInterface {
  Future<http.Response> get(Uri url, {Map<String, String>? headers});
  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body});
  Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body});
  Future<http.Response> delete(Uri url, {Map<String, String>? headers});
}

abstract class TokenStorageInterface {
  Future<void> saveToken(String token);
  Future<void> saveCookie(String cookie);
  Future<String?> getToken();
  Future<String?> getCookie();
  Future<void> removeTokens();
}

// ===== DEFAULT IMPLEMENTIERUNGEN =====

class RealHttpClient implements HttpClientInterface {
  final http.Client _client = http.Client();

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _client.get(url, headers: headers);
  }

  @override
  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) {
    return _client.post(url, headers: headers, body: body);
  }

  @override
  Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body}) {
    return _client.put(url, headers: headers, body: body);
  }

  @override
  Future<http.Response> delete(Uri url, {Map<String, String>? headers}) {
    return _client.delete(url, headers: headers);
  }
}

class SharedPreferencesTokenStorage implements TokenStorageInterface {
  String? _authToken;
  String? _cookieHeader;

  @override
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    _authToken = token;
  }

  @override
  Future<void> saveCookie(String cookie) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_cookie', cookie);
    _cookieHeader = cookie;
  }

  @override
  Future<String?> getToken() async {
    if (_authToken != null) return _authToken;
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('jwt_token');
    return _authToken;
  }

  @override
  Future<String?> getCookie() async {
    if (_cookieHeader != null) return _cookieHeader;
    final prefs = await SharedPreferences.getInstance();
    _cookieHeader = prefs.getString('jwt_cookie');
    return _cookieHeader;
  }

  @override
  Future<void> removeTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('jwt_cookie');
    _authToken = null;
    _cookieHeader = null;
  }
}

// ===== CORE BUSINESS LOGIC (TESTABLE) =====

class ApiServiceCore {
  final HttpClientInterface httpClient;
  final TokenStorageInterface tokenStorage;
  final String baseUrl;

  User? currentUser;

  ApiServiceCore({
    required this.httpClient,
    required this.tokenStorage,
    this.baseUrl = 'http://localhost:8080/api',
  });

  // Verbesserte Token-Verwaltung
  Future<void> initialize() async {
    try {
      final token = await tokenStorage.getToken();
      if (token != null) {
        final user = await getCurrentUser();
        currentUser = user;
        print('DEBUG: Successfully initialized with user: ${user.email}');
      }
    } catch (e) {
      print('DEBUG: Init error: $e');
      await tokenStorage.removeTokens();
    }
  }

  // ignore: unused_element
  Future<Map<String, String>> _getHeaders() async {
    final token = await tokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Verbesserte _getAuthHeaders mit mehr Logging
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await tokenStorage.getToken();
    final cookie = await tokenStorage.getCookie();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      print('DEBUG: Added Authorization header');
    }

    if (cookie != null) {
      headers['Cookie'] = cookie;
      print('DEBUG: Added Cookie header');
    }

    if (token == null && cookie == null) {
      print('DEBUG: WARNING - No authentication headers available');
    }

    return headers;
  }

  String? _extractTokenFromCookie(String? setCookieHeader) {
    if (setCookieHeader == null) return null;

    // Parse Set-Cookie header to extract JWT token
    final cookies = setCookieHeader.split(',');
    for (final cookie in cookies) {
      if (cookie.trim().startsWith('jwt=')) {
        final tokenPart = cookie.trim().substring(4); // Remove 'jwt='
        final tokenEnd = tokenPart.indexOf(';');
        return tokenEnd != -1 ? tokenPart.substring(0, tokenEnd) : tokenPart;
      }
    }
    return null;
  }

  Future<User> login(String email, String password) async {
    final response = await httpClient.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    print('Login Response Status: ${response.statusCode}');
    print('Login Response Body: ${response.body}');
    print('Login Response Headers: ${response.headers}');

    if (response.statusCode == 200) {
      try {
        final responseData = jsonDecode(response.body);

        if (responseData == null) {
          throw Exception('Server returned null data');
        }

        // Extract token from response body
        if (responseData['token'] != null) {
          await tokenStorage.saveToken(responseData['token']);
        }

        // Extract cookie from headers
        final setCookieHeader = response.headers['set-cookie'];
        if (setCookieHeader != null) {
          await tokenStorage.saveCookie(setCookieHeader);
          // Also try to extract token from cookie if not in body
          if (responseData['token'] == null) {
            final cookieToken = _extractTokenFromCookie(setCookieHeader);
            if (cookieToken != null) {
              await tokenStorage.saveToken(cookieToken);
            }
          }
        }

        // Parse user data - FIXED: Handle flat response structure
        if (responseData['userId'] != null) {
          // Create user object from flat response
          final userMap = {
            'userId': responseData['userId'],
            'email': responseData['email'],
            'fullName': responseData['fullName'],
            'role': responseData['role'],
          };
          currentUser = User.fromJson(userMap);
        } else if (responseData['user'] != null) {
          // Handle nested response structure (fallback)
          currentUser = User.fromJson(responseData['user']);
        } else {
          throw Exception('User data not found in response');
        }

        return currentUser!;
      } catch (e) {
        print('Login Parse Error: $e');
        throw Exception('Failed to parse login response: $e');
      }
    } else {
      throw _handleError(response);
    }
  }

  Future<User> register(String fullName, String email, String password) async {
    final response = await httpClient.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
      }),
    );

    print('Register Response Status: ${response.statusCode}');
    print('Register Response Body: ${response.body}');
    print('Register Response Headers: ${response.headers}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isEmpty) {
        throw Exception('Server returned empty response');
      }

      try {
        final responseData = jsonDecode(response.body);

        if (responseData == null) {
          throw Exception('Server returned null data');
        }

        // Extract token from response body
        if (responseData['token'] != null) {
          await tokenStorage.saveToken(responseData['token']);
        }

        // Extract cookie from headers
        final setCookieHeader = response.headers['set-cookie'];
        if (setCookieHeader != null) {
          await tokenStorage.saveCookie(setCookieHeader);
          // Also try to extract token from cookie if not in body
          if (responseData['token'] == null) {
            final cookieToken = _extractTokenFromCookie(setCookieHeader);
            if (cookieToken != null) {
              await tokenStorage.saveToken(cookieToken);
            }
          }
        }

        // Parse user data - FIXED: Handle flat response structure
        if (responseData['userId'] != null) {
          // Create user object from flat response
          final userMap = {
            'userId': responseData['userId'],
            'email': responseData['email'],
            'fullName': responseData['fullName'],
            'role': responseData['role'],
          };
          currentUser = User.fromJson(userMap);
        } else if (responseData['user'] != null) {
          // Handle nested response structure (fallback)
          currentUser = User.fromJson(responseData['user']);
        } else {
          throw Exception('User data not found in response');
        }

        return currentUser!;
      } catch (e) {
        print('Register Parse Error: $e');
        throw Exception('Failed to parse register response: $e');
      }
    } else {
      throw _handleError(response);
    }
  }

  Future<void> logout() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await httpClient.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: headers,
      );

      print('Logout Response Status: ${response.statusCode}');
      print('Logout Response Body: ${response.body}');
    } catch (e) {
      print('Logout Error: $e');
    } finally {
      await tokenStorage.removeTokens();
      currentUser = null;
    }
  }

  // User Methods
  Future<User> getCurrentUser() async {
    try {
      print('DEBUG: === Getting current user data ===');

      if (currentUser != null) {
        print('DEBUG: Using cached user');
        return currentUser!;
      }

      final token = await tokenStorage.getToken();
      final cookie = await tokenStorage.getCookie();

      if (token == null && cookie == null) {
        throw Exception('Nicht angemeldet');
      }

      final response = await httpClient
          .get(Uri.parse('$baseUrl/users/me'), headers: await _getAuthHeaders())
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        currentUser = User.fromJson(userData);
        return currentUser!;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        await tokenStorage.removeTokens();
        throw Exception('Session abgelaufen');
      }

      throw Exception('Fehler beim Laden (${response.statusCode})');
    } catch (e) {
      print('DEBUG: Error: $e');
      if (e.toString().contains('Session abgelaufen')) rethrow;
      throw Exception('Verbindungsfehler: $e');
    }
  }

  Future<User> updateUserName(String newName) async {
    if (currentUser == null) {
      throw Exception('Nicht angemeldet');
    }

    try {
      final response = await httpClient.put(
        Uri.parse('$baseUrl/users/me/name'),
        headers: {
          ...await _getAuthHeaders(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fullName': newName.trim()}),
      );

      print('DEBUG: Update name response: ${response.statusCode}');

      switch (response.statusCode) {
        case 200:
          final userData = jsonDecode(response.body);
          currentUser = User.fromJson(userData);
          return currentUser!;
        case 400:
          throw Exception('Ungültiger Name');
        case 401:
          throw Exception('Sitzung abgelaufen');
        default:
          throw Exception('Server-Fehler (${response.statusCode})');
      }
    } catch (e) {
      print('DEBUG: Update name error: $e');
      rethrow;
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    final headers = await _getAuthHeaders();
    final response = await httpClient.put(
      Uri.parse('$baseUrl/users/me/password'),
      headers: headers,
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    print('Update Password Response Status: ${response.statusCode}');
    print('Update Password Response Body: ${response.body}');

    if (response.statusCode == 200) {
      // Password updated successfully
      return;
    } else if (response.statusCode == 400) {
      // Bad request - could be wrong current password or validation error
      throw Exception(
        'Aktuelles Passwort ist falsch oder neues Passwort ist ungültig',
      );
    } else {
      throw _handleError(response);
    }
  }

  // Item Methods
  Future<List<Item>> getItems({required String location}) async {
    try {
      print('DEBUG: Fetching items from API for location: $location');

      // Standardize location format
      final standardizedLocation = location.toUpperCase().trim();
      print('DEBUG: Standardized location: $standardizedLocation');

      final response = await httpClient.get(
        Uri.parse('$baseUrl/items?location=$standardizedLocation'),
        headers: await _getAuthHeaders(),
      );

      print('DEBUG: API Response Status: ${response.statusCode}');
      print('DEBUG: API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final items = data.map((json) => Item.fromJson(json)).toList();
        print('DEBUG: Successfully loaded ${items.length} items');
        return items;
      } else {
        print('DEBUG: Error response from API: ${response.statusCode}');
        throw _handleError(response);
      }
    } catch (e) {
      print('DEBUG: Error fetching items: $e');
      rethrow;
    }
  }

  Future<Item> getItemById(int itemId) async {
    final headers = await _getAuthHeaders();
    final response = await httpClient.get(
      Uri.parse('$baseUrl/items/$itemId'),
      headers: headers,
    );

    print('Get Item By ID Response Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      try {
        return Item.fromJson(jsonDecode(response.body));
      } catch (e) {
        print('Parse Item Error: $e');
        throw Exception('Failed to parse item: $e');
      }
    } else {
      throw _handleError(response);
    }
  }

  // Rental Methods
  Future<List<Rental>> getUserActiveRentals() async {
    try {
      print('DEBUG: Fetching active rentals');

      if (currentUser == null) {
        print('DEBUG: No current user found');
        throw Exception('Nicht angemeldet');
      }

      print('DEBUG: Current user ID: ${currentUser!.userId}');

      final headers = await _getAuthHeaders();
      print('DEBUG: Request headers: $headers');

      // Changed endpoint to match backend controller
      final response = await httpClient.get(
        Uri.parse('$baseUrl/rentals/user/active'),
        headers: headers,
      );

      print('DEBUG: Active Rentals Response Status: ${response.statusCode}');
      print('DEBUG: Active Rentals Response Headers: ${response.headers}');
      print('DEBUG: Active Rentals Response Body: ${response.body}');

      if (response.statusCode == 401 || response.statusCode == 403) {
        print('DEBUG: Authentication error - clearing token');
        await tokenStorage.removeTokens();
        throw Exception('Bitte erneut anmelden');
      }

      if (response.statusCode != 200) {
        throw _handleError(response);
      }

      final List<dynamic> rentalsJson = jsonDecode(response.body);
      print('DEBUG: Found ${rentalsJson.length} active rentals');

      // Return empty list if no rentals found
      if (rentalsJson.isEmpty) {
        print('DEBUG: No active rentals found');
        return [];
      }

      try {
        final rentals = _parseRentals(rentalsJson);
        print('DEBUG: Successfully parsed ${rentals.length} rentals');
        return rentals;
      } catch (e) {
        print('DEBUG: Error parsing rentals: $e');
        rethrow;
      }
    } catch (e) {
      print('DEBUG: Error getting active rentals: $e');
      print('DEBUG: Stack trace: ${StackTrace.current}');
      throw Exception('Fehler beim Laden der aktiven Ausleihen: $e');
    }
  }

  Future<List<Rental>> getUserRentalHistory() async {
    try {
      print('DEBUG: Fetching rental history');

      if (currentUser == null) {
        throw Exception('Nicht angemeldet');
      }

      final headers = await _getAuthHeaders();
      // Changed endpoint to match backend controller
      final response = await httpClient.get(
        Uri.parse('$baseUrl/rentals/user/history'),
        headers: headers,
      );

      print('DEBUG: Get Rental History Status: ${response.statusCode}');
      print('DEBUG: Get Rental History Body: ${response.body}');

      if (response.statusCode == 401 || response.statusCode == 403) {
        await tokenStorage.removeTokens();
        throw Exception('Bitte erneut anmelden');
      }

      if (response.statusCode != 200) {
        throw _handleError(response);
      }

      final List<dynamic> rentalsJson = jsonDecode(response.body);
      print('DEBUG: Parsed JSON array with ${rentalsJson.length} items');

      return _parseRentals(rentalsJson);
    } catch (e) {
      print('DEBUG: Error fetching rentals: $e');
      rethrow;
    }
  }

  // Helper method to parse rentals consistently
  List<Rental> _parseRentals(List<dynamic> rentalsJson) {
    return rentalsJson.map((json) {
      try {
        print('DEBUG: Parsing rental JSON: $json');

        // Ensure required fields exist
        if (json['id'] == null) throw Exception('Missing rental id');
        if (json['item'] == null) throw Exception('Missing item data');

        // Use current user if user data is missing in the rental
        final user =
            json['user'] != null
                ? User.fromJson(json['user'])
                : currentUser!; // Use logged in user if not provided

        return Rental(
          id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
          item: Item.fromJson(json['item']),
          user: user,
          rentalDate: DateTime.parse(json['rentalDate']),
          endDate: DateTime.parse(json['endDate']),
          returnDate:
              json['returnDate'] != null
                  ? DateTime.parse(json['returnDate'])
                  : null,
          extended: json['extended'] ?? false,
          status: json['status'] ?? 'ACTIVE',
        );
      } catch (e) {
        print('DEBUG: Error parsing rental: $e');
        print('DEBUG: Problematic JSON: $json');
        rethrow;
      }
    }).toList();
  }

  Future<void> rentItem({
    required int itemId,
    required DateTime endDate,
  }) async {
    final headers = await _getAuthHeaders();

    // Debug logging für 403 Fehler
    print('DEBUG: Attempting to rent item $itemId');
    print('DEBUG: Current user: ${currentUser?.email}');
    print('DEBUG: Auth headers: $headers');

    // Format date as YYYY-MM-DD (LocalDate format für Backend)
    final formattedDate =
        '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    final requestBody = {
      'itemId':
          itemId
              .toString(), // Als String senden da Backend request.get("itemId") verwendet
      'endDate': formattedDate, // Als LocalDate format: "2024-03-15"
    };

    print('DEBUG: Request body: $requestBody');

    final response = await httpClient.post(
      Uri.parse('$baseUrl/rentals/rent'),
      headers: headers,
      body: jsonEncode(requestBody),
    );

    print('Rent Item Response Status: ${response.statusCode}');
    print('Rent Item Response Body: ${response.body}');

    if (response.statusCode == 403) {
      // Spezielle Behandlung für 403 - könnte Token-Problem sein
      print('DEBUG: 403 Forbidden - checking auth state');
      await tokenStorage.removeTokens();
      throw Exception('Keine Berechtigung. Bitte neu anmelden.');
    }

    if (response.statusCode == 401) {
      // Token abgelaufen
      await tokenStorage.removeTokens();
      throw Exception('Session abgelaufen. Bitte neu anmelden.');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _handleError(response);
    }
  }

  Future<void> extendRental({
    required int rentalId,
    required DateTime newEndDate,
  }) async {
    final headers = await _getAuthHeaders();
    final response = await httpClient.post(
      Uri.parse('$baseUrl/rentals/$rentalId/extend'),
      headers: headers,
      body: jsonEncode({'newEndDate': newEndDate.toIso8601String()}),
    );

    print('Extend Rental Response Status: ${response.statusCode}');
    print('Extend Rental Response Body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _handleError(response);
    }
  }

  Future<void> returnRental(int rentalId) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/rentals/$rentalId/return'),
        headers: await _getAuthHeaders(),
      );

      print('DEBUG: Return rental response: ${response.statusCode}');

      if (response.statusCode != 200) {
        if (response.statusCode == 401 || response.statusCode == 403) {
          await tokenStorage.removeTokens();
          throw Exception('Bitte erneut anmelden');
        }
        throw Exception('Fehler beim Zurückgeben');
      }
    } catch (e) {
      print('DEBUG: Return rental error: $e');
      rethrow;
    }
  }

  /// Converts a relative image URL to a full URL
  String getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }

    // If it already starts with http or https, it's a complete URL
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // Extract base server URL (without /api)
    String serverUrl = baseUrl;
    if (serverUrl.endsWith('/api')) {
      serverUrl = serverUrl.substring(0, serverUrl.length - 4);
    }

    // If it starts with slash, append to server base URL
    if (imageUrl.startsWith('/')) {
      return '$serverUrl$imageUrl';
    }

    // Otherwise append to API URL
    return '$baseUrl/$imageUrl';
  }

  // Verbesserte Fehlerbehandlung
  Exception _handleError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final message = body['message'] ?? 'Unknown error';

      if (response.statusCode == 403) {
        return Exception('Keine Berechtigung. Bitte neu anmelden.');
      }

      return Exception(message);
    } catch (e) {
      return Exception('Server error (${response.statusCode})');
    }
  }

  // ===== REVIEW SERVICE METHODS =====

  /// Creates a review for a completed rental
  Future<Review> createReview({
    required int rentalId,
    required int rating,
    String? comment,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final body = {
        'rating': rating,
        'rentalId': rentalId,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      };

      print('DEBUG: Creating review with data: $body');

      final response = await httpClient.post(
        Uri.parse('$baseUrl/reviews'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('DEBUG: Review creation response: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final reviewData = jsonDecode(response.body);
        return Review.fromMap(reviewData);
      }

      if (response.statusCode == 400) {
        throw Exception(
          'Sie haben dieses Item bereits bewertet oder die Bewertung ist ungültig.',
        );
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        await tokenStorage.removeTokens();
        throw Exception('Bitte erneut anmelden');
      }

      throw Exception('Fehler beim Erstellen der Bewertung');
    } catch (e) {
      print('DEBUG: Error creating review: $e');
      rethrow;
    }
  }

  /// Get reviews for a specific item
  Future<List<Review>> getReviewsForItem(int itemId) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await httpClient.get(
        Uri.parse('$baseUrl/reviews/item/$itemId'),
        headers: headers,
      );

      print('DEBUG: Get reviews response: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('DEBUG: Parsed response type: ${responseData.runtimeType}');

        // Handle different response formats
        if (responseData is List) {
          // If response is already a list of reviews
          return responseData.map((json) => Review.fromMap(json)).toList();
        } else if (responseData is Map) {
          // If response is a JSON object, look for the reviews list inside it
          print(
            'DEBUG: Response is a Map, keys: ${responseData.keys.toList()}',
          );

          // Try to find reviews in common wrapper fields
          if (responseData.containsKey('reviews')) {
            final reviewsList = responseData['reviews'] as List;
            return reviewsList.map((json) => Review.fromMap(json)).toList();
          } else if (responseData.containsKey('data')) {
            final reviewsList = responseData['data'] as List;
            return reviewsList.map((json) => Review.fromMap(json)).toList();
          } else if (responseData.containsKey('content')) {
            final reviewsList = responseData['content'] as List;
            return reviewsList.map((json) => Review.fromMap(json)).toList();
          } else if (responseData.containsKey('items')) {
            final reviewsList = responseData['items'] as List;
            return reviewsList.map((json) => Review.fromMap(json)).toList();
          } else {
            // If it's a single review object, return it as a list with one item
            try {
              // Cast the map to ensure keys are String
              final Map<String, dynamic> typedMap = Map<String, dynamic>.from(
                responseData,
              );
              final review = Review.fromMap(typedMap);
              return [review];
            } catch (e) {
              print('DEBUG: Could not parse as single review: $e');
              return [];
            }
          }
        }

        // Fallback - if we couldn't figure out the structure
        print('DEBUG: Unhandled response structure: $responseData');
        return [];
      }

      if (response.statusCode == 404) {
        return []; // No reviews found
      }

      throw Exception('Fehler beim Laden der Bewertungen');
    } catch (e) {
      print('DEBUG: Error getting reviews: $e');
      rethrow;
    }
  }

  /// Checks if a user has already reviewed a specific rental
  Future<bool> hasUserReviewedRental(int rentalId) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await httpClient.get(
        Uri.parse('$baseUrl/reviews/rental/$rentalId/exists'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['exists'] ?? false;
      }

      return false;
    } catch (e) {
      print('DEBUG: Error checking if rental was reviewed: $e');
      return false;
    }
  }

  /// Get the average rating for an item
  Future<double> getItemAverageRating(int itemId) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await httpClient.get(
        Uri.parse('$baseUrl/reviews/item/$itemId/average'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return (result['averageRating'] ?? 0.0).toDouble();
      }

      return 0.0;
    } catch (e) {
      print('DEBUG: Error getting item average rating: $e');
      return 0.0;
    }
  }

  // Review Methods
  Future<List<Review>> getItemReviews(int itemId) async {
    try {
      print('DEBUG: Fetching reviews for item $itemId');

      final response = await httpClient.get(
        Uri.parse('$baseUrl/reviews/item/$itemId'),
        headers: await _getAuthHeaders(),
      );

      print('DEBUG: Get reviews response: ${response.statusCode}');
      print('DEBUG: Reviews response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic jsonData = jsonDecode(response.body);

        // Handle both array and object responses
        List<dynamic> reviewsJson;
        if (jsonData is Map<String, dynamic>) {
          // If response is an object, look for reviews array within it
          reviewsJson = jsonData['reviews'] ?? [];
        } else if (jsonData is List) {
          // If response is already an array
          reviewsJson = jsonData;
        } else {
          print('DEBUG: Unexpected reviews data format: $jsonData');
          return [];
        }

        print('DEBUG: Found ${reviewsJson.length} reviews to parse');

        // Parse reviews using fromMap instead of fromJson
        final reviews =
            reviewsJson.map((json) => Review.fromMap(json)).toList();
        print('DEBUG: Successfully parsed ${reviews.length} reviews');
        return reviews;
      } else {
        print('DEBUG: Error response from API: ${response.statusCode}');
        throw _handleError(response);
      }
    } catch (e) {
      print('DEBUG: Error getting reviews: $e');
      print('DEBUG: Stack trace: ${StackTrace.current}');
      return []; // Return empty list instead of throwing
    }
  }
}

// ===== BACKWARD COMPATIBLE STATIC API (ORIGINAL INTERFACE) =====

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';
  static User? currentUser;

  // Private core instance - default implementation
  static ApiServiceCore _core = ApiServiceCore(
    httpClient: RealHttpClient(),
    tokenStorage: SharedPreferencesTokenStorage(),
  );

  // ===== TESTABILITY INJECTION POINT =====
  /// Allows injecting dependencies for testing
  /// Call this method in tests to make ApiService testable
  static void configure({
    required HttpClientInterface httpClient,
    required TokenStorageInterface tokenStorage,
    String? baseUrl,
  }) {
    _core = ApiServiceCore(
      httpClient: httpClient,
      tokenStorage: tokenStorage,
      baseUrl: baseUrl ?? ApiService.baseUrl,
    );
  }

  /// Resets to default configuration
  static void resetToDefault() {
    _core = ApiServiceCore(
      httpClient: RealHttpClient(),
      tokenStorage: SharedPreferencesTokenStorage(),
    );
  }

  // ===== ORIGINAL STATIC API (100% BACKWARD COMPATIBLE) =====

  static Future<void> initialize() async {
    await _core.initialize();
    currentUser = _core.currentUser;
  }

  static Future<User> login(String email, String password) async {
    final user = await _core.login(email, password);
    currentUser = user;
    return user;
  }

  static Future<User> register(String fullName, String email, String password) async {
    final user = await _core.register(fullName, email, password);
    currentUser = user;
    return user;
  }

  static Future<void> logout() async {
    await _core.logout();
    currentUser = null;
  }

  static Future<User> getCurrentUser() async {
    final user = await _core.getCurrentUser();
    currentUser = user;
    return user;
  }

  static Future<User> updateUserName(String newName) async {
    final user = await _core.updateUserName(newName);
    currentUser = user;
    return user;
  }

  static Future<void> updatePassword(String currentPassword, String newPassword) async {
    await _core.updatePassword(currentPassword, newPassword);
  }

  static Future<List<Item>> getItems({required String location}) async {
    return await _core.getItems(location: location);
  }

  static Future<Item> getItemById(int itemId) async {
    return await _core.getItemById(itemId);
  }

  static Future<List<Rental>> getUserActiveRentals() async {
    return await _core.getUserActiveRentals();
  }

  static Future<List<Rental>> getUserRentalHistory() async {
    return await _core.getUserRentalHistory();
  }

  static Future<void> rentItem({required int itemId, required DateTime endDate}) async {
    await _core.rentItem(itemId: itemId, endDate: endDate);
  }

  static Future<void> extendRental({required int rentalId, required DateTime newEndDate}) async {
    await _core.extendRental(rentalId: rentalId, newEndDate: newEndDate);
  }

  static Future<void> returnRental(int rentalId) async {
    await _core.returnRental(rentalId);
  }

  static String getFullImageUrl(String? imageUrl) {
    return _core.getFullImageUrl(imageUrl);
  }

  static Future<Review> createReview({required int rentalId, required int rating, String? comment}) async {
    return await _core.createReview(rentalId: rentalId, rating: rating, comment: comment);
  }

  static Future<List<Review>> getReviewsForItem(int itemId) async {
    return await _core.getReviewsForItem(itemId);
  }

  static Future<bool> hasUserReviewedRental(int rentalId) async {
    return await _core.hasUserReviewedRental(rentalId);
  }

  static Future<double> getItemAverageRating(int itemId) async {
    return await _core.getItemAverageRating(itemId);
  }

  static Future<List<Review>> getItemReviews(int itemId) async {
    return await _core.getItemReviews(itemId);
  }
}

// ===== HELPER CLASS FOR AUTH STATE MANAGEMENT (BACKWARD COMPATIBLE) =====

class AuthStateManager {
  static final ValueNotifier<User?> currentUser = ValueNotifier(null);

  static Future<void> initialize() async {
    await ApiService.initialize();
    currentUser.value = ApiService.currentUser;
  }

  static Future<void> login(String email, String password) async {
    try {
      currentUser.value = await ApiService.login(email, password);
    } catch (e) {
      print('Login Auth Error: $e');
      rethrow;
    }
  }

  static Future<void> register(String fullName, String email, String password) async {
    try {
      currentUser.value = await ApiService.register(fullName, email, password);
    } catch (e) {
      print('Register Auth Error: $e');
      rethrow;
    }
  }

  static Future<void> logout() async {
    try {
      await ApiService.logout();
      currentUser.value = null;
    } catch (e) {
      print('Logout Auth Error: $e');
      // Even if logout fails, clear local data
      currentUser.value = null;
    }
  }
}