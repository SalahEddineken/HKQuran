import 'firebase_quran_service.dart';
import 'models.dart';
import 'quran_api.dart';

/// Database repository for Noor powered by Firebase Cloud Firestore & Tanzil database.
///
/// Features:
/// - Cloud Firestore real-time & cached queries (project: studio-5996533553-9d4ec)
/// - Multi-tiered fallback architecture (Firestore Native -> REST API -> Bundled Assets)
/// - Tanzil Uthmani transcription verified against KFGQPC Madinah Mushaf (6,236 verses)
/// - English translation: Saheeh International
/// - Arabic Tafsir: King Fahad Quran Complex Tafsir Al-Muyassar
/// - Structural mapping: 114 Surahs, 30 Juzs, 60 Hizbs, 604 Madinah Mushaf pages
/// - Pre-compiled SQLite database available at: `assets/quran/quran.db`
class QuranDatabase {
  QuranDatabase._();
  static final QuranDatabase instance = QuranDatabase._();

  final QuranApi _api = QuranApi();
  final FirebaseQuranService firebase = FirebaseQuranService.instance;

  /// SQLite database asset path for local SQLite queries or database replication
  static const String sqliteAssetPath = 'assets/quran/quran.db';

  /// Returns complete verses for any Surah (1..114) with Arabic Uthmani text,
  /// Saheeh International translation, Tafsir Muyassar, page, juz, and words.
  Future<List<Verse>> getSurah(int chapter) => _api.fetchVerses(chapter);

  /// Synchronously returns verses if already in memory, otherwise null.
  List<Verse>? getSurahCached(int chapter) => _api.getCachedVerses(chapter);

  /// Loads all 30 Juz metadata boundaries and Arabic titles.
  Future<List<JuzMeta>> getJuzs() => _api.fetchJuzs();

  /// Search verses across all 114 surahs for a keyword in Arabic or English.
  Future<List<Verse>> search({
    required String query,
    int? surahId,
    int maxResults = 50,
  }) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return const [];

    final results = <Verse>[];
    final targetSurahs = surahId != null ? [surahId] : List.generate(114, (i) => i + 1);

    for (final sId in targetSurahs) {
      final verses = await getSurah(sId);
      for (final v in verses) {
        final matchesArabic = v.text.contains(query.trim());
        final matchesEnglish = v.translation.toLowerCase().contains(cleanQuery);
        final matchesTafsir = v.tafsir != null && v.tafsir!.contains(query.trim());

        if (matchesArabic || matchesEnglish || matchesTafsir) {
          results.add(v);
          if (results.length >= maxResults) return results;
        }
      }
    }
    return results;
  }
}
