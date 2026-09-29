part 'surahs.g.dart';

class SurahMeta {
  final int n;
  final String ar;
  final String arShort;
  final String en;
  final String enMeaning;
  final int ayahs;
  final String type;
  const SurahMeta({
    required this.n,
    required this.ar,
    required this.arShort,
    required this.en,
    required this.enMeaning,
    required this.ayahs,
    required this.type,
  });
}

class Reciter {
  final int id;
  final String en;
  final String ar;
  final String origin;
  const Reciter(this.id, this.en, this.ar, this.origin);
}

/// The six curated reciters — every one verified to expose per-word segment
/// timing for every chapter through quran.com's `chapter_recitations` API.
const List<Reciter> kReciters = [
  Reciter(7, 'Mishary Rashid Alafasy', 'مشاري راشد العفاسي', 'Kuwait'),
  Reciter(6, 'Mahmoud Khalil Al-Husary', 'محمود خليل الحصري', 'Egypt'),
  Reciter(2, 'Abdul Basit Abdul Samad', 'عبد الباسط عبد الصمد', 'Egypt'),
  Reciter(9, 'Mohamed Siddiq al-Minshawi', 'محمد صديق المنشاوي', 'Egypt'),
  Reciter(3, 'Abdur-Rahman as-Sudais', 'عبد الرحمن السديس', 'Saudi Arabia'),
  Reciter(10, "Sa'ud ash-Shuraym", 'سعود الشريم', 'Saudi Arabia'),
];

Reciter reciterById(int id) =>
    kReciters.firstWhere((r) => r.id == id, orElse: () => kReciters.first);

class AyahWord {
  final int position;
  final String text;
  final String? gloss;
  const AyahWord(this.position, this.text, this.gloss);
}

class Verse {
  final String key;
  final int number;
  final String text;
  final String translation;
  final List<AyahWord> words;
  const Verse({
    required this.key,
    required this.number,
    required this.text,
    required this.translation,
    required this.words,
  });
}

class WordSegment {
  /// 1-based word index inside the verse (matches [Verse.words] order).
  final int index;
  final int start;
  final int end;
  const WordSegment(this.index, this.start, this.end);
}

class VerseTiming {
  final String key;
  final int from;
  final int to;
  final List<WordSegment> segments;
  const VerseTiming({
    required this.key,
    required this.from,
    required this.to,
    required this.segments,
  });
}

class ChapterAudio {
  final int reciterId;
  final int chapter;
  final String url;
  final List<VerseTiming> timings;
  const ChapterAudio({
    required this.reciterId,
    required this.chapter,
    required this.url,
    required this.timings,
  });

  /// Returns verse index + word index (0-based, null when between words).
  (int, int?) locate(int ms) {
    int lo = 0, hi = timings.length - 1, verse = 0;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final t = timings[mid];
      if (ms < t.from) {
        hi = mid - 1;
      } else if (ms >= t.to) {
        lo = mid + 1;
        verse = mid;
      } else {
        verse = mid;
        for (final s in t.segments) {
          if (ms >= s.start && ms < s.end) return (mid, s.index - 1);
        }
        return (mid, null);
      }
    }
    return (verse.clamp(0, timings.length - 1), null);
  }
}
