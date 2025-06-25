import 'package:kreisel_frontend/models/item_model.dart';
import 'package:kreisel_frontend/models/user_model.dart';

class Rental {
  final int id;
  final Item item; // Changed from itemId to Item object
  final User user; // Changed from userId to User object
  final DateTime rentalDate;
  final DateTime endDate;
  final DateTime? returnDate;
  final bool extended;
  final String status;

  Rental({
    required this.id,
    required this.item,
    required this.user,
    required this.rentalDate,
    required this.endDate,
    this.returnDate,
    this.extended = false,
    String? status,
  }) : status = status ?? _calculateStatus(endDate, returnDate);

  static String _calculateStatus(DateTime endDate, DateTime? returnDate) {
    if (returnDate != null) return 'RETURNED';
    return endDate.isBefore(DateTime.now()) ? 'OVERDUE' : 'ACTIVE';
  }

  factory Rental.fromJson(Map<String, dynamic> json) {
    try {
      print('DEBUG: Parsing rental JSON: $json');

      // Handle both direct IDs and nested objects
      final userData = json['user'];
      print('DEBUG: User data from rental: $userData');

      final user =
          userData != null
              ? User.fromJson(userData)
              : User(
                userId: json['userId'] ?? 0,
                email: json['userEmail'] ?? '',
                fullName: json['userFullName'] ?? '',
                role: json['userRole'] ?? 'USER',
              );

      print(
        'DEBUG: Created user object with fullName: ${user.fullName}, email: ${user.email}',
      );

      final item =
          json['item'] != null
              ? Item.fromJson(json['item'])
              : Item(
                id: json['itemId'] ?? 0,
                name: json['itemName'] ?? '',
                available: true,
                location: json['location'] ?? '',
                gender: json['gender'] ?? '',
                category: json['category'] ?? '',
                subcategory: json['subcategory'] ?? '',
                zustand:
                    json['zustand'] ??
                    'GEBRAUCHT', // Updated to match backend enum
              );

      return Rental(
        id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
        item: item,
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
      print('Error parsing rental: $e');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'item': item.toJson(), // Convert Item to JSON
    'user': user.toJson(), // Convert User to JSON
    'rentalDate': rentalDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    if (returnDate != null) 'returnDate': returnDate!.toIso8601String(),
    'extended': extended,
    'status': status,
  };

  // Helper getters for compatibility
  int get itemId => item.id;
  int get userId => user.userId; // Fixed to access userId instead of id
}
