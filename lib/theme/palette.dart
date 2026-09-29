import 'package:flutter/material.dart';

enum AppThemeMode { light, dark, noor }

extension AppThemeModeX on AppThemeMode {
  String get label => switch (this) {
    AppThemeMode.light => 'Light',
    AppThemeMode.dark => 'Dark',
    AppThemeMode.noor => 'Noor',
  };

  /// Scrim painted over the background photo so text stays readable.
  Color get scrim => switch (this) {
    AppThemeMode.light => const Color(0xF2EDEDED),
    AppThemeMode.dark => const Color(0xB3000000),
    AppThemeMode.noor => const Color(0xC0053A30),
  };

  Brightness get brightness =>
      this == AppThemeMode.light ? Brightness.light : Brightness.dark;

  Color get ink =>
      this == AppThemeMode.light ? const Color(0xFF111111) : Colors.white;

  Color get inkSoft => switch (this) {
    AppThemeMode.light => const Color(0xFF9F9F9F),
    AppThemeMode.dark => const Color(0xFFA0A0A0),
    AppThemeMode.noor => const Color(0xFFB9CFC6),
  };

  Color get accent => switch (this) {
    AppThemeMode.light => const Color(0xFF9A6B12),
    AppThemeMode.dark => const Color(0xFFF0C878),
    AppThemeMode.noor => const Color(0xFFE4C27A),
  };

  Color get seed => switch (this) {
    AppThemeMode.light => const Color(0xFF6B5CE7),
    AppThemeMode.dark => const Color(0xFF7F8AA6),
    AppThemeMode.noor => const Color(0xFF2E8B6E),
  };
}

class Watchface {
  /// Null asset = plain solid theme background (zeno's watchface 0).
  final String? asset;
  final String nameEn;
  final String nameAr;
  const Watchface(this.asset, this.nameEn, this.nameAr);
}

const List<Watchface> kWatchfaces = [
  Watchface(null, 'Plain', 'سادة'),
  Watchface('assets/bg/bg1.jpg', 'Mosque', 'مسجد'),
  Watchface('assets/bg/bg2.jpg', 'Night sky', 'سماء ليلية'),
  Watchface('assets/bg/bg3.jpg', 'Rain', 'مطر'),
  Watchface('assets/bg/bg4.jpg', 'Ocean', 'محيط'),
  Watchface('assets/bg/bg5.jpg', 'Fire', 'نار'),
  Watchface('assets/bg/bg6.jpg', 'Snow', 'ثلج'),
];
