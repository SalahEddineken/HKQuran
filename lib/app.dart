import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/palette.dart';

import 'state/app_state.dart';
import 'theme/strings.dart';
import 'ui/home_screen.dart';

class HKQuranApp extends StatefulWidget {
  final AppState state;
  const HKQuranApp({super.key, required this.state});

  @override
  State<HKQuranApp> createState() => _HKQuranAppState();
}

class _HKQuranAppState extends State<HKQuranApp> {
  late Locale _locale;
  late AppThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _locale = widget.state.locale;
    _themeMode = widget.state.themeMode;
    widget.state.addListener(_onStateChange);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    final s = widget.state;
    if (s.locale != _locale || s.themeMode != _themeMode) {
      setState(() {
        _locale = s.locale;
        _themeMode = s.themeMode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final theme = hkquranTheme(_themeMode.brightness, _themeMode.seed);
    return AppStateScope(
      state: s,
      child: MaterialApp(
        title: 'HKQuran',
        debugShowCheckedModeBanner: false,
        locale: _locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: theme,
        darkTheme: theme,
        themeMode: ThemeMode.light,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.unknown,
            PointerDeviceKind.trackpad,
          },
        ),
        builder: (context, child) {
          Widget current = child ?? const SizedBox.shrink();
          if (!kIsWeb && Platform.isWindows) {
            // Prevent Windows embedder crash (0xc0000005 in flutter_windows.dll accessibility_bridge.cc AXTree)
            current = ExcludeSemantics(child: current);
          }
          return Directionality(
            textDirection: _locale.languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: current,
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}

/// Backward compatibility alias
typedef NoorApp = HKQuranApp;
