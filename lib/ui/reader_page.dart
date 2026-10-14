import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import 'background.dart';
import 'glass.dart';
import 'vibe_hud.dart';

/// Full reading view of the loaded surah — every ayah on its own glass row,
/// the playing ayah highlighted, tap any ayah to jump there.
class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  AppState? _state;
  final ScrollController _scroll = ScrollController();
  int _lastVerse = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppStateScope.of(context);
    if (!identical(_state, s)) {
      _state?.removeListener(_onState);
      _state = s;
      s.addListener(_onState);
    }
  }

  @override
  void dispose() {
    _state?.removeListener(_onState);
    _scroll.dispose();
    super.dispose();
  }

  void _onState() {
    final s = _state;
    if (s == null || !_scroll.hasClients) return;
    final v = s.player.currentVerse;
    if (v == _lastVerse) return;
    _lastVerse = v;
    if (!s.player.playing) return;
    final hasHeader = s.chapter != 1 && s.chapter != 9;
    final targetIdx = hasHeader ? v + 1 : v;
    final target = (targetIdx * 128.0).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mode = s.themeMode;
    final player = s.player;
    final meta = kSurahs[s.chapter - 1];
    final reciter = reciterById(player.reciterId);
    final verses = player.verses;
    final isSmall = MediaQuery.sizeOf(context).width < 600;

    final showBismillah = s.chapter != 1 && s.chapter != 9;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: WatchfaceBackground()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isSmall ? 14 : 20,
                    isSmall ? 10 : 18,
                    isSmall ? 14 : 20,
                    6,
                  ),
                  child: Row(
                    children: [
                      GlassButton(
                        size: isSmall ? 36 : 44,
                        icon: Icon(
                          s.ar
                              ? Icons.arrow_forward_rounded
                              : Icons.arrow_back_rounded,
                          size: isSmall ? 17 : 20,
                          color: mode.ink,
                        ),
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      SizedBox(width: isSmall ? 10 : 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.ar
                                  ? '${meta.arShort} • ${reciter.ar}'
                                  : '${meta.en} • ${reciter.en}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isSmall ? 15 : 17,
                                fontWeight: FontWeight.w700,
                                color: mode.ink,
                              ),
                            ),
                            Text(
                              s.tr('tapToJump'),
                              style: TextStyle(
                                fontSize: isSmall ? 11 : 12,
                                color: mode.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isSmall ? 8 : 12),
                      GlassButton(
                        size: isSmall ? 36 : 44,
                        color: s.mixer.activeCount > 0
                            ? mode.accent.withValues(alpha: 0.22)
                            : Colors.transparent,
                        icon: Icon(
                          Icons.auto_awesome_rounded,
                          size: isSmall ? 17 : 20,
                          color: s.mixer.activeCount > 0
                              ? mode.accent
                              : mode.inkSoft,
                        ),
                        tooltip: s.tr('vibeQuran'),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _showVibeSheet(context);
                        },
                      ),
                      SizedBox(width: isSmall ? 6 : 8),
                      GlassButton(
                        size: isSmall ? 36 : 44,
                        icon: Icon(
                          Icons.graphic_eq_rounded,
                          size: isSmall ? 17 : 20,
                          color: mode.accent,
                        ),
                        onTap: player.togglePlay,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: verses.isEmpty
                      ? Center(
                          child: Text(
                            s.tr('loading'),
                            style: TextStyle(color: mode.inkSoft),
                          ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: EdgeInsets.fromLTRB(
                            isSmall ? 14 : 20,
                            isSmall ? 8 : 14,
                            isSmall ? 14 : 20,
                            40,
                          ),
                          itemCount: showBismillah ? verses.length + 1 : verses.length,
                          itemBuilder: (context, i) {
                            if (showBismillah && i == 0) {
                              return _BismillahBanner(isSmall: isSmall);
                            }
                            final verseIdx = showBismillah ? i - 1 : i;
                            return RepaintBoundary(
                              child: _AyahRow(
                                index: verseIdx,
                                current: verseIdx == player.currentVerse,
                                isSmall: isSmall,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showVibeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black38,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 12,
          left: 12,
          right: 12,
        ),
        child: SafeArea(
          top: false,
          child: VibeHudCard(
            isBottomSheet: true,
            onClose: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    );
  }
}

class _AyahRow extends StatelessWidget {
  final int index;
  final bool current;
  final bool isSmall;
  const _AyahRow({
    required this.index,
    required this.current,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mode = s.themeMode;
    final player = s.player;
    final verse = player.verses[index];
    final playing = player.playing && current;

    return Padding(
      padding: EdgeInsets.only(bottom: isSmall ? 10 : 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => player.seekToVerse(index),
          child: liquid(
            radius: 22,
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 14 : 20,
              vertical: isSmall ? 12 : 16,
            ),
            tint: current
                ? (mode.brightness == Brightness.light
                      ? const Color(0xFFFBF4E6)
                      : const Color(0xFF2B2519))
                : (mode.brightness == Brightness.light
                      ? Colors.white
                      : const Color(0xFF1E1E22)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isSmall ? 28 : 34,
                  height: isSmall ? 28 : 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: current
                          ? mode.accent
                          : mode.ink.withValues(alpha: 0.25),
                      width: current ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${verse.number}',
                        style: TextStyle(
                          fontSize: isSmall ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          color: current ? mode.accent : mode.inkSoft,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (verse.sajda)
                        Text(
                          '۩',
                          style: TextStyle(
                            fontSize: 9,
                            color: mode.accent,
                            height: 1.0,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: isSmall ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          verse.text,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'UthmanicHafs',
                            fontSize: (isSmall ? 20 : 24) * s.arabicTextScale,
                            height: 2.0,
                            color: playing
                                ? mode.accent
                                : mode.ink.withValues(
                                    alpha: current ? 1 : 0.88,
                                  ),
                          ),
                        ),
                      ),
                      if (s.showTranslation &&
                          verse.translation.isNotEmpty) ...[
                        SizedBox(height: isSmall ? 6 : 8),
                        Text(
                          _strip(verse.translation),
                          textAlign: s.ar ? TextAlign.right : TextAlign.start,
                          style: TextStyle(
                            fontSize: isSmall ? 12 : 13.5,
                            height: 1.45,
                            fontStyle: FontStyle.italic,
                            color: mode.ink.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                      if (verse.page != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: s.ar
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.end,
                          children: [
                            Text(
                              '${s.ar ? "ص ${verse.page}" : "p. ${verse.page}"}${verse.juz != null ? " • ${s.ar ? "الجزء ${verse.juz}" : "Juz ${verse.juz}"}" : ""}',
                              style: TextStyle(
                                fontSize: 11,
                                color: mode.inkSoft.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _strip(String input) => input
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&');
}

class _BismillahBanner extends StatelessWidget {
  final bool isSmall;
  const _BismillahBanner({required this.isSmall});

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mode = s.themeMode;
    return Padding(
      padding: EdgeInsets.only(
        top: isSmall ? 4 : 8,
        bottom: isSmall ? 16 : 22,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'UthmanicHafs',
                fontSize: (isSmall ? 21.0 : 26.0) * s.arabicTextScale,
                height: 1.6,
                fontWeight: FontWeight.w400,
                color: mode.ink,
              ),
            ),
            if (s.showTranslation) ...[
              const SizedBox(height: 6),
              Text(
                s.tr('bismillah'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmall ? 12 : 13.5,
                  fontStyle: FontStyle.italic,
                  color: mode.ink.withValues(alpha: 0.55),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              width: isSmall ? 90 : 130,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    mode.ink.withValues(alpha: 0.0),
                    mode.ink.withValues(alpha: 0.22),
                    mode.ink.withValues(alpha: 0.0),
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

