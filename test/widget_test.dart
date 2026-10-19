import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hkquran/audio/ambient_mixer.dart';
import 'package:hkquran/audio/chapter_player.dart';
import 'package:hkquran/data/hijri.dart';
import 'package:hkquran/data/models.dart';
import 'package:hkquran/data/quran_api.dart';
import 'package:hkquran/state/app_state.dart';
import 'package:hkquran/ui/focus_pill.dart';

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

  test('ten ambient channels with valid assets and presets', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final mixer = AmbientMixer();
    expect(mixer.channels.length, 10);
    expect(
      mixer.channels.map((c) => c.id).toList(),
      [
        'rain',
        'stream',
        'ocean',
        'droplets',
        'birds',
        'fire',
        'wind',
        'thunder',
        'night',
        'desert',
      ],
    );
    expect(kAmbientPresets.length, 5);

    // Apply preset
    final preset = kAmbientPresets.first;
    mixer.applyPreset(preset);
    expect(mixer.isPresetActive(preset), isTrue);
    expect(mixer.activeCount, preset.levels.length);

    // Ambient sound plays immediately when activated
    expect(mixer.effective(0), greaterThan(0.0));

    // Mute all
    mixer.muteAll();
    expect(mixer.activeCount, 0);
    expect(mixer.anyOn, isFalse);

    // Master mute toggle
    mixer.setMaster(0.85);
    mixer.toggleMasterMute();
    expect(mixer.master, 0.0);
    mixer.toggleMasterMute();
    expect(mixer.master, 0.85);

    mixer.dispose();
  });

  test('QuranApi pre-seeded Surah 1 is immediately available in cache', () {
    final api = QuranApi();
    expect(api.hasCachedVerses(1), isTrue);
    expect(api.hasCachedAudio(7, 1), isTrue);

    final verses = api.getCachedVerses(1);
    expect(verses, isNotNull);
    expect(verses!.length, 7);
    expect(verses.first.number, 1);
    expect(verses.first.words.length, 4);

    final audio = api.getCachedAudio(7, 1);
    expect(audio, isNotNull);
    expect(audio!.chapter, 1);
    expect(audio.reciterId, 7);
    expect(audio.timings.length, 7);
    api.dispose();
  });

  test('Verse and ChapterAudio JSON serialization round-trips accurately', () {
    const verse = Verse(
      key: '2:255',
      number: 255,
      text: 'ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ',
      translation: 'Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence.',
      words: [
        AyahWord(1, 'ٱللَّهُ'),
        AyahWord(2, 'لَآ'),
      ],
    );

    final verseJson = verse.toJson();
    final restoredVerse = Verse.fromJson(verseJson);
    expect(restoredVerse.key, verse.key);
    expect(restoredVerse.number, verse.number);
    expect(restoredVerse.text, verse.text);
    expect(restoredVerse.translation, verse.translation);
    expect(restoredVerse.words.length, 2);
    expect(restoredVerse.words[0].text, 'ٱللَّهُ');

    const audio = ChapterAudio(
      reciterId: 6,
      chapter: 112,
      url: 'https://example.com/112.mp3',
      timings: [
        VerseTiming(
          key: '112:1',
          from: 0,
          to: 3500,
          segments: [WordSegment(1, 0, 1000), WordSegment(2, 1000, 3500)],
        ),
      ],
    );

    final audioJson = audio.toJson();
    final restoredAudio = ChapterAudio.fromJson(audioJson);
    expect(restoredAudio.reciterId, 6);
    expect(restoredAudio.chapter, 112);
    expect(restoredAudio.url, 'https://example.com/112.mp3');
    expect(restoredAudio.timings.length, 1);
    expect(restoredAudio.timings.first.segments.length, 2);
  });

  test('HijriDate correctly converts Gregorian dates', () {
    final hijri = HijriDate.fromGregorian(DateTime(2026, 9, 29));
    expect(hijri.year, greaterThanOrEqualTo(1447));
    expect(hijri.month, inInclusiveRange(1, 12));
    expect(hijri.day, inInclusiveRange(1, 30));
    expect(hijri.format(false), contains('AH'));
    expect(hijri.format(true), contains('هـ'));
  });

  testWidgets('safe notifyListeners defers when called during persistent callbacks', (tester) async {
    final api = QuranApi();
    final player = ChapterPlayer(api);
    var notified = false;
    player.addListener(() {
      notified = true;
    });

    // Simulate persistent callbacks phase
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          player.notifyListeners();
          return const SizedBox.shrink();
        },
      ),
    );

    // After the frame finishes building, the deferred listener callback is executed
    await tester.pump();
    expect(notified, isTrue);
    player.dispose();
  });

  testWidgets('Directionality is TextDirection.rtl when locale is Arabic', (tester) async {
    late TextDirection dir;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => Directionality(
          textDirection: Directionality.of(context),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Builder(
          builder: (context) {
            dir = Directionality.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(dir, TextDirection.rtl);
  });

  testWidgets('Directionality is TextDirection.ltr when locale is English', (tester) async {
    late TextDirection dir;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => Directionality(
          textDirection: Directionality.of(context),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Builder(
          builder: (context) {
            dir = Directionality.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(dir, TextDirection.ltr);
  });

  testWidgets('PositionedDirectional correctly places widgets at right edge in RTL', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: Stack(
            children: const [
              PositionedDirectional(
                start: 34,
                top: 30,
                child: SizedBox(key: ValueKey('testStart'), width: 50, height: 50),
              ),
              PositionedDirectional(
                end: 34,
                top: 30,
                child: SizedBox(key: ValueKey('testEnd'), width: 50, height: 50),
              ),
            ],
          ),
        ),
      ),
    );

    final startRect = tester.getRect(find.byKey(const ValueKey('testStart')));
    final endRect = tester.getRect(find.byKey(const ValueKey('testEnd')));

    // Under RTL, start is the right side (800 - 34 = 766)
    expect(startRect.right, 800.0 - 34.0);
    // Under RTL, end is the left side (34)
    expect(endRect.left, 34.0);
  });

  testWidgets('FocusPill toggle opens presets, starts countdown, and collapses cleanly', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    bool open = false;

    Widget buildPill() => MaterialApp(
      home: Scaffold(
        body: AppStateScope(
          state: state,
          child: StatefulBuilder(
            builder: (context, setState) => Center(
              child: FocusPill(
                open: open,
                onOpenChanged: (v) {
                  open = v;
                  setState(() {});
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(buildPill());
    await tester.pumpAndSettle();

    // Idle: Displays "Focus"
    expect(find.text('Focus'), findsOneWidget);
    expect(open, isFalse);

    // Tap to open presets
    await tester.tap(find.text('Focus'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(open, isTrue);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);

    // Pick 15 minutes preset
    await tester.tap(find.text('15'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Focus session started! Presets should be closed and countdown visible
    expect(state.focusing, isTrue);
    expect(open, isFalse);
    expect(find.textContaining(':'), findsWidgets);

    // Tap the toggle again to end focus
    await tester.tap(find.textContaining(':').first);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(state.focusing, isFalse);
    expect(find.text('Focus'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    state.dispose();
  });

  testWidgets('FocusPill renders without error in RTL mode', (tester) async {
    SharedPreferences.setMockInitialValues({'locale': 'ar'});
    final state = await AppState.load();
    bool open = false;

    Widget buildPill() => MaterialApp(
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: AppStateScope(
            state: state,
            child: StatefulBuilder(
              builder: (context, setState) => Center(
                child: FocusPill(
                  open: open,
                  onOpenChanged: (v) {
                    open = v;
                    setState(() {});
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(buildPill());
    await tester.pumpAndSettle();

    // Arabic label for focus
    expect(find.text(state.tr('focus')), findsOneWidget);

    // Tap to open presets in RTL
    await tester.tap(find.text(state.tr('focus')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(open, isTrue);
    expect(find.text('15'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    state.dispose();
  });

  testWidgets('30 min and 45 min preset buttons are clickable within stack and Column bounds', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    bool open = false;

    Widget buildScreen() => MaterialApp(
      home: Scaffold(
        body: AppStateScope(
          state: state,
          child: StatefulBuilder(
            builder: (context, setState) => Stack(
              children: [
                // Tap-outside detector behind FocusPill
                if (open)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => open = false),
                      child: const ColoredBox(color: Colors.transparent),
                    ),
                  ),
                // Top center FocusPill inside Positioned -> Center -> Column
                Positioned(
                  top: 66,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FocusPill(
                          open: open,
                          onOpenChanged: (v) => setState(() => open = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Test 30 min button
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    // Open presets
    await tester.tap(find.text('Focus'));
    await tester.pumpAndSettle();
    expect(open, isTrue);

    // Tap 30 min button
    await tester.tap(find.text('30'));
    await tester.pumpAndSettle();

    // Must start 30 min session, not be swallowed by tap-outside detector
    expect(state.focusing, isTrue);
    expect(state.focusPreviewMinutes, 30);
    expect(open, isFalse);

    // Stop focus
    state.endFocus();
    await tester.pumpAndSettle();
    expect(state.focusing, isFalse);

    // Open presets again
    await tester.tap(find.text('Focus'));
    await tester.pumpAndSettle();
    expect(open, isTrue);

    // Tap 45 min button
    await tester.tap(find.text('45'));
    await tester.pumpAndSettle();

    // Must start 45 min session, not be swallowed by tap-outside detector
    expect(state.focusing, isTrue);
    expect(state.focusPreviewMinutes, 45);
    expect(open, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    state.dispose();
  });
}



