import 'package:flutter/material.dart';

/// Shared "midnight glass" look: deep gradient surfaces with a top sheen, a
/// hairline rim and a coloured glow. Built from gradients rather than
/// BackdropFilter so it stays cheap inside long scrolling channel lists.
class AppColors {
  static const bgTop = Color(0xFF0D1120);
  static const bgBottom = Color(0xFF070910);

  static const surfaceHi = Color(0xFF242C4A);
  static const surfaceLo = Color(0xFF151A2C);

  static const violet = Color(0xFF7C5CFF);
  static const indigo = Color(0xFF4A44C9);
  static const teal = Color(0xFF14C1AE);
  static const sky = Color(0xFF3FA2FF);
  static const rose = Color(0xFFFF5D74);
  static const amber = Color(0xFFFFB03A);
  static const slate = Color(0xFF7C89A8);

  /// Slightly brighter twin of [c], for the top of a gradient.
  static Color lift(Color c, [double amount = 0.22]) =>
      Color.lerp(c, Colors.white, amount)!;

  static const _folderPalette = <Color>[
    sky, violet, teal, amber, rose, indigo,
    Color(0xFF00B7C2), Color(0xFF9B6BFF), Color(0xFF39B37A), Color(0xFFFF7A59),
  ];

  /// A stable colour for a folder, derived from its name so the same group
  /// always looks the same but a list of them is easy to scan.
  static Color forName(String name) {
    var h = 0;
    for (final c in name.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return _folderPalette[h % _folderPalette.length];
  }
}

/// Full-screen backdrop gradient. Wrap a Scaffold body with it.
class GlossyBackground extends StatelessWidget {
  final Widget child;
  const GlossyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgTop, AppColors.bgBottom],
        ),
      ),
      child: child,
    );
  }
}

/// A raised glass panel: gradient body, sheen along the top edge, hairline rim,
/// drop shadow and an optional coloured glow.
class GlossyCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? glow;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool clip;

  const GlossyCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.glow,
    this.radius = 16,
    this.padding = const EdgeInsets.all(16),
    this.clip = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceHi, AppColors.surfaceLo],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.50), blurRadius: 16, offset: const Offset(0, 7)),
          if (glow != null)
            BoxShadow(color: glow!.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: -12, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            // Specular sheen across the top third.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: 0.085), Colors.white.withValues(alpha: 0.0)],
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                borderRadius: r,
                splashColor: Colors.white.withValues(alpha: 0.06),
                highlightColor: Colors.white.withValues(alpha: 0.03),
                child: Padding(padding: padding, child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded icon well with a colour gradient, inner highlight and glow.
class GlossyIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const GlossyIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 54,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.lift(color, 0.28), color],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.42), blurRadius: 16, spreadRadius: -4, offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          // Glass highlight on the upper half.
          Positioned(
            top: 1,
            left: 1,
            right: 1,
            height: size * 0.45,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(size * 0.28)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withValues(alpha: 0.30), Colors.white.withValues(alpha: 0.0)],
                ),
              ),
            ),
          ),
          Center(child: Icon(icon, size: iconSize, color: Colors.white)),
        ],
      ),
    );
  }
}

/// Small gradient pill used for channel counts.
class GlossyCountChip extends StatelessWidget {
  final String label;
  final Color color;
  const GlossyCountChip({super.key, required this.label, this.color = AppColors.teal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.lift(color, 0.30), color],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, spreadRadius: -3, offset: const Offset(0, 3)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Gradient wash for app bars, so the top of the screen reads as glass too.
BoxDecoration glossyAppBarDecoration() => BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1B2138), Color(0xFF11162A)],
      ),
      border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
    );
