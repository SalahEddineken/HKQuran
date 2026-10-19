import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/ambient_mixer.dart';
import '../audio/chapter_player.dart';
import '../data/models.dart';
import '../data/prayer_times_service.dart';
import '../data/quran_api.dart';
import '../data/todo.dart';
import '../services/notification_service.dart';
import '../theme/palette.dart';
import '../theme/strings.dart';

/// App-wide state + persistence. UI listens through [AppStateScope].
class AppState extends ChangeNotifier {
  AppState._(this.prefs, this.prayerService) {
    _instance = this;
    player = ChapterPlayer(QuranApi(prefs: prefs));
    mixer = AmbientMixer();
    _restore();
    _attach();
  }

  static AppState? _instance;
  static AppState? get current => _instance;

  final SharedPreferences prefs;
  late final ChapterPlayer player;
  late final AmbientMixer mixer;
  final PrayerTimesService prayerService;

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final prayerService = await PrayerTimesService.create();
    return AppState._(prefs, prayerService);
  }

  // ---- Mawaqit (Prayer Times) ----
  bool desktopMawaqitOpen = true;
  bool desktopMawaqitCollapsed = false;

  void toggleDesktopMawaqit() {
    desktopMawaqitOpen = !desktopMawaqitOpen;
    prefs.setBool('desktopMawaqitOpen', desktopMawaqitOpen);
    notifyListeners();
  }

  void toggleDesktopMawaqitCollapse() {
    desktopMawaqitCollapsed = !desktopMawaqitCollapsed;
    prefs.setBool('desktopMawaqitCollapsed', desktopMawaqitCollapsed);
    notifyListeners();
  }

  // ---- persisted settings ----
  Locale locale = const Locale('en');
  AppThemeMode themeMode = AppThemeMode.dark;
  int watchface = 3;
  int? _previewWatchface;

  int get effectiveWatchface => _previewWatchface ?? watchface;
  int? get previewingWatchface => _previewWatchface;

  int reciterId = kReciters.first.id;
  int chapter = 1;
  bool showTranslation = true;
  double reciterVolume = 1.0;
  double _preMuteReciterVolume = 1.0;

  // ---- bookmark & study ----
  int? bookmarkChapter;
  int? bookmarkVerse;

  // ---- audio playback extras ----
  bool autoAdvance = true;
  double arabicTextScale = 1.0;

  // ---- focus session ----
  DateTime? focusEnd;
  int focusPreviewMinutes = 0;

  // ---- to-do list ----
  List<TodoItem> todos = [];
  bool todoCollapsed = false;

  bool get ar => locale.languageCode == 'ar';
  bool get focusing => focusEnd != null && focusEnd!.isAfter(DateTime.now());

  Duration get focusRemaining =>
      focusing ? focusEnd!.difference(DateTime.now()) : Duration.zero;

  String tr(String key) {
    final m = kStringsLookup[key];
    if (m == null) return key;
    return m[ar ? 'ar' : 'en'] ?? m['en'] ?? key;
  }

  void _restore() {
    locale = Locale(prefs.getString('locale') ?? 'en');
    watchface = (prefs.getInt('watchface') ?? 3).clamp(
      0,
      kWatchfaces.length - 1,
    );
    _syncThemeWithWatchface();
    reciterId = prefs.getInt('reciter') ?? kReciters.first.id;
    chapter = 1;
    showTranslation = prefs.getBool('translation') ?? true;
    autoAdvance = prefs.getBool('autoAdvance') ?? true;
    arabicTextScale = (prefs.getDouble('arabicScale') ?? 1.0).clamp(0.8, 1.4);
    bookmarkChapter = prefs.getInt('bmChapter');
    bookmarkVerse = prefs.getInt('bmVerse');

    final savedSpeed = prefs.getDouble('playerSpeed') ?? 1.0;
    player.setSpeed(savedSpeed);

    final savedRepeat = prefs.getInt('repeatMode') ?? 0;
    player.repeatMode = AudioRepeatMode.values[savedRepeat.clamp(0, AudioRepeatMode.values.length - 1)];

    final vols = (prefs.getStringList(
      'ambVol',
    ))?.map((e) => double.tryParse(e) ?? 0.7).toList();
    final ons = prefs.getStringList('ambOn')?.map((e) => e == '1').toList();
    final master = prefs.getDouble('ambMaster') ?? 0.8;
    if (vols != null && ons != null) {
      mixer.restore(vols, ons, master);
    }
    reciterVolume = (prefs.getDouble('reciterVol') ?? 1.0).clamp(0.0, 1.0);
    player.setVolume(reciterVolume);

    final savedTodos = prefs.getStringList('todos_list');
    if (savedTodos != null) {
      todos = savedTodos.map((s) {
        try {
          return TodoItem.fromJson(jsonDecode(s) as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      }).whereType<TodoItem>().toList();
    } else {
      todos = [];
    }
    todoCollapsed = prefs.getBool('todoCollapsed') ?? false;
    desktopMawaqitOpen = prefs.getBool('desktopMawaqitOpen') ?? true;
    desktopMawaqitCollapsed = prefs.getBool('desktopMawaqitCollapsed') ?? false;

    if (!kIsWeb) {
      prayerService.onPrayerArrived = (prayer, ar, en) {
        if (prayerService.notificationEnabled) {
          NotificationService.instance.showPrayerNotification(
            prayerNameAr: ar,
            prayerNameEn: en,
            cityName: prayerService.cityName,
          );
        }
      };
    }

    _applyUriOverrides();
  }

  void _syncThemeWithWatchface() {
    final wf = kWatchfaces[effectiveWatchface];
    themeMode = wf.isWhite ? AppThemeMode.light : AppThemeMode.dark;
  }

  /// Deep links / test hooks: `?watchface=4&locale=ar&surah=36`
  /// `&reciter=7&focus=30`. Never persisted.
  void _applyUriOverrides() {
    final q = Uri.base.queryParameters;
    final wf = int.tryParse(q['watchface'] ?? '');
    if (wf != null) {
      watchface = wf.clamp(0, kWatchfaces.length - 1);
      _syncThemeWithWatchface();
    }
    final t = q['theme'];
    if (t != null) {
      if (t == 'light') {
        watchface = 0;
        themeMode = AppThemeMode.light;
      } else if (t == 'dark') {
        if (kWatchfaces[watchface].isWhite) watchface = 1;
        themeMode = AppThemeMode.dark;
      }
    }
    final loc = q['locale'];
    if (loc == 'ar' || loc == 'en') locale = Locale(loc!);
    final rec = int.tryParse(q['reciter'] ?? '');
    if (rec != null && kReciters.any((r) => r.id == rec)) reciterId = rec;
    final ch = int.tryParse(q['surah'] ?? '');
    if (ch != null) chapter = ch.clamp(1, 114);
    final foc = int.tryParse(q['focus'] ?? '');
    if (foc != null && foc > 0) {
      focusEnd = DateTime.now().add(Duration(minutes: foc));
    }
  }

  void _attach() {
    player.addListener(_onPlayer);
    // Auto-advance to the next Surah when playback completes
    player.onSurahCompleted = () {
      if (autoAdvance) {
        final next = chapter < 114 ? chapter + 1 : 1;
        openSurah(next, autoplay: true);
      }
    };
    // Forward mixer changes so ambient sliders/toggles update the UI live.
    mixer.addListener(_onMixer);
    // Forward prayer time changes
    prayerService.addListener(notifyListeners);
  }

  PlayerStatus? _lastPlayerStatus;
  bool _lastPlayerPlaying = false;
  int _lastPlayerChapter = -1;
  int _lastPlayerVerse = -1;
  Timer? _saveTimer;

  void _onPlayer() {
    final statusChanged = player.status != _lastPlayerStatus;
    final playingChanged = player.playing != _lastPlayerPlaying;
    final chapterChanged = player.chapter != _lastPlayerChapter;
    final verseChanged = player.currentVerse != _lastPlayerVerse;

    _lastPlayerStatus = player.status;
    _lastPlayerPlaying = player.playing;
    _lastPlayerChapter = player.chapter;
    _lastPlayerVerse = player.currentVerse;

    // Only notify AppStateScope dependents if macroscopic playback state changed
    // (play/pause, chapter, verse change, or status), NOT on every individual word change.
    // Word-by-word karaoke is handled reactively by AyahCard via ListenableBuilder(listenable: player).
    if (statusChanged || playingChanged || chapterChanged || verseChanged) {
      notifyListeners();
    }

    if (_saveTimer == null && player.status == PlayerStatus.ready) {
      _saveTimer = Timer(const Duration(seconds: 4), () {
        _saveTimer = null;
        if (player.status == PlayerStatus.ready) {
          prefs.setInt('position', player.position.inMilliseconds);
        }
      });
    }
  }

  void _onMixer() => notifyListeners();

  // ---- setters (persist immediately) ----
  void setLocale(Locale l) {
    locale = l;
    prefs.setString('locale', l.languageCode);
    notifyListeners();
  }

  void cycleLocale() => setLocale(ar ? const Locale('en') : const Locale('ar'));

  void setTheme(AppThemeMode m) {
    if (m == AppThemeMode.light) {
      setWatchface(0);
    } else {
      if (kWatchfaces[watchface].isWhite) {
        setWatchface(1);
      }
    }
  }

  void cycleTheme() => cycleWatchface();

  void previewWatchface(int? index) {
    if (_previewWatchface != index) {
      _previewWatchface = index;
      _syncThemeWithWatchface();
      notifyListeners();
    }
  }

  void setWatchface(int i) {
    _previewWatchface = null;
    watchface = i.clamp(0, kWatchfaces.length - 1);
    _syncThemeWithWatchface();
    prefs.setInt('watchface', watchface);
    prefs.setInt('theme', themeMode.index);
    notifyListeners();
  }

  void cycleWatchface() => setWatchface((watchface + 1) % kWatchfaces.length);

  void setReciter(int id) {
    reciterId = id;
    player.reciterId = id;
    prefs.setInt('reciter', id);
    notifyListeners();
  }

  void setChapter(int n) {
    chapter = n.clamp(1, 114);
    prefs.setInt('chapter', chapter);
    notifyListeners();
  }

  void setTranslation(bool val) {
    if (showTranslation == val) return;
    showTranslation = val;
    prefs.setBool('translation', showTranslation);
    notifyListeners();
  }

  void toggleTranslation() => setTranslation(!showTranslation);

  void toggleAutoAdvance() {
    autoAdvance = !autoAdvance;
    prefs.setBool('autoAdvance', autoAdvance);
    notifyListeners();
  }

  void setArabicTextScale(double scale) {
    arabicTextScale = scale.clamp(0.8, 1.4);
    prefs.setDouble('arabicScale', arabicTextScale);
    notifyListeners();
  }

  void saveBookmark(int ch, int v) {
    if (bookmarkChapter == ch && bookmarkVerse == v) {
      bookmarkChapter = null;
      bookmarkVerse = null;
      prefs.remove('bmChapter');
      prefs.remove('bmVerse');
    } else {
      bookmarkChapter = ch;
      bookmarkVerse = v;
      prefs.setInt('bmChapter', ch);
      prefs.setInt('bmVerse', v);
    }
    notifyListeners();
  }

  bool isBookmarked(int ch, int v) =>
      bookmarkChapter == ch && bookmarkVerse == v;

  void saveAmbient() {
    prefs.setStringList(
      'ambVol',
      mixer.channels.map((c) => c.volume.toString()).toList(),
    );
    prefs.setStringList(
      'ambOn',
      mixer.channels.map((c) => c.on ? '1' : '0').toList(),
    );
    prefs.setDouble('ambMaster', mixer.master);
  }

  void setReciterVolume(double v) {
    reciterVolume = v.clamp(0.0, 1.0);
    prefs.setDouble('reciterVol', reciterVolume);
    player.setVolume(reciterVolume);
    notifyListeners();
  }

  void toggleReciterMute() {
    if (reciterVolume > 0) {
      _preMuteReciterVolume = reciterVolume;
      setReciterVolume(0);
    } else {
      setReciterVolume(_preMuteReciterVolume > 0 ? _preMuteReciterVolume : 1.0);
    }
  }

  void cycleSpeed() {
    player.cycleSpeed();
    prefs.setDouble('playerSpeed', player.speed);
    notifyListeners();
  }

  void cycleRepeatMode() {
    player.cycleRepeatMode();
    prefs.setInt('repeatMode', player.repeatMode.index);
    notifyListeners();
  }

  void cycleAyahRepeatTarget() {
    player.cycleAyahRepeatTarget();
    notifyListeners();
  }

  void startFocus(int minutes) {
    focusEnd = DateTime.now().add(Duration(minutes: minutes));
    focusPreviewMinutes = minutes;
    notifyListeners();
  }

  void endFocus() {
    focusEnd = null;
    notifyListeners();
  }

  Future<void> openSurah(int n, {bool autoplay = true}) async {
    final fresh = player.status == PlayerStatus.idle;
    int resume = 0;
    if (fresh) {
      if ((prefs.getInt('chapter') ?? n) == n) {
        resume = prefs.getInt('position') ?? 0;
      }
    } else if (player.chapter == n) {
      resume = player.position.inMilliseconds;
    }
    setChapter(n);
    await player.load(
      reciterId: reciterId,
      chapter: n,
      resumeMs: resume,
      autoplay: autoplay,
    );
  }

  Future<void> changeReciter(int id) async {
    setReciter(id);
    await player.reloadSamePosition();
  }

  // ---- to-do list actions ----
  void addTodo(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final item = TodoItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: trimmed,
      completed: false,
      createdAt: DateTime.now(),
    );
    todos = [...todos, item];
    _saveTodos();
    notifyListeners();
  }

  void toggleTodo(String id) {
    final idx = todos.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final item = todos[idx];
      todos = List.of(todos)..[idx] = item.copyWith(completed: !item.completed);
      _saveTodos();
      notifyListeners();
    }
  }

  void removeTodo(String id) {
    todos = todos.where((t) => t.id != id).toList();
    _saveTodos();
    notifyListeners();
  }

  void clearCompletedTodos() {
    todos = todos.where((t) => !t.completed).toList();
    _saveTodos();
    notifyListeners();
  }

  void setTodoCollapsed(bool collapsed) {
    todoCollapsed = collapsed;
    prefs.setBool('todoCollapsed', collapsed);
    notifyListeners();
  }

  void toggleTodoCollapsed() => setTodoCollapsed(!todoCollapsed);

  void _saveTodos() {
    final list = todos.map((t) => jsonEncode(t.toJson())).toList();
    prefs.setStringList('todos_list', list);
  }

  @override
  void notifyListeners() {
    try {
      if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (hasListeners) super.notifyListeners();
        });
        return;
      }
    } catch (_) {}
    super.notifyListeners();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    player.removeListener(_onPlayer);
    mixer.removeListener(_onMixer);
    prayerService.removeListener(notifyListeners);
    player.dispose();
    mixer.dispose();
    prayerService.dispose();
    super.dispose();
  }
}

/// The string table lives in strings.dart; re-exported lookup for AppState.
const Map<String, Map<String, String>> kStringsLookup = kStrings;

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    if (context is Element) {
      bool isInactive = false;
      assert(() {
        if (!context.debugIsActive) {
          isInactive = true;
        }
        return true;
      }());
      if (isInactive || !context.mounted) {
        if (AppState.current != null) return AppState.current!;
      }
    }

    try {
      final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
      if (scope?.notifier != null) return scope!.notifier!;
    } catch (_) {
      if (AppState.current != null) return AppState.current!;
    }
    if (AppState.current != null) return AppState.current!;
    throw StateError('No AppState found in context');
  }
}
