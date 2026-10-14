import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/palette.dart';
import 'glass.dart';

/// The centerpiece — a clean analog clock based on Benjamin Kao's design
/// (60 precision perimeter tick marks with prominent quarter markers, classic
/// baton hands with drop shadows), with integrated focus
/// session countdown and interaction:
/// * Idle: real local time with hour and minute hands.
/// * Drag anywhere on the dial to set a focus session (0–60 min), then
///   release to start it — minute hand indicates the remaining focus time
///   while the hour hand keeps real local time, framed by a smooth focus ring.
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
    // Ticks every 500ms to stay in sync with seconds and smooth countdowns
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

    // Dial and hands colors
    final Color tickColor = isDark ? Colors.white : const Color(0xFF282A30);
    final Color minuteTickColor =
        isDark ? const Color(0x66FFFFFF) : const Color(0xFF868A94);

    final Color hourHandColor =
        isDark ? Colors.white : const Color(0xFF1B1C20);
    final Color minuteHandColor =
        isDark ? const Color(0xFFE2E4E8) : const Color(0xFF2C2E34);
    final Color centerDotColor = mode.accent;
    final Color handShadowColor =
        isDark ? const Color(0x80000000) : const Color(0x40000000);

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
          maxDial = 180.0;
        } else if (isMobile) {
          maxDial = (screenWidth * 0.68).clamp(200.0, 270.0);
        } else if (isLargeDesktop) {
          maxDial = 360.0;
        } else if (isDesktop) {
          maxDial = 320.0;
        } else {
          maxDial = 290.0;
        }
        final heightCappedDial = math.min(maxDial, screenHeight * 0.42);
        final minDial = isTinyScreen ? 120.0 : (isMobile ? 180.0 : 210.0);
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
                  // Transparent Clock Body Container
                  SizedBox(
                    width: size,
                    height: size,
                    child: Padding(
                      padding: EdgeInsets.all(facePadding),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Dial Face (Ticks) - Cached layer
                          RepaintBoundary(
                            child: CustomPaint(
                              painter: ClockDialPainter(
                                tickColor: tickColor,
                                minuteTickColor: minuteTickColor,
                              ),
                            ),
                          ),
                          // Hands layer (Hour, Minute, Center Pivot)
                          RepaintBoundary(
                            child: CustomPaint(
                              painter: ClockHandsPainter(
                                time: clockFn(),
                                hourHandColor: hourHandColor,
                                minuteHandColor: minuteHandColor,
                                centerDotColor: centerDotColor,
                                shadowColor: handShadowColor,
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

/// Dial painter rendering 60 perimeter ticks with prominent quarter markers.
class ClockDialPainter extends CustomPainter {
  final Color tickColor;
  final Color minuteTickColor;

  ClockDialPainter({
    required this.tickColor,
    required this.minuteTickColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2.0;
    // Calibrated against base dial radius (~122px)
    final scale = radius / 122.0;

    final quarterTickLength = 10.0 * scale;
    final hourTickLength = 7.5 * scale;
    final minuteTickLength = 4.0 * scale;

    final quarterTickWidth = 2.4 * scale;
    final hourTickWidth = 1.8 * scale;
    final minuteTickWidth = 1.0 * scale;

    final angle = 2.0 * math.pi / 60.0;

    final quarterTickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = quarterTickWidth
      ..strokeCap = StrokeCap.round;

    final hourTickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = hourTickWidth
      ..strokeCap = StrokeCap.round;

    final minuteTickPaint = Paint()
      ..color = minuteTickColor
      ..strokeWidth = minuteTickWidth
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(radius, radius);

    for (int i = 0; i < 60; i++) {
      final isQuarter = (i % 15 == 0);
      final isHour = (i % 5 == 0);

      // Draw tick marks
      if (isQuarter) {
        canvas.drawLine(
          Offset(0.0, -radius + (1.5 * scale)),
          Offset(0.0, -radius + (1.5 * scale) + quarterTickLength),
          quarterTickPaint,
        );
      } else if (isHour) {
        canvas.drawLine(
          Offset(0.0, -radius + (1.5 * scale)),
          Offset(0.0, -radius + (1.5 * scale) + hourTickLength),
          hourTickPaint,
        );
      } else {
        canvas.drawLine(
          Offset(0.0, -radius + (1.5 * scale)),
          Offset(0.0, -radius + (1.5 * scale) + minuteTickLength),
          minuteTickPaint,
        );
      }

      canvas.rotate(angle);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ClockDialPainter oldDelegate) {
    return oldDelegate.tickColor != tickColor ||
        oldDelegate.minuteTickColor != minuteTickColor;
  }
}

/// Hands painter rendering classic sculpted baton hour and minute hands
/// with realistic drop shadows and a center pivot cap.
class ClockHandsPainter extends CustomPainter {
  final DateTime time;
  final Color hourHandColor;
  final Color minuteHandColor;
  final Color centerDotColor;
  final Color shadowColor;

  ClockHandsPainter({
    required this.time,
    required this.hourHandColor,
    required this.minuteHandColor,
    required this.centerDotColor,
    required this.shadowColor,
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

    final hourHandPaint = Paint()
      ..color = hourHandColor
      ..style = PaintingStyle.fill;

    final minuteHandPaint = Paint()
      ..color = minuteHandColor
      ..style = PaintingStyle.fill;

    // 1. Hour Hand (baton shape with tail)
    {
      canvas.save();
      canvas.translate(radius, radius);
      canvas.rotate(hourAngle);

      final hw = 5.0 * scale;
      final tail = 10.0 * scale;
      final tip = -radius + (radius / 3.0) + (radius / 8.0);

      final hourPath = Path()
        ..moveTo(-hw, tail)
        ..lineTo(-hw, tip)
        ..lineTo(hw, tip)
        ..lineTo(hw, tail)
        ..close();

      canvas.drawShadow(hourPath, shadowColor, 6.0 * scale, false);
      canvas.drawPath(hourPath, hourHandPaint);
      canvas.restore();
    }

    // 2. Minute Hand (slender baton shape with tail)
    {
      canvas.save();
      canvas.translate(radius, radius);
      canvas.rotate(minuteAngle);

      final mw = 3.5 * scale;
      final tail = 13.0 * scale;
      final tip = -radius + (radius / 10.0);

      final minutePath = Path()
        ..moveTo(-mw, tail)
        ..lineTo(-mw, tip)
        ..lineTo(mw, tip)
        ..lineTo(mw, tail)
        ..close();

      canvas.drawShadow(minutePath, shadowColor, 4.0 * scale, false);
      canvas.drawPath(minutePath, minuteHandPaint);
      canvas.restore();
    }

    // 3. Center Pivot Cap
    {
      final center = Offset(radius, radius);
      // Outer collar / cap in accent color
      canvas.drawCircle(
        center,
        4.5 * scale,
        Paint()
          ..color = centerDotColor
          ..style = PaintingStyle.fill,
      );
      // Inner pin in hour hand color
      canvas.drawCircle(
        center,
        2.0 * scale,
        Paint()
          ..color = hourHandColor
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ClockHandsPainter oldDelegate) {
    return oldDelegate.time.second != time.second ||
        oldDelegate.time.minute != time.minute ||
        oldDelegate.time.hour != time.hour ||
        oldDelegate.hourHandColor != hourHandColor ||
        oldDelegate.minuteHandColor != minuteHandColor ||
        oldDelegate.centerDotColor != centerDotColor ||
        oldDelegate.shadowColor != shadowColor;
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
