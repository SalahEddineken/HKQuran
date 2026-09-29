import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../data/models.dart';
import '../data/quran_api.dart';

enum PlayerStatus { idle, loading, ready, error }

/// Streams one surah at a time from quran.com's chapter files and exposes
/// karaoke state: the current ayah and the current word being recited.
class ChapterPlayer extends ChangeNotifier {
  final QuranApi api;
  ChapterPlayer(this.api) {
    _player.positionStream.listen(_onPosition);
    _player.playerStateStream.listen((_) => notifyListeners());
    _player.durationStream.listen((_) => notifyListeners());
  }

  final AudioPlayer _player = AudioPlayer();

  PlayerStatus status = PlayerStatus.idle;
  String? error;
  ChapterAudio? audio;
  List<Verse> verses = const [];

  int reciterId = kReciters.first.id;
  int chapter = 1;

  int currentVerse = 0;
  int? currentWord;

  AudioPlayer get rawPlayer => _player;
  bool get playing => _player.playing;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  Verse? get verse =>
      verses.isEmpty ? null : verses[currentVerse.clamp(0, verses.length - 1)];

  void _onPosition(Duration pos) {
    final a = audio;
    if (a == null) return;
    final ms = pos.inMilliseconds;
    final (v, w) = a.locate(ms);
    final verseChanged = v != currentVerse;
    final wordChanged = w != currentWord;
    if (verseChanged || wordChanged) {
      currentVerse = v;
      currentWord = w;
      notifyListeners();
    }
  }

  Future<void> load({
    required int reciterId,
    required int chapter,
    int resumeMs = 0,
    bool autoplay = true,
  }) async {
    this.reciterId = reciterId;
    this.chapter = chapter;
    status = PlayerStatus.loading;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        api.fetchAudio(reciterId, chapter),
        api.fetchVerses(chapter),
      ]);
      final a = results[0] as ChapterAudio;
      final v = results[1] as List<Verse>;
      audio = a;
      verses = v;
      currentVerse = 0;
      currentWord = null;
      // Release the current source first: on web, setting a new source while
      // the old one is active can leave the underlying media element playing
      // the previous file (stale audio after switching surah).
      try {
        await _player.stop();
      } catch (_) {}
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(a.url)),
        preload: true,
      );
      status = PlayerStatus.ready;
      notifyListeners();
      if (resumeMs > 0) {
        await _player.seek(Duration(milliseconds: resumeMs));
      }
      if (autoplay) await _player.play();
    } catch (e) {
      status = PlayerStatus.error;
      error = e is ApiException ? e.message : 'Playback failed: $e';
      notifyListeners();
    }
  }

  /// Reload keeping the current ayah position (e.g. after switching reciter).
  Future<void> reloadSamePosition({bool autoplay = true}) async {
    final keepVerse = currentVerse;
    final t = audio?.timings;
    final ms = (t != null && t.isNotEmpty)
        ? t[keepVerse.clamp(0, t.length - 1)].from
        : 0;
    await load(
      reciterId: reciterId,
      chapter: chapter,
      resumeMs: ms,
      autoplay: autoplay,
    );
  }

  void togglePlay() {
    if (status != PlayerStatus.ready) return;
    _player.playing ? _player.pause() : _player.play();
    notifyListeners();
  }

  void play() {
    if (status == PlayerStatus.ready) _player.play();
  }

  void pause() => _player.pause();

  Future<void> seekToVerse(int index) async {
    final a = audio;
    if (a == null || a.timings.isEmpty) return;
    final i = index.clamp(0, a.timings.length - 1);
    await _player.seek(Duration(milliseconds: a.timings[i].from));
    currentVerse = i;
    currentWord = null;
    notifyListeners();
  }

  Future<void> seekRelative(int delta) => seekToVerse(currentVerse + delta);

  Future<void> seekFraction(double f) async {
    final d = duration;
    if (d.inMilliseconds == 0) return;
    await _player.seek(
      Duration(milliseconds: (d.inMilliseconds * f.clamp(0, 1)).round()),
    );
  }

  double get progress {
    final d = duration.inMilliseconds;
    return d == 0 ? 0 : (position.inMilliseconds / d).clamp(0, 1);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
