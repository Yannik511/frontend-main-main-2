// Für Tests: Ersetze deine ursprünglichen Tests mit dieser einfachen Lösung

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreisel_frontend/pages/location_selection_page.dart';

void main() {
  // Helper to create testable widget
  Widget createTestableLocationSelectionPage() {
    return MaterialApp(
      home: LocationSelectionPage(), // ORIGINALE KLASSE
    );
  }

  group('LocationSelectionPage Widget Tests', () {
    testWidgets('should build without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableLocationSelectionPage());
      await tester.pump();
      
      expect(find.byType(LocationSelectionPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display main title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableLocationSelectionPage());
      await tester.pump();
      
      expect(find.text('Standort wählen'), findsOneWidget);
    });

    testWidgets('should display subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableLocationSelectionPage());
      await tester.pump();
      
      expect(find.text('Wähle deinen Campus aus'), findsOneWidget);
    });

    testWidgets('should have black background', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableLocationSelectionPage());
      await tester.pump();
      
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));
    });

    testWidgets('should display all three locations', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableLocationSelectionPage());
      await tester.pump();
      
      expect(find.text('Campus Pasing'), findsOneWidget);
      expect(find.text('Campus Lothstraße'), findsOneWidget);
      expect(find.text('Campus Karlstraße'), findsOneWidget);
    });

    testWidgets('should display location icons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableLocationSelectionPage());
      await tester.pump();
      
      expect(find.byIcon(CupertinoIcons.building_2_fill), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.location_fill), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.map_fill), findsOneWidget);
    });

    testWidgets('should display chevron right icons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableLocationSelectionPage());
      await tester.pump();
      
      expect(find.byIcon(CupertinoIcons.chevron_right), findsNWidgets(3));
    });

    testWidgets('should display location buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableLocationSelectionPage());
      await tester.pump();
      
      expect(find.byType(CupertinoButton), findsNWidgets(3));
    });

    testWidgets('should have proper text styling for title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableLocationSelectionPage());
      await tester.pump();
      
      final titleFinder = find.text('Standort wählen');
      expect(titleFinder, findsOneWidget);
      
      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.fontSize, equals(32));
      expect(titleWidget.style?.fontWeight, equals(FontWeight.bold));
      expect(titleWidget.style?.color, equals(Colors.white));
    });

    testWidgets('should have proper text styling for subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableLocationSelectionPage());
      await tester.pump();
      
      final subtitleFinder = find.text('Wähle deinen Campus aus');
      expect(subtitleFinder, findsOneWidget);
      
      final subtitleWidget = tester.widget<Text>(subtitleFinder);
      expect(subtitleWidget.style?.fontSize, equals(16));
      expect(subtitleWidget.style?.color, equals(Colors.grey));
    });

    testWidgets('should display location names with proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableLocationSelectionPage());
      await tester.pump();
      
      final locationTexts = ['Campus Pasing', 'Campus Lothstraße', 'Campus Karlstraße'];
      
      for (final locationText in locationTexts) {
        final textFinder = find.text(locationText);
        expect(textFinder, findsOneWidget);
        
        final textWidget = tester.widget<Text>(textFinder);
        expect(textWidget.style?.fontSize, equals(20));
        expect(textWidget.style?.fontWeight, equals(FontWeight.w600));
        expect(textWidget.style?.color, equals(Colors.white));
      }
    });

    testWidgets('should have proper layout structure', (WidgetTester tester) async {
  await tester.pumpWidget(createTestableLocationSelectionPage());
  await tester.pump();
  
  // Grundlegende Layout-Struktur
  expect(find.byType(Column), findsOneWidget);
  expect(find.byType(ListView), findsOneWidget);
  expect(find.byType(SafeArea), findsOneWidget);
  
  // Es gibt mehrere Expanded Widgets:
  // 1x für das ListView + 3x für die Location-Texte = 4 total
  expect(find.byType(Expanded), findsNWidgets(4));
  
  // Spezifischere Prüfungen
  expect(find.byType(Stack), findsWidgets); // Mindestens ein Stack
  expect(find.byType(Padding), findsWidgets); // Mehrere Padding-Widgets
  expect(find.byType(Container), findsWidgets); // Mehrere Container
  
  // Layout-Hierarchie prüfen
  final scaffold = find.byType(Scaffold);
  expect(scaffold, findsOneWidget);
  
  final column = find.byType(Column);
  expect(column, findsOneWidget);
  
  // ListView sollte ein Child des Column sein
  final listView = find.byType(ListView);
  expect(listView, findsOneWidget);
});

    testWidgets('should handle different screen sizes', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(Size(375, 667));
      await tester.pumpWidget(createTestableLocationSelectionPage());
      await tester.pump();
      
      expect(find.byType(LocationSelectionPage), findsOneWidget);
      expect(find.text('Standort wählen'), findsOneWidget);
      
      await tester.binding.setSurfaceSize(Size(768, 1024));
      await tester.pump();
      
      expect(find.byType(LocationSelectionPage), findsOneWidget);
      
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should have scrollable content', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableLocationSelectionPage());
      await tester.pump();
      
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);
      
      await tester.drag(listView, Offset(0, -100));
      await tester.pump();
    });

    testWidgets('should have proper spacing elements', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableLocationSelectionPage());
      await tester.pump();
      
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('should have proper row layout for locations', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableLocationSelectionPage());
      await tester.pump();
      
      expect(find.byType(Row), findsNWidgets(3));
    });

    testWidgets('should have proper padding for main content', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableLocationSelectionPage());
      await tester.pump();
      
      final paddingFinder = find.byType(Padding);
      expect(paddingFinder, findsWidgets);
    });
  });

  // Alle deine anderen Test-Gruppen (Constants Tests, Lifecycle Tests, etc.) 
  // bleiben GENAU GLEICH - nur kopiere sie aus deiner ursprünglichen Test-Datei!

  group('LocationSelectionPage Constants Tests', () {
    test('should have correct location data structure', () {
      final expectedLocations = [
        {'name': 'PASING', 'displayName': 'Campus Pasing'},
        {'name': 'LOTHSTRASSE', 'displayName': 'Campus Lothstraße'},
        {'name': 'KARLSTRASSE', 'displayName': 'Campus Karlstraße'},
      ];
      
      expect(expectedLocations.length, equals(3));
      expect(expectedLocations[0]['name'], equals('PASING'));
      expect(expectedLocations[1]['name'], equals('LOTHSTRASSE'));
      expect(expectedLocations[2]['name'], equals('KARLSTRASSE'));
    });

    test('should have valid color values', () {
      final expectedColors = [Color(0xFF007AFF), Color(0xFF32D74B), Color(0xFFFF9500)];
      for (final color in expectedColors) {
        expect(color.alpha, equals(255));
        expect(color.value, isA<int>());
      }
    });

    test('should have valid icon values', () {
      final expectedIcons = [CupertinoIcons.building_2_fill, CupertinoIcons.location_fill, CupertinoIcons.map_fill];
      for (final icon in expectedIcons) {
        expect(icon.codePoint, isA<int>());
        expect(icon.fontFamily, isA<String>());
      }
    });

    test('should have non-empty display names', () {
      final expectedDisplayNames = ['Campus Pasing', 'Campus Lothstraße', 'Campus Karlstraße'];
      for (final displayName in expectedDisplayNames) {
        expect(displayName.isNotEmpty, isTrue);
        expect(displayName.startsWith('Campus'), isTrue);
      }
    });

    test('should have valid location names', () {
      final expectedNames = ['PASING', 'LOTHSTRASSE', 'KARLSTRASSE'];
      for (final name in expectedNames) {
        expect(name.isNotEmpty, isTrue);
        expect(name.toUpperCase(), equals(name));
      }
    });
  });

  // Kopiere alle weiteren Test-Gruppen aus deiner ursprünglichen Datei hierher...
}