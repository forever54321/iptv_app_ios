import 'package:flutter/material.dart';

/// Keeps every screen clear of the SIDE safe areas while in portrait.
///
/// The iPhone Duo's folded outer display (466 x 678 pt) has an ~84 pt
/// camera/status strip on the RIGHT that iOS reports as safe-area padding;
/// Flutter screens draw straight under it unless something applies that
/// padding. Wrapping the app here fixes every route, sheet and dialog at once.
/// Ordinary iPhones have no side insets in portrait, so this is a no-op there,
/// and landscape (full-screen video, the notch side) is deliberately untouched.
class SideSafeArea extends StatelessWidget {
  const SideSafeArea({required this.child, this.color, super.key});

  final Widget child;

  /// Fills the strip behind the inset; defaults to the scaffold background.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final pad = mq.padding;
    if (mq.orientation != Orientation.portrait ||
        (pad.left == 0 && pad.right == 0)) {
      return child;
    }
    return ColoredBox(
      color: color ?? Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(top: false, bottom: false, child: child),
    );
  }
}
