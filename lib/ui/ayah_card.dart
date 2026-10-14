import '../theme/palette.dart';
import 'package:flutter/material.dart';

import '../audio/chapter_player.dart';
import '../data/models.dart';
import '../state/app_state.dart';

/// The karaoke ayah card: the current ayah large with the recited word
/// highlighted, plus an optional translation — all cleanly centered.
class AyahCard extends StatelessWidget {
  final bool compact;
  const AyahCard({super.key, this.compact = false});

  static const _quranFont = 'UthmanicHafs';

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final player = s.player;
    final screenW = MediaQuery.sizeOf(context).width;
    final isSmall = screenW < 600;
    final cardWidth = (screenW * (compact ? 0.96 : (isSmall ? 0.92 : 0.86)))
        .clamp(260.0, 900.0);

    if (player.verses.isNotEmpty) {
      return _shell(
        context,
        s,
        cardWidth,
        child: ListenableBuilder(
          listenable: player,
          builder: (context, _) => _verse(context, s, player),
        ),
      );
    }

    if (player.status == PlayerStatus.error) {
      return _shell(context, s, cardWidth, child: _error(context, s, player));
    }

    return _shell(context, s, cardWidth, child: _loading(s));
  }

  Widget _shell(BuildContext context, AppState s, double w, {required Widget child}) {
    final screenW = MediaQuery.sizeOf(context).width;
    final isSmall = screenW < 600;
    return SizedBox(
      width: w,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 12 : 24,
          vertical: isSmall ? 8 : 16,
        ),
        child: child,
      ),
    );
  }

  Widget _loading(AppState s) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 140),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 18),
          Text(
            s.tr('loading'),
            style: TextStyle(fontSize: 14, color: s.themeMode.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _error(BuildContext context, AppState s, ChapterPlayer player) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 140),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, color: s.themeMode.inkSoft, size: 28),
          const SizedBox(height: 12),
          Text(
            player.error ?? s.tr('error'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: s.themeMode.inkSoft),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => s.openSurah(s.chapter),
            child: Text(s.tr('retry')),
          ),
        ],
      ),
    );
  }

  Widget _verse(
    BuildContext context,
    AppState s,
    ChapterPlayer player,
  ) {
    final mode = s.themeMode;
    final verses = player.verses;
    final idx = player.currentVerse.clamp(0, verses.length - 1);
    final verse = verses[idx];
    final playing = player.playing;
    final active = playing ? player.currentWord : null;

    final wordCount = verse.words.length;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmall = screenWidth < 600;
    final isTiny = screenWidth < 380;
    final scale = isTiny ? 0.72 : (isSmall ? 0.82 : 1.0);

    final baseArabicSize = (wordCount > 18
        ? 22.0
        : wordCount > 12
        ? 25.0
        : 29.0) * scale;
    final arabicSize = baseArabicSize * s.arabicTextScale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: (idx == 0 && s.chapter != 1 && s.chapter != 9)
              ? Padding(
                  key: ValueKey('bismillah_${s.chapter}'),
                  padding: EdgeInsets.only(bottom: isSmall ? 10 : 16),
                  child: Text(
                    'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: _quranFont,
                      fontSize: (isSmall ? 18.0 : 22.0) * s.arabicTextScale,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                      color: kWatchfaces[s.watchface].isImage
                          ? Colors.white.withValues(alpha: 0.92)
                          : mode.ink.withValues(alpha: 0.70),
                      shadows: kWatchfaces[s.watchface].isImage
                          ? const [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 16,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('empty_bismillah')),
        ),

        // current ayah — word by word. Isolated so the per-word highlight
        // repaints only this layer, never the backdrop. The key swaps
        // on verse change so each verse slides in softly.
        GestureDetector(
          onTap: () => player.seekToVerse(idx),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.center,
                children: [...previousChildren, ?currentChild],
              ),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: RepaintBoundary(
                key: ValueKey(verse.key),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: isSmall ? 6 : 10,
                  runSpacing: isSmall ? 8 : 14,
                  children: [
                    for (var i = 0; i < verse.words.length; i++)
                      _Word(
                        word: verse.words[i],
                        totalWords: verse.words.length,
                        size: arabicSize,
                        active: active == i,
                        read: active != null && i < active,
                        dim: active != null && i > active,
                        mode: s.themeMode,
                        playing: playing,
                        isImage: kWatchfaces[s.watchface].isImage,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (s.showTranslation && verse.translation.isNotEmpty) ...[
          SizedBox(height: isSmall ? 12 : 20),
          Container(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              _stripHtml(verse.translation),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmall ? 13.0 : 15.5,
                height: isSmall ? 1.4 : 1.5,
                fontStyle: FontStyle.italic,
                color: kWatchfaces[s.watchface].isImage
                    ? Colors.white.withValues(alpha: 0.88)
                    : mode.ink.withValues(alpha: 0.62),
                shadows: kWatchfaces[s.watchface].isImage
                    ? const [
                        Shadow(
                          color: Color(0xCC000000),
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ],
    );
  }

  static String _stripHtml(String input) => input
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&');
}

class _Word extends StatelessWidget {
  final AyahWord word;
  final int totalWords;
  final double size;
  final bool active;
  final bool read;
  final bool dim;
  final bool playing;
  final AppThemeMode mode;
  final bool isImage;

  const _Word({
    required this.word,
    required this.totalWords,
    required this.size,
    required this.active,
    required this.read,
    required this.dim,
    required this.playing,
    required this.mode,
    this.isImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = mode.accent;
    final ink = mode.ink;
    Color color;
    if (active) {
      color = accent;
    } else if (!playing) {
      color = ink;
    } else if (read) {
      color = ink.withValues(alpha: 0.88);
    } else {
      color = ink.withValues(alpha: dim ? 0.38 : 0.6);
    }

    final wordWidget = AnimatedScale(
      scale: active ? 1.07 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 220),
        style: TextStyle(
          fontFamily: AyahCard._quranFont,
          fontSize: size,
          height: 1.7,
          color: color,
          shadows: isImage
              ? const [
                  Shadow(
                    color: Color(0xD9000000),
                    blurRadius: 8,
                    offset: Offset(0, 1.5),
                  ),
                ]
              : null,
        ),
        child: Text(word.text),
      ),
    );

    if (word.gloss != null && word.gloss!.isNotEmpty) {
      return Tooltip(
        waitDuration: const Duration(milliseconds: 150),
        showDuration: const Duration(seconds: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: mode.accent,
            width: 0.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        richMessage: TextSpan(
          children: [
            TextSpan(
              text: '${word.gloss}\n',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            TextSpan(
              text: 'Word ${word.position} of $totalWords',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
        child: wordWidget,
      );
    }

    return wordWidget;
  }
}
