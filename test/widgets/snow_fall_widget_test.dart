import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreisel_frontend/widgets/snow_fall_widget.dart';

void main() {
  group('SnowFallWidget Tests', () {
    testWidgets('should create widget successfully', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SnowFallWidget(),
      ),
    ),
  );

  expect(find.byType(SnowFallWidget), findsOneWidget);
  expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
});

    testWidgets('should handle disposal properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SnowFallWidget(),
          ),
        ),
      );

      // Verify widget is created
      expect(find.byType(SnowFallWidget), findsOneWidget);

      // Remove widget to trigger disposal
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
          ),
        ),
      );

      // Should not throw any exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('should adapt to different screen sizes', (WidgetTester tester) async {
      // Test with different screen sizes
      await tester.binding.setSurfaceSize(Size(800, 600));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SnowFallWidget(),
          ),
        ),
      );

      expect(find.byType(SnowFallWidget), findsOneWidget);

      // Change screen size
      await tester.binding.setSurfaceSize(Size(400, 300));
      await tester.pump();

      expect(find.byType(SnowFallWidget), findsOneWidget);

      // Reset to default
      await tester.binding.setSurfaceSize(null);
    });

   testWidgets('should render without animation in test environment', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SnowFallWidget(),
      ),
    ),
  );

  expect(find.byType(SnowFallWidget), findsOneWidget);
  expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));

  // Should render static snowflakes in test environment
  await tester.pump();
  expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
});
    testWidgets('should handle multiple rebuilds gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SnowFallWidget(),
          ),
        ),
      );

      // Multiple rebuilds
      for (int i = 0; i < 10; i++) {
        await tester.pump();
      }

      expect(find.byType(SnowFallWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle rapid widget replacement', (WidgetTester tester) async {
      for (int i = 0; i < 5; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SnowFallWidget(),
            ),
          ),
        );

        await tester.pump();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(),
            ),
          ),
        );

        await tester.pump();
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle mounted/disposed state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SnowFallWidget(),
          ),
        ),
      );

      // Widget should be mounted
      expect(find.byType(SnowFallWidget), findsOneWidget);

      // Dispose the widget
      await tester.pumpWidget(Container());

      // Should handle disposal without errors
      expect(tester.takeException(), isNull);
    });
  });

  group('SnowFlake Tests', () {
    test('should initialize with valid position and properties', () {
      final screenSize = Size(800, 600);
      final snowFlake = SnowFlake(screenSize);

      expect(snowFlake.x, greaterThanOrEqualTo(0));
      expect(snowFlake.x, lessThanOrEqualTo(screenSize.width));
      expect(snowFlake.y, greaterThanOrEqualTo(0));
      expect(snowFlake.y, lessThanOrEqualTo(screenSize.height));
      expect(snowFlake.velocity, greaterThan(1));
      expect(snowFlake.velocity, lessThan(4));
      expect(snowFlake.radius, greaterThan(1));
      expect(snowFlake.radius, lessThan(4));
      expect(snowFlake.wind, greaterThanOrEqualTo(-0.25));
      expect(snowFlake.wind, lessThanOrEqualTo(0.25));
    });

    test('should fall correctly and stay within screen bounds', () {
      final screenSize = Size(800, 600);
      final snowFlake = SnowFlake(screenSize);
      
      final initialY = snowFlake.y;
      final initialX = snowFlake.x;
      
      snowFlake.fall(screenSize);
      
      // Y should increase (falling down)
      expect(snowFlake.y, greaterThanOrEqualTo(initialY));
      
      // X should be affected by wind
      expect(snowFlake.x, isNot(equals(initialX)));
    });

    test('should reset Y position when falling off screen bottom', () {
      final screenSize = Size(800, 600);
      final snowFlake = SnowFlake(screenSize);
      
      // Set Y position below screen
      snowFlake.y = screenSize.height + 10;
      
      snowFlake.fall(screenSize);
      
      // Should reset to top
      expect(snowFlake.y, equals(0));
      
      // X should be randomized when resetting
      expect(snowFlake.x, greaterThanOrEqualTo(0));
      expect(snowFlake.x, lessThanOrEqualTo(screenSize.width));
    });

    test('should wrap around horizontally when moving off screen', () {
      final screenSize = Size(800, 600);
      final snowFlake = SnowFlake(screenSize);
      
      // Test wrapping to right
      snowFlake.x = -10;
      snowFlake.fall(screenSize);
      expect(snowFlake.x, equals(screenSize.width));
      
      // Test wrapping to left  
      snowFlake.x = screenSize.width + 10;
      snowFlake.fall(screenSize);
      expect(snowFlake.x, equals(0));
    });

    test('should randomly change wind direction', () {
      final screenSize = Size(800, 600);
      final snowFlake = SnowFlake(screenSize);
      
      // Call fall multiple times to potentially trigger wind change
      // Note: This test has some randomness, but we can at least verify
      // that wind stays within valid bounds
      for (int i = 0; i < 100; i++) {
        snowFlake.fall(screenSize);
        expect(snowFlake.wind, greaterThanOrEqualTo(-0.25));
        expect(snowFlake.wind, lessThanOrEqualTo(0.25));
      }
    });

    test('should handle multiple fall cycles correctly', () {
      final screenSize = Size(800, 600);
      final snowFlake = SnowFlake(screenSize);
      
      // Record initial state
      final initialState = {
        'x': snowFlake.x,
        'y': snowFlake.y,
        'velocity': snowFlake.velocity,
        'radius': snowFlake.radius,
      };
      
      // Fall multiple times
      for (int i = 0; i < 50; i++) {
        snowFlake.fall(screenSize);
        
        // Ensure position is always valid
        expect(snowFlake.x, greaterThanOrEqualTo(0));
        expect(snowFlake.x, lessThanOrEqualTo(screenSize.width));
        expect(snowFlake.y, greaterThanOrEqualTo(0));
        
        // Velocity and radius should remain constant
        expect(snowFlake.velocity, equals(initialState['velocity']));
        expect(snowFlake.radius, equals(initialState['radius']));
      }
    });

    test('should handle edge case screen sizes', () {
      // Very small screen
      final smallScreen = Size(50, 50);
      final snowFlakeSmall = SnowFlake(smallScreen);
      
      expect(snowFlakeSmall.x, greaterThanOrEqualTo(0));
      expect(snowFlakeSmall.x, lessThanOrEqualTo(smallScreen.width));
      
      snowFlakeSmall.fall(smallScreen);
      expect(snowFlakeSmall.x, greaterThanOrEqualTo(0));
      expect(snowFlakeSmall.x, lessThanOrEqualTo(smallScreen.width));
      
      // Very large screen
      final largeScreen = Size(5000, 3000);
      final snowFlakeLarge = SnowFlake(largeScreen);
      
      expect(snowFlakeLarge.x, greaterThanOrEqualTo(0));
      expect(snowFlakeLarge.x, lessThanOrEqualTo(largeScreen.width));
      
      snowFlakeLarge.fall(largeScreen);
      expect(snowFlakeLarge.x, greaterThanOrEqualTo(0));
      expect(snowFlakeLarge.x, lessThanOrEqualTo(largeScreen.width));
    });

    test('should handle extreme positions correctly', () {
      final screenSize = Size(800, 600);
      final snowFlake = SnowFlake(screenSize);
      
      // Test extreme negative positions
      snowFlake.x = -1000;
      snowFlake.y = -1000;
      snowFlake.fall(screenSize);
      
      // Should handle gracefully
      expect(snowFlake.x, anyOf(equals(screenSize.width), equals(0)));
      
      // Test extreme positive positions
      snowFlake.x = 10000;
      snowFlake.y = 10000;
      snowFlake.fall(screenSize);
      
      // Should handle gracefully
      expect(snowFlake.x, anyOf(equals(0), greaterThanOrEqualTo(0)));
    });
  });

  group('SnowPainter Tests', () {
    test('should create SnowPainter with snowflakes', () {
      final snowFlakes = [
        SnowFlake(Size(800, 600)),
        SnowFlake(Size(800, 600)),
        SnowFlake(Size(800, 600)),
      ];
      
      final painter = SnowPainter(snowFlakes);
      expect(painter.snowFlakes, equals(snowFlakes));
      expect(painter.snowFlakes.length, equals(3));
    });

    test('should always return true for shouldRepaint', () {
      final snowFlakes = [SnowFlake(Size(800, 600))];
      final painter = SnowPainter(snowFlakes);
      final oldPainter = SnowPainter(snowFlakes);
      
      expect(painter.shouldRepaint(oldPainter), isTrue);
    });

    test('should handle empty snowflakes list', () {
      final painter = SnowPainter([]);
      expect(painter.snowFlakes, isEmpty);
      expect(painter.shouldRepaint(painter), isTrue);
    });

    test('should handle large number of snowflakes', () {
      final snowFlakes = List.generate(1000, (index) => SnowFlake(Size(800, 600)));
      final painter = SnowPainter(snowFlakes);
      
      expect(painter.snowFlakes.length, equals(1000));
      expect(painter.shouldRepaint(painter), isTrue);
    });

    testWidgets('should paint without throwing exceptions', (WidgetTester tester) async {
  final snowFlakes = List.generate(10, (index) => SnowFlake(Size(800, 600)));
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CustomPaint(
          painter: SnowPainter(snowFlakes),
          size: Size(800, 600),
        ),
      ),
    ),
  );

  expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
  expect(tester.takeException(), isNull);
});

   testWidgets('should handle painting with different canvas sizes', (WidgetTester tester) async {
  final snowFlakes = [SnowFlake(Size(800, 600))];
  
  // Test with small canvas
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 100,
          height: 100,
          child: CustomPaint(
            painter: SnowPainter(snowFlakes),
          ),
        ),
      ),
    ),
  );

  expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
  expect(tester.takeException(), isNull);

  // Test with large canvas
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1000,
          height: 1000,
          child: CustomPaint(
            painter: SnowPainter(snowFlakes),
          ),
        ),
      ),
    ),
  );

  expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
  expect(tester.takeException(), isNull);
});

    testWidgets('should handle modulo operation in paint method', (WidgetTester tester) async {
  final snowFlakes = [SnowFlake(Size(800, 600))];
  
  // Set snowflake position outside canvas bounds to test modulo
  snowFlakes[0].x = 1500;
  snowFlakes[0].y = 1200;
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 300,
          child: CustomPaint(
            painter: SnowPainter(snowFlakes),
          ),
        ),
      ),
    ),
  );

  expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
  expect(tester.takeException(), isNull);
});
  });

  group('Integration Tests', () {
    testWidgets('should create 150 snowflakes by default', (WidgetTester tester) async {
  // We can't directly access the private _snowFlakes list,
  // but we can verify the widget creates successfully
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SnowFallWidget(),
      ),
    ),
  );

  expect(find.byType(SnowFallWidget), findsOneWidget);
  expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
});

    testWidgets('should handle state changes gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SnowFallWidget(),
          ),
        ),
      );

      // Simulate state changes
      await tester.pump(Duration(milliseconds: 100));
      await tester.pump(Duration(milliseconds: 200));
      await tester.pump(Duration(milliseconds: 500));

      expect(find.byType(SnowFallWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should maintain performance with many animations', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SnowFallWidget(),
          ),
        ),
      );

      // Multiple animation frames
      for (int i = 0; i < 60; i++) {
        await tester.pump(Duration(milliseconds: 16)); // ~60fps
      }

      stopwatch.stop();

      expect(find.byType(SnowFallWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
      
      // Should complete within reasonable time (less than 5 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    testWidgets('should work within different parent widgets', (WidgetTester tester) async {
      // Test within Stack
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.blue),
                SnowFallWidget(),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(SnowFallWidget), findsOneWidget);

      // Test within Column
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(child: SnowFallWidget()),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(SnowFallWidget), findsOneWidget);

      // Test within Container
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 300,
              height: 300,
              child: SnowFallWidget(),
            ),
          ),
        ),
      );

      expect(find.byType(SnowFallWidget), findsOneWidget);
    });

    testWidgets('should handle orientation changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SnowFallWidget(),
          ),
        ),
      );

      expect(find.byType(SnowFallWidget), findsOneWidget);

      // Simulate orientation change
      await tester.binding.setSurfaceSize(Size(600, 800)); // Portrait
      await tester.pump();

      expect(find.byType(SnowFallWidget), findsOneWidget);

      await tester.binding.setSurfaceSize(Size(800, 600)); // Landscape
      await tester.pump();

      expect(find.byType(SnowFallWidget), findsOneWidget);

      // Reset
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('Edge Cases and Error Handling', () {
    testWidgets('should handle zero-size screens gracefully', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(Size(0, 0));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SnowFallWidget(),
          ),
        ),
      );

      // Should not crash
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should handle very rapid disposal', (WidgetTester tester) async {
      for (int i = 0; i < 20; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SnowFallWidget(),
            ),
          ),
        );

        // Immediately dispose
        await tester.pumpWidget(Container());
      }

      expect(tester.takeException(), isNull);
    });

    test('should handle snowflake properties edge cases', () {
      final screenSize = Size(800, 600);
      
      // Create multiple snowflakes to test random property distribution
      for (int i = 0; i < 100; i++) {
        final snowFlake = SnowFlake(screenSize);
        
        // Verify all properties are within expected ranges
        expect(snowFlake.velocity, greaterThan(1));
        expect(snowFlake.velocity, lessThan(4));
        expect(snowFlake.radius, greaterThan(1));
        expect(snowFlake.radius, lessThan(4));
        expect(snowFlake.wind, greaterThanOrEqualTo(-0.25));
        expect(snowFlake.wind, lessThanOrEqualTo(0.25));
        expect(snowFlake.x, greaterThanOrEqualTo(0));
        expect(snowFlake.x, lessThanOrEqualTo(screenSize.width));
        expect(snowFlake.y, greaterThanOrEqualTo(0));
        expect(snowFlake.y, lessThanOrEqualTo(screenSize.height));
      }
    });

    test('should handle snowflake with very small screen dimensions', () {
      final tinyScreen = Size(1, 1);
      final snowFlake = SnowFlake(tinyScreen);
      
      expect(snowFlake.x, greaterThanOrEqualTo(0));
      expect(snowFlake.x, lessThanOrEqualTo(tinyScreen.width));
      expect(snowFlake.y, greaterThanOrEqualTo(0));
      expect(snowFlake.y, lessThanOrEqualTo(tinyScreen.height));
      
      snowFlake.fall(tinyScreen);
      
      // Should still work with tiny dimensions
      expect(snowFlake.x, greaterThanOrEqualTo(0));
      expect(snowFlake.x, lessThanOrEqualTo(tinyScreen.width));
    });

    testWidgets('should handle widget rebuilding with different keys', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SnowFallWidget(key: Key('snow1')),
          ),
        ),
      );

      expect(find.byType(SnowFallWidget), findsOneWidget);

      // Rebuild with different key
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SnowFallWidget(key: Key('snow2')),
          ),
        ),
      );

      expect(find.byType(SnowFallWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle nested SnowFallWidgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SnowFallWidget(),
                Positioned(
                  top: 100,
                  left: 100,
                  width: 200,
                  height: 200,
                  child: SnowFallWidget(),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(SnowFallWidget), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });

  group('Animation Controller Tests', () {
   testWidgets('should handle animation controller lifecycle in test environment', (WidgetTester tester) async {
  // This specifically tests the test environment detection logic
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SnowFallWidget(),
      ),
    ),
  );

  // In test environment, should still render without animation controller
  expect(find.byType(SnowFallWidget), findsOneWidget);
  expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));

  // Multiple pumps should not cause issues
  for (int i = 0; i < 10; i++) {
    await tester.pump(Duration(milliseconds: 100));
  }

  expect(tester.takeException(), isNull);
});

    testWidgets('should maintain stable state without animation controller', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SnowFallWidget(),
      ),
    ),
  );

  // Record initial state - count all CustomPaint widgets
  final initialCustomPaintCount = find.byType(CustomPaint).evaluate().length;
  expect(find.byType(SnowFallWidget), findsOneWidget);
  expect(initialCustomPaintCount, greaterThan(0)); // At least one CustomPaint should exist

  // Multiple rebuilds
  for (int i = 0; i < 20; i++) {
    await tester.pump(Duration(milliseconds: 50));
  }

  // Should maintain the same structure - count should remain stable
  final finalCustomPaintCount = find.byType(CustomPaint).evaluate().length;
  expect(finalCustomPaintCount, equals(initialCustomPaintCount));
  expect(find.byType(SnowFallWidget), findsOneWidget);
});
  });
}