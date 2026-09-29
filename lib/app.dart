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
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return AppStateScope(
      state: s,
      child: ListenableBuilder(
        listenable: s,
        builder: (context, _) {
          final theme = noorTheme(s.themeMode.brightness, s.themeMode.seed);
          return MaterialApp(
            title: 'Noor',
            debugShowCheckedModeBanner: false,
            locale: s.locale,
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: theme,
            darkTheme: theme,
            themeMode: ThemeMode.light,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
