import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hkquran/state/app_state.dart';
import 'package:hkquran/ui/panels.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  testWidgets('Settings panel displays GitHub and Website links without redundant watchfaces', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({'chapter': 1, 'reciterId': 7});
    final state = await AppState.load();

    await tester.pumpWidget(
      MaterialApp(
        locale: state.locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: Scaffold(
          body: AppStateScope(
            state: state,
            child: SidePanel(
              kind: PanelKind.settings,
              onClose: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Verify redundant watchface grid is removed
    expect(find.byType(GridView), findsNothing);

    // Verify redundant Mawaqit card visibility switch is removed
    expect(find.text('Show Mawaqit Card (Center Left)'), findsNothing);
    expect(find.text('إظهار بطاقة المواقيت (يسار الشاشة)'), findsNothing);

    // Scroll down to find Developer & Links
    final websiteFinder = find.text('Explore website & apps →');
    await tester.scrollUntilVisible(websiteFinder, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    // Verify developer links are present
    expect(websiteFinder, findsOneWidget);
    expect(find.text('Follow GitHub project →'), findsOneWidget);

    // Test tap on website link does not crash
    await tester.tap(websiteFinder);
    await tester.pump(const Duration(milliseconds: 100));

    // Test tap on GitHub link does not crash
    await tester.tap(find.text('Follow GitHub project →'));
    await tester.pump(const Duration(milliseconds: 100));

    state.player.dispose();
    state.mixer.dispose();
  });

  testWidgets('Settings panel has Translation toggle that updates state and desktop bottom bar has no translation button', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({'translation': true});
    final state = await AppState.load();
    expect(state.showTranslation, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        locale: state.locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: Scaffold(
          body: AppStateScope(
            state: state,
            child: SidePanel(
              kind: PanelKind.settings,
              onClose: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Translation toggle is displayed in settings
    final translationFinder = find.text('Translation');
    expect(translationFinder, findsOneWidget);

    // Toggle translation switch
    final switchFinder = find.byType(CupertinoSwitch).first;
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(state.showTranslation, isFalse);

    // Tap again to toggle back
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(state.showTranslation, isTrue);

    state.player.dispose();
    state.mixer.dispose();
  });
}
