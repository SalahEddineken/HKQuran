import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';

import '../data/models.dart';
import '../data/quran_api.dart';

enum PlayerStatus { idle, loading, ready, error }

enum AudioRepeatMode { off, repeatSurah, repeatAyah }

/// Streams one surah at a time from quran.com's chapter files and exposes
/// karaoke state: the current ayah and the current word being recited.
/// Optimized for instant reciter switching, non-blocking playback,
/// and intelligent proactive prefetching.
class ChapterPlayer extends ChangeNotifier {
  final QuranApi api;
  ChapterPlayer(this.api) {
    _player.positionStream.listen(_onPosition);
    _player.playerStateStream.listen((state) {
      notifyListeners();
      if (state.processingState == ProcessingState.completed) {
        _handlePlaybackCompleted();
      }
    });
    _player.durationStream.listen((_) => notifyListeners());

    // Immediately seed with cached Surah 1 so frame 1 renders verses instantly
    final v = api.getCachedVerses(chapter);
    if (v != null && v.isNotEmpty) {
      verses = v;
    }
    final a = api.getCachedAudio(reciterId, chapter);
    if (a != null) {
      audio = a;
    }
  }

  final AudioPlayer _player = AudioPlayer();

  bool _audioSourceLoaded = false;
  bool get isAudioSourceLoaded => _audioSourceLoaded;
  PlayerStatus status = PlayerStatus.idle;
  String? error;
  ChapterAudio? audio;
  List<Verse> verses = const [];

  int reciterId = kReciters.first.id;
  int chapter = 1;

  int currentVerse = 0;
  int? currentWord;

  // Playback speed & repeat modes
  double speed = 1.0;
  AudioRepeatMode repeatMode = AudioRepeatMode.off;
  int ayahRepeatTarget = 1; // 1: once, 3: 3x, 5: 5x, 0: infinite loop
  int currentAyahRepeatCount = 0;
  VoidCallback? onSurahCompleted;

  AudioPlayer get rawPlayer => _player;
  bool get playing => _player.playing;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  double get volume => _player.volume;
  Verse? get verse =>
      verses.isEmpty ? null : verses[currentVerse.clamp(0, verses.length - 1)];

  Future<void> setVolume(double v) async {
    await _player.setVolume(v.clamp(0.0, 1.0));
    notifyListeners();
  }

  Future<void> setSpeed(double s) async {
    speed = s;
    await _player.setSpeed(s);
    notifyListeners();
  }

  void cycleSpeed() {
    const speeds = [0.75, 1.0, 1.25, 1.5];
    final idx = speeds.indexWhere((sp) => (sp - speed).abs() < 0.05);
    final next = speeds[(idx + 1) % speeds.length];
    setSpeed(next);
  }

  void cycleRepeatMode() {
    repeatMode = switch (repeatMode) {
      AudioRepeatMode.off => AudioRepeatMode.repeatSurah,
      AudioRepeatMode.repeatSurah => AudioRepeatMode.repeatAyah,
      AudioRepeatMode.repeatAyah => AudioRepeatMode.off,
    };
    currentAyahRepeatCount = 0;
    notifyListeners();
  }

  void cycleAyahRepeatTarget() {
    const targets = [1, 3, 5, 0];
    final idx = targets.indexOf(ayahRepeatTarget);
    ayahRepeatTarget = targets[(idx + 1) % targets.length];
    currentAyahRepeatCount = 0;
    notifyListeners();
  }

  void _handlePlaybackCompleted() {
    if (repeatMode == AudioRepeatMode.repeatSurah) {
      seekFraction(0);
      play();
    } else if (repeatMode == AudioRepeatMode.repeatAyah) {
      seekToVerse(currentVerse);
      play();
    } else {
      onSurahCompleted?.call();
    }
  }

  void _onPosition(Duration pos) {
    final a = audio;
    if (a == null) return;
    final ms = pos.inMilliseconds;
    final (v, w) = a.locate(ms);
    final verseChanged = v != currentVerse;
    final wordChanged = w != currentWord;

    // Ayah repeat logic for Hifdh mode
    if (repeatMode == AudioRepeatMode.repeatAyah && a.timings.isNotEmpty) {
      final t = a.timings;
      if (currentVerse < t.length) {
        final endMs = t[currentVerse].to;
        if (ms >= endMs - 75) {
          if (ayahRepeatTarget == 0 ||
              currentAyahRepeatCount + 1 < ayahRepeatTarget) {
            currentAyahRepeatCount++;
            seekToVerse(currentVerse);
            return;
          } else {
            currentAyahRepeatCount = 0;
            if (currentVerse + 1 < t.length) {
              seekToVerse(currentVerse + 1);
              return;
            }
          }
        }
      }
    }

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
    error = null;

    // Check instant cache availability
    final cachedAudio = api.getCachedAudio(reciterId, chapter);
    final cachedVerses = api.getCachedVerses(chapter);

    if (cachedVerses != null && cachedVerses.isNotEmpty) {
      verses = cachedVerses;
    } else {
      verses = const [];
    }
    if (cachedAudio != null) {
      audio = cachedAudio;
    } else {
      audio = null;
    }

    // Set loading if either audio or verses are not in cache
    if (audio == null || verses.isEmpty) {
      status = PlayerStatus.loading;
      notifyListeners();
    }

    try {
      // 1. Fetch verses if not in cache
      if (verses.isEmpty) {
        final v = await api.fetchVerses(chapter);
        if (this.chapter != chapter) return;
        verses = v;
        notifyListeners();
      }

      // 2. Fetch audio if not in cache
      final a = audio ?? await api.fetchAudio(reciterId, chapter);
      if (this.chapter != chapter || this.reciterId != reciterId) {
        return;
      }
      audio = a;
      currentVerse = 0;
      currentWord = null;

      try {
        await _player.stop();
      } catch (_) {}

      // Supports both local assets ('assets/audio/...') and remote URLs with fallback
      try {
        await _setAudioSource(a.url, reciterId, chapter);
        _audioSourceLoaded = true;
      } catch (e) {
        debugPrint('Audio loading error: $e');
      }

      if (resumeMs > 0) {
        final (v, w) = a.locate(resumeMs);
        currentVerse = v;
        currentWord = w;
        try {
          await _player.seek(Duration(milliseconds: resumeMs));
        } catch (_) {}
      }

      status = PlayerStatus.ready;
      notifyListeners();

      if (autoplay) {
        try {
          await _player.play();
        } catch (_) {}
      }

      _triggerPrefetch(chapter, reciterId);
    } catch (e) {
      status = PlayerStatus.error;
      error = e is ApiException ? e.message : 'Playback failed: $e';
      notifyListeners();
    }
  }

