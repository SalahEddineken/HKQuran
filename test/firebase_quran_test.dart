import 'package:flutter_test/flutter_test.dart';
import 'package:noor/data/firebase_quran_service.dart';
import 'package:noor/data/quran_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Quran Database Integration', () {
    test('FirebaseQuranService configuration points to studio-5996533553-9d4ec', () {
      expect(FirebaseQuranService.projectId, 'studio-5996533553-9d4ec');
      expect(FirebaseQuranService.apiKey, isNotEmpty);
      expect(FirebaseQuranService.instance, isNotNull);
    });

    test('Firebase Quran Database retrieves Surah 1 with 7 verses and word tokens', () async {
      final db = QuranDatabase.instance;
      final verses = await db.getSurah(1);

      expect(verses, isNotEmpty);
      expect(
        verses.first.text,
        anyOf(
          contains('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'),
          contains('بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ'),
        ),
      );
      expect(verses.first.words, isNotEmpty);
      expect(verses.first.words.first.text, 'بِسْمِ');
    });

    test('Firebase Quran Database retrieves all 30 Juzs', () async {
      final db = QuranDatabase.instance;
      final juzs = await db.getJuzs();

      expect(juzs, isNotEmpty);
      expect(juzs.length, 30);
      expect(juzs.first.number, 1);
      expect(juzs.last.number, 30);
    });

    test('Firebase Quran Database retrieves short Surah 114 (An-Naas)', () async {
      final db = QuranDatabase.instance;
      final verses = await db.getSurah(114);

      expect(verses.length, 6);
      expect(verses.first.key, '114:1');
      expect(verses.first.text, contains('قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ'));
    });
  });
}
