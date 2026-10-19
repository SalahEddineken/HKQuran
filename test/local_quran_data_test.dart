import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkquran/data/local_quran_data.dart';
import 'package:hkquran/data/models.dart';
import 'package:hkquran/data/quran_api.dart';

void main() {
  test('Local Quran verses are loaded directly from source code', () {
    // Starter surahs in local map
    expect(kLocalSurahVerses.containsKey(1), isTrue);
    expect(kLocalSurahVerses.containsKey(112), isTrue);
    expect(kLocalSurahVerses.containsKey(113), isTrue);
    expect(kLocalSurahVerses.containsKey(114), isTrue);

    final fatiha = getLocalVerses(1);
    expect(fatiha.length, 7);
    expect(fatiha.first.words.length, 4);
    expect(fatiha.first.text, contains('بِسْمِ ٱللَّهِ'));

    final ikhlas = getLocalVerses(112);
    expect(ikhlas.length, 4);
    expect(ikhlas.first.text, contains('قُلْ هُوَ ٱللَّهُ أَحَدٌ'));

    // Any surah beyond the starter set is cleanly synthesized from kSurahs
    final baqara = getLocalVerses(2);
    expect(baqara.length, 286);
  });

  test('Local follow-up karaoke timings loaded directly from source code', () {
    // Al-Fatiha for Mishary (reciter 7)
    final fatihaAudio = getLocalChapterAudio(7, 1);
    expect(fatihaAudio.reciterId, 7);
    expect(fatihaAudio.chapter, 1);
    expect(fatihaAudio.url, 'assets/audio/1.mp3');
    expect(fatihaAudio.timings.length, 7);

    // Verify word segments in follow-up
    final firstTiming = fatihaAudio.timings.first;
    expect(firstTiming.segments.isNotEmpty, isTrue);

    // Dynamic follow-up generation for any other surah
    final customAudio = getLocalChapterAudio(7, 36);
    expect(customAudio.chapter, 36);
    expect(customAudio.timings.isNotEmpty, isTrue);
  });

  test('QuranApi serves completely offline from local data source', () async {
    final api = QuranApi();
    final verses = await api.fetchVerses(1);
    expect(verses.length, 7);

    final audio = await api.fetchAudio(7, 1);
    expect(audio.timings.length, 7);
    expect(api.hasCachedVerses(1), isTrue);
    expect(api.hasCachedAudio(7, 1), isTrue);
  });

  test('Local audio assets exist on disk and have valid sizes', () {
    final audioFiles = ['1.mp3', '108.mp3', '112.mp3', '113.mp3', '114.mp3'];
    for (final filename in audioFiles) {
      final file = File('assets/audio/$filename');
      expect(file.existsSync(), isTrue, reason: 'assets/audio/$filename must exist');
      expect(file.lengthSync(), greaterThan(10000), reason: '$filename size must be valid');
    }
  });

  test('Reciters have local asset paths and fallback patterns configured', () {
    for (final r in kReciters) {
      expect(r.assetFolder, isNotEmpty);
      expect(r.localAssetPath(1), startsWith('assets/audio'));
      expect(r.remoteUrlPattern, isNotNull);
    }
  });

  test('Gaitco Quran database SQLite asset exists and is valid', () {
    final dbFile = File('assets/quran/quran.db');
    expect(dbFile.existsSync(), isTrue, reason: 'assets/quran/quran.db must exist');
    expect(dbFile.lengthSync(), greaterThan(5 * 1024 * 1024), reason: 'quran.db size must be at least 5 MB');
  });

  test('All 114 Surahs and 6,236 Ayahs are present with complete metadata', () {
    var totalAyahs = 0;
    for (var s = 1; s <= 114; s++) {
      final file = File('assets/quran/surahs/$s.json');
      expect(file.existsSync(), isTrue, reason: 'assets/quran/surahs/$s.json must exist');
      final list = jsonDecode(file.readAsStringSync()) as List;
      expect(list.isNotEmpty, isTrue);
      expect(list.length, kSurahs[s - 1].ayahs, reason: 'Surah $s ayah count mismatch');
      totalAyahs += list.length;
    }
    // Total verses in the Holy Quran
    expect(totalAyahs, 6236);

    // Verify metadata files
    final surahsMetaFile = File('assets/quran/surahs.json');
    expect(surahsMetaFile.existsSync(), isTrue);
    final surahsMeta = jsonDecode(surahsMetaFile.readAsStringSync()) as List;
    expect(surahsMeta.length, 114);

    final juzsMetaFile = File('assets/quran/juzs.json');
    expect(juzsMetaFile.existsSync(), isTrue);
    final juzsMeta = jsonDecode(juzsMetaFile.readAsStringSync()) as List;
    expect(juzsMeta.length, 30);
  });
}
