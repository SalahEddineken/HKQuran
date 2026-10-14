import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';

import '../data/hijri.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import 'ayah_card.dart';
import 'background.dart';
import 'clock_view.dart';
import 'glass.dart';
import 'panels.dart';
import 'player_bar.dart';
import 'focus_pill.dart';
import 'reader_page.dart';

/// The single immersive view: background watchface, date, focus controls,
/// the ayah card over the analog clock, the transport bar, the action rail
/// and the sliding glass panels.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PanelKind? _panel;
  bool _focusMenuOpen = false;
  bool _uriRead = false;
  bool _initialSurahLoaded = false;
  AppState? _state;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    final s = _state;
    if (s == null) return;

    if (key == LogicalKeyboardKey.space) {
      s.player.togglePlay();
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      s.player.seekRelative(-1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      s.player.seekRelative(1);
    } else if (key == LogicalKeyboardKey.keyM) {
      s.toggleReciterMute();
    } else if (key == LogicalKeyboardKey.keyF) {
      if (s.focusing) {
        s.endFocus();
      } else {
        setState(() => _focusMenuOpen = !_focusMenuOpen);
      }
    } else if (key == LogicalKeyboardKey.keyV) {
      _togglePanel(PanelKind.ambient);
    } else if (key == LogicalKeyboardKey.digit1) {
      _togglePanel(PanelKind.surahs);
    } else if (key == LogicalKeyboardKey.digit2) {
      _togglePanel(PanelKind.reciters);
    } else if (key == LogicalKeyboardKey.digit3) {
      _togglePanel(PanelKind.ambient);
    } else if (key == LogicalKeyboardKey.digit4) {
      _togglePanel(PanelKind.settings);
    } else if (key == LogicalKeyboardKey.escape) {
      if (_panel != null) {
        setState(() => _panel = null);
      } else if (_focusMenuOpen) {
        setState(() => _focusMenuOpen = false);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state = AppStateScope.of(context);
    final s = _state!;
    s.onOpenAmbientPanel = () {
      if (mounted) setState(() => _panel = PanelKind.ambient);
    };
    if (!_uriRead) {
      _uriRead = true;
      final q = Uri.base.queryParameters;
      final p = q['panel'];
      if (p != null) {
        for (final k in PanelKind.values) {
          if (k.name == p) _panel = k;
        }
      }
      if (q['focusmenu'] == '1') _focusMenuOpen = true;
      if (q['page'] == 'reader') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).push(
              PageTransition(
                type: PageTransitionType.fade,
                duration: const Duration(milliseconds: 450),
                child: const ReaderPage(),
              ),
            );
          }
        });
      }
    }
    if (!_initialSurahLoaded) {
      _initialSurahLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) s.openSurah(s.chapter, autoplay: false);
      });
    }
  }

  void _togglePanel(PanelKind k) {
    setState(() => _panel = _panel == k ? null : k);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mode = s.themeMode;
    final focusing = s.focusing;
    final size = MediaQuery.sizeOf(context);
    final wide = size.width > 920;
    final isSmall = size.width < 600 || size.height < 760;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const Positioned.fill(child: WatchfaceBackground()),

            // ---- centre: ayah + clock, vertically centered in available space ----
            // Rendered first so chrome (date, buttons, focus pill) sits above it
            // in the Stack and wins Flutter's reverse hit-test order.
            Builder(
              builder: (context) {
                final focusPillTop = isSmall ? 20.0 : 66.0;
                const focusPillHeight = 48.0;
                final hasBookmarkChip =
                    s.bookmarkChapter != null &&
                    s.bookmarkVerse != null &&
                    !focusing;
                final focusAreaBottom =
                    focusPillTop +
                    focusPillHeight +
                    (hasBookmarkChip ? (10.0 + 32.0) : 0.0);
                final bottomPadding = isSmall ? 85.0 : 100.0;

                return Positioned(
                  top: focusAreaBottom + (isSmall ? 8.0 : 16.0),
                  bottom: bottomPadding,
                  left: 0,
                  right: 0,
                  child: ListenableBuilder(
                    listenable: s.player,
                    builder: (context, _) {
                      final verse = s.player.verse;
                      final hasBismillah = s.player.currentVerse == 0 &&
                          s.chapter != 1 &&
                          s.chapter != 9;
                      final hideClock = _isBigAyah(
                        verse,
                        showTranslation: s.showTranslation,
                        hasBismillah: hasBismillah,
                        maxHeight: size.height,
                      );

                      return Listener(
                        onPointerSignal: (event) {
                          if (event is PointerScrollEvent && _panel == null) {
                            final dy = event.scrollDelta.dy;
                            if (dy == 0) return;
                            const step = 0.05;
                            final change = dy < 0 ? step : -step;
                            final newVol =
                                ((s.reciterVolume + change) * 20).round() / 20.0;
                            s.setReciterVolume(newVol.clamp(0.0, 1.0));
                          }
                        },
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const RepaintBoundary(child: AyahCard()),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: (child, anim) =>
                                      FadeTransition(
                                    opacity: anim,
                                    child: SizeTransition(
                                      sizeFactor: anim,
                                      axisAlignment: -1.0,
                                      child: Center(
                                        child: child,
                                      ),
                                    ),
                                  ),
                                  child: hideClock
                                      ? const SizedBox.shrink(
                                          key: ValueKey('clock_hidden'),
                                        )
                                      : Column(
                                          key: const ValueKey('clock_visible'),
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(height: isSmall ? 10 : 16),
                                            const RepaintBoundary(
                                              child: ClockView(),
                                            ),
                                          ],
                                        ),
                                ),
                                if (focusing) ...[
                                  const SizedBox(height: 12),
                                  const RepaintBoundary(child: _Countdown()),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // ---- date (zeno-style, top start) ----
            PositionedDirectional(
              top: isSmall ? 14 : 30,
              start: isSmall ? 16 : 34,
              child: _FadeOut(
                hidden: focusing || !wide,
                child: RepaintBoundary(child: _DateBlock()),
              ),
            ),

            // ---- top actions (top end) ----
            PositionedDirectional(
              top: isSmall ? 14 : 30,
              end: isSmall ? 14 : 34,
              child: _FadeOut(
                hidden: focusing,
                child: RepaintBoundary(
                  child: Row(
                    children: [
                      GlassButton(
                        size: isSmall ? 36 : 44,
                        icon: Icon(
                          Icons.translate_rounded,
                          size: isSmall ? 17 : 20,
                          color: mode.ink,
                        ),
                        tooltip: s.tr('language'),
                        onTap: s.cycleLocale,
                      ),
                      SizedBox(width: isSmall ? 6 : 10),
                      GlassButton(
                        size: isSmall ? 36 : 44,
                        icon: Icon(
                          Icons.wallpaper_rounded,
                          size: isSmall ? 17 : 20,
                          color: mode.ink,
                        ),
                        tooltip: s.tr('watchfaces'),
                        onTap: s.cycleWatchface,
                      ),
                      SizedBox(width: isSmall ? 6 : 10),
                      GlassButton(
                        size: isSmall ? 36 : 44,
                        icon: Icon(
                          Icons.menu_book_rounded,
                          size: isSmall ? 17 : 20,
                          color: mode.ink,
                        ),
                        tooltip: s.tr('reader'),
                        onTap: () => Navigator.of(context).push(
                          PageTransition(
                            type: PageTransitionType.fade,
                            duration: const Duration(milliseconds: 450),
                            child: const ReaderPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ---- tap-outside detector for focus presets menu ----
            if (_focusMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _focusMenuOpen = false),
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),

            // ---- focus pill & bookmark resume (top center) ----
            Positioned(
              top: isSmall ? 20 : 66,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FocusPill(
                      open: _focusMenuOpen,
                      onOpenChanged: (v) => setState(() => _focusMenuOpen = v),
                    ),
                    if (s.bookmarkChapter != null &&
                        s.bookmarkVerse != null &&
                        !focusing) ...[
                      const SizedBox(height: 10),
                      _FadeOut(
                        hidden: focusing,
                        child: GestureDetector(
                          onTap: () async {
                            final ch = s.bookmarkChapter!;
                            final v = s.bookmarkVerse!;
                            await s.openSurah(ch, autoplay: true);
                            s.player.seekToVerse(v - 1);
                          },
                          child: liquid(
                            radius: 999,
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            tint: mode.brightness == Brightness.light
                                ? const Color(0xFFFFF9ED)
                                : const Color(0xFF262118),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bookmark_rounded,
                                  size: 14,
                                  color: mode.accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${s.tr('resumeBookmark')}: ${s.ar ? kSurahs[s.bookmarkChapter! - 1].arShort : kSurahs[s.bookmarkChapter! - 1].en} ${s.bookmarkChapter}:${s.bookmarkVerse}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: mode.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ---- transport ----
            Positioned(
              bottom: isSmall ? 14 : 30,
              left: 0,
              right: 0,
              child: Center(
                child: _FadeOut(
                  hidden: focusing,
                  child: const RepaintBoundary(child: PlayerBar()),
                ),
              ),
            ),

            // ---- action rail (desktop) ----
            if (wide)
              PositionedDirectional(
                end: 34,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _FadeOut(
                    hidden: focusing,
                    child: RepaintBoundary(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Favorite button directly ABOVE Surahs button
                          Builder(
                            builder: (context) {
                              final currentAyah = s.player.verses.isNotEmpty
                                  ? s.player.currentVerse + 1
                                  : (s.bookmarkVerse ?? 1);
                              final isFav = s.isBookmarked(
                                s.chapter,
                                currentAyah,
                              );
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 7,
                                ),
                                child: GlassButton(
                                  size: 46,
                                  color: isFav
                                      ? (mode.brightness == Brightness.light
                                            ? const Color(0xFFFFF3D6)
                                            : const Color(0xFF332915))
                                      : (mode.brightness == Brightness.light
                                            ? Colors.white
                                            : const Color(0xFF222226)),
                                  tooltip: isFav
                                      ? s.tr('bookmarked')
                                      : s.tr('bookmark'),
                                  icon: Icon(
                                    isFav
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
                                    size: 20,
                                    color: isFav ? mode.accent : mode.ink,
                                  ),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    s.saveBookmark(s.chapter, currentAyah);
                                  },
                                ),
                              );
                            },
                          ),
                          for (final k in PanelKind.values)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              child: GlassButton(
                                size: 46,
                                color: _panel == k
                                    ? mode.accent
                                    : (mode.brightness == Brightness.light
                                          ? Colors.white
                                          : const Color(0xFF222226)),
                                icon: Icon(
                                  _iconFor(k),
                                  size: 20,
                                  color: _panel == k
                                      ? (mode.brightness == Brightness.light
                                            ? Colors.white
                                            : const Color(0xFF1B1B1D))
                                      : mode.ink,
                                ),
                                onTap: () => _togglePanel(k),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ---- mobile floating action pill ----
            if (!wide)
              Positioned(
                bottom: isSmall ? 70 : 96,
                left: 0,
                right: 0,
                child: Center(
                  child: _FadeOut(
                    hidden: focusing,
                    child: RepaintBoundary(
                      child: liquid(
                        radius: 999,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 6 : 10,
                          vertical: isSmall ? 3 : 4,
                        ),
                        tint: mode.brightness == Brightness.light
                            ? Colors.white
                            : const Color(0xFF1E1E22),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Favorite button directly before / above Surahs button
                            Builder(
                              builder: (context) {
                                final currentAyah = s.player.verses.isNotEmpty
                                    ? s.player.currentVerse + 1
                                    : (s.bookmarkVerse ?? 1);
                                final isFav = s.isBookmarked(
                                  s.chapter,
                                  currentAyah,
                                );
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmall ? 2 : 4,
                                  ),
                                  child: GlassButton(
                                    size: isSmall ? 34 : 38,
                                    color: isFav
                                        ? (mode.brightness == Brightness.light
                                              ? const Color(0xFFFFF3D6)
                                              : const Color(0xFF332915))
                                        : Colors.transparent,
                                    tooltip: isFav
                                        ? s.tr('bookmarked')
                                        : s.tr('bookmark'),
                                    icon: Icon(
                                      isFav
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_border_rounded,
                                      size: isSmall ? 16 : 18,
                                      color: isFav ? mode.accent : mode.ink,
                                    ),
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      s.saveBookmark(s.chapter, currentAyah);
                                    },
                                  ),
                                );
                              },
                            ),
                            for (final k in PanelKind.values)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmall ? 2 : 4,
                                ),
                                child: GlassButton(
                                  size: isSmall ? 34 : 38,
                                  color: _panel == k
                                      ? mode.accent
                                      : Colors.transparent,
                                  icon: Icon(
                                    _iconFor(k),
                                    size: isSmall ? 16 : 18,
                                    color: _panel == k
                                        ? (mode.brightness == Brightness.light
                                              ? Colors.white
                                              : const Color(0xFF1B1B1D))
                                        : mode.ink,
                                  ),
                                  onTap: () => _togglePanel(k),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ---- panel backdrop ----
            AnimatedOpacity(
              duration: const Duration(milliseconds: 350),
              opacity: _panel != null ? 1 : 0,
              child: IgnorePointer(
                ignoring: _panel == null,
                child: GestureDetector(
                  onTap: () => setState(() => _panel = null),
                  child: Container(color: Colors.black26),
                ),
              ),
            ),

            // ---- sliding glass panel ----
            PositionedDirectional(
              end: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                ignoring: _panel == null,
                child: RepaintBoundary(
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    offset: _panel != null
                        ? Offset.zero
                        : Offset(s.ar ? -1.1 : 1.1, 0),
                    child: SizedBox(
                      width: math.min(372.0, size.width * 0.92),
                      child: _panel != null
                          ? SidePanel(
                              key: ValueKey(_panel),
                              kind: _panel!,
                              onClose: () => setState(() => _panel = null),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isBigAyah(
    Verse? verse, {
    required bool showTranslation,
    required bool hasBismillah,
    required double maxHeight,
  }) {
    if (verse == null) return false;
    final words = verse.words.length;
    final trLen = showTranslation ? verse.translation.length : 0;
    final textLen = verse.text.length;

    // The clock shows in the middle for verses with 1-2 lines of Arabic
    // and 2-3 lines of English (e.g. up to ~22 words and ~220 characters).
    // It only hides for genuinely large ayahs (e.g. 3-4+ lines of Arabic
    // or 4+ lines of English, like 3:7 with 50 words / 480 chars).
    if (maxHeight < 760) {
      if (words >= 26 || trLen >= 240) return true;
      if (words >= 20 && trLen >= 190) return true;
      if (hasBismillah && (words >= 20 || trLen >= 180)) return true;
      return textLen >= 200;
    }

    // Standard & larger screens
    if (words >= 30 || trLen >= 270) return true;
    if (words >= 24 && trLen >= 220) return true;
    if (hasBismillah && (words >= 24 || trLen >= 210)) return true;
    return textLen >= 230;
  }

  static IconData _iconFor(PanelKind k) => switch (k) {
    PanelKind.surahs => Icons.format_list_numbered_rounded,
    PanelKind.reciters => Icons.record_voice_over_rounded,
    PanelKind.ambient => Icons.waves_rounded,
    PanelKind.settings => Icons.tune_rounded,
  };
}

/// Chrome that fades away (zeno's "UI disappears") while a focus session runs.
class _FadeOut extends StatelessWidget {
  final bool hidden;
  final Widget child;
  const _FadeOut({required this.hidden, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      opacity: hidden ? 0 : 1,
      child: IgnorePointer(ignoring: hidden, child: child),
    );
  }
}

class _DateBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final isImage = kWatchfaces[s.watchface].isImage;
    final now = DateTime.now();
    final loc = s.locale.toLanguageTag();
    final hijri = HijriDate.fromGregorian(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat.EEEE(loc).format(now),
          style: TextStyle(
            fontSize: 32,
            height: 1.05,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: s.themeMode.ink,
            shadows: isImage
                ? const [
                    Shadow(
                      color: Color(0xB3000000),
                      blurRadius: 8,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
        ),
        Text(
          DateFormat('dd.MM').format(now),
          style: TextStyle(
            fontSize: 32,
            height: 1.05,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: isImage
                ? Colors.white.withValues(alpha: 0.85)
                : s.themeMode.inkSoft,
            shadows: isImage
                ? const [
                    Shadow(
                      color: Color(0xB3000000),
                      blurRadius: 8,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 6),
        liquid(
          radius: 12,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          tint: s.themeMode.brightness == Brightness.light
              ? const Color(0xFFFFF9ED)
              : const Color(0xFF262118),
          child: Text(
            hijri.format(s.ar),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: s.themeMode.accent,
            ),
          ),
        ),
      ],
    );
  }
}

class _Countdown extends StatefulWidget {
  const _Countdown();

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    if (!s.focusing) return const SizedBox.shrink();
    final isImage = kWatchfaces[s.watchface].isImage;
    final d = s.focusRemaining;
    final m = d.inMinutes.toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return Text(
      '$m:$sec',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 3,
        color: isImage
            ? Colors.white.withValues(alpha: 0.9)
            : s.themeMode.ink.withValues(alpha: 0.75),
        fontFeatures: const [FontFeature.tabularFigures()],
        shadows: isImage
            ? const [
                Shadow(
                  color: Color(0xCC000000),
                  blurRadius: 8,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
    );
  }
}
