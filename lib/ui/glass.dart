import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/palette.dart';

/// Legacy blur constant kept for compatibility with callers.
const double kGlassBlur = 0.0;

/// Simple pass-through group (legacy compatibility).
Widget glassGroup({required Widget child}) => child;

/// Modern solid surface helper providing a clean, high-performance card container
/// with solid backgrounds, crisp borders, and subtle elevation — zero glass or blur effects.
Widget liquid({
  required Widget child,
  double radius = 24,
  double? width,
  double? height,
  Color? tint,
  EdgeInsetsGeometry? padding,
  bool enabled = true,
  Brightness? brightness,
  double? blur,
  bool touchFlex = true,
  dynamic refractionIndex,
  dynamic refractionWidth,
  dynamic specular,
  dynamic glow,
  dynamic shadow,
}) {
  return _SolidSurface(
    radius: radius,
    width: width,
    height: height,
    tint: tint,
    padding: padding,
    enabled: enabled,
    brightness: brightness,
    child: child,
  );
}

class _SolidSurface extends StatelessWidget {
  final Widget child;
  final double radius;
  final double? width;
  final double? height;
  final Color? tint;
  final EdgeInsetsGeometry? padding;
  final bool enabled;
  final Brightness? brightness;

  const _SolidSurface({
    required this.child,
    required this.radius,
    this.width,
    this.height,
    this.tint,
    this.padding,
    required this.enabled,
    this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    if (padding != null) content = Padding(padding: padding!, child: content);

    final br = brightness ??
        AppState.current?.themeMode.brightness ??
        Theme.of(context).brightness;
    final isLight = br == Brightness.light;

    if (!enabled) {
      final shape = BorderRadius.circular(radius);
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: shape,
          color: tint ?? Colors.transparent,
        ),
        child: content,
      );
    }

    // 100% solid surfaces - no translucency or faux glass
    final defaultBg = isLight ? Colors.white : const Color(0xFF1E1E22);

    final borderColor = isLight
        ? const Color(0xFFE4E4E7)
        : const Color(0xFF2E2E33);

    final decoration = BoxDecoration(
      borderRadius: radius > 0 ? BorderRadius.circular(radius) : BorderRadius.zero,
      color: tint ?? defaultBg,
      border: Border.all(color: borderColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: isLight
              ? const Color(0x0D000000)
              : const Color(0x33000000),
          blurRadius: 4,
          offset: const Offset(0, 1.5),
        ),
      ],
    );

    return Container(
      width: width,
      height: height,
      decoration: decoration,
      child: content,
    );
  }
}

/// Solid, high-performance button used across the app chrome.
/// Features clean solid styling, crisp border, and instant non-delayed tap feedback.
class GlassButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double size;
  final Color? color;
  final String? tooltip;

  const GlassButton({
    super.key,
    required this.icon,
    this.onTap,
    this.onLongPress,
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
    final br = AppState.current?.themeMode.brightness ??
        Theme.of(context).brightness;
    final isLight = br == Brightness.light;

    final defaultColor = isLight ? Colors.white : const Color(0xFF222226);

    final borderColor = isLight
        ? const Color(0xFFE4E4E7)
        : const Color(0xFF333338);

    final btn = Semantics(
      button: true,
      enabled: widget.onTap != null || widget.onLongPress != null,
      label: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: widget.onLongPress,
        onTapDown: (_) {
          if (mounted) setState(() => _pressed = true);
        },
        onTapUp: (_) {
          if (mounted) setState(() => _pressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () {
          if (mounted) setState(() => _pressed = false);
        },
        child: RepaintBoundary(
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutQuad,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color ?? defaultColor,
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: isLight
                        ? const Color(0x0A000000)
                        : const Color(0x28000000),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
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
