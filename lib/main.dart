import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'audio/reciter_download_service.dart';
import 'firebase_options.dart';
import 'services/desktop_window_service.dart';
import 'services/notification_service.dart';
import 'state/app_state.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  PaintingBinding.instance.imageCache.maximumSizeBytes = 60 * 1024 * 1024; // 60 MB max
  PaintingBinding.instance.imageCache.maximumSize = 15; // 15 images max

  final isMinimized = !kIsWeb &&
      Platform.isWindows &&
      (args.contains('--minimized') ||
          Platform.executableArguments.contains('--minimized'));

  // Initialize desktop window, system tray, notifications and storage
  if (!kIsWeb && Platform.isWindows) {
    try {
      await DesktopWindowService.instance.init(startMinimized: isMinimized);
      await NotificationService.instance.init();
      await ReciterDownloadService.instance.init();
    } catch (e) {
      debugPrint('Desktop initialization note: $e');
    }
  }

  // Initialize Firebase with platform-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }

  final results = await Future.wait<dynamic>([
    AppState.load(),
    initializeDateFormatting('ar'),
  ]);
  final state = results[0] as AppState;

  // Connect desktop tray actions to app state
  if (!kIsWeb && Platform.isWindows) {
    DesktopWindowService.instance.onPlayPauseToggle =
        () => state.player.togglePlay();
    DesktopWindowService.instance.onNextDhikr =
        () => NotificationService.instance.showNextDhikrNotification(force: true);
  }

  // Debug aid: ?semantics=1 forces the web semantics tree on so automated
  // tools can reach every button. No effect in normal use.
  if (kIsWeb && Uri.base.queryParameters['semantics'] == '1') {
    SemanticsBinding.instance.ensureSemantics();
  }

  runApp(HKQuranApp(state: state));
}
