import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kreisel_frontend/models/rental_model.dart';
import 'package:kreisel_frontend/services/api_service.dart';
import 'package:kreisel_frontend/widgets/create_review_dialog.dart';

class MyRentalsPage extends StatefulWidget {
  const MyRentalsPage({super.key});

  @override
  _MyRentalsPageState createState() => _MyRentalsPageState();
}

class _MyRentalsPageState extends State<MyRentalsPage> {
  List<Rental> _activeRentals = [];
  List<Rental> _pastRentals = [];
  bool _isLoading = true;

  void _showAlert(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text(title),
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
  void initState() {
    super.initState();
    _loadRentals();
  }

  Future<void> _loadRentals() async {
    try {
      setState(() => _isLoading = true);
      final activeRentals = await ApiService.getUserActiveRentals();
      final historicalRentals = await ApiService.getUserRentalHistory();

      if (mounted) {
        setState(() {
          _activeRentals = activeRentals;
          _pastRentals = historicalRentals;
          _isLoading = false;
        });
        _debugRentals();
      }
    } catch (e) {
      print('DEBUG: Error loading rentals: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showAlert(
          'Fehler',
          'Ausleihen konnten nicht geladen werden: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _returnItem(Rental rental) async {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Item zurückgeben'),
            content: Text(
              'Möchten Sie ${rental.item.name} wirklich zurückgeben?',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Abbrechen'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Zurückgeben'),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ApiService.returnRental(rental.id);
                    if (mounted) {
                      _showAlert('Erfolgreich', 'Item wurde zurückgegeben!');
                      _loadRentals();
                    }
                  } catch (e) {
                    if (mounted) {
                      _showAlert(
                        'Fehler',
                        'Rückgabe fehlgeschlagen: ${e.toString()}',
                      );
                    }
                  }
                },
              ),
            ],
          ),
    );
  }

  void _showReviewDialog(Rental rental) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CreateReviewDialog(
            rental: rental,
            onReviewSubmitted: () {
              _loadRentals();
              _showAlert(
                'Vielen Dank!',
                'Ihre Bewertung wurde erfolgreich gespeichert.',
              );
            },
          ),
    );
  }

  Future<void> _extendRental(Rental rental) async {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Ausleihe verlängern'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(rental.item.name),
                const SizedBox(height: 8),
                const Text('Die Ausleihe wird um einen Monat verlängert.'),
                const SizedBox(height: 8),
                Text(
                  'Neues Rückgabedatum: ${_formatDate(rental.endDate.add(const Duration(days: 30)))}',
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Abbrechen'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                child: const Text('Verlängern'),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    // Extend by exactly 30 days
                    final newEndDate = rental.endDate.add(
                      const Duration(days: 30),
                    );
                    await ApiService.extendRental(
                      rentalId: rental.id,
                      newEndDate: newEndDate,
                    );

                    if (mounted) {
                      _showAlert(
                        'Erfolgreich',
                        'Ausleihe wurde um einen Monat verlängert!',
                      );
                      _loadRentals();
                    }
                  } catch (e) {
                    if (mounted) {
                      _showAlert(
                        'Fehler',
                        'Verlängerung fehlgeschlagen: ${e.toString()}',
                      );
                    }
                  }
                },
              ),
            ],
          ),
    );
  }

  void _debugRentals() {
    print('DEBUG: ---- Rental Debug Info ----');
    print('Active rentals: ${_activeRentals.length}');
    for (var rental in _activeRentals) {
      print('Active: ${rental.item.name} - Status: ${rental.status}');
    }
    print('Past rentals: ${_pastRentals.length}');
    for (var rental in _pastRentals) {
      print('Past: ${rental.item.name} - Returned: ${rental.returnDate}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Meine Ausleihen',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : RefreshIndicator(
                  onRefresh: _loadRentals,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Aktuelle Ausleihen
                        Text(
                          'Aktuelle Ausleihen (${_activeRentals.length})',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_activeRentals.isEmpty)
                          _buildEmptyState('Keine aktiven Ausleihen')
                        else
                          ..._activeRentals.map(
                            (rental) => _buildActiveRentalCard(rental),
                          ),

                        const SizedBox(height: 32),

                        // Vergangene Ausleihen
                        Text(
                          'Vergangene Ausleihen (${_pastRentals.length})',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_pastRentals.isEmpty)
                          _buildEmptyState('Keine vergangenen Ausleihen')
                        else
                          ..._pastRentals.map(
                            (rental) => _buildPastRentalCard(rental),
                          ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActiveRentalCard(Rental rental) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rental.item.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Status: ${rental.status}',
            style: TextStyle(
              color: rental.status == 'OVERDUE' ? Colors.red : Colors.grey,
            ),
          ),
          Text(
            'Rückgabe: ${_formatDate(rental.endDate)}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.blue,
                  child: const Text('Verlängern'),
                  onPressed: () => _extendRental(rental),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.red,
                  child: const Text('Zurückgeben'),
                  onPressed: () => _returnItem(rental),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPastRentalCard(Rental rental) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rental.item.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ausgeliehen: ${_formatDate(rental.rentalDate)}',
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            'Zurückgegeben: ${rental.returnDate != null ? _formatDate(rental.returnDate!) : 'N/A'}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: const Color(0xFF5856D6), // Purple color
              child: const Text('Bewerten'),
              onPressed: () => _showReviewDialog(rental),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
