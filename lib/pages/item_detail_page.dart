import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kreisel_frontend/models/item_model.dart';
import 'package:kreisel_frontend/models/review_model.dart';
import 'package:kreisel_frontend/services/api_service.dart';

class ItemDetailPage extends StatefulWidget {
  final Item item;

  const ItemDetailPage({super.key, required this.item});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  bool _isLoadingReviews = false;
  List<Review> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (widget.item.reviewCount == 0) return; // Skip if no reviews

    setState(() => _isLoadingReviews = true);

    try {
      final reviews = await ApiService.getReviewsForItem(widget.item.id);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      print('ERROR: Failed to load reviews - $e');
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Icon(CupertinoIcons.back, color: Color(0xFF007AFF)),
                  ),
                  Expanded(
                    child: Text(
                      widget.item.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Item details
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Image - now square and centered
                    _buildItemImage(),

                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Availability badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  widget.item.available
                                      ? Color(0xFF32D74B)
                                      : Color(0xFFFF453A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.item.available
                                  ? 'Verfügbar'
                                  : 'Ausgeliehen',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: 24),

                          // Rating display if available
                          if (widget.item.reviewCount > 0) ...[
                            Row(
                              children: [
                                _buildStarRating(widget.item.averageRating),
                                SizedBox(width: 8),
                                Text(
                                  '${widget.item.averageRating.toStringAsFixed(1)} (${widget.item.reviewCount})',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                          ],

                          // Brand
                          if (widget.item.brand != null &&
                              widget.item.brand!.isNotEmpty) ...[
                            Text(
                              'Marke',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              widget.item.brand!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 16),
                          ],

                          // Size
                          if (widget.item.size != null &&
                              widget.item.size!.isNotEmpty) ...[
                            Text(
                              'Größe',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              widget.item.size!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 16),
                          ],

                          // Description
                          if (widget.item.description != null &&
                              widget.item.description!.isNotEmpty) ...[
                            Text(
                              'Beschreibung',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              widget.item.description!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 16),
                          ],

                          // Categories
                          Text(
                            'Kategorien',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (widget.item.gender != null &&
                                  widget.item.gender!.isNotEmpty)
                                _buildDetailChip(widget.item.gender!),
                              if (widget.item.category != null &&
                                  widget.item.category!.isNotEmpty)
                                _buildDetailChip(widget.item.category!),
                              if (widget.item.subcategory != null &&
                                  widget.item.subcategory!.isNotEmpty)
                                _buildDetailChip(widget.item.subcategory!),
                              if (widget.item.zustand != null &&
                                  widget.item.zustand!.isNotEmpty)
                                _buildDetailChip(widget.item.zustand!),
                            ],
                          ),

                          // Location
                          if (widget.item.location != null &&
                              widget.item.location!.isNotEmpty) ...[
                            SizedBox(height: 16),
                            Text(
                              'Standort',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _formatLocation(widget.item.location!),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],

                          // Reviews section
                          if (widget.item.reviewCount > 0) ...[
                            SizedBox(height: 32),
                            Text(
                              'Bewertungen',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            _buildReviewsSection(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    if (_isLoadingReviews) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'Keine Bewertungen vorhanden',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _reviews.map((review) => _buildReviewCard(review)).toList(),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.username ?? 'Anonymous User',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                review.formattedDate,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          SizedBox(height: 8),
          _buildStarRating(review.rating.toDouble()),

          if (review.comment != null && review.comment!.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(review.comment!, style: TextStyle(color: Colors.white70)),
          ],
        ],
      ),
    );
  }

  Widget _buildItemImage() {
    if (widget.item.imageUrl == null || widget.item.imageUrl!.isEmpty) {
      // If no image, show placeholder in square format
      return Center(
        child: Container(
          width: 280,
          height: 280,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
              SizedBox(height: 8),
              Text('Kein Bild verfügbar', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Show image in square format with rounded corners
    return Center(
      child: Container(
        width: 280,
        height: 280,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background color while loading
              Container(color: Color(0xFF1C1C1E)),

              // Actual image with error handling
              Image.network(
                widget.item.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;

                  // Show loading indicator while image loads
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF007AFF),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('ERROR loading image: $error');

                  // Show error widget
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 60, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Fehler beim Laden des Bildes',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatLabel(label),
        style: TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }

  String _formatLabel(String label) {
    // Convert "EQUIPMENT" to "Equipment" for better display
    if (label.isEmpty) return '';

    // Handle all uppercase words
    if (label == label.toUpperCase()) {
      return label.substring(0, 1) + label.substring(1).toLowerCase();
    }

    return label;
  }

  String _formatLocation(String location) {
    // Format locations like "PASING" to readable "Pasing"
    switch (location.toUpperCase()) {
      case 'PASING':
        return 'Pasing';
      case 'KARLSTRASSE':
        return 'Karlstraße';
      case 'LOTHSTRASSE':
        return 'Lothstraße';
      default:
        return _formatLabel(location);
    }
  }

  Widget _buildStarRating(double rating) {
    int roundedRating = rating.round(); // Rundet korrekt: 3.1 → 3, 3.7 → 4
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < roundedRating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }
}
