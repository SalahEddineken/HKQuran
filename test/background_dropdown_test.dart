import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkquran/state/app_state.dart';
import 'package:hkquran/theme/palette.dart';
import 'package:hkquran/ui/background_changer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Background changer button toggles dropdown and hover previews background', (tester) async {
    SharedPreferences.setMockInitialValues({'watchface': 2});
    final state = await AppState.load();
    bool open = false;

    Widget buildTestWidget() => MaterialApp(
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.ltr,
          child: AppStateScope(
            state: state,
            child: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox.expand(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 20,
                        right: 20,
                        child: ElevatedButton(
                          key: const ValueKey('toggleBtn'),
                          onPressed: () => setState(() => open = !open),
                          child: const Icon(Icons.wallpaper_rounded),
                        ),
                      ),
                      BackgroundDropdown(
                        isOpen: open,
                        topOffset: 80,
                        endOffset: 20,
                        onClose: () => setState(() {
                          open = false;
                          state.previewWatchface(null);
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify initially closed
    expect(find.byType(ListView), findsNothing);

    // Tap the wallpaper button
    await tester.tap(find.byKey(const ValueKey('toggleBtn')));
    await tester.pumpAndSettle();

    // Dropdown is now open and displays the cards
    expect(find.byType(ListView), findsOneWidget);

    // Initial state
    expect(state.watchface, 2);
    expect(state.effectiveWatchface, 2);

    // Simulate hover over first card (White watchface, targetIndex = 0)
    final firstCard = find.descendant(
      of: find.byType(BackgroundDropdown),
      matching: find.byType(MouseRegion),
    ).at(1); // skip outer list MouseRegion

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    await gesture.moveTo(tester.getCenter(firstCard));
    await tester.pumpAndSettle();

    // Live preview should now reflect index 0 (White) while saved remains 2
    expect(state.effectiveWatchface, 0);
    expect(state.watchface, 2);
    expect(state.themeMode, AppThemeMode.light);

    // Move cursor outside the dropdown
    await gesture.moveTo(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Preview should reset to saved watchface 2
    expect(state.effectiveWatchface, 2);
    expect(state.themeMode, AppThemeMode.dark);

    // Click on the first card to commit
    await tester.tap(firstCard);
    await tester.pumpAndSettle();

    // Watchface is now permanently set to 0
    expect(state.watchface, 0);
    expect(state.effectiveWatchface, 0);
    expect(state.themeMode, AppThemeMode.light);

    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });
}
