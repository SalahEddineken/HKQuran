import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Shared liquid-glass tuning for every surface in Noor.
///
/// Hand-built glass: a backdrop blur, a frosted tint with one calm diagonal
/// reflection, a hairline light border and a soft drop shadow. Every surface
/// hugs its child exactly and centers it, so each widget reads as one clean
/// glass object (the packaged LiquidGlassEffect stretched its internal Stack
/// to fill the parent, which broke sizing, centering and hit-testing).
const double kGlassBlur = 22;

/// A glass region. Surfaces are self-contained (each carries its own backdrop
/// blur), so this stays as a semantic pass-through so existing call sites
/// keep working.
Widget glassGroup({required Widget child}) => child;

/// Liquid-glass surface helper — every chrome element in Noor is built with
/// this so the whole UI shares one glass language.
Widget liquid({
  required Widget child,
  double radius = 24,
  double? width,
  double? height,
  Color? tint,
  EdgeInsetsGeometry? padding,
  bool enabled = true,
}) {
  Widget content = child;
  if (padding != null) content = Padding(padding: padding, child: content);

  final base = tint ?? Colors.white.withValues(alpha: 0.10);
  final shape = BorderRadius.circular(radius);

  // Frosted surface: soft white sheen sweeping diagonally over the tint.
  final surface = Container(
    decoration: BoxDecoration(
      borderRadius: shape,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.20),
          base,
          Colors.white.withValues(alpha: 0.05),
          Color.alphaBlend(Colors.white.withValues(alpha: 0.06), base),
        ],
        stops: const [0.0, 0.38, 0.72, 1.0],
      ),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.28),
        width: 0.8,
      ),
    ),
    child: content,
  );

  final Widget glass = enabled
      ? BackdropFilter(
          filter: ImageFilter.blur(sigmaX: kGlassBlur, sigmaY: kGlassBlur),
          child: surface,
        )
      : Container(
          decoration: BoxDecoration(borderRadius: shape, color: base),
          child: content,
        );

  // Drop shadow lives on the outer container so the clip never cuts it.
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: shape,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 18,
          offset: const Offset(0, 8),
          spreadRadius: -6,
        ),
      ],
    ),
    child: ClipRRect(borderRadius: shape, child: glass),
  );
}

/// Round glass button used across the chrome. Presses squish slightly for
/// a tactile liquid feel; the scale lives in its own repaint layer so the
/// backdrop blur never re-renders on interaction.
class GlassButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final double size;
  final Color? color;
  final String? tooltip;

  const GlassButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 48,
    this.color,
    this.tooltip,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onTap,
        onHighlightChanged: (v) {
          if (_pressed != v) setState(() => _pressed = v);
        },
        child: RepaintBoundary(
          child: AnimatedScale(
            scale: _pressed ? 0.90 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: liquid(
              radius: widget.size / 2,
              width: widget.size,
              height: widget.size,
              tint: widget.color ?? Colors.white.withValues(alpha: 0.12),
              child: Center(child: widget.icon),
            ),
          ),
        ),
      ),
    );
    if (widget.tooltip == null) return btn;
    return Tooltip(message: widget.tooltip!, child: btn);
  }
}
