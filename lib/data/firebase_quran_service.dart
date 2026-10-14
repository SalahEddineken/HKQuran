import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../firebase_options.dart';
import 'local_quran_data.dart';
import 'models.dart';

/// Production-grade Firebase Cloud Firestore Quran Service.
///
/// Multi-tiered data retrieval strategy:
/// 1. Cloud Firestore native SDK (with automatic offline persistence cache)
/// 2. Cloud Firestore REST API over HTTPS with project Web API Key
/// 3. Bundled offline asset fallback (assets/quran/surahs/*.json)
/// 4. Hardcoded in-memory starter verses for instant zero-latency boot
class FirebaseQuranService {
  FirebaseQuranService._();
  static final FirebaseQuranService instance = FirebaseQuranService._();

  static const String projectId = 'studio-5996533553-9d4ec';
  static final String apiKey = DefaultFirebaseOptions.web.apiKey;
  static const String firestoreRestBase =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  /// Fetches complete verses for a given Surah (1..114).
  /// Prioritizes bundled local assets for instant, reliable, zero-latency loading.
  Future<List<Verse>> getSurah(int chapter) async {
    // Tier 1: Bundled local JSON asset (Instant, complete Tanzil Uthmani text + words)
    try {
      final jsonString =
          await rootBundle.loadString('assets/quran/surahs/$chapter.json');
      final list = jsonDecode(jsonString) as List;
      final verses = list
          .map((e) => Verse.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (verses.isNotEmpty) {
        return verses;
      }
    } catch (e) {
      debugPrint('Local asset fetch note for Surah $chapter: $e');
    }

    // Tier 2: Hardcoded starter surahs in memory
    if (kLocalSurahVerses.containsKey(chapter)) {
      return kLocalSurahVerses[chapter]!;
    }

    // Tier 3: Cloud Firestore Native SDK
    try {
      final doc = await firestore.collection('surahs').doc('$chapter').get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['verses'] is List) {
          final versesList = (data['verses'] as List)
              .map((e) => Verse.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          if (versesList.isNotEmpty) {
            return versesList;
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore native fetch note for Surah $chapter: $e');
    }

    // Tier 4: Firestore REST API via HTTP
    try {
      final url = Uri.parse('$firestoreRestBase/surahs/$chapter?key=$apiKey');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final fields = decoded['fields'] as Map<String, dynamic>?;
        final versesValue = fields?['verses']?['arrayValue']?['values'] as List?;
        if (versesValue != null && versesValue.isNotEmpty) {
          final verses = versesValue
              .map((raw) => _verseFromRestValue(raw as Map<String, dynamic>))
              .toList();
          if (verses.isNotEmpty) {
            return verses;
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore REST fetch note for Surah $chapter: $e');
    }

    // Tier 5: Generated fallback
    return getLocalVerses(chapter);
  }

  /// Fetches all 30 Juzs.
  Future<List<JuzMeta>> getJuzs() async {
    // Tier 1: Local JSON Asset
    try {
      final jsonString = await rootBundle.loadString('assets/quran/juzs.json');
      final list = jsonDecode(jsonString) as List;
      final result = list
          .map((e) => JuzMeta.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (result.isNotEmpty) return result;
    } catch (e) {
      debugPrint('Local Juzs fetch note: $e');
    }

    // Tier 2: Firestore Native
    try {
      final snapshot =
          await firestore.collection('juzs').orderBy('number').get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return JuzMeta(
            id: (data['id'] as num?)?.toInt() ?? 0,
            number: (data['number'] as num?)?.toInt() ?? 0,
            nameAr: (data['nameAr'] as String?) ?? '',
            startAyah: (data['startAyah'] as num?)?.toInt() ?? 0,
            endAyah: (data['endAyah'] as num?)?.toInt() ?? 0,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Firestore native Juzs fetch note: $e');
    }

    // Tier 3: Firestore REST API
    try {
      final url = Uri.parse('$firestoreRestBase/juzs?key=$apiKey');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final docs = decoded['documents'] as List?;
        if (docs != null && docs.isNotEmpty) {
          final list = docs.map((d) {
            final f = (d as Map<String, dynamic>)['fields'] as Map<String, dynamic>;
            return JuzMeta(
              id: int.tryParse(f['id']?['integerValue']?.toString() ?? '') ?? 0,
              number: int.tryParse(f['number']?['integerValue']?.toString() ?? '') ?? 0,
              nameAr: f['nameAr']?['stringValue']?.toString() ?? '',
              startAyah: int.tryParse(f['startAyah']?['integerValue']?.toString() ?? '') ?? 0,
              endAyah: int.tryParse(f['endAyah']?['integerValue']?.toString() ?? '') ?? 0,
            );
          }).toList();
          list.sort((a, b) => a.number.compareTo(b.number));
          return list;
        }
      }
    } catch (e) {
      debugPrint('Firestore REST Juzs fetch note: $e');
    }

    return const [];
  }

  /// Helper to convert a Firestore REST document representation into a [Verse]
  Verse _verseFromRestValue(Map<String, dynamic> raw) {
    final fields = (raw['mapValue']?['fields'] as Map<String, dynamic>?) ?? {};
    final key = fields['k']?['stringValue'] ?? '';
    final number = int.tryParse(fields['n']?['integerValue']?.toString() ?? '0') ?? 0;
    final text = fields['t']?['stringValue'] ?? '';
    final translation = fields['tr']?['stringValue'] ?? '';
    final tafsir = fields['tf']?['stringValue'];
    final page = int.tryParse(fields['pg']?['integerValue']?.toString() ?? '');
    final juz = int.tryParse(fields['j']?['integerValue']?.toString() ?? '');
    final rub = int.tryParse(fields['rb']?['integerValue']?.toString() ?? '');
    final sajda = fields['s']?['booleanValue'] == true;

    final rawWords = fields['w']?['arrayValue']?['values'] as List?;
    final words = <AyahWord>[];
    if (rawWords != null) {
      for (final w in rawWords) {
        final wf = (w as Map<String, dynamic>)['mapValue']?['fields'] as Map<String, dynamic>?;
        if (wf != null) {
          final p = int.tryParse(wf['p']?['integerValue']?.toString() ?? '0') ?? 0;
          final t = wf['t']?['stringValue'] ?? '';
          final g = wf['g']?['stringValue'];
          words.add(AyahWord(p, t, g));
        }
      }
    }

    var cleanText = text;
    var cleanWords = words;
    final surahNum = int.tryParse(key.split(':').first) ?? 0;
    if (surahNum > 1 && number == 1) {
      final bismillahRegex = RegExp(
        r'^ب[\u0640-\u065F]*سْمِ\s+ٱللَّهِ\s+ٱلرَّحْمَٰ?ـ?نِ\s+ٱلرَّحِيمِ\s*',
      );
      if (bismillahRegex.hasMatch(cleanText)) {
        cleanText = cleanText.replaceFirst(bismillahRegex, '');
        if (cleanWords.length > 4 && cleanWords.first.text.contains('سْمِ')) {
          cleanWords = [
            for (var i = 4; i < cleanWords.length; i++)
              AyahWord(i - 3, cleanWords[i].text, cleanWords[i].gloss),
          ];
        }
      }
    }

    return Verse(
      key: key,
      number: number,
      text: cleanText,
      translation: translation,
      words: cleanWords,
      tafsir: tafsir,
      page: page,
      juz: juz,
      rub: rub,
      sajda: sajda,
    );
  }
}
