import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kreisel_frontend/models/rental_model.dart';
import 'package:kreisel_frontend/services/api_service.dart';
import 'package:kreisel_frontend/widgets/create_review_dialog.dart';

// Abstract interface für Dependency Injection
abstract class RentalsApiService {
  Future<List<Rental>> getUserActiveRentals();
  Future<List<Rental>> getUserRentalHistory();
  Future<void> returnRental(int rentalId);
  Future<void> extendRental({required int rentalId, required DateTime newEndDate});
}

// Konkrete Implementierung
class DefaultRentalsApiService implements RentalsApiService {
  @override
  Future<List<Rental>> getUserActiveRentals() => ApiService.getUserActiveRentals();
  
  @override
  Future<List<Rental>> getUserRentalHistory() => ApiService.getUserRentalHistory();
  
  @override
  Future<void> returnRental(int rentalId) => ApiService.returnRental(rentalId);
  
  @override
  Future<void> extendRental({required int rentalId, required DateTime newEndDate}) =>
      ApiService.extendRental(rentalId: rentalId, newEndDate: newEndDate);
}

class MyRentalsPage extends StatefulWidget {
  final RentalsApiService? apiService; // Für Tests injectable
  
  const MyRentalsPage({super.key, this.apiService});

  @override
  MyRentalsPageState createState() => MyRentalsPageState();
}

class MyRentalsPageState extends State<MyRentalsPage> {
  List<Rental> _activeRentals = [];
  List<Rental> _pastRentals = [];
  bool _isLoading = true;
  
  // Getter für API Service (testbar)
  RentalsApiService get apiService => widget.apiService ?? DefaultRentalsApiService();

  @override
  void initState() {
    super.initState();
    loadRentals();
  }

  // Public für Tests
  Future<void> loadRentals() async {
    try {
      setState(() => _isLoading = true);
      final activeRentals = await apiService.getUserActiveRentals();
      final historicalRentals = await apiService.getUserRentalHistory();

      if (mounted) {
        setState(() {
          _activeRentals = activeRentals;
          _pastRentals = historicalRentals;
          _isLoading = false;
        });
        debugRentals();
      }
    } catch (e) {
      print('DEBUG: Error loading rentals: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        showAlert(
          'Fehler',
          'Ausleihen konnten nicht geladen werden: ${e.toString()}',
        );
      }
    }
  }

  // Public für Tests
  void showAlert(String title, String message) {
    if (!mounted) return;
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
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

  // Public für Tests
  Future<void> returnItem(Rental rental) async {
    if (!mounted) return;
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
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
                await apiService.returnRental(rental.id);
                if (mounted) {
                  showAlert('Erfolgreich', 'Item wurde zurückgegeben!');
                  loadRentals();
                }
              } catch (e) {
                if (mounted) {
                  showAlert(
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

  // Public für Tests
  void showReviewDialog(Rental rental) {
    if (!mounted) return;
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CreateReviewDialog(
        rental: rental,
        onReviewSubmitted: () {
          loadRentals();
          showAlert(
            'Vielen Dank!',
            'Ihre Bewertung wurde erfolgreich gespeichert.',
          );
        },
      ),
    );
  }

  // Public für Tests
  Future<void> extendRental(Rental rental) async {
    if (!mounted) return;
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
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
              'Neues Rückgabedatum: ${formatDate(rental.endDate.add(const Duration(days: 30)))}',
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
                final newEndDate = rental.endDate.add(const Duration(days: 30));
                await apiService.extendRental(
                  rentalId: rental.id,
                  newEndDate: newEndDate,
                );

                if (mounted) {
                  showAlert(
                    'Erfolgreich',
                    'Ausleihe wurde um einen Monat verlängert!',
                  );
                  loadRentals();
                }
              } catch (e) {
                if (mounted) {
                  showAlert(
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

  // Public für Tests
  void debugRentals() {
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

  // Public für Tests
  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // Public für Tests
  Widget buildEmptyState(String text) {
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

  // Public für Tests
  Widget buildActiveRentalCard(Rental rental) {
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
            'Rückgabe: ${formatDate(rental.endDate)}',
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
                  onPressed: () => extendRental(rental),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.red,
                  child: const Text('Zurückgeben'),
                  onPressed: () => returnItem(rental),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Public für Tests
  Widget buildPastRentalCard(Rental rental) {
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
            'Ausgeliehen: ${formatDate(rental.rentalDate)}',
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            'Zurückgegeben: ${rental.returnDate != null ? formatDate(rental.returnDate!) : 'N/A'}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: const Color(0xFF5856D6),
              child: const Text('Bewerten'),
              onPressed: () => showReviewDialog(rental),
            ),
          ),
        ],
      ),
    );
  }

  // Getters für Tests
  List<Rental> get activeRentals => _activeRentals;
  List<Rental> get pastRentals => _pastRentals;
  bool get isLoading => _isLoading;

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
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : RefreshIndicator(
                onRefresh: loadRentals,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        buildEmptyState('Keine aktiven Ausleihen')
                      else
                        ..._activeRentals.map(
                          (rental) => buildActiveRentalCard(rental),
                        ),
                      const SizedBox(height: 32),
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
                        buildEmptyState('Keine vergangenen Ausleihen')
                      else
                        ..._pastRentals.map(
                          (rental) => buildPastRentalCard(rental),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}