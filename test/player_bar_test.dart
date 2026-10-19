import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hkquran/state/app_state.dart';
import 'package:hkquran/ui/player_bar.dart';

void main() {
  testWidgets('PlayerBar uses spinning vinyl as play/pause button and has no repeat or speed buttons', (tester) async {
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

    // Repeat toggle chip is removed from the player bar
    expect(find.byIcon(Icons.repeat_rounded), findsNothing);

    // No play/pause icons on the disk or transport — pure spinning motion indicates state
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    expect(find.byIcon(Icons.pause_rounded), findsNothing);

    // Previous and Next buttons should exist
    expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
    expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);

    // Volume button is removed from player bar in favor of mouse wheel control
    expect(find.byTooltip('Mute'), findsNothing);
    expect(find.byTooltip('Unmute'), findsNothing);

    // Initial volume is 1.0; scrolling down decreases volume
    expect(state.reciterVolume, equals(1.0));
    final playerBarFinder = find.byType(PlayerBar);
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(playerBarFinder),
        scrollDelta: const Offset(0, 100),
      ),
    );
    await tester.pump();
    expect(state.reciterVolume, lessThan(1.0));

    // Spinning vinyl disk button exists via its tooltip
    expect(find.byTooltip('Play'), findsOneWidget);

    // Unmount before disposing state to cleanly shut down controllers
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    state.dispose();
  });
}
