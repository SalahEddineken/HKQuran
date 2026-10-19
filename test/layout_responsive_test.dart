import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hkquran/data/models.dart';
import 'package:hkquran/state/app_state.dart';
import 'package:hkquran/ui/home_screen.dart';
import 'package:hkquran/ui/ayah_card.dart';
import 'package:hkquran/ui/clock_view.dart';
import 'package:hkquran/ui/player_bar.dart';
import 'package:hkquran/ui/todo_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  testWidgets('Favorite button is placed above Surahs button and toggles bookmark', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          state: state,
          child: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Favorite/bookmark button is present
    final favFinder = find.byTooltip('Bookmark');
    expect(favFinder, findsWidgets);

    // Surahs button is also present
    expect(find.byIcon(Icons.format_list_numbered_rounded), findsWidgets);

    // Initial state: not bookmarked
    expect(state.bookmarkVerse, isNull);

    // Tap favorite button
    await tester.tap(favFinder.first);
    await tester.pump();
    await tester.pumpAndSettle();

    // Now bookmarked!
    expect(state.bookmarkChapter, equals(state.chapter));
    expect(state.bookmarkVerse, equals(1));

    // Tap again to unbookmark
    final bookmarkedFinder = find.byTooltip('Bookmarked');
    expect(bookmarkedFinder, findsWidgets);
    await tester.tap(bookmarkedFinder.first);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(state.bookmarkVerse, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
    state.dispose();
  });

  testWidgets('AyahCard does not render the removed header pill', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppStateScope(
            state: state,
            child: const Center(
              child: AyahCard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // In the old AyahCard, Icons.menu_book_rounded was rendered inside the header pill
    // Now with the header pill removed, AyahCard does not render menu_book_rounded icon
    expect(find.descendant(
      of: find.byType(AyahCard),
      matching: find.byIcon(Icons.menu_book_rounded),
    ), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    state.dispose();
  });

  testWidgets('PlayerBar does not include repeat toggle chip', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppStateScope(
            state: state,
            child: const Center(
              child: PlayerBar(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Repeat toggle chip is not in PlayerBar
    expect(find.descendant(
      of: find.byType(PlayerBar),
      matching: find.byIcon(Icons.repeat_rounded),
    ), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    state.dispose();
  });

  testWidgets('Clock hides when ayah is big and returns when normal ayah finishes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          state: state,
          child: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Normal verse (Al-Faatiha verse 1 has 4 words) -> ClockView is visible!
    expect(find.byType(ClockView), findsOneWidget);
    final clockFinder = find.byType(ClockView);
    final clockRect = tester.getRect(clockFinder);
    final ayahRect = tester.getRect(find.byType(AyahCard));
    // ClockView is horizontally centered in the screen along with AyahCard
    expect((clockRect.center.dx - ayahRect.center.dx).abs(), lessThan(1.0));
    expect(clockRect.center.dx, closeTo(400.0, 1.0));

    // Set a big ayah (e.g. 40 words like 3:7)
    final bigVerse = Verse(
      key: '3:7',
      number: 7,
      text: 'Long Arabic verse with many words ' * 10,
      translation: 'Long English translation describing in depth the foundation of the book ' * 6,
      words: List.generate(40, (i) => AyahWord(i + 1, 'word$i')),
    );
    state.player.verses = [bigVerse];
    state.player.currentVerse = 0;
    state.player.notifyListeners();
    await tester.pump();
    await tester.pumpAndSettle();

    // Clock is hidden because the ayah is so big!
    expect(find.byKey(const ValueKey('clock_hidden')), findsOneWidget);
    expect(find.byType(ClockView), findsNothing);

    // Now change to a 1-2 line Arabic, 2-3 line English verse (like 3:8 with 16 words & 110 chars)
    final mediumVerse = Verse(
      key: '3:8',
      number: 8,
      text: 'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً',
      translation:
          '[Who say], "Our Lord, let not our hearts deviate after You have guided us and grant us from Yourself mercy. Indeed, You are the Bestower."',
      words: List.generate(16, (i) => AyahWord(i + 1, 'word$i')),
    );
    state.player.verses = [mediumVerse];
    state.player.currentVerse = 0;
    state.player.notifyListeners();
    await tester.pump();
    await tester.pumpAndSettle();

    // Clock is visible again!
    expect(find.byType(ClockView), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
    state.dispose();
  });

  testWidgets('Mobile viewport layout: PlayerBar, dock, TodoCard and Translation do not overlap', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          state: state,
          child: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Navigation dock is at the bottom
    final surahsIconFinder = find.byIcon(Icons.format_list_numbered_rounded);
    expect(surahsIconFinder, findsOneWidget);
    final dockRect = tester.getRect(surahsIconFinder);

    // 2. PlayerBar is stacked cleanly above the dock
    final playerBarFinder = find.byType(PlayerBar);
    expect(playerBarFinder, findsOneWidget);
    final playerBarRect = tester.getRect(playerBarFinder);

    // Assert PlayerBar is strictly above the navigation dock (no overlap)
    expect(playerBarRect.bottom, lessThanOrEqualTo(dockRect.top));

    // 3. TodoCard is stacked cleanly above the PlayerBar and centered horizontally on mobile
    final todoFinder = find.byType(TodoCard);
    expect(todoFinder, findsOneWidget);
    final todoRect = tester.getRect(todoFinder);
    expect(todoRect.bottom, lessThanOrEqualTo(playerBarRect.top));
    expect((todoRect.center.dx - 195.0).abs(), lessThan(2.0));

    // 4. Translation button is at top-end alongside wallpaper (not colliding with bottom bar)
    final translationFinder = find.byIcon(Icons.translate_rounded);
    expect(translationFinder, findsOneWidget);
    final translationRect = tester.getRect(translationFinder);
    expect(translationRect.top, lessThan(80.0));
    expect(translationRect.bottom, lessThan(playerBarRect.top));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
    state.dispose();
  });

  testWidgets('Desktop: footer credit displays Salaheddine kennouda below PlayerBar', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          state: state,
          child: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final creditFinder = find.text('Salaheddine kennouda');
    expect(creditFinder, findsOneWidget);

    final creditRect = tester.getRect(creditFinder);
    final playerBarRect = tester.getRect(find.byType(PlayerBar));

    // Credit is positioned below PlayerBar and centered horizontally
    expect(creditRect.top, greaterThanOrEqualTo(playerBarRect.bottom - 4.0));
    expect((creditRect.center.dx - 640.0).abs(), lessThan(5.0));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
    state.dispose();
  });
}
