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
  /// Base folder for local audio assets, e.g. 'assets/audio'
  final String assetFolder;
  /// Optional remote fallback URL pattern if local file is absent
  final String? remoteUrlPattern;

  const Reciter(
    this.id,
    this.en,
    this.ar,
    this.origin, {
    this.assetFolder = 'assets/audio',
    this.remoteUrlPattern,
  });

  /// Resolves the local asset path for a chapter
  String localAssetPath(int chapter) => '$assetFolder/$chapter.mp3';

  /// Resolves remote audio URL for a chapter if available
  String? remoteAudioUrl(int chapter) {
    if (remoteUrlPattern == null) return null;
    final chStr = (id == 10) ? chapter.toString().padLeft(3, '0') : chapter.toString();
    return remoteUrlPattern!.replaceAll('{chapter}', chStr);
  }
}

/// Curated reciters with local asset paths and fallback streaming templates.
/// Easily add or customize your reciters here in code source.
const List<Reciter> kReciters = [
  Reciter(
    7,
    'Mishary Rashid Alafasy',
    'مشاري راشد العفاسي',
    'Kuwait',
    assetFolder: 'assets/audio',
    remoteUrlPattern:
        'https://download.quranicaudio.com/qdc/mishari_al_afasy/murattal/{chapter}.mp3',
  ),
  Reciter(
    6,
    'Mahmoud Khalil Al-Husary',
    'محمود خليل الحصري',
    'Egypt',
    assetFolder: 'assets/audio/husary',
    remoteUrlPattern:
        'https://download.quranicaudio.com/qdc/khalil_al_husary/murattal/{chapter}.mp3',
  ),
  Reciter(
    2,
    'Abdul Basit Abdul Samad',
    'عبد الباسط عبد الصمد',
    'Egypt',
    assetFolder: 'assets/audio/abdul_basit',
    remoteUrlPattern:
        'https://download.quranicaudio.com/qdc/abdul_baset/murattal/{chapter}.mp3',
  ),
  Reciter(
    9,
    'Mohamed Siddiq al-Minshawi',
    'محمد صديق المنشاوي',
    'Egypt',
    assetFolder: 'assets/audio/minshawi',
    remoteUrlPattern:
        'https://download.quranicaudio.com/qdc/siddiq_minshawi/murattal/{chapter}.mp3',
  ),
  Reciter(
    3,
    'Abdur-Rahman as-Sudais',
    'عبد الرحمن السديس',
    'Saudi Arabia',
    assetFolder: 'assets/audio/sudais',
    remoteUrlPattern:
        'https://download.quranicaudio.com/qdc/abdurrahmaan_as_sudais/murattal/{chapter}.mp3',
  ),
  Reciter(
    10,
    "Sa'ud ash-Shuraym",
    'سعود الشريم',
    'Saudi Arabia',
    assetFolder: 'assets/audio/shuraym',
    remoteUrlPattern:
        'https://download.quranicaudio.com/qdc/saud_ash-shuraym/murattal/{chapter}.mp3',
  ),
];

Reciter reciterById(int id) =>
    kReciters.firstWhere((r) => r.id == id, orElse: () => kReciters.first);

class AyahWord {
  final int position;
  final String text;
  final String? gloss;
  const AyahWord(this.position, this.text, [this.gloss]);

  Map<String, dynamic> toJson() => {
    'p': position,
    't': text,
    if (gloss != null) 'g': gloss,
  };

  factory AyahWord.fromJson(Map<String, dynamic> json) => AyahWord(
    ((json['p'] ?? json['position'] ?? 0) as num).toInt(),
    (json['t'] ?? json['text'] ?? '') as String,
    (json['g'] ?? json['gloss']) as String?,
  );
}

class Verse {
  final String key;
  final int number;
  final String text;
  final String translation;
  final List<AyahWord> words;
  final String? tafsir;
  final int? page;
  final int? juz;
  final int? rub;
  final bool sajda;

  const Verse({
    required this.key,
    required this.number,
    required this.text,
    required this.translation,
    required this.words,
    this.tafsir,
    this.page,
    this.juz,
    this.rub,
    this.sajda = false,
  });

  Map<String, dynamic> toJson() => {
    'k': key,
    'n': number,
    't': text,
    'tr': translation,
    'w': words.map((w) => w.toJson()).toList(),
    if (tafsir != null) 'tf': tafsir,
    if (page != null) 'pg': page,
    if (juz != null) 'j': juz,
    if (rub != null) 'rb': rub,
    if (sajda) 's': true,
  };

