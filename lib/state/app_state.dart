import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/ambient_mixer.dart';
import '../audio/chapter_player.dart';
import '../data/models.dart';
import '../data/quran_api.dart';
import '../theme/palette.dart';
import '../theme/strings.dart';

/// App-wide state + persistence. UI listens through [AppStateScope].
class AppState extends ChangeNotifier {
  AppState._(this.prefs) {
    player = ChapterPlayer(QuranApi());
    mixer = AmbientMixer();
    _restore();
    _attach();
  }

  final SharedPreferences prefs;
  late final ChapterPlayer player;
  late final AmbientMixer mixer;

  static Future<AppState> load() async =>
      AppState._(await SharedPreferences.getInstance());

  // ---- persisted settings ----
  Locale locale = const Locale('en');
  AppThemeMode themeMode = AppThemeMode.dark;
  int watchface = 2;
  int reciterId = kReciters.first.id;
  int chapter = 1;
  bool showTranslation = true;

  // ---- focus session ----
  DateTime? focusEnd;
  int focusPreviewMinutes = 0;

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
    themeMode =
        AppThemeMode.values[(prefs.getInt('theme') ?? 2).clamp(
          0,
          AppThemeMode.values.length - 1,
        )];
    watchface = (prefs.getInt('watchface') ?? 2).clamp(
      0,
      kWatchfaces.length - 1,
    );
    reciterId = prefs.getInt('reciter') ?? kReciters.first.id;
    chapter = (prefs.getInt('chapter') ?? 1).clamp(1, 114);
    showTranslation = prefs.getBool('translation') ?? true;
    final vols = (prefs.getStringList(
      'ambVol',
    ))?.map((e) => double.parse(e)).toList();
    final ons = prefs.getStringList('ambOn')?.map((e) => e == '1').toList();
    final master = prefs.getDouble('ambMaster') ?? 0.8;
    if (vols != null && ons != null) mixer.restore(vols, ons, master);
    _applyUriOverrides();
  }

  /// Deep links / test hooks: `?theme=light&watchface=4&locale=ar&surah=36`
  /// `&reciter=7&focus=30`. Never persisted.
  void _applyUriOverrides() {
    final q = Uri.base.queryParameters;
    final t = q['theme'];
    if (t != null) {
      final i = AppThemeMode.values.indexWhere((m) => m.name == t);
      if (i >= 0) themeMode = AppThemeMode.values[i];
    }
    final wf = int.tryParse(q['watchface'] ?? '');
    if (wf != null) watchface = wf.clamp(0, kWatchfaces.length - 1);
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
    // Forward mixer changes so ambient sliders/toggles update the UI live.
    mixer.addListener(_onMixer);
  }

  bool _saving = false;
  void _onPlayer() {
    notifyListeners();
    if (!_saving && player.status == PlayerStatus.ready) {
      _saving = true;
      Future.delayed(const Duration(seconds: 4), () {
        _saving = false;
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
    themeMode = m;
    prefs.setInt('theme', m.index);
    notifyListeners();
  }

  void cycleTheme() => setTheme(
    AppThemeMode.values[(themeMode.index + 1) % AppThemeMode.values.length],
  );

  void setWatchface(int i) {
    watchface = i.clamp(0, kWatchfaces.length - 1);
    prefs.setInt('watchface', watchface);
    notifyListeners();
  }

  void cycleWatchface() => setWatchface((watchface + 1) % kWatchfaces.length);

  void setReciter(int id) {
    reciterId = id;
    prefs.setInt('reciter', id);
    notifyListeners();
  }

  void setChapter(int n) {
    chapter = n.clamp(1, 114);
    prefs.setInt('chapter', chapter);
    notifyListeners();
  }

  void toggleTranslation() {
    showTranslation = !showTranslation;
    prefs.setBool('translation', showTranslation);
    notifyListeners();
  }

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

  @override
  void dispose() {
    player.removeListener(_onPlayer);
    mixer.removeListener(_onMixer);
    player.dispose();
    mixer.dispose();
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

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppStateScope>()!.notifier!;
}
