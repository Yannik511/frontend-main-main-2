import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kreisel_frontend/models/item_model.dart';
import 'package:kreisel_frontend/services/api_service.dart';

class RentItemDialog extends StatefulWidget {
  final Item item;
  final VoidCallback onRented;

  const RentItemDialog({super.key, required this.item, required this.onRented});

  @override
  _RentItemDialogState createState() => _RentItemDialogState();
}

class _RentItemDialogState extends State<RentItemDialog> {
  int selectedMonths = 1;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final returnDate = _calculateReturnDate();

    return CupertinoAlertDialog(
      title: Text('${widget.item.name} ausleihen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          if (widget.item.brand != null)
            Text(
              'Marke: ${widget.item.brand}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          if (widget.item.size != null)
            Text(
              'Größe: ${widget.item.size}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 16),
          const Text('Ausleihdauer wählen:'),
          const SizedBox(height: 16),
          CupertinoSegmentedControl<int>(
            groupValue: selectedMonths,
            children: const {
              1: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('1 Mnt.'),
              ),
              2: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('2 Mnte.'),
              ),
              3: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('3 Mnte.'),
              ),
            },
            onValueChanged: (int value) {
              setState(() => selectedMonths = value);
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Rückgabedatum: ${_formatDate(returnDate)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
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
          onPressed: isLoading ? null : _rentItem,
          child:
              isLoading
                  ? const CupertinoActivityIndicator()
                  : const Text(
                    'Jetzt ausleihen',
                    style: TextStyle(color: Colors.blue),
                  ),
        ),
      ],
    );
  }

  DateTime _calculateReturnDate() {
    return DateTime.now().add(Duration(days: 30 * selectedMonths));
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _rentItem() async {
    setState(() => isLoading = true);

    try {
      final returnDate = _calculateReturnDate();
      await ApiService.rentItem(itemId: widget.item.id, endDate: returnDate);

      if (!mounted) return;
      Navigator.pop(context);
      widget.onRented();

      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Erfolgreich ausgeliehen'),
              content: Text(
                '${widget.item.name} wurde bis zum ${_formatDate(returnDate)} reserviert.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
    } catch (e) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Fehler beim Ausleihen'),
              content: Text(e.toString()),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}
