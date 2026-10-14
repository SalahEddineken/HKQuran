import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PaintingBinding.instance.imageCache.maximumSizeBytes = 60 * 1024 * 1024; // 60 MB max
  PaintingBinding.instance.imageCache.maximumSize = 15; // 15 images max

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

  // Debug aid: ?semantics=1 forces the web semantics tree on so automated
  // tools can reach every button. No effect in normal use.
  if (Uri.base.queryParameters['semantics'] == '1') {
    SemanticsBinding.instance.ensureSemantics();
  }

  runApp(NoorApp(state: state));
}
