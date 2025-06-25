import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class HoverButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final String tooltip;
  final Color color;

  const HoverButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.tooltip,
    this.color = const Color(0xFF007AFF),
  });

  @override
  _HoverButtonState createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(isHovered ? 1.1 : 1.0),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: widget.onPressed,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
