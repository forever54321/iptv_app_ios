import 'package:flutter/material.dart';

/// Lets a full-screen Column (with Spacers) fill the screen when it fits and
/// scroll when it doesn't — short screens such as the iPhone Duo's folded
/// 678 pt outer display otherwise clip the bottom buttons.
class FillOrScroll extends StatelessWidget {
  const FillOrScroll({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: IntrinsicHeight(child: child),
        ),
      ),
    );
  }
}
