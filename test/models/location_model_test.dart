import 'package:flutter_test/flutter_test.dart';
import 'package:kreisel_frontend/models/location_model.dart';

void main() {
  group('Location Enum', () {
    test('enthält alle erwarteten Werte', () {
      expect(Location.values.length, 3);
      expect(Location.values.contains(Location.PASING), isTrue);
      expect(Location.values.contains(Location.KARLSTRASSE), isTrue);
      expect(Location.values.contains(Location.LOTHSTRASSE), isTrue);
    });

    test('enum Werte sind korrekt benannt', () {
      expect(Location.PASING.name, 'PASING');
      expect(Location.KARLSTRASSE.name, 'KARLSTRASSE');
      expect(Location.LOTHSTRASSE.name, 'LOTHSTRASSE');
    });

    test('toString gibt korrekten Wert zurück', () {
      expect(Location.PASING.toString(), 'Location.PASING');
    });
  });
}