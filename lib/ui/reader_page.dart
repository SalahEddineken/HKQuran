import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import 'background.dart';
import 'glass.dart';

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
    final target = (v * 128.0).clamp(0.0, _scroll.position.maxScrollExtent);
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: WatchfaceBackground()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                  child: glassGroup(
                    child: Row(
                      children: [
                        GlassButton(
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: mode.ink,
                          ),
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 14),
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
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: mode.ink,
                                ),
                              ),
                              Text(
                                s.tr('tapToJump'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: mode.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GlassButton(
                          icon: Icon(
                            Icons.graphic_eq_rounded,
                            size: 20,
                            color: mode.accent,
                          ),
                          onTap: player.togglePlay,
                        ),
                      ],
                    ),
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
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
                          // The glass shader supports at most 4 shapes per
                          // group, so rows are chunked into 4-row groups.
                          // This also keeps the whole list from repainting
                          // its backdrop shaders on every karaoke tick.
                          itemCount: (verses.length + 3) ~/ 4,
                          itemBuilder: (context, gi) {
                            final start = gi * 4;
                            final end = math.min(start + 4, verses.length);
                            return RepaintBoundary(
                              child: glassGroup(
                                child: Column(
                                  children: [
                                    for (var i = start; i < end; i++)
                                      _AyahRow(
                                        index: i,
                                        current: i == player.currentVerse,
                                      ),
                                  ],
                                ),
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
}

class _AyahRow extends StatelessWidget {
  final int index;
  final bool current;
  const _AyahRow({required this.index, required this.current});

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mode = s.themeMode;
    final player = s.player;
    final verse = player.verses[index];
    final playing = player.playing && current;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => player.seekToVerse(index),
            child: liquid(
              radius: 22,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              tint: current
                  ? mode.accent.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.05),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
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
                    child: Text(
                      '${verse.number}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: current ? mode.accent : mode.inkSoft,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                              fontSize: 24,
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
                          const SizedBox(height: 8),
                          Text(
                            _strip(verse.translation),
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              fontStyle: FontStyle.italic,
                              color: mode.ink.withValues(alpha: 0.55),
                            ),
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
