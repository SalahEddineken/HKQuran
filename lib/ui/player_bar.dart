import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/chapter_player.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import 'glass.dart';
import 'vibe_hud.dart';

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

  Timer? _volHudTimer;
  bool _showVolHud = false;
  bool _showVibeHud = false;
  double? _lastVolume;

  void _showVolumeFeedback() {
    setState(() => _showVolHud = true);
    _volHudTimer?.cancel();
    _volHudTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showVolHud = false);
    });
  }

  void _handleScroll(PointerScrollEvent event, AppState s) {
    final dy = event.scrollDelta.dy;
    if (dy == 0) return;
    // dy < 0 = scroll wheel UP (increase volume)
    // dy > 0 = scroll wheel DOWN (decrease volume)
    const step = 0.05;
    final change = dy < 0 ? step : -step;
    final newVol = ((s.reciterVolume + change) * 20).round() / 20.0;
    s.setReciterVolume(newVol.clamp(0.0, 1.0));
    _showVolumeFeedback();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppStateScope.of(context);
    final playing = s.player.playing;
    playing ? _spin.repeat() : _spin.stop();
    if (_lastVolume != null && _lastVolume != s.reciterVolume) {
      _showVolumeFeedback();
    }
    _lastVolume = s.reciterVolume;
  }

  @override
  void dispose() {
    _volHudTimer?.cancel();
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
    final isImage = kWatchfaces[s.watchface].isImage;
    final meta = kSurahs[s.chapter - 1];
    final reciter = reciterById(player.reciterId);
    final width = MediaQuery.sizeOf(context).width;
    final isSmall = width < 600;
    final barWidth = (width * (isSmall ? 0.95 : 0.92)).clamp(280.0, 780.0);

    final playing = player.playing;
    if (playing && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!playing && _spin.isAnimating) {
      _spin.stop();
    }

    final verseNum = player.verses.isNotEmpty
        ? ' • ${player.currentVerse + 1}/${meta.ayahs}'
        : '';
    final surahTitle = s.ar
        ? '${meta.arShort}$verseNum • ${reciter.ar}'
        : '${meta.en}$verseNum • ${reciter.en}';

    final pct = (s.reciterVolume * 100).round();
    final volIcon = s.reciterVolume == 0
        ? Icons.volume_off_rounded
        : (s.reciterVolume < 0.4
            ? Icons.volume_down_rounded
            : Icons.volume_up_rounded);

    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _handleScroll(event, s);
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Floating HUD showing volume percentage when scrolling mouse wheel
          Positioned(
            top: -44,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              opacity: _showVolHud ? 1.0 : 0.0,
              child: IgnorePointer(
                child: liquid(
                  radius: 999,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  tint: mode.brightness == Brightness.light
                      ? Colors.white
                      : const Color(0xFF1E1E22),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(volIcon, size: 15, color: mode.accent),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 58,
                        height: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: s.reciterVolume,
                            backgroundColor: mode.ink.withValues(alpha: 0.15),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(mode.accent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: mode.ink,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Floating Vibe HUD Card directly above PlayerBar
          Positioned(
            bottom: isSmall ? 68 : 84,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              offset: _showVibeHud ? Offset.zero : const Offset(0, 0.12),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showVibeHud ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !_showVibeHud,
                  child: VibeHudCard(
                    onClose: () => setState(() => _showVibeHud = false),
                    onOpenFullMixer: () {
                      setState(() => _showVibeHud = false);
                      s.onOpenAmbientPanel?.call();
                    },
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: barWidth,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 12 : 20,
                vertical: isSmall ? 8 : 14,
              ),
              child: Row(
                children: [
            // Spinning vinyl play/pause button
            _SpinningVinylButton(
              size: isSmall ? 40 : 54,
              animation: _spin,
              playing: playing,
              accent: mode.accent,
              ink: mode.ink,
              onTap: player.togglePlay,
              tooltip: s.tr(playing ? 'pause' : 'play'),
            ),
            SizedBox(width: isSmall ? 10 : 16),

            // info + scrubber
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          surahTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isSmall ? 11.5 : 13.5,
                            fontWeight: FontWeight.w600,
                            color: mode.ink.withValues(alpha: 0.9),
                            shadows: isImage
                                ? const [
                                    Shadow(
                                      color: Color(0xB3000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Repeat Ayah toggle button in surat title
                      GestureDetector(
                        onTap: s.cycleAyahRepeatTarget,
                        child: Tooltip(
                          message:
                              '${s.tr('repeatAyah')}: ${player.ayahRepeatTarget == 0 ? "∞" : "${player.ayahRepeatTarget}x"}',
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmall ? 5 : 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: player.repeatMode ==
                                      AudioRepeatMode.repeatAyah
                                  ? (mode.brightness == Brightness.light
                                      ? const Color(0xFFFBF4E6)
                                      : const Color(0xFF2D271B))
                                  : (mode.brightness == Brightness.light
                                      ? const Color(0xFFF4F4F5)
                                      : const Color(0xFF27272A)),
                              border: Border.all(
                                color: player.repeatMode ==
                                        AudioRepeatMode.repeatAyah
                                    ? mode.accent
                                    : (mode.brightness == Brightness.light
                                        ? const Color(0xFFE4E4E7)
                                        : const Color(0xFF333338)),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.repeat_rounded,
                                  size: isSmall ? 11 : 13,
                                  color: player.repeatMode ==
                                          AudioRepeatMode.repeatAyah
                                      ? mode.accent
                                      : mode.inkSoft,
                                ),
                                const SizedBox(width: 2.5),
                                Text(
                                  player.ayahRepeatTarget == 0
                                      ? '∞'
                                      : '${player.ayahRepeatTarget}x',
                                  style: TextStyle(
                                    fontSize: isSmall ? 9 : 10,
                                    fontWeight: FontWeight.w600,
                                    color: player.repeatMode ==
                                            AudioRepeatMode.repeatAyah
                                        ? mode.accent
                                        : mode.inkSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (s.mixer.activeCount > 0) ...[
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _showVibeHud = !_showVibeHud);
                          },
                          child: Tooltip(
                            message: s.tr('vibeQuran'),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmall ? 5 : 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: mode.accent.withValues(alpha: 0.18),
                                border: Border.all(
                                  color: mode.accent.withValues(alpha: 0.45),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: isSmall ? 10 : 12,
                                    color: mode.accent,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    s.mixer.activePreset != null
                                        ? (s.ar
                                            ? s.mixer.activePreset!.ar
                                            : s.mixer.activePreset!.en)
                                        : '${s.mixer.activeCount}',
                                    style: TextStyle(
                                      fontSize: isSmall ? 9 : 10,
                                      fontWeight: FontWeight.w700,
                                      color: mode.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
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
                                    fontSize: isSmall ? 10.5 : 12,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                    color: isImage
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : mode.inkSoft,
                                    shadows: isImage
                                        ? const [
                                            Shadow(
                                              color: Color(0xB3000000),
                                              blurRadius: 6,
                                              offset: Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmall ? 6 : 8),
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
            SizedBox(width: isSmall ? 8 : 14),

                  // transport: previous & next
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Btn(
                          icon: Icons.skip_previous_rounded,
                          size: isSmall ? 32 : 38,
                          color: mode.ink,
                          tooltip: s.ar ? 'السورة السابقة' : 'Previous Surah',
                          onTap: () => s.openSurah(
                              s.chapter > 1 ? s.chapter - 1 : 114),
                        ),
                        SizedBox(width: isSmall ? 3 : 6),
                        _Btn(
                          icon: Icons.skip_next_rounded,
                          size: isSmall ? 32 : 38,
                          color: mode.ink,
                          tooltip: s.ar ? 'السورة التالية' : 'Next Surah',
                          onTap: () => s.openSurah(
                              s.chapter < 114 ? s.chapter + 1 : 1),
                        ),
                        SizedBox(width: isSmall ? 3 : 6),
                        _Btn(
                          icon: Icons.auto_awesome_rounded,
                          size: isSmall ? 32 : 38,
                          color: s.mixer.activeCount > 0 ? mode.accent : mode.ink,
                          highlight: s.mixer.activeCount > 0 || _showVibeHud,
                          tooltip: s.tr('vibeQuran'),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _showVibeHud = !_showVibeHud);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpinningVinylButton extends StatefulWidget {
  final Animation<double> animation;
  final bool playing;
  final Color accent;
  final Color ink;
  final VoidCallback onTap;
  final String tooltip;

  final double size;

  const _SpinningVinylButton({
    required this.animation,
    required this.playing,
    required this.accent,
    required this.ink,
    required this.onTap,
    required this.tooltip,
    this.size = 54,
  });

  @override
  State<_SpinningVinylButton> createState() => _SpinningVinylButtonState();
}

class _SpinningVinylButtonState extends State<_SpinningVinylButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final playing = widget.playing;
    final accent = widget.accent;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed
                ? 0.93
                : (_hovered ? 1.04 : 1.0),
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(
                      alpha: playing ? 0.38 : (_hovered ? 0.26 : 0.12),
                    ),
                    blurRadius: playing ? (widget.size * 0.3) : (_hovered ? 12 : 8),
                    spreadRadius: playing ? 1 : 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: widget.animation,
                  builder: (context, _) => Transform.rotate(
                    angle: widget.animation.value * 2 * math.pi,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accent.withValues(alpha: 0.9),
                            accent.withValues(alpha: 0.45),
                            const Color(0xFF1E1E22),
                            const Color(0xFF121214),
                          ],
                          stops: const [0.0, 0.22, 0.65, 1.0],
                        ),
                        border: Border.all(
                          color: accent.withValues(alpha: _hovered ? 0.5 : 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Vinyl light reflection sheen (makes rotation clearly visible)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: 0.14),
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: 0.08),
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: 0.14),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.22, 0.45, 0.55, 0.72, 0.95, 1.0],
                              ),
                            ),
                          ),
                          // Concentric vinyl grooves
                          CustomPaint(
                            painter: _VinylRingsPainter(
                              grooveColor: accent.withValues(alpha: 0.22),
                            ),
                          ),
                          // Center spindle hole/dot
                          Center(
                            child: Container(
                              width: widget.size * (10 / 54),
                              height: widget.size * (10 / 54),
                              decoration: BoxDecoration(
                                color: widget.ink.withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.4),
                                  width: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VinylRingsPainter extends CustomPainter {
  final Color grooveColor;

  const _VinylRingsPainter({required this.grooveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = grooveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    final r = size.width / 2;
    canvas.drawCircle(center, r * 0.55, paint);
    canvas.drawCircle(center, r * 0.70, paint);
    canvas.drawCircle(center, r * 0.85, paint);
  }

  @override
  bool shouldRepaint(_VinylRingsPainter oldDelegate) =>
      oldDelegate.grooveColor != grooveColor;
}

class _Btn extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final String? tooltip;
  final VoidCallback? onTap;
  final bool highlight;

  const _Btn({
    required this.icon,
    required this.size,
    required this.color,
    this.tooltip,
    this.onTap,
    this.highlight = false,
  });

  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final isLight = s.themeMode == AppThemeMode.light;

    final btnSurface = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.highlight
            ? s.themeMode.accent.withValues(alpha: 0.22)
            : (isLight ? Colors.white : const Color(0xFF222226)),
        border: Border.all(
          color: widget.highlight
              ? s.themeMode.accent.withValues(alpha: 0.55)
              : (isLight
                  ? const Color(0xFFE4E4E7)
                  : const Color(0xFF333338)),
          width: widget.highlight ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.highlight
                ? s.themeMode.accent.withValues(alpha: 0.25)
                : (isLight
                    ? const Color(0x0A000000)
                    : const Color(0x28000000)),
            blurRadius: widget.highlight ? 8 : 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          widget.icon,
          size: widget.size * 0.52,
          color: widget.color,
        ),
      ),
    );

    final btn = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: btnSurface,
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: btn);
    }
    return btn;
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
  double? _hoverFraction;

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

        final previewFraction = _dragFraction ?? _hoverFraction;

        return MouseRegion(
          cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onHover: widget.enabled
              ? (e) => setState(() => _hoverFraction = (e.localPosition.dx / w).clamp(0.0, 1.0))
              : null,
          onExit: (_) => setState(() => _hoverFraction = null),
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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                RepaintBoundary(
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
                if (previewFraction != null)
                  Positioned(
                    left: (previewFraction * w - 24).clamp(0.0, w - 48.0),
                    top: -24,
                    child: IgnorePointer(
                      child: liquid(
                        radius: 6,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        tint: const Color(0xFF1E1E22),
                        child: Text(
                          _PlayerBarState._ts(
                            Duration(
                              milliseconds: (widget.player.duration.inMilliseconds * previewFraction).round(),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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


