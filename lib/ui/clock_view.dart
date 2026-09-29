import '../theme/palette.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:animated_analog_clock/animated_analog_clock.dart';
import 'package:flutter/material.dart';

import '../state/app_state.dart';

/// The centrepiece — a numeral-less analog clock in the spirit of zeno.day.
/// * Idle: real local time, two hairline hands, no numbers.
/// * Drag anywhere on the dial to set a focus session (0–60 min), then
///   release to start it — the minute hand sweeps the countdown down while
///   the hour hand keeps real time, exactly like zeno.
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

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 400), (_) {
      final s = _state;
      if (s != null && (s.focusing || _dragMinutes != null) && mounted) {
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
    final ink = mode.ink;
    final focusing = s.focusing;

    return LayoutBuilder(
      builder: (context, box) {
        final size = math
            .min(math.min(box.maxWidth, box.maxHeight), 300.0)
            .clamp(160.0, 300.0);

        DateTime clockFn() {
          if (!focusing) return DateTime.now();
          final rem = s.focusRemaining;
          final now = DateTime.now();
          final mins = rem.inMinutes.clamp(0, 59);
          final secs = rem.inSeconds % 60;
          return DateTime(now.year, now.month, now.day, now.hour, mins, secs);
        }

        return MouseRegion(
          cursor: widget.interactive
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) {},
            onPanUpdate: (d) => _dragUpdate(d.localPosition, Size(size, size)),
            onPanEnd: (_) => _dragEnd(Size(size, size)),
            onDoubleTap: () {
              if (focusing) s.endFocus();
            },
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ticks every second; keep it on its own layer so the
                  // glass group behind it never repaints with the hands.
                  RepaintBoundary(
                    child: AnimatedAnalogClock(
                      size: size,
                      clock: clockFn,
                      dialType: DialType.dashes,
                      hourHandColor: ink,
                      minuteHandColor: ink,
                      showSecondHand: false,
                      hourDashColor: ink,
                      minuteDashColor: ink.withValues(alpha: 0.35),
                      centerDotColor: mode.accent,
                      backgroundColor: Colors.transparent,
                      extendHourHand: false,
                      extendMinuteHand: false,
                      updateInterval: const Duration(seconds: 1),
                    ),
                  ),
                  if (focusing)
                    RepaintBoundary(
                      child: CustomPaint(
                        size: Size(size + 36, size + 36),
                        painter: _FocusRingPainter(
                          fraction:
                              s.focusRemaining.inSeconds /
                              (s.focusPreviewMinutes * 60).clamp(1, 3600),
                          color: mode.accent,
                        ),
                      ),
                    ),
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
        );
      },
    );
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
