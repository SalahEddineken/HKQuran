import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hkquran/state/app_state.dart';
import 'package:hkquran/ui/home_screen.dart';
import 'package:hkquran/ui/surah_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  testWidgets('Desktop: SurahMenuButton toggles SurahSelectorPopup with search and selection', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({'chapter': 1});
    final state = await AppState.load();

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          state: state,
          child: const HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Verify SurahSelectorPopup is initially closed
    expect(find.byType(SurahSelectorPopup), findsOneWidget);
    expect(find.text('Al-Baqara'), findsNothing);

    // Find the SurahMenuButton (eject icon button at bottom right)
    final ejectBtnFinder = find.byType(SurahMenuButton);
    expect(ejectBtnFinder, findsOneWidget);

    // Tap the eject button to open the selector
    await tester.tap(ejectBtnFinder);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify SurahSelectorPopup is now visible and displays surahs
    expect(find.text('Al-Faatiha'), findsOneWidget);
    expect(find.text('Al-Baqara'), findsOneWidget);

    // Verify search works
    final searchFinder = find.byType(TextField);
    expect(searchFinder, findsOneWidget);
    await tester.enterText(searchFinder, 'Yunus');
    await tester.pump(const Duration(milliseconds: 300));

    // In the ListView, Yunus is visible
    final yunusInList = find.descendant(
      of: find.byType(ListView),
      matching: find.text('Yunus'),
    );
    expect(yunusInList, findsOneWidget);
    expect(find.text('Al-Faatiha'), findsNothing);

    // Tap on Yunus in the list
    await tester.tap(yunusInList);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Yunus (chapter 10) was selected
    expect(state.chapter, equals(10));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
    state.dispose();
  });

  testWidgets('Desktop: Pressing escape or tapping outside closes SurahSelectorPopup', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({'chapter': 1});
    final state = await AppState.load();

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          state: state,
          child: const HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Open via SurahMenuButton
    final ejectBtnFinder = find.byType(SurahMenuButton);
    await tester.tap(ejectBtnFinder);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Al-Faatiha'), findsOneWidget);

    // Tap outside (center of screen)
    await tester.tapAt(const Offset(400, 400));
    await tester.pump(const Duration(milliseconds: 300));

    // Selector should be closed
    expect(find.text('Al-Baqara'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
    state.dispose();
  });

  testWidgets('Mobile: Tapping Surahs in navigation dock toggles SurahSelectorPopup', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({'chapter': 1});
    final state = await AppState.load();

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          state: state,
          child: const HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Find the Surahs button in mobile nav dock
    final surahsIconFinder = find.byIcon(Icons.format_list_numbered_rounded);
    expect(surahsIconFinder, findsOneWidget);

    // Tap it to open SurahSelectorPopup
    await tester.tap(surahsIconFinder);
    await tester.pump(const Duration(milliseconds: 300));

    // Surah selector popup is open
    expect(find.text('Al-Faatiha'), findsOneWidget);
    expect(find.text('Al-Baqara'), findsOneWidget);

    // Tap it again to close
    await tester.tap(surahsIconFinder);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Al-Baqara'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
    state.dispose();
  });
}
