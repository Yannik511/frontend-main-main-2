import 'package:kreisel_frontend/services/api_service.dart'; // Add this import

class Item {
  final int id;
  final String name;
  final String? size;
  final bool available;
  final String? description;
  final String? brand;
  final String? imageUrl;
  final double averageRating;
  final int reviewCount;
  final String? location;
  final String? gender;
  final String? category;
  final String? subcategory;
  final String? zustand;

  Item({
    required this.id,
    required this.name,
    this.size,
    this.available = true,
    this.description,
    this.brand,
    this.imageUrl,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.location,
    this.gender,
    this.category,
    this.subcategory,
    this.zustand,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    // Process image URL to ensure it's complete
    String? processedImageUrl;
    if (json['imageUrl'] != null) {
      processedImageUrl = ApiService.getFullImageUrl(json['imageUrl']);
    }

    return Item(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      size: json['size'],
      available: json['available'] ?? true,
      description: json['description'],
      brand: json['brand'],
      imageUrl: processedImageUrl,
      averageRating: json['averageRating']?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      location: json['location'],
      gender: json['gender'],
      category: json['category'],
      subcategory: json['subcategory'],
      zustand: json['zustand'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'available': available,
      'description': description,
      'brand': brand,
      'imageUrl': imageUrl,
      'location': location,
      'gender': gender,
      'category': category,
      'subcategory': subcategory,
      'zustand': zustand,
    };
  }
}
