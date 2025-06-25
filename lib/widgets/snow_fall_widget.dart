import 'package:flutter/material.dart';
import 'dart:math';

class SnowFallWidget extends StatefulWidget {
  const SnowFallWidget({super.key});

  @override
  _SnowFallWidgetState createState() => _SnowFallWidgetState();
}

class _SnowFallWidgetState extends State<SnowFallWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<SnowFlake> _snowFlakes = [];
  late Size _screenSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Initialize with dummy size, will be updated in build
    _screenSize = Size(1000, 1000);

    // Create 150 snowflakes
    for (int i = 0; i < 150; i++) {
      _snowFlakes.add(SnowFlake(_screenSize));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get actual screen size
    _screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        for (final flake in _snowFlakes) {
          flake.fall(_screenSize);
        }
        return CustomPaint(
          painter: SnowPainter(_snowFlakes),
          size: Size.infinite,
        );
      },
    );
  }
}

class SnowFlake {
  late double x;
  late double y;
  double velocity = 1 + Random().nextDouble() * 3;
  double radius = 1 + Random().nextDouble() * 3;
  double wind = Random().nextDouble() * 0.5 - 0.25;

  SnowFlake(Size screenSize) {
    x = Random().nextDouble() * screenSize.width;
    y = Random().nextDouble() * screenSize.height;
  }

  void fall(Size screenSize) {
    y += velocity;
    x += wind;

    if (y > screenSize.height) {
      y = 0;
      x = Random().nextDouble() * screenSize.width;
    }

    // Wrap around horizontally
    if (x < 0) {
      x = screenSize.width;
    } else if (x > screenSize.width) {
      x = 0;
    }

    if (Random().nextDouble() > 0.9) {
      wind = Random().nextDouble() * 0.5 - 0.25;
    }
  }
}

class SnowPainter extends CustomPainter {
  final List<SnowFlake> snowFlakes;

  SnowPainter(this.snowFlakes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    for (final flake in snowFlakes) {
      canvas.drawCircle(
        Offset(flake.x % size.width, flake.y % size.height),
        flake.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SnowPainter oldDelegate) => true;
}
