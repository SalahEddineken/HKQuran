import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hkquran/state/app_state.dart';
import 'package:hkquran/ui/home_screen.dart';
import 'package:hkquran/ui/todo_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  testWidgets('TodoCard renders on bottom left with Today, items, and Add to-do', (tester) async {
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

    // Verify TodoCard is present in HomeScreen
    expect(find.byType(TodoCard), findsOneWidget);

    // Verify "Today" title is rendered
    expect(find.text('Today'), findsOneWidget);

    // Verify "Add to-do" button is rendered
    expect(find.text('Add to-do'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
    state.dispose();
  });

  testWidgets('TodoCard allows adding new todo and toggling it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppStateScope(
            state: state,
            child: const Center(
              child: TodoCard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initial state: 0 items
    expect(state.todos.length, equals(0));

    // Tap "Add to-do" to reveal inline input
    await tester.tap(find.text('Add to-do'));
    await tester.pumpAndSettle();

    // TextField should be present
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    // Enter new todo text and submit
    await tester.enterText(textFieldFinder, 'Read Surah Al-Kahf');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Verify new todo added
    expect(state.todos.length, equals(1));
    expect(find.text('Read Surah Al-Kahf'), findsOneWidget);
    expect(state.todos.first.completed, isFalse);

    // Tap checkbox to toggle it
    final checkboxFinder = find.byType(AnimatedContainer);
    expect(checkboxFinder, findsWidgets);
    await tester.tap(checkboxFinder.first);
    await tester.pumpAndSettle();

    // Now completed
    expect(state.todos.first.completed, isTrue);

    // Tap collapse button in header
    final collapseBtnFinder = find.byTooltip('Collapse');
    expect(collapseBtnFinder, findsOneWidget);
    await tester.tap(collapseBtnFinder);
    await tester.pumpAndSettle();

    // Now collapsed (shows pill with count)
    expect(state.todoCollapsed, isTrue);
    expect(find.text('Add to-do'), findsNothing);

    // Tap pill to expand back
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(state.todoCollapsed, isFalse);
    expect(find.byType(TextField), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    state.dispose();
  });

  testWidgets('TodoCard positioning: centered above PlayerBar on phone, bottom-start on desktop', (tester) async {
    // 1. Phone viewport
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

    final todoRectPhone = tester.getRect(find.byType(TodoCard));
    // Centered horizontally on phone (width 390 -> center dx ~ 195)
    expect((todoRectPhone.center.dx - 195.0).abs(), lessThan(2.0));

    // 2. Desktop viewport
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();

    final todoRectDesktop = tester.getRect(find.byType(TodoCard));
    // Positioned at bottom-start (left side of screen) on desktop
    expect(todoRectDesktop.left, lessThan(60.0));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
    state.dispose();
  });
}
