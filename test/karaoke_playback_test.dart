import 'package:flutter_test/flutter_test.dart';
import 'package:hkquran/data/quran_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Karaoke Playback and Surah 2 Verification', () {
    test('Surah 2 loads authentic Tanzil text with word-by-word tokens, not dummy text', () async {
      final api = QuranApi();
      final verses = await api.fetchVerses(2);

      expect(verses.length, 286);

      // Ayah 41 (index 40)
      final ayah41 = verses[40];
      expect(ayah41.number, 41);
      expect(ayah41.key, '2:41');

      // MUST NOT be the old dummy text
      expect(ayah41.text, isNot('البقرة — آية 41'));
      expect(ayah41.text, contains('وَءَامِنُوا۟'));
      expect(ayah41.text, contains('أَنزَلْتُ'));

      // Real word-by-word tokens for karaoke display
      expect(ayah41.words.length, greaterThan(10));
      expect(ayah41.words[0].text, 'وَءَامِنُوا۟');
      expect(ayah41.words[1].text, 'بِمَآ');
      expect(ayah41.words[2].text, 'أَنزَلْتُ');
    });

    test('Surah 2 loads accurate word timing segments for Mishary', () async {
      final api = QuranApi();
      final audio = await api.fetchAudio(7, 2);

      expect(audio.chapter, 2);
      expect(audio.reciterId, 7);
      expect(audio.timings.length, 286);

      // Ayah 41 timing check (index 40)
      final timing41 = audio.timings[40];
      expect(timing41.key, '2:41');
      expect(timing41.from, 760790);
      expect(timing41.to, 782920);
      expect(timing41.segments.length, greaterThan(10));

      // Check locate() during Ayah 41 recitation
      // First word of Ayah 41 is between 760685 and 761955 ms
      final (verseIdx, wordIdx) = audio.locate(761000);
      expect(verseIdx, 40); // 0-indexed for Ayah 41
      expect(wordIdx, 0); // first word active
    });
  });
}
