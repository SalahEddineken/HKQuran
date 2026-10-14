import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noor/data/models.dart';
import 'package:noor/state/app_state.dart';
import 'package:noor/ui/home_screen.dart';
import 'package:noor/ui/ayah_card.dart';
import 'package:noor/ui/clock_view.dart';
import 'package:noor/ui/player_bar.dart';

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

  testWidgets('PlayerBar includes repeat toggle chip in the title area', (tester) async {
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

    // Repeat toggle chip is inside PlayerBar
    expect(find.descendant(
      of: find.byType(PlayerBar),
      matching: find.byIcon(Icons.repeat_rounded),
    ), findsOneWidget);

    expect(find.descendant(
      of: find.byType(PlayerBar),
      matching: find.text('1x'),
    ), findsOneWidget);

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
}