  /// Sets audio source supporting Flutter asset bundles with remote fallback.
  Future<void> _setAudioSource(String url, int rId, int ch) async {
    final reciter = reciterById(rId);
    final remote = reciter.remoteAudioUrl(ch);

    // On Web, stream directly from high-speed CDN to keep website bundle lightweight & instant
    if (kIsWeb && remote != null) {
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(remote)),
        preload: true,
      );
      return;
    }

    if (url.startsWith('assets/')) {
      try {
        await _player
            .setAsset(url, preload: true)
            .timeout(const Duration(seconds: 5));
        return;
      } catch (_) {
        // Fallback to remote CDN if local asset is not on disk yet or fails
        if (remote != null) {
          await _player
              .setAudioSource(
                AudioSource.uri(Uri.parse(remote)),
                preload: true,
              )
              .timeout(const Duration(seconds: 8));
          return;
        }
        rethrow;
      }
    } else {
      await _player
          .setAudioSource(
            AudioSource.uri(Uri.parse(url)),
            preload: true,
          )
          .timeout(const Duration(seconds: 8));
    }
  }

  /// Ultra-fast reciter switch: does NOT re-fetch verses, smoothly transfers
  /// ayah playback position to the new reciter's audio stream.
  Future<void> reloadSamePosition({bool autoplay = true}) async {
    final keepVerse = currentVerse;
    final targetReciter = reciterId;
    final targetChapter = chapter;

    try {
      final cachedAudio = api.getCachedAudio(targetReciter, targetChapter);
      final ChapterAudio a = cachedAudio ??
          await api.fetchAudio(targetReciter, targetChapter);

      if (reciterId != targetReciter || chapter != targetChapter) return;

      audio = a;
      final t = a.timings;
      final ms = (t.isNotEmpty && keepVerse < t.length)
          ? t[keepVerse.clamp(0, t.length - 1)].from
          : 0;

      try {
        await _player.stop();
      } catch (_) {}

      try {
        await _setAudioSource(a.url, targetReciter, targetChapter);
        _audioSourceLoaded = true;
      } catch (e) {
        debugPrint('Audio reload error: $e');
      }

      status = PlayerStatus.ready;
      currentVerse = keepVerse;
      currentWord = null;
      notifyListeners();

      if (ms > 0) {
        try {
          await _player.seek(Duration(milliseconds: ms));
        } catch (_) {}
      }
      if (autoplay) {
        try {
          await _player.play();
        } catch (_) {}
      }

      _triggerPrefetch(targetChapter, targetReciter);
    } catch (e) {
      await load(
        reciterId: reciterId,
        chapter: chapter,
        resumeMs: 0,
        autoplay: autoplay,
      );
    }
  }

  Timer? _prefetchTimer;

  void _triggerPrefetch(int ch, int reciter) {
    // Gently prefetch the next surah in the background without saturating browser network
    _prefetchTimer?.cancel();
    _prefetchTimer = Timer(const Duration(seconds: 4), () {
      if (!_disposed && chapter == ch && ch < 114) {
        api.prefetchSurah(reciter, ch + 1);
      }
    });
  }

  Future<void> togglePlay() async {
    if (status == PlayerStatus.error) return;
    if (!_audioSourceLoaded || _player.audioSource == null) {
      await load(reciterId: reciterId, chapter: chapter, autoplay: true);
      return;
    }
    _player.playing ? await _player.pause() : await _player.play();
    notifyListeners();
  }

  Future<void> play() async {
    if (status == PlayerStatus.error) return;
    if (!_audioSourceLoaded || _player.audioSource == null) {
      await load(reciterId: reciterId, chapter: chapter, autoplay: true);
      return;
    }
    await _player.play();
    notifyListeners();
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

  bool _disposed = false;

  @override
  void notifyListeners() {
    if (_disposed) return;
    try {
      final phase = SchedulerBinding.instance.schedulerPhase;
      if (phase == SchedulerPhase.persistentCallbacks) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!_disposed && hasListeners) super.notifyListeners();
        });
        return;
      }
    } catch (_) {}
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _prefetchTimer?.cancel();
    _player.dispose();
    api.dispose();
    super.dispose();
  }
}
