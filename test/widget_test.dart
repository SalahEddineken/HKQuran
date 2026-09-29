import 'package:flutter_test/flutter_test.dart';
import 'package:noor/data/models.dart';

void main() {
  test('114 surahs with sane metadata', () {
    expect(kSurahs.length, 114);
    expect(kSurahs.first.en, 'Al-Faatiha');
    expect(kSurahs.first.ayahs, 7);
    expect(kSurahs.last.n, 114);
    expect(kSurahs.map((s) => s.n).toList(), List.generate(114, (i) => i + 1));
  });

  test('six curated reciters, all resolvable', () {
    expect(kReciters.length, 6);
    for (final r in kReciters) {
      expect(reciterById(r.id).id, r.id);
    }
  });

  test('karaoke locate maps ms to verse and word', () {
    const audio = ChapterAudio(
      reciterId: 7,
      chapter: 1,
      url: 'x',
      timings: [
        VerseTiming(key: '1:1', from: 0, to: 6090, segments: [
          WordSegment(1, 0, 580),
          WordSegment(2, 580, 1409),
          WordSegment(3, 1409, 2502),
          WordSegment(4, 2502, 5840),
        ]),
        VerseTiming(key: '1:2', from: 6025, to: 11550, segments: [
          WordSegment(1, 6025, 7025),
          WordSegment(2, 7025, 7885),
        ]),
      ],
    );

    final (v0, w0) = audio.locate(300);
    expect(v0, 0);
    expect(w0, 0);

    final (v1, w1) = audio.locate(1000);
    expect(v1, 0);
    expect(w1, 1);

    // inside verse 1 but after its last word (pause)
    final (v2, w2) = audio.locate(5900);
    expect(v2, 0);
    expect(w2, isNull);

    final (v3, w3) = audio.locate(7500);
    expect(v3, 1);
    expect(w3, 1);

    final (v4, w4) = audio.locate(99999);
    expect(v4, 1);
  });
}
