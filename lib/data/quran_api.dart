import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_quran_service.dart';
import 'local_quran_data.dart';
import 'models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// Comprehensive Quran database repository powered by gaitco/quran-database.
/// Delivers verified Tanzil Uthmani text, Saheeh International translations,
/// King Fahad Complex Tafsir Muyassar, Juzs, and karaoke word timings.
class QuranApi {
  QuranApi({this.prefs});

  final SharedPreferences? prefs;

  /// Global in-memory cache of loaded surahs for instant synchronous retrieval.
  static final Map<int, List<Verse>> _versesCache = {};
  static final Map<String, ChapterAudio> _audioCache = {};
  static List<JuzMeta>? _juzsCache;

  /// Instant synchronous cache check
  ChapterAudio? getCachedAudio(int reciterId, int chapter) {
    final key = '$reciterId:$chapter';
    if (_audioCache.containsKey(key)) {
      return _audioCache[key];
    }
    if (kLocalChapterAudio.containsKey(key)) {
      return kLocalChapterAudio[key];
    }
    return null;
  }

  /// Instant synchronous cache check
  List<Verse>? getCachedVerses(int chapter) {
    if (_versesCache.containsKey(chapter)) {
      return _versesCache[chapter];
    }
    if (kLocalSurahVerses.containsKey(chapter)) {
      return kLocalSurahVerses[chapter];
    }
    return null;
  }

  bool hasCachedAudio(int reciterId, int chapter) =>
      _audioCache.containsKey('$reciterId:$chapter') ||
      kLocalChapterAudio.containsKey('$reciterId:$chapter');

  bool hasCachedVerses(int chapter) =>
      _versesCache.containsKey(chapter) || hasStarterVerses(chapter);

  /// Returns chapter audio and follow-up (karaoke timings)
  Future<ChapterAudio> fetchAudio(int reciterId, int chapter) async {
    final key = '$reciterId:$chapter';
    if (_audioCache.containsKey(key)) {
      return _audioCache[key]!;
    }
    if (kLocalChapterAudio.containsKey(key)) {
      final a = kLocalChapterAudio[key]!;
      _audioCache[key] = a;
      return a;
    }

    // Load word-by-word timings from bundled assets/quran/timings/${reciterId}_$chapter.json
    try {
      final jsonStr = await rootBundle
          .loadString('assets/quran/timings/${reciterId}_$chapter.json');
      final decoded = jsonDecode(jsonStr);
      final audioObj = ChapterAudio.fromJson(
        Map<String, dynamic>.from(decoded as Map),
      );
      if (audioObj.timings.isNotEmpty) {
        _audioCache[key] = audioObj;
        return audioObj;
      }
    } catch (e) {
      debugPrint('Timing asset load note for $key: $e');
    }

    // Fallback: estimate intervals from real verses
    final verses = await fetchVerses(chapter);
    final fallbackAudio = getLocalChapterAudio(reciterId, chapter, verses);
    _audioCache[key] = fallbackAudio;
    return fallbackAudio;
  }

  /// Returns surah verses and words directly from bundled assets / Firebase
  Future<List<Verse>> fetchVerses(int chapter) async {
    if (_versesCache.containsKey(chapter)) {
      return _versesCache[chapter]!;
    }
    if (kLocalSurahVerses.containsKey(chapter)) {
      final v = kLocalSurahVerses[chapter]!;
      _versesCache[chapter] = v;
      return v;
    }

    final verses = await FirebaseQuranService.instance.getSurah(chapter);
    if (verses.isNotEmpty) {
      _versesCache[chapter] = verses;
    }
    return verses;
  }

  /// Loads all 30 Juz boundaries and metadata from Firebase
  Future<List<JuzMeta>> fetchJuzs() async {
    if (_juzsCache != null && _juzsCache!.isNotEmpty) return _juzsCache!;
    final juzs = await FirebaseQuranService.instance.getJuzs();
    if (juzs.isNotEmpty) {
      _juzsCache = juzs;
    }
    return _juzsCache ?? const [];
  }

  /// Proactive background prefetch for upcoming surahs
  void prefetchSurah(int reciterId, int chapter) {
    if (chapter >= 1 && chapter <= 114) {
      unawaited(fetchVerses(chapter));
    }
  }

  void prefetchAudio(int reciterId, int chapter) {
    if (chapter >= 1 && chapter <= 114) {
      unawaited(fetchAudio(reciterId, chapter));
    }
  }

  /// Search across loaded surahs for a query in Arabic or English
  List<Verse> searchCached(String query) {
    if (query.trim().isEmpty) return const [];
    final q = query.trim().toLowerCase();
    final results = <Verse>[];
    for (final vList in _versesCache.values) {
      for (final v in vList) {
        if (v.text.contains(query) ||
            v.translation.toLowerCase().contains(q) ||
            (v.tafsir != null && v.tafsir!.contains(query))) {
          results.add(v);
        }
      }
    }
    return results;
  }

  void dispose() {}
}
