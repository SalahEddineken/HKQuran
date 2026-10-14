import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../state/app_state.dart';
import '../theme/palette.dart';
import 'glass.dart';

// ═══════════════════════════════════════════════════════════════════════
//  Focus pill
//
//  Geometry, colour and timing decoded from reference recording:
//
//    track    114×48 idle → 110×48 armed (112×48 focusing countdown)
//    knob     Ø40 white, 4 px inset, smooth travel, 300 ms easeOutCubic
//    label    swaps sides with the knob; dips cleanly out of sight
//             halfway through so characters never awkwardly poke out
//             behind the knob. Sized so "Focus", "تركيز" and "MM:SS"
//             never clip or truncate.
//    presets  three Ø48 chips rolling out from behind the track:
//             slide, spin, fade, scale with 60 ms lead-in + 65 ms stagger.
//             Properly collapses when a focus session starts.
// ═══════════════════════════════════════════════════════════════════════
const double _kPillH = 48;
const double _kKnobD = 40;
const double _kKnobInset = 4;

/// Width of the label slot. Ample width prevents any clipping across English,
/// Arabic, or tabular digits countdown.
const double _kLabelSlot = 46;
const double _kCountSlot = 48;

const double _kLabelGapIdle = 10; // knob → label, idle
const double _kLabelGapArmed = 8; // label → knob, armed
const double _kLabelPadIdle = 14; // label → track edge, idle
const double _kLabelPadArmed = 12; // track edge → label, armed

/// Width the pill rests at when idle: 4 + 40 + 10 + 46 + 14 = 114 px.
const double _kPillIdleW =
    _kKnobInset + _kKnobD + _kLabelGapIdle + _kLabelSlot + _kLabelPadIdle;

const double _kChipD = 48;
const double _kChipGap = 10; // chip ↔ chip (pitch 58)
const double _kStripGap = 17; // armed track → first chip
const int _kPresetCount = 3;
const List<int> _kPresetMinutes = [15, 30, 45];
const double _kPresetRowW =
    _kPresetCount * _kChipD + (_kPresetCount - 1) * _kChipGap;

const Duration _kToggleDur = Duration(milliseconds: 300);
const Duration _kStripDur = Duration(milliseconds: 280);
const Duration _kPresetStagger = Duration(milliseconds: 65);
const Duration _kPresetLeadIn = Duration(milliseconds: 60);
const Duration _kPresetDur = Duration(milliseconds: 340);

double _lerp(double a, double b, double t) => a + (b - a) * t;

String _mmss(Duration d) => '${d.inMinutes.toString().padLeft(2, '0')}:'
    '${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// The focus toggle: a pill that flips on to reveal three duration chips
/// which roll out from behind it.
class FocusPill extends StatefulWidget {
  final bool open;
  final ValueChanged<bool> onOpenChanged;

  const FocusPill({
    super.key,
    required this.open,
    required this.onOpenChanged,
  });

  @override
  State<FocusPill> createState() => _FocusPillState();
}

class _FocusPillState extends State<FocusPill> {
  Timer? _ticker;
  AppState? _state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state = AppStateScope.of(context);
    _syncTicker(_state!.focusing);
  }

  void _syncTicker(bool focusing) {
    if (focusing == (_ticker != null)) return;
    _ticker?.cancel();
    _ticker = null;
    if (focusing) {
      _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!mounted) return;
        if (_state?.focusing != true) {
          _syncTicker(false);
          if (mounted) setState(() {});
          return;
        }
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mode = s.themeMode;
    final focusing = s.focusing;
    final armed = widget.open || focusing;
    final showPresets = widget.open && !focusing;
    _syncTicker(focusing);

    // Keep the pill anchored while presets unfold on screens wide enough.
    final screenW = MediaQuery.sizeOf(context).width;
    final anchored =
        screenW / 2 - _kPillIdleW / 2 - 24 > _kPresetRowW + _kStripGap;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: _kLabelSlot,
        end: focusing ? _kCountSlot : _kLabelSlot,
      ),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, slot, _) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: armed ? 1.0 : 0.0),
        duration: _kToggleDur,
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: showPresets ? 1.0 : 0.0),
          duration: _kStripDur,
          curve: Curves.easeOutCubic,
          builder: (context, stripT, _) {
            final pillW = _lerp(
              _kKnobInset + _kKnobD + _kLabelGapIdle + slot + _kLabelPadIdle,
              _kLabelPadArmed + slot + _kLabelGapArmed + _kKnobD + _kKnobInset,
              t,
            );

            final row = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FocusToggle(
                  width: pillW,
                  t: t,
                  slot: slot,
                  focusing: focusing,
                  mode: mode,
                  label: s.tr('focus'),
                  remaining: s.focusRemaining,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (focusing) {
                      s.endFocus();
                    } else {
                      widget.onOpenChanged(!widget.open);
                    }
                  },
                ),
                SizedBox(width: _kStripGap * stripT),
                ClipRect(
                  clipper: const _HorizontalClipper(),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: stripT,
                    // 1.0 ensures Align hugs height without vertically dragging
                    // the pill.
                    heightFactor: 1.0,
                    child: _FocusPresets(
                      key: ValueKey<bool>(showPresets),
                      visible: showPresets,
                      ink: mode.ink,
                      label: s.tr('min'),
                      onPick: (m) {
                        HapticFeedback.lightImpact();
                        widget.onOpenChanged(false);
                        s.startFocus(m);
                      },
                    ),
                  ),
                ),
              ],
            );

            if (!anchored) return row;
            return Transform.translate(
              offset: Offset(
                (isRtl ? -1.0 : 1.0) *
                    (_kStripGap + _kPresetRowW) *
                    stripT /
                    2.0,
                0,
              ),
              child: row,
            );
          },
        ),
      ),
    );
  }
}

