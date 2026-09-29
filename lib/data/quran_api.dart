import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// quran.com v4 — chapter audio (single file per surah) with per-word
/// timestamps, plus Uthmani word text and a translation for the same chapter.
/// Verified: `Access-Control-Allow-Origin: *`, no auth required.
class QuranApi {
  static const _base = 'https://api.quran.com/api/v4';
  static const translationId = 20; // Saheeh International

  static Future<dynamic> _get(String url, {int tries = 3}) async {
    Object? last;
    for (var i = 0; i < tries; i++) {
      try {
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 25));
        if (res.statusCode == 200) {
          return jsonDecode(utf8.decode(res.bodyBytes));
        }
        last = ApiException('HTTP ${res.statusCode}');
      } catch (e) {
        last = e;
        await Future<void>.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
    }
    throw ApiException(
      'Could not reach quran.com (${last is ApiException ? last.message : last})',
    );
  }

  Future<ChapterAudio> fetchAudio(int reciterId, int chapter) async {
    final url =
        '$_base/chapter_recitations/$reciterId?chapter_number=$chapter&segments=true';
    final json = await _get(url) as Map<String, dynamic>;
    final files = (json['audio_files'] as List?) ?? const [];
    if (files.isEmpty) throw ApiException('No audio for this reciter/surah');
    final file = files.first as Map<String, dynamic>;
    final timings = <VerseTiming>[];
    for (final t in (file['timestamps'] as List?) ?? const []) {
      final m = t as Map<String, dynamic>;
      final segs = <WordSegment>[];
      for (final s in (m['segments'] as List?) ?? const []) {
        final l = s as List;
        if (l.length >= 3) {
          segs.add(
            WordSegment(
              (l[0] as num).toInt(),
              (l[1] as num).toInt(),
              (l[2] as num).toInt(),
            ),
          );
        }
      }
      timings.add(
        VerseTiming(
          key: m['verse_key'] as String,
          from: (m['timestamp_from'] as num).toInt(),
          to: (m['timestamp_to'] as num).toInt(),
          segments: segs,
        ),
      );
    }
    if (timings.isEmpty) throw ApiException('No timing data for this surah');
    return ChapterAudio(
      reciterId: reciterId,
      chapter: chapter,
      url: file['audio_url'] as String,
      timings: timings,
    );
  }

  Future<List<Verse>> fetchVerses(int chapter) async {
    final verses = <Verse>[];
    var page = 1;
    var totalPages = 1;
    do {
      final url =
          '$_base/verses/by_chapter/$chapter'
          '?fields=text_uthmani&words=true&word_fields=text_uthmani,translation'
          '&translations=$translationId&per_page=50&page=$page';
      final json = await _get(url) as Map<String, dynamic>;
      final pag = json['pagination'] as Map<String, dynamic>? ?? const {};
      totalPages = (pag['total_pages'] as num?)?.toInt() ?? 1;
      for (final v in json['verses'] as List) {
        final m = v as Map<String, dynamic>;
        final words = <AyahWord>[];
        for (final w in (m['words'] as List?) ?? const []) {
          final wm = w as Map<String, dynamic>;
          if (wm['char_type_name'] != 'word') continue;
          final gloss =
              ((wm['translation'] as Map<String, dynamic>?)?['text']
                  as String?);
          words.add(
            AyahWord(
              (wm['position'] as num).toInt(),
              (wm['text_uthmani'] ?? wm['text']) as String,
              gloss,
            ),
          );
        }
        words.sort((a, b) => a.position.compareTo(b.position));
        final trans = (m['translations'] as List?) ?? const [];
        verses.add(
          Verse(
            key: m['verse_key'] as String,
            number: (m['verse_number'] as num).toInt(),
            text: (m['text_uthmani'] ?? '') as String,
            translation: trans.isNotEmpty
                ? ((trans.first as Map<String, dynamic>)['text'] ?? '')
                      as String
                : '',
            words: words,
          ),
        );
      }
      page++;
    } while (page <= totalPages);
    return verses;
  }
}
