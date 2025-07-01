import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kreisel_frontend/models/rental_model.dart';
import 'package:kreisel_frontend/services/api_service.dart';

// Abstract interface for external dependencies - enables testing
abstract class ReviewDialogDependencies {
  Future<void> submitReview({
    required int rentalId,
    required int rating,
    String? comment,
  });
  
  void showErrorDialog(BuildContext context, String message);
  void closeDialog(BuildContext context, VoidCallback onSuccess);
}

// Production implementation using real services
class ProductionReviewDependencies implements ReviewDialogDependencies {
  @override
  Future<void> submitReview({
    required int rentalId,
    required int rating,
    String? comment,
  }) {
    return ApiService.createReview(
      rentalId: rentalId,
      rating: rating,
      comment: comment,
    );
  }

  @override
  void showErrorDialog(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Fehler'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  void closeDialog(BuildContext context, VoidCallback onSuccess) {
    Navigator.pop(context);
    onSuccess();
  }
}

class CreateReviewDialog extends StatefulWidget {
  final Rental rental;
  final Function() onReviewSubmitted;
  final ReviewDialogDependencies? dependencies; // Optional injection for testing

  const CreateReviewDialog({
    super.key,
    required this.rental,
    required this.onReviewSubmitted,
    this.dependencies, // Hidden from normal usage
  });

  @override
  _CreateReviewDialogState createState() => _CreateReviewDialogState();
}

class _CreateReviewDialogState extends State<CreateReviewDialog> {
  int _selectedRating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  
  // Use injected dependencies or default to production implementation
  late final ReviewDialogDependencies _deps;

  @override
  void initState() {
    super.initState();
    _deps = widget.dependencies ?? ProductionReviewDependencies();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Validation logic - extracted for testability
  @visibleForTesting
  String? validateRating(int rating) {
    if (rating < 1 || rating > 5) {
      return 'Bitte wählen Sie eine Bewertung zwischen 1 und 5 Sternen.';
    }
    return null;
  }

  // Comment processing - extracted for testability
  @visibleForTesting
  String? processComment(String comment) {
    final trimmed = comment.trim();
    return trimmed.isNotEmpty ? trimmed : null;
  }

  // Rating update - extracted for testability
  @visibleForTesting
  void updateRating(int newRating) {
    if (mounted) {
      setState(() {
        _selectedRating = newRating;
      });
    }
  }

  // Main submission logic
  Future<void> _submitReview() async {
    // Validate rating
    final validationError = validateRating(_selectedRating);
    if (validationError != null) {
      if (mounted) {
        _deps.showErrorDialog(context, validationError);
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      final processedComment = processComment(_commentController.text);
      
      await _deps.submitReview(
        rentalId: widget.rental.id,
        rating: _selectedRating,
        comment: processedComment,
      );

      if (mounted) {
        _deps.closeDialog(context, widget.onReviewSubmitted);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _deps.showErrorDialog(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Bewertung abgeben'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            widget.rental.item.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),

          // Star rating
          Wrap(
            alignment: WrapAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                key: Key('star_button_$index'),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(),
                iconSize: 32,
                icon: Icon(
                  index < _selectedRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () => updateRating(index + 1),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Comment field (Material widget inside Cupertino dialog)
          Material(
            color: Colors.transparent,
            child: TextField(
              key: const Key('comment_field'),
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Kommentar (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          key: const Key('cancel_button'),
          child: const Text('Abbrechen'),
          onPressed: () => Navigator.pop(context),
        ),
        CupertinoDialogAction(
          key: const Key('submit_button'),
          isDefaultAction: true,
          onPressed: _isSubmitting ? null : _submitReview,
          child: _isSubmitting
              ? const CupertinoActivityIndicator()
              : const Text('Bewertung absenden'),
        ),
      ],
    );
  }
}