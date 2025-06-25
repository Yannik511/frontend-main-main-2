import 'package:intl/intl.dart';

class Review {
  final int? id;
  final int itemId;
  final int userId;
  final int rentalId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? username; // For display purposes

  Review({
    this.id,
    required this.itemId,
    required this.userId,
    required this.rentalId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.username,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    // Debug logging to see what fields are coming from API
    print('DEBUG: Review data from API: $map');

    // Extract user data - could be nested or flat
    final userData = map['user'] is Map ? map['user'] : null;

    return Review(
      id: map['id'],
      itemId: map['item'] is Map ? map['item']['id'] : map['itemId'] ?? 0,
      userId: userData?['userId'] ?? map['userId'] ?? 0,
      rentalId:
          map['rental'] is Map ? map['rental']['id'] : map['rentalId'] ?? 0,
      rating: map['rating'] ?? 5,
      // Check multiple possible comment field names
      comment: map['comment'] ?? map['commentText'] ?? map['text'],
      createdAt:
          map['createdAt'] is String
              ? DateTime.parse(map['createdAt'])
              : (map['createdAt'] ?? DateTime.now()),
      username:
          userData?['fullName'] ??
          userData?['username'] ??
          map['username'] ??
          'User',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rentalId': rentalId,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
    };
  }

  String get formattedDate {
    return DateFormat('dd.MM.yyyy').format(createdAt);
  }
}
