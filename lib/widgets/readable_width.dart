import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Caps a screen's content at a readable width and centres it, so forms,
/// onboarding and paywalls don't stretch edge to edge on a regular-width
/// screen (iPhone Duo unfolded, iPad). Phones are narrower than [maxWidth],
/// so their layout is unchanged.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({required this.child, this.maxWidth = 640, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth <= maxWidth) return child;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: math.min(box.maxWidth, maxWidth),
            height: box.maxHeight.isFinite ? box.maxHeight : null,
            child: child,
          ),
        );
      },
    );
  }
}
