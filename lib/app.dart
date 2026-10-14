import 'theme/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'state/app_state.dart';
import 'theme/strings.dart';
import 'ui/home_screen.dart';

class NoorApp extends StatefulWidget {
  final AppState state;
  const NoorApp({super.key, required this.state});

  @override
  State<NoorApp> createState() => _NoorAppState();
}

class _NoorAppState extends State<NoorApp> {
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
    final theme = noorTheme(_themeMode.brightness, _themeMode.seed);
    return AppStateScope(
      state: s,
      child: MaterialApp(
        title: 'Noor',
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
        builder: (context, child) => Directionality(
          textDirection: _locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
