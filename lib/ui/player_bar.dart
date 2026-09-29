import '../theme/palette.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../audio/chapter_player.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'glass.dart';

/// Bottom glass transport: spinning vinyl, waveform scrubber, controls.
///
/// Per-frame work is isolated behind [RepaintBoundary]s so the liquid-glass
/// backdrop shader never re-runs while audio position ticks or the vinyl
/// spins — only the tiny spinning/text layers repaint.
class PlayerBar extends StatefulWidget {
  const PlayerBar({super.key});

  @override
  State<PlayerBar> createState() => _PlayerBarState();
}

class _PlayerBarState extends State<PlayerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final playing = AppStateScope.of(context).player.playing;
    playing ? _spin.repeat() : _spin.stop();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  static String _ts(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$sec' : '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final player = s.player;
    final mode = s.themeMode;
    final meta = kSurahs[s.chapter - 1];
    final reciter = reciterById(player.reciterId);
    final width = MediaQuery.sizeOf(context).width;
    final barWidth = (width * 0.92).clamp(300.0, 780.0);

    final playing = player.playing;
    if (playing && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!playing && _spin.isAnimating) {
      _spin.stop();
    }

    return liquid(
      width: barWidth,
      radius: 32,
      tint: Colors.white.withValues(alpha: 0.09),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // vinyl — spins continuously, but only this layer repaints.
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _spin,
              builder: (context, _) => Transform.rotate(
                angle: _spin.value * 2 * math.pi,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        mode.accent.withValues(alpha: 0.9),
                        mode.accent.withValues(alpha: 0.45),
                        const Color(0xFF1A1A1A),
                      ],
                      stops: const [0.0, 0.18, 1.0],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: mode.ink.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // info + scrubber
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.ar
                            ? '${meta.arShort} • ${reciter.ar}'
                            : '${meta.en} • ${reciter.en}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: mode.ink.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Position ticks every ~200 ms while playing; keep the
                    // text in its own layer so the glass never repaints.
                    Flexible(
                      child: RepaintBoundary(
                        child: StreamBuilder<Duration>(
                          stream: player.rawPlayer.positionStream,
                          builder: (context, snap) {
                            final pos = snap.data ?? player.position;
                            final dur = player.duration;
                            return FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${_ts(pos)} / ${_ts(dur)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                  color: mode.inkSoft,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _WaveformScrubber(
                  player: player,
                  seed: s.chapter,
                  accent: mode.accent,
                  base: mode.ink,
                  enabled: player.status == PlayerStatus.ready,
                  onSeek: player.seekFraction,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // transport
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Btn(
                icon: Icons.skip_previous_rounded,
                size: 34,
                color: mode.ink,
                onTap: () => s.openSurah(s.chapter > 1 ? s.chapter - 1 : 114),
              ),
              const SizedBox(width: 4),
              _Btn(
                icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 56,
                filled: true,
                accent: mode.accent,
                color: mode.ink,
                onTap: player.togglePlay,
              ),
              const SizedBox(width: 4),
              _Btn(
                icon: Icons.skip_next_rounded,
                size: 34,
                color: mode.ink,
                onTap: () => s.openSurah(s.chapter < 114 ? s.chapter + 1 : 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool filled;
  final Color color;
  final Color? accent;
  final VoidCallback? onTap;

  const _Btn({
    required this.icon,
    required this.size,
    required this.color,
    this.filled = false,
    this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? accent : color.withValues(alpha: 0.08),
      ),
      child: Icon(
        icon,
        size: size * 0.55,
        color: filled ? const Color(0xFF111111) : color,
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class _WaveformScrubber extends StatefulWidget {
  final ChapterPlayer player;
  final int seed;
  final Color accent;
  final Color base;
  final bool enabled;
  final ValueChanged<double> onSeek;

  const _WaveformScrubber({
    required this.player,
    required this.seed,
    required this.accent,
    required this.base,
    required this.enabled,
    required this.onSeek,
  });

  @override
  State<_WaveformScrubber> createState() => _WaveformScrubberState();
}

class _WaveformScrubberState extends State<_WaveformScrubber> {
  static const _barCount = 64;

  double? _dragFraction;

  double _height(int i, int n) {
    final t = i / n;
    final env = 0.45 + 0.55 * math.sin(math.pi * t); // fade at edges
    final wobble =
        0.5 + 0.5 * math.sin(i * 0.55 + widget.seed * 0.7) *
            math.cos(i * 0.21 + widget.seed);
    final noise = (math.sin(i * 12.9898 + widget.seed * 78.233) * 43758.5453) %
        1;
    final r = noise.abs();
    return (0.18 + 0.82 * (0.55 * wobble + 0.45 * r)) * env;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;

        Widget bars(double progress) => CustomPaint(
              size: Size(w, 30),
              painter: _BarsPainter(
                progress: progress,
                accent: widget.accent,
                base: widget.base,
                heightFn: _height,
                n: _barCount,
              ),
            );
        return MouseRegion(
          cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: widget.enabled
                ? (d) => widget.onSeek((d.localPosition.dx / w).clamp(0, 1))
                : null,
            onHorizontalDragStart: widget.enabled
                ? (d) => setState(
                      () => _dragFraction = (d.localPosition.dx / w).clamp(0, 1),
                    )
                : null,
            onHorizontalDragUpdate: widget.enabled
                ? (d) => setState(
                      () => _dragFraction = (d.localPosition.dx / w).clamp(0, 1),
                    )
                : null,
            onHorizontalDragEnd: widget.enabled
                ? (_) {
                    final f = _dragFraction;
                    setState(() => _dragFraction = null);
                    if (f != null) widget.onSeek(f);
                  }
                : null,
            onHorizontalDragCancel: widget.enabled
                ? () => setState(() => _dragFraction = null)
                : null,
            // The played fraction ticks with the position stream (~5x/s) so
            // the bar moves smoothly; the whole widget sits behind a
            // RepaintBoundary so only these bars repaint, never the glass.
            child: RepaintBoundary(
              child: StreamBuilder<Duration>(
                stream: widget.player.rawPlayer.positionStream,
                builder: (context, snap) {
                  final dur = widget.player.duration.inMilliseconds;
                  final pos = (snap.data ?? widget.player.position)
                      .inMilliseconds;
                  final live = dur == 0 ? 0.0 : (pos / dur).clamp(0.0, 1.0);
                  return bars(_dragFraction ?? live);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BarsPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final Color base;
  final double Function(int, int) heightFn;
  final int n;

  _BarsPainter({
    required this.progress,
    required this.accent,
    required this.base,
    required this.heightFn,
    required this.n,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 2.0;
    final bw = (size.width - gap * (n - 1)) / n;
    final played = progress * n;
    for (var i = 0; i < n; i++) {
      final h = heightFn(i, n) * size.height;
      final x = i * (bw + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, (size.height - h) / 2, bw, h),
        Radius.circular(bw / 2),
      );
      final paint = Paint()
        ..color = i < played ? accent : base.withValues(alpha: 0.28);
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.progress != progress || old.accent != accent || old.base != base;
}
