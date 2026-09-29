import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Glass surfaces are pure Flutter now (liquid_glass_ui_design) — no shader
  // precache needed. Prefs and Arabic date symbols still load before the
  // first frame so nothing pops in afterwards.
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