  factory Verse.fromJson(Map<String, dynamic> json) {
    final key = (json['k'] ?? json['key'] ?? '') as String;
    final number = ((json['n'] ?? json['number'] ?? 0) as num).toInt();
    var text = (json['t'] ?? json['text'] ?? '') as String;
    var words = List<AyahWord>.from(
      ((json['w'] ?? json['words'] as List?) ?? const [])
          .map((w) => AyahWord.fromJson(Map<String, dynamic>.from(w as Map))),
    );

    // Defensive check: If verse 1 of any surah other than Al-Fatiha (1) has Bismillah prepended, strip it
    final surahNum = int.tryParse(key.split(':').first) ?? 0;
    if (surahNum > 1 && number == 1) {
      final bismillahRegex = RegExp(
        r'^ب[\u0640-\u065F]*سْمِ\s+ٱللَّهِ\s+ٱلرَّحْمَٰ?ـ?نِ\s+ٱلرَّحِيمِ\s*',
      );
      if (bismillahRegex.hasMatch(text)) {
        text = text.replaceFirst(bismillahRegex, '');
        if (words.length > 4 && words.first.text.contains('سْمِ')) {
          words = [
            for (var i = 4; i < words.length; i++)
              AyahWord(i - 3, words[i].text, words[i].gloss),
          ];
        }
      }
    }

    return Verse(
      key: key,
      number: number,
      text: text,
      translation: (json['tr'] ?? json['translation'] ?? '') as String,
      tafsir: (json['tf'] ?? json['tafsir']) as String?,
      page: (json['pg'] ?? json['page'] as num?)?.toInt(),
      juz: (json['j'] ?? json['juz'] as num?)?.toInt(),
      rub: (json['rb'] as num?)?.toInt(),
      sajda: (json['s'] ?? json['sajda'] as bool?) ?? false,
      words: words,
    );
  }
}

class JuzMeta {
  final int id;
  final int number;
  final String nameAr;
  final int startAyah;
  final int endAyah;
  const JuzMeta({
    required this.id,
    required this.number,
    required this.nameAr,
    required this.startAyah,
    required this.endAyah,
  });

  factory JuzMeta.fromJson(Map<String, dynamic> json) => JuzMeta(
    id: (json['id'] as num).toInt(),
    number: (json['number'] as num).toInt(),
    nameAr: json['nameAr'] as String,
    startAyah: (json['startAyah'] as num).toInt(),
    endAyah: (json['endAyah'] as num).toInt(),
  );
}

class WordSegment {
  /// 1-based word index inside the verse (matches [Verse.words] order).
  final int index;
  final int start;
  final int end;
  const WordSegment(this.index, this.start, this.end);

  List<int> toJson() => [index, start, end];

  factory WordSegment.fromList(List list) => WordSegment(
    (list[0] as num).toInt(),
    (list[1] as num).toInt(),
    (list[2] as num).toInt(),
  );
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

  Map<String, dynamic> toJson() => {
    'k': key,
    'f': from,
    't': to,
    's': segments.map((s) => s.toJson()).toList(),
  };

  factory VerseTiming.fromJson(Map<String, dynamic> json) => VerseTiming(
    key: (json['k'] ?? json['key'] ?? '') as String,
    from: ((json['f'] ?? json['from'] ?? 0) as num).toInt(),
    to: ((json['t'] ?? json['to'] ?? 0) as num).toInt(),
    segments: List<WordSegment>.from(
      ((json['s'] ?? json['segments'] as List?) ?? const [])
          .map((s) => WordSegment.fromList(s as List)),
    ),
  );
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

  Map<String, dynamic> toJson() => {
    'r': reciterId,
    'c': chapter,
    'u': url,
    't': timings.map((t) => t.toJson()).toList(),
  };

  factory ChapterAudio.fromJson(Map<String, dynamic> json) => ChapterAudio(
    reciterId: ((json['r'] ?? json['reciterId'] ?? 0) as num).toInt(),
    chapter: ((json['c'] ?? json['chapter'] ?? 0) as num).toInt(),
    url: (json['u'] ?? json['url'] ?? '') as String,
    timings: List<VerseTiming>.from(
      ((json['t'] ?? json['timings'] as List?) ?? const [])
          .map((t) => VerseTiming.fromJson(Map<String, dynamic>.from(t as Map))),
    ),
  );

  /// Returns verse index + word index (0-based, null when before recited words or during inter-verse pause).
  (int, int?) locate(int ms) {
    if (timings.isEmpty) return (0, null);
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
        for (var si = 0; si < t.segments.length; si++) {
          final s = t.segments[si];
          if (ms >= s.start && ms < s.end) return (mid, s.index - 1);
          if (si + 1 < t.segments.length &&
              ms >= s.end &&
              ms < t.segments[si + 1].start) {
            return (mid, s.index - 1);
          }
        }
        return (mid, null);
      }
    }
    return (verse.clamp(0, timings.length - 1), null);
  }
}
