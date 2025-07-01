import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreisel_frontend/pages/item_detail_page.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:kreisel_frontend/pages/home_page.dart';
import 'package:kreisel_frontend/services/api_service.dart';
import 'package:kreisel_frontend/models/item_model.dart';
import 'package:kreisel_frontend/models/user_model.dart';

class MockHttpClient implements HttpClientInterface {
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    if (url.toString().contains("location=PASING")) {
      return http.Response(
        jsonEncode([
          {
            "id": 1,
            "name": "Ski Rossignol",
            "size": "M",
            "available": true,
            "description": "Perfekte Ski",
            "brand": "Rossignol",
            "imageUrl": "https://example.com/ski.jpg",
            "averageRating": 4.5,
            "reviewCount": 10,
            "location": "PASING",
            "gender": "UNISEX",
            "category": "EQUIPMENT",
            "subcategory": "SKI",
            "zustand": "NEU",
          },
        ]),
        200,
      );
    }

    return http.Response("{}", 400);
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return http.Response("{}", 200);
  }

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return http.Response("{}", 200);
  }

  @override
  Future<http.Response> delete(Uri url, {Map<String, String>? headers}) async {
    return http.Response("{}", 200);
  }
}

void main() {
  late MockHttpClient mockClient;

  final testUser = User(
    userId: 1,
    fullName: 'Test User',
    email: 'test@example.com',
    role: 'USER',
  );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    mockClient = MockHttpClient();

    ApiService.configure(
      httpClient: mockClient,
      tokenStorage: SharedPreferencesTokenStorage(),
    );

    SharedPreferences.setMockInitialValues({'jwt_token': 'mock_token_123'});

    ApiService.currentUser = testUser;
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: HomePage(selectedLocation: 'PASING', locationDisplayName: 'Pasing'),
    );
  }

  testWidgets('zeigt Items korrekt an', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Ski Rossignol'), findsOneWidget);
    expect(find.text('Verfügbar'), findsOneWidget);
    expect(find.text('Rossignol'), findsOneWidget);
    expect(find.textContaining('Größe:'), findsOneWidget);
  });

  testWidgets('testet Suchfunktion', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(seconds: 1));

    final searchField = find.byType(CupertinoSearchTextField);
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'rossignol');
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Ski Rossignol'), findsOneWidget);
  });

  testWidgets('Filter "Nur verfügbare Items anzeigen" funktioniert', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(seconds: 1));

    final toggle = find.text('Nur verfügbare Items anzeigen');
    expect(toggle, findsOneWidget);

    await tester.tap(toggle);
    await tester.pump(const Duration(milliseconds: 500));

    // sollte immer noch angezeigt werden (weil verfügbar = true)
    expect(find.text('Ski Rossignol'), findsOneWidget);
  });

  testWidgets('öffnet Miet-Dialog beim Button-Tap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(seconds: 1));

    final ausleihenButton = find.text('Ausleihen');
    expect(ausleihenButton, findsOneWidget);

    await tester.tap(ausleihenButton);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
  });

  testWidgets('zeigt Fehlerdialog bei API-Fehler', (WidgetTester tester) async {
    // Erzeuge Fehlerantwort durch ungültige Location
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          selectedLocation: 'INVALID_LOCATION',
          locationDisplayName: 'Fehler',
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Fehler beim Laden'), findsOneWidget);
    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
  });

  testWidgets('Gender-Filter funktioniert (UNISEX)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(seconds: 1));

    final chip = find.text('UNISEX');
    await tester.tap(chip);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Ski Rossignol'), findsOneWidget);
  });
}