import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/hijri.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import 'ayah_card.dart';
import 'background.dart';
import 'background_changer.dart';
import 'clock_view.dart';
import 'glass.dart';
import 'panels.dart';
import 'player_bar.dart';
import 'focus_pill.dart';
import 'reader_page.dart';
import 'todo_card.dart';
import 'surah_selector.dart';
import 'reciter_selector.dart';
import 'mawaqit_card.dart';
import 'adhkar_panel.dart';

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
  bool _backgroundMenuOpen = false;
  bool _surahSelectorOpen = false;
  bool _reciterSelectorOpen = false;
  bool _desktopAmbientOpen = false;
  bool _settingsOpen = false;
  bool _adhkarOpen = false;
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
    final primary = FocusManager.instance.primaryFocus;
    if (primary != null &&
        primary != _focusNode &&
        primary.context?.widget is EditableText) {
      return;
    }
    final key = event.logicalKey;
    final s = _state;
    if (s == null) return;

    if (key == LogicalKeyboardKey.space) {
      if (_adhkarOpen) return;
      s.player.togglePlay();
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      if (_adhkarOpen) return;
      s.player.seekRelative(-1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      if (_adhkarOpen) return;
      s.player.seekRelative(1);
    } else if (key == LogicalKeyboardKey.keyM) {
      s.toggleReciterMute();
    } else if (key == LogicalKeyboardKey.keyF) {
      if (s.focusing) {
        s.endFocus();
      } else {
        setState(() => _focusMenuOpen = !_focusMenuOpen);
      }
    } else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.keyS) {
      _toggleSurahSelector();
    } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.keyR) {
      _toggleReciterSelector();
    } else if (key == LogicalKeyboardKey.digit3) {
      final isWide = MediaQuery.sizeOf(context).width > 920;
      if (isWide) {
        setState(() {
          _desktopAmbientOpen = !_desktopAmbientOpen;
          if (_desktopAmbientOpen) {
            _settingsOpen = false;
            _adhkarOpen = false;
            _backgroundMenuOpen = false;
            _surahSelectorOpen = false;
            _reciterSelectorOpen = false;
          }
        });
      } else {
        _togglePanel(PanelKind.ambient);
      }
    } else if (key == LogicalKeyboardKey.digit4) {
      _toggleSettings();
    } else if (!kIsWeb && (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.keyA)) {
      _toggleAdhkar();
    } else if (!kIsWeb && key == LogicalKeyboardKey.keyP) {
      s.toggleDesktopMawaqit();
    } else if (key == LogicalKeyboardKey.keyW) {
      setState(() {
        _backgroundMenuOpen = !_backgroundMenuOpen;
        if (!_backgroundMenuOpen) {
          s.previewWatchface(null);
        }
      });
    } else if (key == LogicalKeyboardKey.escape) {
      if (_adhkarOpen) {
        setState(() => _adhkarOpen = false);
      } else if (_settingsOpen) {
        setState(() => _settingsOpen = false);
      } else if (_surahSelectorOpen) {
        setState(() => _surahSelectorOpen = false);
      } else if (_reciterSelectorOpen) {
        setState(() => _reciterSelectorOpen = false);
      } else if (_desktopAmbientOpen) {
        setState(() => _desktopAmbientOpen = false);
      } else if (_panel != null) {
        setState(() => _panel = null);
      } else if (_backgroundMenuOpen) {
        setState(() => _backgroundMenuOpen = false);
        s.previewWatchface(null);
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
    if (!_uriRead) {
      _uriRead = true;
      final q = Uri.base.queryParameters;
      final p = q['panel'];
      if (p != null) {
        if (p == 'settings') {
          _settingsOpen = true;
        } else {
          for (final k in PanelKind.values) {
            if (k.name == p) _panel = k;
          }
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
      for (final wf in kWatchfaces) {
        if (wf.asset != null) {
          precacheImage(AssetImage(wf.asset!), context);
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) s.openSurah(s.chapter, autoplay: false);
      });
    }
  }

  void _toggleSettings() {
    setState(() {
      _settingsOpen = !_settingsOpen;
      if (_settingsOpen) {
        _adhkarOpen = false;
        _surahSelectorOpen = false;
        _reciterSelectorOpen = false;
        _desktopAmbientOpen = false;
        _panel = null;
        _backgroundMenuOpen = false;
        _focusMenuOpen = false;
        _state?.previewWatchface(null);
      }
    });
  }

  void _toggleAdhkar() {
    setState(() {
      _adhkarOpen = !_adhkarOpen;
      if (_adhkarOpen) {
        _settingsOpen = false;
        _surahSelectorOpen = false;
        _reciterSelectorOpen = false;
        _desktopAmbientOpen = false;
        _panel = null;
        _backgroundMenuOpen = false;
        _focusMenuOpen = false;
        _state?.previewWatchface(null);
      }
    });
  }

  void _toggleSurahSelector() {
    setState(() {
      _surahSelectorOpen = !_surahSelectorOpen;
      if (_surahSelectorOpen) {
        _adhkarOpen = false;
        _settingsOpen = false;
        _reciterSelectorOpen = false;
        _panel = null;
        _backgroundMenuOpen = false;
        _focusMenuOpen = false;
        _state?.previewWatchface(null);
      }
    });
  }

  void _toggleReciterSelector() {
    setState(() {
      _reciterSelectorOpen = !_reciterSelectorOpen;
      if (_reciterSelectorOpen) {
        _adhkarOpen = false;
        _settingsOpen = false;
        _surahSelectorOpen = false;
        _panel = null;
        _backgroundMenuOpen = false;
        _focusMenuOpen = false;
        _state?.previewWatchface(null);
      }
    });
  }

  void _togglePanel(PanelKind k) {
    if (k == PanelKind.surahs) {
      _toggleSurahSelector();
      return;
    }
    if (k == PanelKind.reciters) {
      _toggleReciterSelector();
      return;
    }
    if (k == PanelKind.settings) {
      _toggleSettings();
      return;
    }
    if (k == PanelKind.adhkar) {
      _toggleAdhkar();
      return;
    }
    setState(() {
      _adhkarOpen = false;
      _settingsOpen = false;
      _surahSelectorOpen = false;
      _reciterSelectorOpen = false;
      _panel = _panel == k ? null : k;
      if (_panel != null && _backgroundMenuOpen) {
        _backgroundMenuOpen = false;
        _state?.previewWatchface(null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mode = s.themeMode;
    final focusing = s.focusing;
    final size = MediaQuery.sizeOf(context);
    final wide = size.width > 920;
    final isSmall = size.width < 600 || size.height < 760;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final navDockBottom =
        isSmall ? (bottomInset > 0 ? bottomInset + 4.0 : 12.0) : 18.0;
    final navDockHeight = isSmall ? 44.0 : 48.0;
    final playerBarBottom = wide
        ? (isSmall ? 18.0 : 30.0)
        : (navDockBottom + navDockHeight + (isSmall ? 8.0 : 12.0));
    final isAmbientOpen =
        wide ? _desktopAmbientOpen : (_panel == PanelKind.ambient);
    final isImage = kWatchfaces[s.effectiveWatchface].isImage;

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
                final focusPillTop = isSmall ? 14.0 : 66.0;
                const focusPillHeight = 48.0;
                final hasBookmarkChip =
                    s.bookmarkChapter != null &&
                    s.bookmarkVerse != null &&
                    !focusing;
                final focusAreaBottom =
                    focusPillTop +
                    focusPillHeight +
                    (hasBookmarkChip ? (10.0 + 32.0) : 0.0);
                final bottomPadding = wide
                    ? (isSmall ? 85.0 : 100.0)
                    : (playerBarBottom + (isSmall ? 68.0 : 74.0) + 10.0);

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

            // ---- top start: settings button & date block ----
            PositionedDirectional(
              top: isSmall ? 14 : 30,
              start: isSmall ? 16 : 34,
              child: _FadeOut(
                hidden: focusing,
                child: RepaintBoundary(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlassButton(
                        size: isSmall ? 36 : 44,
                        color: _settingsOpen
                            ? (mode.brightness == Brightness.light
                                ? const Color(0xFF1E1E22)
                                : Colors.white)
                            : null,
                        icon: Icon(
                          Icons.tune_rounded,
                          size: isSmall ? 17 : 20,
                          color: _settingsOpen
                              ? (mode.brightness == Brightness.light
                                  ? Colors.white
                                  : const Color(0xFF1E1E22))
                              : mode.ink,
                        ),
                        tooltip: s.tr('settings'),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _toggleSettings();
                        },
                      ),
                      if (wide) ...[
                        const SizedBox(width: 14),
                        _FadeOut(
                          hidden: _settingsOpen,
                          child: const _DateBlock(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ---- top actions (top end) ----
            PositionedDirectional(
              top: isSmall ? 14 : (wide ? 30 : 20),
              end: isSmall ? 14 : 34,
              child: _FadeOut(
                hidden: focusing || (!wide && _focusMenuOpen && size.width < 440),
                child: RepaintBoundary(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!wide) ...[
                        GlassButton(
                          size: isSmall ? 36 : 44,
                          color: s.showTranslation
                              ? (mode.brightness == Brightness.light
                                  ? const Color(0xFFFFF3D6)
                                  : const Color(0xFF332915))
                              : null,
                          icon: Icon(
                            Icons.translate_rounded,
                            size: isSmall ? 17 : 20,
                            color: s.showTranslation ? mode.accent : mode.ink,
                          ),
                          tooltip: s.tr('translation'),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            s.toggleTranslation();
                          },
                        ),
                        SizedBox(width: isSmall ? 6 : 8),
                      ],
                      // Software only: Adhkar button
                      if (!kIsWeb) ...[
                        // Adhkar & Sebha button
                        GlassButton(
                          size: isSmall ? 36 : 44,
                          color: _adhkarOpen
                              ? (mode.brightness == Brightness.light
                                  ? const Color(0xFF1E1E22)
                                  : Colors.white)
                              : null,
                          icon: Icon(
                            Icons.auto_stories_rounded,
                            size: isSmall ? 17 : 20,
                            color: _adhkarOpen
                                ? (mode.brightness == Brightness.light
                                    ? Colors.white
                                    : const Color(0xFF1E1E22))
                                : mode.ink,
                          ),
                          tooltip: s.ar ? 'الأذكار والمسبحة' : 'Adhkar & Tasbeeh',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _toggleAdhkar();
                          },
                        ),
                        SizedBox(width: isSmall ? 6 : 8),
                      ],
                      // Ambient sound button next to background changer button
                      GlassButton(
                        size: isSmall ? 36 : 44,
                        color: (wide ? _desktopAmbientOpen : _panel == PanelKind.ambient)
                            ? (mode.brightness == Brightness.light
                                ? const Color(0xFF1E1E22)
                                : Colors.white)
                            : (s.mixer.anyOn
                                ? (mode.brightness == Brightness.light
                                    ? const Color(0xFFFFF3D6)
                                    : const Color(0xFF332915))
                                : null),
                        icon: Icon(
                          Icons.waves_rounded,
                          size: isSmall ? 17 : 20,
                          color: (wide ? _desktopAmbientOpen : _panel == PanelKind.ambient)
                              ? (mode.brightness == Brightness.light
                                  ? Colors.white
                                  : const Color(0xFF1E1E22))
                              : (s.mixer.anyOn ? mode.accent : mode.ink),
                        ),
                        tooltip: s.tr('ambient'),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (wide) {
                            setState(() {
                              _desktopAmbientOpen = !_desktopAmbientOpen;
                              if (_desktopAmbientOpen) {
                                _settingsOpen = false;
                                _adhkarOpen = false;
                                _backgroundMenuOpen = false;
                                _surahSelectorOpen = false;
                                _reciterSelectorOpen = false;
                              }
                            });
                          } else {
                            _togglePanel(PanelKind.ambient);
                          }
                        },
                      ),
                      SizedBox(width: isSmall ? 6 : 8),
                      GlassButton(
                        size: isSmall ? 36 : 44,
                        color: _backgroundMenuOpen
                            ? (mode.brightness == Brightness.light
                                ? const Color(0xFF1E1E22)
                                : Colors.white)
                            : null,
                        icon: Icon(
                          Icons.wallpaper_rounded,
                          size: isSmall ? 17 : 20,
                          color: _backgroundMenuOpen
                              ? (mode.brightness == Brightness.light
                                  ? Colors.white
                                  : const Color(0xFF1E1E22))
                              : mode.ink,
                        ),
                        tooltip: s.tr('watchfaces'),
                        onTap: () {
                          setState(() {
                            _backgroundMenuOpen = !_backgroundMenuOpen;
                            if (_backgroundMenuOpen) {
                              _settingsOpen = false;
                              _panel = null;
                              _focusMenuOpen = false;
                              _surahSelectorOpen = false;
                            } else {
                              s.previewWatchface(null);
                            }
                          });
                        },
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

            // ---- desktop app download chip (top center, web only) ----
            if (kIsWeb)
              Positioned(
                top: isSmall ? 10 : 18,
                left: 0,
                right: 0,
                child: _FadeOut(
                  hidden: focusing,
                  child: Center(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          launchUrl(
                            Uri.parse('https://github.com/SalahEddineken/Quran/releases/latest'),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: liquid(
                          radius: 999,
                          height: isSmall ? 28 : 32,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmall ? 10 : 14,
                            vertical: 0,
                          ),
                          tint: mode.brightness == Brightness.light
                              ? Colors.white.withValues(alpha: 0.92)
                              : const Color(0xFF1E1E22).withValues(alpha: 0.92),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.download_rounded,
                                size: isSmall ? 13 : 15,
                                color: mode.accent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                s.tr('downloadDesktopApp'),
                                style: TextStyle(
                                  fontSize: isSmall ? 10.5 : 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  color: mode.ink,
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

            // ---- focus pill & bookmark resume (top center) ----
            Positioned(
              top: isSmall ? (kIsWeb ? 46 : 14) : 66,
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



            // ---- tap-outside detector for surah selector ----
            if (_surahSelectorOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _surahSelectorOpen = false),
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),

            // ---- tap-outside detector for reciter selector ----
            if (_reciterSelectorOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _reciterSelectorOpen = false),
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),

            // ---- desktop mawaqit (prayer times) card in center-left (Software only) ----
            if (!kIsWeb && wide && s.desktopMawaqitOpen)
              PositionedDirectional(
                start: isSmall ? 16 : 34,
                top: isSmall ? 172 : 196,
                child: _FadeOut(
                  hidden: focusing ||
                      _backgroundMenuOpen ||
                      _surahSelectorOpen ||
                      _reciterSelectorOpen ||
                      _settingsOpen,
                  duration: const Duration(milliseconds: 220),
                  child: RepaintBoundary(
                    child: MawaqitCard(
                      isCollapsed: s.desktopMawaqitCollapsed,
                      onToggleCollapse: s.toggleDesktopMawaqitCollapse,
                    ),
                  ),
                ),
              ),

            // ---- click outside to close settings ----
            if (_settingsOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _settingsOpen = false),
                  child: const SizedBox.expand(),
                ),
              ),

            // ---- settings panel card (clean floating card below settings button) ----
            PositionedDirectional(
              start: isSmall ? 16 : 34,
              top: isSmall ? 58 : 82,
              child: _FadeOut(
                hidden: focusing ||
                    _backgroundMenuOpen ||
                    _surahSelectorOpen ||
                    _reciterSelectorOpen ||
                    !_settingsOpen,
                duration: const Duration(milliseconds: 220),
                child: RepaintBoundary(
                  child: Container(
                    width: isSmall ? 300 : 330,
                    constraints: BoxConstraints(
                      maxHeight: size.height - (isSmall ? 76 : 110),
                    ),
                    decoration: BoxDecoration(
                      color: mode.brightness == Brightness.light
                          ? Colors.white
                          : const Color(0xFF1B1B1E),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: mode.brightness == Brightness.light
                            ? const Color(0x0F000000)
                            : const Color(0xFF2E2E34),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: mode.brightness == Brightness.light ? 0.09 : 0.38,
                          ),
                          blurRadius: 28,
                          spreadRadius: 0,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: mode.brightness == Brightness.light ? 0.03 : 0.12,
                          ),
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: SettingsPanel(
                          onClose: () => setState(() => _settingsOpen = false),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),


            // ---- mobile floating action pill ----
            if (!wide)
              Positioned(
                bottom: navDockBottom,
                left: 0,
                right: 0,
                child: Center(
                  child: _FadeOut(
                    hidden: focusing || _backgroundMenuOpen,
                    duration: const Duration(milliseconds: 200),
                    child: RepaintBoundary(
                      child: liquid(
                        radius: 999,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 8 : 12,
                          vertical: isSmall ? 4 : 5,
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
                                    size: isSmall ? 36 : 40,
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
                                      size: isSmall ? 17 : 19,
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
                              Builder(
                                builder: (context) {
                                  final isSelected = k == PanelKind.surahs
                                      ? _surahSelectorOpen
                                      : (k == PanelKind.settings
                                          ? _settingsOpen
                                          : (k == PanelKind.adhkar
                                              ? _adhkarOpen
                                              : _panel == k));
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmall ? 2 : 4,
                                    ),
                                    child: GlassButton(
                                      size: isSmall ? 36 : 40,
                                      color: isSelected
                                          ? mode.accent
                                          : Colors.transparent,
                                      icon: Icon(
                                        _iconFor(k),
                                        size: isSmall ? 17 : 19,
                                        color: isSelected
                                            ? (mode.brightness == Brightness.light
                                                  ? Colors.white
                                                  : const Color(0xFF1B1B1D))
                                            : mode.ink,
                                      ),
                                      onTap: () => _togglePanel(k),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ---- tap-outside detector for background menu ----
            if (_backgroundMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _backgroundMenuOpen = false);
                    s.previewWatchface(null);
                  },
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),

            // ---- background changer dropdown ----
            BackgroundDropdown(
              isOpen: _backgroundMenuOpen,
              topOffset: isSmall ? 56 : 84,
              endOffset: isSmall ? 14 : 34,
              onClose: () {
                setState(() => _backgroundMenuOpen = false);
                s.previewWatchface(null);
              },
            ),

            // ---- transport ----
            Positioned(
              bottom: playerBarBottom,
              left: 0,
              right: 0,
              child: Center(
                child: _FadeOut(
                  hidden: focusing,
                  child: RepaintBoundary(
                    child: PlayerBar(
                      hideNextPrev: isAmbientOpen,
                    ),
                  ),
                ),
              ),
            ),

            // ---- footer author credit ----
            if (wide)
              Positioned(
                bottom: isSmall ? 4.0 : 8.0,
                left: 0,
                right: 0,
                child: Center(
                  child: _FadeOut(
                    hidden: focusing || _backgroundMenuOpen,
                    duration: const Duration(milliseconds: 220),
                    child: RepaintBoundary(
                      child: Text(
                        'Salaheddine kennouda',
                        style: TextStyle(
                          fontSize: isSmall ? 10.5 : 12.0,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                          color: isImage
                              ? Colors.white.withValues(alpha: 0.65)
                              : mode.inkSoft,
                          shadows: isImage
                              ? const [
                                  Shadow(
                                    color: Color(0xB3000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ---- to-do list (centered above player bar on mobile/small screens, bottom-start on desktop) ----
            if (wide)
              PositionedDirectional(
                start: isSmall ? 16 : 34,
                bottom: isSmall ? 14 : 30,
                child: _FadeOut(
                  hidden: focusing || _settingsOpen,
                  child: const RepaintBoundary(
                    child: TodoCard(),
                  ),
                ),
              )
            else
              Positioned(
                bottom: playerBarBottom + (isSmall ? 74.0 : 106.0),
                left: 0,
                right: 0,
                child: Center(
                  child: _FadeOut(
                    hidden: focusing ||
                        _settingsOpen ||
                        _surahSelectorOpen ||
                        _reciterSelectorOpen ||
                        _backgroundMenuOpen,
                    child: const RepaintBoundary(
                      child: TodoCard(),
                    ),
                  ),
                ),
              ),

            // ---- desktop bottom-end controls (bookmark, reciter & surah picker) ----
            if (wide)
              PositionedDirectional(
                end: isSmall ? 16 : 34,
                bottom: isSmall ? 14 : 30,
                child: _FadeOut(
                  hidden: focusing || _backgroundMenuOpen || isAmbientOpen,
                  duration: const Duration(milliseconds: 220),
                  child: RepaintBoundary(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Bookmark button
                        Builder(
                          builder: (context) {
                            final currentAyah = s.player.verses.isNotEmpty
                                ? s.player.currentVerse + 1
                                : (s.bookmarkVerse ?? 1);
                            final isFav = s.isBookmarked(
                              s.chapter,
                              currentAyah,
                            );
                            return GlassButton(
                              size: isSmall ? 36 : 46,
                              color: isFav
                                  ? (mode.brightness == Brightness.light
                                        ? const Color(0xFFFFF3D6)
                                        : const Color(0xFF332915))
                                  : null,
                              tooltip: isFav
                                  ? s.tr('bookmarked')
                                  : s.tr('bookmark'),
                              icon: Icon(
                                isFav
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                size: isSmall ? 17 : 20,
                                color: isFav ? mode.accent : mode.ink,
                              ),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                s.saveBookmark(s.chapter, currentAyah);
                              },
                            );
                          },
                        ),
                        SizedBox(width: isSmall ? 8 : 10),
                        ReciterMenuButton(
                          size: isSmall ? 36 : 46,
                          isOpen: _reciterSelectorOpen,
                          onTap: _toggleReciterSelector,
                        ),
                        SizedBox(width: isSmall ? 8 : 10),
                        SurahMenuButton(
                          size: isSmall ? 36 : 46,
                          isOpen: _surahSelectorOpen,
                          onTap: _toggleSurahSelector,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ---- desktop ambient sound panel card ("just make the ambient sound panel there") ----
            if (wide)
              PositionedDirectional(
                end: isSmall ? 16 : 34,
                top: isSmall ? 64 : 84,
                child: _FadeOut(
                  hidden: focusing ||
                      _backgroundMenuOpen ||
                      _surahSelectorOpen ||
                      _reciterSelectorOpen ||
                      !_desktopAmbientOpen,
                  duration: const Duration(milliseconds: 220),
                  child: RepaintBoundary(
                    child: Container(
                      width: isSmall ? 320 : 365,
                      constraints: BoxConstraints(
                        maxHeight: size.height - (isSmall ? 80 : 110),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: mode.brightness == Brightness.light
                              ? const Color(0xFFE4E4E8)
                              : const Color(0xFF2E2E34),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 28,
                            spreadRadius: 0,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: liquid(
                          width: isSmall ? 320 : 365,
                          radius: 0,
                          tint: mode.brightness == Brightness.light
                              ? const Color(0xFFFAFBFD)
                              : const Color(0xFF161619),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            child: AmbientPanel(
                              onClose: () => setState(() => _desktopAmbientOpen = false),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ---- reciter selector popup ----
            ReciterSelectorPopup(
              isOpen: _reciterSelectorOpen,
              endOffset: isSmall ? 60.0 : 90.0,
              bottomOffset: wide
                  ? (isSmall ? 14.0 : 30.0) + (isSmall ? 36.0 : 46.0) + 12.0
                  : navDockBottom + navDockHeight + 10.0,
              onClose: () => setState(() => _reciterSelectorOpen = false),
            ),

            // ---- surah selector popup (Pic 2) ----
            SurahSelectorPopup(
              isOpen: _surahSelectorOpen,
              endOffset: isSmall ? 16 : 34,
              bottomOffset: wide
                  ? (isSmall ? 14.0 : 30.0) + (isSmall ? 36.0 : 46.0) + 12.0
                  : navDockBottom + navDockHeight + 10.0,
              onClose: () => setState(() => _surahSelectorOpen = false),
            ),

            // ---- Adhkar modal dialog (centered, clean, polished) ----
            if (_adhkarOpen) ...[
              // Backdrop
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 200),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, val, child) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _adhkarOpen = false),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.50 * val),
                    ),
                  ),
                ),
              ),
              // Centered Modal Card
              Positioned.fill(
                child: Center(
                  child: AdhkarModal(
                    onClose: () => setState(() => _adhkarOpen = false),
                  ),
                ),
              ),
            ],

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

            // ---- sliding glass panel (settings drawer from left) ----
            PositionedDirectional(
              start: 0,
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
                        : Offset(s.ar ? 1.1 : -1.1, 0),
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
    PanelKind.adhkar => Icons.auto_stories_rounded,
  };
}

/// Chrome that fades away (zeno's "UI disappears") while a focus session runs.
class _FadeOut extends StatelessWidget {
  final bool hidden;
  final Widget child;
  final Duration duration;
  const _FadeOut({
    required this.hidden,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: duration,
      curve: Curves.easeInOut,
      opacity: hidden ? 0 : 1,
      child: IgnorePointer(ignoring: hidden, child: child),
    );
  }
}

class _DateBlock extends StatelessWidget {
  const _DateBlock();

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final isImage = kWatchfaces[s.effectiveWatchface].isImage;
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
    final isImage = kWatchfaces[s.effectiveWatchface].isImage;
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
