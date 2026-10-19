import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hkquran/state/app_state.dart';
import 'package:hkquran/ui/home_screen.dart';
import 'package:hkquran/ui/panels.dart';
import 'package:hkquran/ui/reciter_selector.dart';
import 'package:hkquran/ui/surah_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  testWidgets('Desktop: ReciterMenuButton toggles ReciterSelectorPopup with search and selection', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({'chapter': 1, 'reciterId': 7});
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

    // Verify ReciterSelectorPopup is initially closed
    expect(find.byType(ReciterSelectorPopup), findsOneWidget);
    expect(find.text('Mahmoud Khalil Al-Husary'), findsNothing);

    // Find the ReciterMenuButton at bottom right
    final reciterBtnFinder = find.byType(ReciterMenuButton);
    expect(reciterBtnFinder, findsOneWidget);

    // Translation button has been moved to settings panel, so it is absent from bottom controls
    expect(find.byIcon(Icons.translate_rounded), findsNothing);

    // Tap to open the popup
    await tester.tap(reciterBtnFinder);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify ReciterSelectorPopup is now visible and displays reciters
    expect(find.text('Mishary Rashid Alafasy'), findsOneWidget);
    expect(find.text('Mahmoud Khalil Al-Husary'), findsOneWidget);

    // Verify search works
    final searchFinder = find.descendant(
      of: find.byType(ReciterSelectorPopup),
      matching: find.byType(TextField),
    );
    expect(searchFinder, findsOneWidget);
    await tester.enterText(searchFinder, 'Sudais');
    await tester.pump(const Duration(milliseconds: 300));

    // Find Sudais in list
    final sudaisInList = find.descendant(
      of: find.byType(ListView),
      matching: find.text('Abdur-Rahman as-Sudais'),
    );
    expect(sudaisInList, findsOneWidget);
    expect(find.text('Mahmoud Khalil Al-Husary'), findsNothing);

    // Tap on Sudais
    await tester.tap(sudaisInList);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify reciter changed to Sudais (id: 3)
    expect(state.reciterId, equals(3));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
    state.dispose();
  });

  testWidgets('Desktop: Settings button is at top left and AmbientPanel is embedded on the right', (tester) async {
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

    // Verify AmbientPanel is rendered on the screen
    expect(find.byType(AmbientPanel), findsOneWidget);

    // Verify Settings button is present with tune icon
    final settingsIconFinder = find.byIcon(Icons.tune_rounded);
    expect(settingsIconFinder, findsOneWidget);

    // Tap the settings button
    await tester.tap(settingsIconFinder);
    await tester.pump(const Duration(milliseconds: 400));

    // Verify SettingsPanel opened without SidePanel
    expect(find.byType(SettingsPanel), findsOneWidget);
    expect(find.byType(SidePanel), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
    state.dispose();
  });

  testWidgets('Desktop: Ambient sound panel fades out when Surah or Reciter selector opens', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({'chapter': 1, 'reciterId': 7});
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

    // Tap ambient button to open ambient sound panel
    final ambientBtn = find.byIcon(Icons.waves_rounded).first;
    await tester.tap(ambientBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // Find the AnimatedOpacity wrapping the AmbientPanel container
    final ambientFinder = find.byType(AmbientPanel);
    expect(ambientFinder, findsOneWidget);

    final opacityBefore = tester.widget<AnimatedOpacity>(
      find.ancestor(of: ambientFinder, matching: find.byType(AnimatedOpacity)).first,
    );
    expect(opacityBefore.opacity, equals(1.0));

    // Tap ReciterMenuButton to open reciter picker
    final reciterBtn = find.byType(ReciterMenuButton);
    await tester.tap(reciterBtn);
    await tester.pump(const Duration(milliseconds: 300));

    final opacityDuringReciter = tester.widget<AnimatedOpacity>(
      find.ancestor(of: ambientFinder, matching: find.byType(AnimatedOpacity)).first,
    );
    expect(opacityDuringReciter.opacity, equals(0.0));

    // Tap ReciterMenuButton again to close it
    await tester.tap(reciterBtn);
    await tester.pump(const Duration(milliseconds: 300));

    final opacityAfterReciter = tester.widget<AnimatedOpacity>(
      find.ancestor(of: ambientFinder, matching: find.byType(AnimatedOpacity)).first,
    );
    expect(opacityAfterReciter.opacity, equals(1.0));

    // Now tap SurahMenuButton to open surah picker
    final surahBtn = find.byType(SurahMenuButton);
    await tester.tap(surahBtn);
    await tester.pump(const Duration(milliseconds: 300));

    final opacityDuringSurah = tester.widget<AnimatedOpacity>(
      find.ancestor(of: ambientFinder, matching: find.byType(AnimatedOpacity)).first,
    );
    expect(opacityDuringSurah.opacity, equals(0.0));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
    state.dispose();
  });
}
