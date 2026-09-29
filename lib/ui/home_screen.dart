import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';

import '../audio/chapter_player.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import 'ayah_card.dart';
import 'background.dart';
import 'clock_view.dart';
import 'glass.dart';
import 'panels.dart';
import 'player_bar.dart';
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
  AppState? _state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state = AppStateScope.of(context);
    final s = _state!;
    for (final w in kWatchfaces) {
      if (w.asset != null) {
        precacheImage(AssetImage(w.asset!), context);
      }
    }
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
    if (s.player.status == PlayerStatus.idle) {
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: WatchfaceBackground()),

          // ---- date (zeno-style, top left) ----
          Positioned(
            top: 30,
            left: 34,
            child: _FadeOut(hidden: focusing || !wide, child: _DateBlock()),
          ),

          // ---- top-right actions ----
          Positioned(
            top: 30,
            right: 34,
            child: _FadeOut(
              hidden: focusing,
              child: glassGroup(
                child: Row(
                  children: [
                    GlassButton(
                      icon: Icon(
                        Icons.translate_rounded,
                        size: 20,
                        color: mode.ink,
                      ),
                      tooltip: s.tr('language'),
                      onTap: s.cycleLocale,
                    ),
                    const SizedBox(width: 10),
                    GlassButton(
                      icon: Icon(
                        mode == AppThemeMode.light
                            ? Icons.light_mode_rounded
                            : mode == AppThemeMode.dark
                            ? Icons.dark_mode_rounded
                            : Icons.auto_awesome_rounded,
                        size: 20,
                        color: mode.ink,
                      ),
                      tooltip: s.tr('theme'),
                      onTap: s.cycleTheme,
                    ),
                    const SizedBox(width: 10),
                    GlassButton(
                      icon: Icon(
                        Icons.wallpaper_rounded,
                        size: 20,
                        color: mode.ink,
                      ),
                      tooltip: s.tr('watchfaces'),
                      onTap: s.cycleWatchface,
                    ),
                    const SizedBox(width: 10),
                    GlassButton(
                      icon: Icon(
                        Icons.menu_book_rounded,
                        size: 20,
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

          // ---- focus pill (top center) ----
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Center(
              child: _FocusBar(
                open: _focusMenuOpen,
                onOpenChanged: (v) => setState(() => _focusMenuOpen = v),
              ),
            ),
          ),

          // ---- centre: ayah + clock, dead centre of the screen ----
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 110),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0, box.maxHeight - 220),
                  ),
                  child: Center(
                    child: glassGroup(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AyahCard(),
                          const SizedBox(height: 34),
                          const ClockView(),
                          if (focusing) ...[
                            const SizedBox(height: 14),
                            const _Countdown(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ---- transport ----
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: _FadeOut(
                hidden: focusing,
                child: glassGroup(child: const PlayerBar()),
              ),
            ),
          ),

          // ---- action rail ----
          Positioned(
            right: 34,
            top: 0,
            bottom: 0,
            child: Center(
              child: _FadeOut(
                hidden: focusing,
                child: glassGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final k in PanelKind.values)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: GlassButton(
                            size: 46,
                            color: _panel == k
                                ? mode.accent.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.12),
                            icon: Icon(
                              _iconFor(k),
                              size: 20,
                              color: _panel == k ? mode.accent : mode.ink,
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
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: _panel == null,
              child: glassGroup(
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 480),
                  curve: Curves.easeOutCubic,
                  offset: _panel != null ? Offset.zero : const Offset(1.1, 0),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _panel != null ? 1 : 0,
                    child: SizedBox(
                      width: 372,
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
          ),
        ],
      ),
    );
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
    final now = DateTime.now();
    final loc = s.locale.toLanguageTag();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat.EEEE(loc).format(now),
          style: TextStyle(
            fontSize: 34,
            height: 1.05,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: s.themeMode.ink,
          ),
        ),
        Text(
          DateFormat('dd.MM').format(now),
          style: TextStyle(
            fontSize: 34,
            height: 1.05,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: s.themeMode.inkSoft,
          ),
        ),
      ],
    );
  }
}

class _FocusBar extends StatefulWidget {
  final bool open;
  final ValueChanged<bool> onOpenChanged;
  const _FocusBar({required this.open, required this.onOpenChanged});

  @override
  State<_FocusBar> createState() => _FocusBarState();
}

class _FocusBarState extends State<_FocusBar> {
  Timer? _ticker;
  AppState? _state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state = AppStateScope.of(context);
  }

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final s = _state;
      // Tick while focusing so the countdown stays fresh, and for a moment
      // after it ends so the pill notices the session finished.
      if (mounted && s != null && s.focusing) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _countdown(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mode = s.themeMode;
    final focusing = s.focusing;

    return glassGroup(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () {
                if (focusing) {
                  s.endFocus();
                } else {
                  widget.onOpenChanged(!widget.open);
                }
              },
              child: liquid(
                radius: 999,
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                tint: focusing
                    ? mode.accent.withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 30,
                      height: 18,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: focusing
                            ? mode.accent
                            : mode.ink.withValues(alpha: 0.25),
                      ),
                      child: Align(
                        alignment: focusing
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      focusing
                          ? '${_countdown(s.focusRemaining)}  •  ${s.tr('endFocus')}'
                          : s.tr('focus'),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: focusing ? mode.accent : mode.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            child: (widget.open && !focusing)
                ? Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final m in const [15, 30, 45])
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _DurationButton(
                              minutes: m,
                              label: s.tr('min'),
                              color: mode.accent,
                              ink: mode.ink,
                              onTap: () {
                                widget.onOpenChanged(false);
                                s.startFocus(m);
                              },
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: 0, height: 46),
          ),
        ],
      ),
    );
  }
}

/// A 15/30/45-minute chip. Glass button with a Material tap layer so it
/// actually receives clicks (a bare GestureDetector under glass was not
/// hit-testable), plus a soft press squish.
class _DurationButton extends StatelessWidget {
  final int minutes;
  final String label;
  final Color color;
  final Color ink;
  final VoidCallback onTap;

  const _DurationButton({
    required this.minutes,
    required this.label,
    required this.color,
    required this.ink,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: liquid(
          radius: 999,
          width: 62,
          height: 46,
          tint: color.withValues(alpha: 0.14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$minutes',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: ink.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
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
    final d = s.focusRemaining;
    final m = d.inMinutes.toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return Text(
      '$m:$sec',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 3,
        color: s.themeMode.ink.withValues(alpha: 0.75),
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
