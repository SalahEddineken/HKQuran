import '../theme/palette.dart';
import 'package:flutter/material.dart';

import '../audio/chapter_player.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'glass.dart';

/// The karaoke ayah card: the current ayah large with the recited word
/// highlighted, plus an optional translation — all on one liquid-glass
/// surface, everything centered.
class AyahCard extends StatelessWidget {
  final bool compact;
  const AyahCard({super.key, this.compact = false});

  static const _quranFont = 'UthmanicHafs';

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final player = s.player;
    final cardWidth = (MediaQuery.sizeOf(context).width * (compact ? 0.94 : 0.86))
        .clamp(280.0, 900.0);

    return switch (player.status) {
      PlayerStatus.idle ||
      PlayerStatus.loading => _shell(context, cardWidth, child: _loading(s)),
      PlayerStatus.error => _shell(
        context,
        cardWidth,
        child: _error(context, s, player),
      ),
      PlayerStatus.ready => _shell(
        context,
        cardWidth,
        child: _verse(context, s, player),
      ),
    };
  }

  Widget _shell(BuildContext context, double w, {required Widget child}) {
    return liquid(
      width: w,
      radius: 32,
      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 26),
      tint: Colors.white.withValues(alpha: 0.07),
      child: child,
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
    final meta = kSurahs[s.chapter - 1];
    final verses = player.verses;
    final idx = player.currentVerse.clamp(0, verses.length - 1);
    final verse = verses[idx];
    final playing = player.playing;
    final active = playing ? player.currentWord : null;

    final wordCount = verse.words.length;
    final arabicSize = wordCount > 18
        ? 24.0
        : wordCount > 12
        ? 27.0
        : 31.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // header
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, size: 15, color: mode.accent),
            const SizedBox(width: 8),
            Text(
              s.ar ? meta.arShort : meta.en,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: mode.ink.withValues(alpha: 0.85),
              ),
            ),
            Text(
              '  •  ${idx + 1} / ${meta.ayahs}',
              style: TextStyle(fontSize: 13, color: mode.inkSoft),
            ),
            if (playing) ...[
              const SizedBox(width: 10),
              _LiveDot(color: mode.accent),
            ],
          ],
        ),
        const SizedBox(height: 20),

        // current ayah — word by word. Isolated so the per-word highlight
        // repaints only this layer, never the glass backdrop. The key swaps
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
                  spacing: 10,
                  runSpacing: 14,
                  children: [
                    for (var i = 0; i < verse.words.length; i++)
                      _Word(
                        text: verse.words[i].text,
                        size: arabicSize,
                        active: active == i,
                        read: active != null && i < active,
                        dim: active != null && i > active,
                        mode: s.themeMode,
                        playing: playing,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (s.showTranslation && verse.translation.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              _stripHtml(verse.translation),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.5,
                height: 1.5,
                fontStyle: FontStyle.italic,
                color: mode.ink.withValues(alpha: 0.62),
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
  final String text;
  final double size;
  final bool active;
  final bool read;
  final bool dim;
  final bool playing;
  final AppThemeMode mode;

  const _Word({
    required this.text,
    required this.size,
    required this.active,
    required this.read,
    required this.dim,
    required this.playing,
    required this.mode,
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

    return AnimatedScale(
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
        ),
        child: Text(text),
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  final Color color;
  const _LiveDot({required this.color});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
