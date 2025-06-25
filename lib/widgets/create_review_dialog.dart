import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kreisel_frontend/models/rental_model.dart';
import 'package:kreisel_frontend/services/api_service.dart';

class CreateReviewDialog extends StatefulWidget {
  final Rental rental;
  final Function() onReviewSubmitted;

  const CreateReviewDialog({
    super.key,
    required this.rental,
    required this.onReviewSubmitted,
  });

  @override
  _CreateReviewDialogState createState() => _CreateReviewDialogState();
}

class _CreateReviewDialogState extends State<CreateReviewDialog> {
  int _selectedRating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_selectedRating < 1 || _selectedRating > 5) {
      _showError('Bitte wählen Sie eine Bewertung zwischen 1 und 5 Sternen.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ApiService.createReview(
        rentalId: widget.rental.id,
        rating: _selectedRating,
        comment:
            _commentController.text.trim().isNotEmpty
                ? _commentController.text.trim()
                : null,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onReviewSubmitted();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError(e.toString());
      }
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
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
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(),
                iconSize: 32,
                icon: Icon(
                  index < _selectedRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () {
                  setState(() {
                    _selectedRating = index + 1;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 16),

          // Comment field (Material widget inside Cupertino dialog)
          Material(
            color: Colors.transparent,
            child: TextField(
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
          child: const Text('Abbrechen'),
          onPressed: () => Navigator.pop(context),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _isSubmitting ? null : _submitReview,
          child:
              _isSubmitting
                  ? const CupertinoActivityIndicator()
                  : const Text('Bewertung absenden'),
        ),
      ],
    );
  }
}