/// The pill itself: track, label and knob, all driven by a single `t`
/// (0 = idle, 1 = armed).
class _FocusToggle extends StatelessWidget {
  final double width;
  final double t;
  final double slot;
  final bool focusing;
  final AppThemeMode mode;
  final String label;
  final Duration remaining;
  final VoidCallback onTap;

  const _FocusToggle({
    required this.width,
    required this.t,
    required this.slot,
    required this.focusing,
    required this.mode,
    required this.label,
    required this.remaining,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = mode.brightness == Brightness.light;

    final track = Color.lerp(
      isLight ? Colors.white : const Color(0xFF222226),
      isLight ? const Color(0xFF232427) : const Color(0xFF3A3D42),
      t,
    )!;
    final labelColor = Color.lerp(
      isLight ? const Color(0xFF1E1E20) : Colors.white,
      Colors.white,
      t,
    )!;

    final labelStart = _lerp(
      _kKnobInset + _kKnobD + _kLabelGapIdle,
      _kLabelPadArmed,
      t,
    );
    final knobStart = _lerp(_kKnobInset, width - _kKnobInset - _kKnobD, t);

    // As the knob crosses the pill, the label dips cleanly out of sight
    // so characters never awkwardly poke out behind the knob.
    final labelOpacity = Curves.easeInOut
        .transform(((t - 0.5).abs() * 2.0).clamp(0.0, 1.0));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: liquid(
        radius: _kPillH / 2,
        width: width,
        height: _kPillH,
        tint: track,
        child: Stack(
          children: [
            PositionedDirectional(
              start: labelStart,
              top: 0,
              bottom: 0,
              width: slot,
              child: Center(
                child: Opacity(
                  opacity: labelOpacity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: focusing
                        ? Text(
                            _mmss(remaining),
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: labelColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          )
                        : Text(
                            label,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: labelColor,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              start: knobStart,
              top: _kKnobInset,
              child: Container(
                width: _kKnobD,
                height: _kKnobD,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The three duration chips. They roll in when the menu opens.
class _FocusPresets extends StatelessWidget {
  final bool visible;
  final Color ink;
  final String label;
  final ValueChanged<int> onPick;

  const _FocusPresets({
    super.key,
    required this.visible,
    required this.ink,
    required this.label,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        opacity: visible ? 1.0 : 0.0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _kPresetCount; i++) ...[
              if (i > 0) const SizedBox(width: _kChipGap),
              _DurationButton(
                minutes: _kPresetMinutes[i],
                label: label,
                ink: ink,
                onTap: () => onPick(_kPresetMinutes[i]),
              )
                  .animate()
                  .fadeIn(
                    delay: _kPresetLeadIn + _kPresetStagger * i,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                  )
                  .slideX(
                    begin: isRtl ? 0.55 : -0.55,
                    end: 0,
                    delay: _kPresetLeadIn + _kPresetStagger * i,
                    duration: _kPresetDur,
                    curve: Curves.easeOutCubic,
                  )
                  .rotate(
                    begin: isRtl ? 0.075 : -0.075,
                    end: 0,
                    delay: _kPresetLeadIn + _kPresetStagger * i,
                    duration: _kPresetDur,
                    curve: Curves.easeOutCubic,
                  )
                  .scale(
                    begin: const Offset(0.86, 0.86),
                    end: const Offset(1, 1),
                    delay: _kPresetLeadIn + _kPresetStagger * i,
                    duration: _kPresetDur,
                    curve: Curves.easeOutCubic,
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact circular glass chip for a focus duration — Ø48, matching the
/// pill's height so the strip reads as one continuous control.
class _DurationButton extends StatefulWidget {
  final int minutes;
  final String label;
  final Color ink;
  final VoidCallback onTap;

  const _DurationButton({
    required this.minutes,
    required this.label,
    required this.ink,
    required this.onTap,
  });

  @override
  State<_DurationButton> createState() => _DurationButtonState();
}

class _DurationButtonState extends State<_DurationButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: liquid(
          radius: _kChipD / 2,
          width: _kChipD,
          height: _kChipD,
          tint: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : const Color(0xFF222226),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.minutes}',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.05,
                    fontWeight: FontWeight.w600,
                    color: widget.ink,
                  ),
                ),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.05,
                    color: widget.ink.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Clips the preset strip horizontally only, so the chips can spin past the
/// pill's height without their corners being shaved off.
class _HorizontalClipper extends CustomClipper<Rect> {
  const _HorizontalClipper();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, -400, size.width, size.height + 400);

  @override
  bool shouldReclip(covariant _HorizontalClipper oldClipper) => false;
}
