import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/palette.dart';
import 'glass.dart';

/// The centerpiece — an ultra-minimalist analog clock:
/// * Thin outer perimeter ring with 12 subtle radial hour ticks.
/// * Clean linear hour and minute hands originating from a solid center dot.
/// * Real local time or countdown mode during focus sessions.
class ClockView extends StatefulWidget {
  final bool interactive;
  const ClockView({super.key, this.interactive = true});

  @override
  State<ClockView> createState() => _ClockViewState();
}

class _ClockViewState extends State<ClockView> {
  Timer? _ticker;
  int? _dragMinutes;
  AppState? _state;
  DateTime? _lastTap;

  @override
  void initState() {
    super.initState();
    // Ticks every 500ms to stay in sync with time and focus countdown
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state = AppStateScope.of(context);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _dragUpdate(Offset local, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final d = local - c;
    if (d.distance < 8) return;
    final deg = (math.atan2(d.dy, d.dx) * 180 / math.pi + 90 + 360) % 360;
    var minutes = (deg / 360 * 60).round() % 60;
    if (minutes == 0) minutes = 60;
    if (minutes != _dragMinutes) {
      setState(() => _dragMinutes = minutes);
    }
  }

  void _dragEnd(Size size) {
    final m = _dragMinutes;
    setState(() => _dragMinutes = null);
    if (m != null && widget.interactive) _state?.startFocus(m);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mode = s.themeMode;
    final isDark = mode.brightness == Brightness.dark;
    final ink = mode.ink;
    final focusing = s.focusing;

    // Minimalist monochrome palette matching the reference watchface
    final Color handColor = isDark ? Colors.white : const Color(0xFF111111);
    final Color dialColor = isDark ? Colors.white : const Color(0xFF111111);

    return LayoutBuilder(
      builder: (context, box) {
        final media = MediaQuery.sizeOf(context);
        final screenWidth = media.width;
        final screenHeight = media.height;
        final isMobile = screenWidth < 600;
        final isTinyScreen = screenWidth < 380 || screenHeight < 550;
        final isLargeDesktop = screenWidth >= 1350 && screenHeight >= 860;
        final isDesktop = screenWidth >= 900;

        // Dial sizing: sized to fit as an elegant centerpiece
        final double maxDial;
        if (isTinyScreen) {
          maxDial = 160.0;
        } else if (isMobile) {
          maxDial = (screenWidth * 0.58).clamp(170.0, 230.0);
        } else if (isLargeDesktop) {
          maxDial = 360.0;
        } else if (isDesktop) {
          maxDial = 320.0;
        } else {
          maxDial = 290.0;
        }
        final heightCappedDial =
            math.min(maxDial, screenHeight * (isMobile ? 0.35 : 0.42));
        final minDial = isTinyScreen ? 120.0 : (isMobile ? 150.0 : 210.0);
        final size =
            math.min(box.maxWidth, heightCappedDial).clamp(minDial, maxDial);

        final facePadding = (size * 0.032).clamp(6.0, 12.0);

        DateTime clockFn() {
          if (!focusing) return DateTime.now();
          final rem = s.focusRemaining;
          final now = DateTime.now();
          final mins = rem.inMinutes.clamp(0, 59);
          final secs = rem.inSeconds % 60;
          return DateTime(now.year, now.month, now.day, now.hour, mins, secs);
        }

        return Center(
          child: MouseRegion(
            cursor: widget.interactive
                ? SystemMouseCursors.click
                : MouseCursor.defer,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) {},
              onPanUpdate: (d) => _dragUpdate(d.localPosition, Size(size, size)),
              onPanEnd: (_) => _dragEnd(Size(size, size)),
              onTap: () {
                final now = DateTime.now();
                if (focusing &&
                    _lastTap != null &&
                    now.difference(_lastTap!) < const Duration(milliseconds: 320)) {
                  s.endFocus();
                  _lastTap = null;
                  return;
                }
                _lastTap = now;
              },
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Transparent Clock Dial Container
                    SizedBox(
                      width: size,
                      height: size,
                      child: Padding(
                        padding: EdgeInsets.all(facePadding),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Outer ring + 12 radial hour ticks - Cached layer
                            RepaintBoundary(
                              child: CustomPaint(
                                painter: ClockDialPainter(
                                  color: dialColor,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                            // Hands layer (Hour, Minute, Solid Center Dot)
                            RepaintBoundary(
                              child: CustomPaint(
                                painter: ClockHandsPainter(
                                  time: clockFn(),
                                  handColor: handColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Focus Countdown Ring
                    if (focusing)
                      RepaintBoundary(
                        child: CustomPaint(
                          size: Size(size + 36, size + 36),
                          painter: _FocusRingPainter(
                            fraction: s.focusRemaining.inSeconds /
                                (s.focusPreviewMinutes * 60).clamp(1, 3600),
                            color: mode.accent,
                          ),
                        ),
                      ),

                    // Drag Preview Hand
                    if (_dragMinutes != null)
                      RepaintBoundary(
                        child: CustomPaint(
                          size: Size(size, size),
                          painter: _PreviewHandPainter(
                            minutes: _dragMinutes!,
                            color: mode.accent,
                          ),
                        ),
                      ),

                    // Drag Minutes Indicator
                    if (_dragMinutes != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: size * 0.62),
                        child: _MiniChip(
                          label: '${_dragMinutes!} min',
                          color: mode.accent,
                          ink: ink,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dial painter rendering a thin outer circle and 12 radial hour tick marks.
class ClockDialPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  ClockDialPainter({
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2.0;
    final scale = radius / 122.0;
    final ringRadius = radius - (1.5 * scale);

    final ringPaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.35 : 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * scale;

    final tickPaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.50 : 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale
      ..strokeCap = StrokeCap.round;

    final center = Offset(radius, radius);

    // 1. Thin outer perimeter circle
    canvas.drawCircle(center, ringRadius, ringPaint);

    // 2. 12 radial hour tick marks
    final tickLength = 10.0 * scale;
    final angle = 2.0 * math.pi / 12.0;

    canvas.save();
    canvas.translate(radius, radius);

    for (int i = 0; i < 12; i++) {
      canvas.drawLine(
        Offset(0.0, -ringRadius),
        Offset(0.0, -ringRadius + tickLength),
        tickPaint,
      );
      canvas.rotate(angle);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ClockDialPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isDark != isDark;
  }
}

/// Hands painter rendering minimalist linear hour and minute hands
/// with rounded caps and a prominent solid center dot.
class ClockHandsPainter extends CustomPainter {
  final DateTime time;
  final Color handColor;

  ClockHandsPainter({
    required this.time,
    required this.handColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2.0;
    final scale = radius / 122.0;

    final hourAngle = 2.0 *
        math.pi *
        (((time.hour % 12) / 12.0) + (time.minute / 720.0));
    final minuteAngle =
        2.0 * math.pi * ((time.minute + (time.second / 60.0)) / 60.0);

    final hourLength = radius * 0.48;
    final minuteLength = radius * 0.74;

    final handPaint = Paint()
      ..color = handColor
      ..strokeWidth = 2.8 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = handColor
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(radius, radius);

    // 1. Hour Hand (straight line from center, no tail)
    canvas.save();
    canvas.rotate(hourAngle);
    canvas.drawLine(Offset.zero, Offset(0.0, -hourLength), handPaint);
    canvas.restore();

    // 2. Minute Hand (straight line from center, no tail)
    canvas.save();
    canvas.rotate(minuteAngle);
    canvas.drawLine(Offset.zero, Offset(0.0, -minuteLength), handPaint);
    canvas.restore();

    // 3. Center Dot (prominent solid circle matching the reference image)
    canvas.drawCircle(Offset.zero, 5.8 * scale, dotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ClockHandsPainter oldDelegate) {
    return oldDelegate.time.second != time.second ||
        oldDelegate.time.minute != time.minute ||
        oldDelegate.time.hour != time.hour ||
        oldDelegate.handColor != handColor;
  }
}

class _FocusRingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  _FocusRingPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * fraction.clamp(0, 1),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.9),
    );
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(_FocusRingPainter old) =>
      old.fraction != fraction || old.color != color;
}

class _PreviewHandPainter extends CustomPainter {
  final int minutes;
  final Color color;
  _PreviewHandPainter({required this.minutes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final angle = (minutes / 60) * 2 * math.pi - math.pi / 2;
    final tip =
        center + Offset(math.cos(angle), math.sin(angle)) * (size.width * 0.34);
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
    canvas.drawCircle(tip, 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PreviewHandPainter old) =>
      old.minutes != minutes || old.color != color;
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color ink;
  const _MiniChip({
    required this.label,
    required this.color,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    return liquid(
      radius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      tint: const Color(0xFF18181B),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
