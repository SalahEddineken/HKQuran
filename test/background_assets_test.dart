import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/theme/palette.dart';
import 'package:noor/ui/background.dart';
import 'package:noor/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

(int, int)? _getJpegDimensions(List<int> bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return null;
  var i = 2;
  while (i + 8 < bytes.length) {
    if (bytes[i] != 0xFF) {
      i++;
      continue;
    }
    final marker = bytes[i + 1];
    i += 2;
    if (marker == 0xC0 || marker == 0xC1 || marker == 0xC2) {
      final height = (bytes[i + 3] << 8) | bytes[i + 4];
      final width = (bytes[i + 5] << 8) | bytes[i + 6];
      return (width, height);
    }
    final length = (bytes[i] << 8) | bytes[i + 1];
    i += length;
  }
  return null;
}

void main() {
  test('White and Black backgrounds are preserved as the first watchfaces', () {
    expect(kWatchfaces[0].asset, isNull);
    expect(kWatchfaces[0].nameEn, 'White');
    expect(kWatchfaces[0].isWhite, isTrue);

    expect(kWatchfaces[1].asset, isNull);
    expect(kWatchfaces[1].nameEn, 'Black');
    expect(kWatchfaces[1].isBlack, isTrue);
  });

  test('all background photo assets exist and are true 4K resolution (3840x2160)', () {
    final photoWatchfaces = kWatchfaces.where((w) => w.asset != null).toList();
    expect(photoWatchfaces, isNotEmpty);

    for (final wf in photoWatchfaces) {
      final file = File(wf.asset!);
      expect(file.existsSync(), isTrue, reason: '${wf.asset} must exist on disk');

      final bytes = file.readAsBytesSync();
      final dims = _getJpegDimensions(bytes);
      expect(dims, isNotNull, reason: 'Must be a valid JPEG: ${wf.asset}');
      final (width, height) = dims!;
      expect(width, equals(3840), reason: '${wf.asset} width should be 3840 (4K UHD)');
      expect(height, equals(2160), reason: '${wf.asset} height should be 2160 (4K UHD)');
    }
  });

  testWidgets('WatchfaceBackground widget renders without throwing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(
          home: Scaffold(
            body: WatchfaceBackground(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WatchfaceBackground), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });

  testWidgets('White background sets light theme and Black/Image sets dark theme', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();

    // Select White
    state.setWatchface(0);
    expect(state.watchface, 0);
    expect(kWatchfaces[state.watchface].isWhite, isTrue);
    expect(state.themeMode, AppThemeMode.light);

    // Select Black
    state.setWatchface(1);
    expect(state.watchface, 1);
    expect(kWatchfaces[state.watchface].isBlack, isTrue);
    expect(state.themeMode, AppThemeMode.dark);

    // Select Mosque (Image)
    state.setWatchface(2);
    expect(state.watchface, 2);
    expect(kWatchfaces[state.watchface].isImage, isTrue);
    expect(state.themeMode, AppThemeMode.dark);

    state.dispose();
  });
}
